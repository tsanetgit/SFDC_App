/**
 * Centralised, race-safe upsert by external Id.
 *
 * Salesforce upsert internally does SELECT-by-external-Id then INSERT/UPDATE. When two
 * transactions upsert the same external Id concurrently, the loser's SELECT misses the
 * winner's row and falls into the INSERT branch — the unique index on the external Id
 * field then rejects it with DUPLICATE_VALUE.
 *
 * This utility recovers from that race by re-querying the existing record(s) by
 * external Id (USER_MODE) and retrying as Id-based UPDATE.
 */
public with sharing class UpsertExecutor {

    private static final String LOG_CONTEXT_RETRY = 'UPSERT_RETRY_ERROR_LOG';
    private static final Integer STACK_TRACE_MAX_LEN = 255;
    private static final Pattern SAFE_IDENTIFIER = Pattern.compile('^[A-Za-z0-9_]+$');

    /** Raised when a dynamic SOQL identifier fails validation. */
    public class UpsertExecutorException extends Exception {}

    /**
     * Upsert with concurrent-insert recovery.
     * @param records list of SObjects to upsert (no-op if null/empty)
     * @param externalIdField external Id field used to match existing rows
     * @param accessLevel access level for the initial upsert
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
     * Re-queries existing Ids by external Id (USER_MODE) and updates the records by Id.
     */
    private static void retryAsUpdate(List<SObject> records, SObjectField externalIdField){
        if (records == null || records.isEmpty()) { return; }

        DescribeSObjectResult objectDescribe = records[0].getSObjectType().getDescribe();
        String fieldName = externalIdField.getDescribe().getName();
        String objectName = objectDescribe.getName();

        Set<String> extIds = collectExternalIds(records, fieldName);
        if (extIds.isEmpty()) { return; }

        Map<String, Id> extIdToId = lookupExistingIds(objectDescribe, fieldName, extIds);
        List<SObject> toUpdate = stampIds(records, fieldName, extIdToId);
        if (toUpdate.isEmpty()) { return; }

        if (!objectDescribe.isUpdateable()) { return; }

        Database.SaveResult[] saveResults = Database.update(toUpdate, false, AccessLevel.USER_MODE);
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

    /**
     * Returns externalId-to-Id map by re-querying the object in USER_MODE.
     * Identifiers come from describe results and SAFE_IDENTIFIER, not caller input.
     */
    private static Map<String, Id> lookupExistingIds(DescribeSObjectResult objectDescribe,
                                                     String fieldName,
                                                     Set<String> extIds){
        String objectName = assertSafeIdentifier(objectDescribe.getName());
        String safeFieldName = assertSafeIdentifier(fieldName);

        if (!objectDescribe.fields.getMap().containsKey(safeFieldName)) {
            throw new UpsertExecutorException(
                'Unknown external Id field ' + safeFieldName + ' on ' + objectName
            );
        }

        String soql = 'SELECT Id, ' + safeFieldName + ' FROM ' + objectName +
                      ' WHERE ' + safeFieldName + ' IN :extIds';

        Map<String, Object> binds = new Map<String, Object>{ 'extIds' => extIds };
        Map<String, Id> extIdToId = new Map<String, Id>();
        for (SObject existing : Database.queryWithBinds(soql, binds, AccessLevel.USER_MODE)) {
            extIdToId.put(String.valueOf(existing.get(safeFieldName)), (Id) existing.get('Id'));
        }
        return extIdToId;
    }

    /** Rejects anything that is not a bare API name before it reaches dynamic SOQL. */
    private static String assertSafeIdentifier(String identifier){
        if (String.isBlank(identifier) || !SAFE_IDENTIFIER.matcher(identifier).matches()) {
            throw new UpsertExecutorException('Unsafe SOQL identifier: ' + identifier);
        }
        return identifier;
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
