public inherited sharing class ErrorLogger {

    public static void logError(Exception ex, String context) {
        try {
            tsanetconnect__TSANetError__c  log = new tsanetconnect__TSANetError__c ();
            log.tsanetconnect__ErrorMessage__c  = ex.getMessage();
            log.tsanetconnect__Type__c       	 = ex.getTypeName();
            log.tsanetconnect__StackTrace__c 	 = ex.getStackTraceString();
            log.tsanetconnect__Context__c    	 = context;
            
            Database.insert(log, AccessLevel.USER_MODE);
        } catch (Exception e) {}
    }
    
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
            log.tsanetconnect__StackTrace__c 	 = stackTrace;
            log.tsanetconnect__Case__c 	 	 = caseId;
            log.tsanetconnect__TSANetCase__c 	 = tsaNetId;
            log.tsanetconnect__TSANetNote__c 	 = tsaNetNoteId;
            log.tsanetconnect__Context__c    	 = context;
            Database.insert(log, AccessLevel.USER_MODE);
        } catch (Exception e) {}
    }
    
    public static void logError(Exception ex, String context, Map<String, String> relations) {
        String caseId = relations.get('caseId');
        String tsaNetId = relations.get('tsaNetCaseId');
        String tsaNetNoteId = relations.get('tsaNetNoteId');
        try {
            tsanetconnect__TSANetError__c  log = new tsanetconnect__TSANetError__c();
            log.Name = context + ' - ' + System.now().format();
            log.tsanetconnect__ErrorMessage__c  = ex.getMessage();
            log.tsanetconnect__Type__c       	 = ex.getTypeName();
            log.tsanetconnect__StackTrace__c 	 = ex.getStackTraceString();
            log.tsanetconnect__Case__c 	     = caseId;
            log.tsanetconnect__TSANetCase__c 	 = tsaNetId;
            log.tsanetconnect__TSANetNote__c 	 = tsaNetNoteId;
            log.tsanetconnect__Context__c    	 = context;
            Database.insert(log, AccessLevel.USER_MODE);
        } catch (Exception e) {}
    }

    public static void logError(String message, String context) {
        try {
            tsanetconnect__TSANetError__c log = new tsanetconnect__TSANetError__c();
            log.tsanetconnect__ErrorMessage__c = message;
            log.tsanetconnect__Context__c = context;
            Database.insert(log, AccessLevel.USER_MODE);
        } catch (Exception e) {}
    }
    
    public static tsanetconnect__TSANetError__c getLogError(String message, String context) {
        tsanetconnect__TSANetError__c log = new tsanetconnect__TSANetError__c();
        log.tsanetconnect__ErrorMessage__c = message;
        log.tsanetconnect__Context__c = context;
        return log;
    }
    
    public static void logErrors(tsanetconnect__TSANetError__c[] errors) {
        try {
            Database.insert(errors, AccessLevel.USER_MODE);
        } catch (Exception e) {}
    }
}