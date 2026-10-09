/** Persists error and exception records for diagnostics and troubleshooting. */
public with sharing class ErrorLogger {

    private static final Integer STACK_TRACE_MAX_LEN = 255;

    /**
     * Single insert sink for error logs: object CRUD plus field-level create checks sit
     * next to the DML so scanners can bind them, and inaccessible fields are stripped.
     * @param logs error log records to persist
     */
    private static void insertLogs(tsanetconnect__TSANetError__c[] logs) {
        if (logs == null || logs.isEmpty()) {
            return;
        }
        if (!Schema.sObjectType.tsanetconnect__TSANetError__c.isCreateable()) {
            return;
        }
        SObjectAccessDecision decision = Security.stripInaccessible(AccessType.CREATABLE, logs);
        tsanetconnect__TSANetError__c[] safeLogs = new tsanetconnect__TSANetError__c[]{};
        for (SObject logRecord : decision.getRecords()) {
            safeLogs.add((tsanetconnect__TSANetError__c) logRecord);
        }
        if (safeLogs.isEmpty()) {
            return;
        }
        Database.insert(safeLogs, false, AccessLevel.USER_MODE);
    }

    /**
     * Truncates stack traces to fit tsanetconnect__StackTrace__c (Text 255).
     * @param stackTrace the full stack trace string
     * @return truncated stack trace or the original if within limit
     */
    private static String truncateStackTrace(String stackTrace) {
        if (String.isBlank(stackTrace)) {
            return stackTrace;
        }
        return stackTrace.length() > STACK_TRACE_MAX_LEN
            ? stackTrace.substring(0, STACK_TRACE_MAX_LEN)
            : stackTrace;
    }

    /**
     * Creates and inserts an error log record from an exception.
     * @param ex the caught exception
     * @param context description of where the error occurred
     */
    public static void logError(Exception ex, String context) {
        try {
            tsanetconnect__TSANetError__c  log = new tsanetconnect__TSANetError__c ();
            log.tsanetconnect__ErrorMessage__c  = ex.getMessage();
            log.tsanetconnect__Type__c       	 = ex.getTypeName();
            log.tsanetconnect__StackTrace__c 	 = truncateStackTrace(ex.getStackTraceString());
            log.tsanetconnect__Context__c    	 = context;

            insertLogs(new tsanetconnect__TSANetError__c[]{ log });
        } catch (Exception e) {
            // Last resort: the error-log insert itself failed. Do not debug the payload —
            // debug logs have a wider audience than the records that failed to persist.
        }
    }

    /**
     * Logs a UI-originated error with optional record relationships.
     * @param ex map containing message, type, and stackTrace keys
     * @param context description of where the error occurred
     * @param relations map with optional caseId, tsaNetCaseId, and tsaNetNoteId
     */
    @AuraEnabled
    public static void logUIError(Map<String, Object> ex, String context, Map<String, String> relations) {

        String message = ex.containsKey('message') ? (String) ex.get('message') : '';
        String type = ex.containsKey('type') ? (String) ex.get('type') : '';
        String stackTrace = ex.containsKey('stackTrace') ? (String) ex.get('stackTrace') : '';

        String caseId = relations.get('caseId');
        String tsaNetId = relations.get('tsaNetCaseId');
        String tsaNetNoteId = relations.get('tsaNetNoteId');
        try {
            tsanetconnect__TSANetError__c  log = new tsanetconnect__TSANetError__c();
            log.Name = context + ' - ' + System.now().format();
            log.tsanetconnect__ErrorMessage__c  = message;
            log.tsanetconnect__Type__c       	 = type;
            log.tsanetconnect__StackTrace__c 	 = truncateStackTrace(stackTrace);
            log.tsanetconnect__Case__c 	 	 = caseId;
            log.tsanetconnect__TSANetCase__c 	 = tsaNetId;
            log.tsanetconnect__TSANetNote__c 	 = tsaNetNoteId;
            log.tsanetconnect__Context__c    	 = context;
            insertLogs(new tsanetconnect__TSANetError__c[]{ log });
        } catch (Exception e) {
            // Last resort: the error-log insert itself failed. Do not debug the payload —
            // debug logs have a wider audience than the records that failed to persist.
        }
    }

    /**
     * Creates and inserts an error log record with optional record relationships.
     * @param ex the caught exception
     * @param context description of where the error occurred
     * @param relations map with optional caseId, tsaNetCaseId, and tsaNetNoteId
     */
    public static void logError(Exception ex, String context, Map<String, String> relations) {
        Map<String, String> safeRelations = relations == null ? new Map<String, String>() : relations;
        String caseId = safeRelations.get('caseId');
        String tsaNetId = safeRelations.get('tsaNetCaseId');
        String tsaNetNoteId = safeRelations.get('tsaNetNoteId');
        try {
            tsanetconnect__TSANetError__c  log = new tsanetconnect__TSANetError__c();
            log.Name = context + ' - ' + System.now().format();
            log.tsanetconnect__ErrorMessage__c  = withRelations(ex.getMessage(), safeRelations);
            log.tsanetconnect__Type__c       	 = ex.getTypeName();
            log.tsanetconnect__StackTrace__c 	 = truncateStackTrace(ex.getStackTraceString());
            log.tsanetconnect__Case__c 	     = caseId;
            log.tsanetconnect__TSANetCase__c 	 = tsaNetId;
            log.tsanetconnect__TSANetNote__c 	 = tsaNetNoteId;
            log.tsanetconnect__Context__c    	 = context;
            insertLogs(new tsanetconnect__TSANetError__c[]{ log });
        } catch (Exception e) {
            // Last resort: the error-log insert itself failed. Do not debug the payload —
            // debug logs have a wider audience than the records that failed to persist.
        }
    }

    /** Appends non-blank relation keys to the error message so the log is searchable without lookups. */
    private static String withRelations(String message, Map<String, String> relations) {
        if (relations == null || relations.isEmpty()) {
            return message;
        }
        String[] details = new String[]{};
        for (String key : relations.keySet()) {
            String value = relations.get(key);
            if (String.isNotBlank(value)) {
                details.add(key + '=' + value);
            }
        }
        if (details.isEmpty()) {
            return message;
        }
        return (message == null ? '' : message) + ' | ' + String.join(details, ' | ');
    }

    /**
     * Creates and inserts an error log from a plain message string.
     * @param message the error message text
     * @param context description of where the error occurred
     */
    public static void logError(String message, String context) {
        try {
            tsanetconnect__TSANetError__c log = new tsanetconnect__TSANetError__c();
            log.tsanetconnect__ErrorMessage__c = message;
            log.tsanetconnect__Context__c = context;
            insertLogs(new tsanetconnect__TSANetError__c[]{ log });
        } catch (Exception e) {
            // Last resort: the error-log insert itself failed. Do not debug the payload —
            // debug logs have a wider audience than the records that failed to persist.
        }
    }

    /**
     * Builds an error log record without inserting it.
     * @param message the error message text
     * @param context description of where the error occurred
     * @return unsaved TSANetError__c record
     */
    public static tsanetconnect__TSANetError__c getLogError(String message, String context) {
        tsanetconnect__TSANetError__c log = new tsanetconnect__TSANetError__c();
        log.tsanetconnect__ErrorMessage__c = message;
        log.tsanetconnect__Context__c = context;
        return log;
    }

    /**
     * Inserts a list of error log records in bulk.
     * @param errors list of TSANetError__c records to insert
     */
    public static void logErrors(tsanetconnect__TSANetError__c[] errors) {
        try {
            insertLogs(errors);
        } catch (Exception e) {
            // Last resort: the error-log insert itself failed. Do not debug the payload —
            // debug logs have a wider audience than the records that failed to persist.
        }
    }
}