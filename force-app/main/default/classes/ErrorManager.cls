/** Handles HTTP response errors and collects DML failures for TSANet operations. */
public with sharing class ErrorManager {

    /** Exception thrown when an API response indicates an error. */
    public class ErrorManagerException extends Exception {}

    /** Wrapper for deserializing TSANet API error responses. */
    public class TSANetError {
        String message;
        String detail;
    }

    /**
     * Throws an exception if the HTTP response indicates an error.
     * @param response the HTTP response to inspect
     */
    public static void handleResponseErrors(HTTPResponse response){
        if(response.getStatusCode() != TSANetConstants.SUCCESS_CODE){
            if(response.getBody().contains('The authorization token provided was invalid.')){
                tsanetconnect__TSANet_Credentials__c cred = CredentialManager.getCredentials();
                Database.update(new tsanetconnect__TSANet_Credentials__c(Id = cred.Id, tsanetconnect__Token__c = NULL), AccessLevel.USER_MODE);
                throw new ErrorManagerException('Unauthorized');
            } else {
                TSANetError parsedError = (TSANetError) System.JSON.deserialize(response.getBody(), TSANetError.class);
                String errorMessage = parsedError.message != NULL ? parsedError.message : parsedError.detail;
                throw new ErrorManagerException(errorMessage);
            }
        }
    }

    /**
     * Collects error log records from upsert results for failed rows.
     * Each error captures: object name, row index, external Id, all field errors,
     * the failing record JSON, and the calling Apex stack — everything needed to triage.
     * @param results the Database.UpsertResult list
     * @param records the SObject records that were upserted
     * @param externalIdField the external Id field used for upsert
     * @return list of TSANetError__c records for failed rows
     */
    public static tsanetconnect__TSANetError__c[] collectErrors(List<Database.UpsertResult> results, List<SObject> records, SObjectField externalIdField) {
        tsanetconnect__TSANetError__c[] errors = new tsanetconnect__TSANetError__c[]{};

        if (results == null || results.isEmpty()) {
            return errors;
        }

        String objectName = (records != null && !records.isEmpty() && records[0] != null)
            ? String.valueOf(records[0].getSObjectType())
            : 'Unknown';
        String externalIdName = (externalIdField != null) ? externalIdField.getDescribe().getName() : '(none)';
        String callerStack = new DmlException().getStackTraceString();

        for (Integer i = 0; i < results.size(); i++) {
            Database.UpsertResult ur = results[i];
            if (ur == null || ur.isSuccess()) {
                continue;
            }

            SObject record = (records != null && i < records.size()) ? records[i] : null;
            String extIdValue = readExternalId(record, externalIdName);
            String recordJson = serializeRecordSafe(record);

            for (Database.Error e : ur.getErrors()) {
                String fieldsJoined = (e.getFields() == null || e.getFields().isEmpty())
                    ? '(none)'
                    : String.join(e.getFields(), ',');

                // ErrorMessage__c is LongTextArea(10000) — pack the full diagnostic payload here
                // since StackTrace__c is only Text(255).
                String errMsg =
                    'Upsert FAILED on ' + objectName + ' [row#' + i + ']' +
                    ' | externalId(' + externalIdName + ')=' + (extIdValue == null ? '(null)' : extIdValue) +
                    ' | StatusCode=' + e.getStatusCode() +
                    ' | Fields=[' + fieldsJoined + ']' +
                    ' | Message=' + e.getMessage() +
                    '\n--- Failing record ---\n' + recordJson +
                    '\n--- Caller stack ---\n' + callerStack;

                tsanetconnect__TSANetError__c errorLog = ErrorLogger.getLogError(errMsg, 'UPSERT_ERROR_LOG');
                errorLog.tsanetconnect__Type__c = 'Database.Error.' + String.valueOf(e.getStatusCode());
                errorLog.tsanetconnect__StackTrace__c = truncate(callerStack, 255);
                errors.add(errorLog);
            }
        }
        return errors;
    }

    /** Safely reads the external Id value from an SObject; returns null on any access error. */
    private static String readExternalId(SObject record, String fieldName) {
        if (record == null || String.isBlank(fieldName)) {
            return null;
        }
        try {
            Object value = record.get(fieldName);
            return value == null ? null : String.valueOf(value);
        } catch (Exception ex) {
            System.debug(LoggingLevel.WARN, 'ErrorManager.readExternalId: ' + ex.getMessage());
            return null;
        }
    }

    /** Safely serializes an SObject to JSON; returns a placeholder string on failure. */
    private static String serializeRecordSafe(SObject record) {
        if (record == null) {
            return '(null)';
        }
        try {
            return JSON.serialize(record);
        } catch (Exception ex) {
            return '(serialize failed: ' + ex.getMessage() + ')';
        }
    }

    /** Returns the first `maxLen` chars of `value`, or `value` if shorter; null-safe. */
    private static String truncate(String value, Integer maxLen) {
        if (String.isBlank(value) || value.length() <= maxLen) {
            return value;
        }
        return value.substring(0, maxLen);
    }

    /**
     * Checks whether the response body indicates an invalid authorization token.
     * @param body HTTP response body
     * @return true if the body contains the unauthorized message
     */
    public static Boolean isUnauthorized(String body){
        return body.contains('The authorization token provided was invalid');
    }
}