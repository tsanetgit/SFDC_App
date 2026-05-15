/**
 * Centralised, race-safe upsert by external Id.
 *
 * Salesforce upsert internally does SELECT-by-external-Id then INSERT/UPDATE. When two
 * transactions upsert the same external Id concurrently, the loser's SELECT misses the
 * winner's row and falls into the INSERT branch — the unique index on the external Id
 * field then rejects it with DUPLICATE_VALUE.
 *
 * This utility transparently recovers from that race by re-querying the existing
 * record(s) by external Id and retrying as Id-based UPDATE, so the losing transaction's
 * payload still gets persisted. Only genuine, non-recoverable failures are written to
 * tsanetconnect__TSANetError__c.
 *
 * The recovery path runs in SYSTEM_MODE so it can also fix the cross-owner case where
 * the original upsert ran USER_MODE but the running user can't see the existing row
 * because of sharing/FLS.
 */
public without sharing class UpsertExecutor {

    private static final String LOG_CONTEXT_RETRY = 'UPSERT_RETRY_ERROR_LOG';
    private static final Integer STACK_TRACE_MAX_LEN = 255;

    /**
     * Upsert with concurrent-insert recovery.
     * @param records list of SObjects to upsert (no-op if null/empty)
     * @param externalIdField external Id field used to match existing rows
     * @param accessLevel access level for the initial upsert (USER_MODE or SYSTEM_MODE)
     */
    public static void execute(List<SObject> records,
                               SObjectField externalIdField,
                               AccessLevel accessLevel){
        if (records == null || records.isEmpty()) { return; }

        Database.UpsertResult[] results = Database.upsert(
            records, externalIdField, false, accessLevel
        );

        List<SObject> recoverable = new List<SObject>();
        List<Database.UpsertResult> hardErrors = new List<Database.UpsertResult>();
        List<SObject> hardErrorRecords = new List<SObject>();

        for (Integer i = 0; i < results.size(); i++) {
            if (results[i].isSuccess()) { continue; }
            if (isDuplicateValueError(results[i])) {
                recoverable.add(records[i]);
            } else {
                hardErrors.add(results[i]);
                hardErrorRecords.add(records[i]);
            }
        }

        retryAsUpdate(recoverable, externalIdField);

        if (!hardErrors.isEmpty()) {
            ErrorLogger.logErrors(
                ErrorManager.collectErrors(hardErrors, hardErrorRecords, externalIdField)
            );
        }
    }

    /** True when the result has at least one DUPLICATE_VALUE error. */
    private static Boolean isDuplicateValueError(Database.UpsertResult result){
        for (Database.Error e : result.getErrors()) {
            if (e.getStatusCode() == StatusCode.DUPLICATE_VALUE) { return true; }
        }
        return false;
    }

    /**
     * Re-queries existing Ids by external Id (SYSTEM_MODE) and updates the records
     * by Id; logs any retry failures. SYSTEM_MODE is intentional: the only reason we
     * are here is the running user couldn't see the existing row during the original
     * upsert's SELECT phase.
     */
    private static void retryAsUpdate(List<SObject> records, SObjectField externalIdField){
        if (records == null || records.isEmpty()) { return; }

        String fieldName = externalIdField.getDescribe().getName();
        String objectName = records[0].getSObjectType().getDescribe().getName();

        Set<String> extIds = collectExternalIds(records, fieldName);
        if (extIds.isEmpty()) { return; }

        Map<String, Id> extIdToId = lookupExistingIds(objectName, fieldName, extIds);
        List<SObject> toUpdate = stampIds(records, fieldName, extIdToId);
        if (toUpdate.isEmpty()) { return; }

        Database.SaveResult[] saveResults = Database.update(toUpdate, false, AccessLevel.SYSTEM_MODE);
        logRetryFailures(saveResults, toUpdate, fieldName, objectName);
    }

    /** Collects non-null external Id values from the given records into a Set. */
    private static Set<String> collectExternalIds(List<SObject> records, String fieldName){
        Set<String> extIds = new Set<String>();
        for (SObject r : records) {
            Object v = r.get(fieldName);
            if (v != null) { extIds.add(String.valueOf(v)); }
        }
        return extIds;
    }

    /** Returns externalId-to-Id map by re-querying the object in SYSTEM_MODE. */
    private static Map<String, Id> lookupExistingIds(String objectName,
                                                     String fieldName,
                                                     Set<String> extIds){
        String soql = 'SELECT Id, ' + fieldName + ' FROM ' + objectName +
                      ' WHERE ' + fieldName + ' IN :extIds WITH SYSTEM_MODE';
        Map<String, Id> extIdToId = new Map<String, Id>();
        for (SObject existing : Database.query(soql)) {
            extIdToId.put(String.valueOf(existing.get(fieldName)), (Id) existing.get('Id'));
        }
        return extIdToId;
    }

    /** Stamps each record's Id from the lookup map; returns the list ready for update. */
    private static List<SObject> stampIds(List<SObject> records,
                                          String fieldName,
                                          Map<String, Id> extIdToId){
        List<SObject> toUpdate = new List<SObject>();
        for (SObject r : records) {
            Id existingId = extIdToId.get(String.valueOf(r.get(fieldName)));
            if (existingId != null) {
                r.put('Id', existingId);
                toUpdate.add(r);
            }
        }
        return toUpdate;
    }

    /** Persists detailed error logs for any retry failures. */
    private static void logRetryFailures(Database.SaveResult[] saveResults,
                                         List<SObject> records,
                                         String fieldName,
                                         String objectName){
        tsanetconnect__TSANetError__c[] errors = new tsanetconnect__TSANetError__c[]{};
        String stack = new DmlException().getStackTraceString();

        for (Integer i = 0; i < saveResults.size(); i++) {
            if (saveResults[i].isSuccess()) { continue; }
            for (Database.Error e : saveResults[i].getErrors()) {
                String msg = 'Retry update FAILED on ' + objectName +
                    ' [externalId(' + fieldName + ')=' + String.valueOf(records[i].get(fieldName)) + ']' +
                    ' | StatusCode=' + e.getStatusCode() +
                    ' | Message=' + e.getMessage() +
                    '\n--- Failing record ---\n' + JSON.serialize(records[i]) +
                    '\n--- Caller stack ---\n' + stack;

                tsanetconnect__TSANetError__c log = ErrorLogger.getLogError(msg, LOG_CONTEXT_RETRY);
                log.tsanetconnect__Type__c = 'Database.Error.' + String.valueOf(e.getStatusCode());
                log.tsanetconnect__StackTrace__c = truncate(stack, STACK_TRACE_MAX_LEN);
                errors.add(log);
            }
        }
        if (!errors.isEmpty()) { ErrorLogger.logErrors(errors); }
    }

    /** Returns the first `maxLen` chars of `value`; null-safe. */
    private static String truncate(String value, Integer maxLen){
        if (String.isBlank(value) || value.length() <= maxLen) { return value; }
        return value.substring(0, maxLen);
    }
}
