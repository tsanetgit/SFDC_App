public inherited sharing class ErrorLogger {

    public static void logError(Exception ex, String context) {
        try {
            tsanet_connect__TSANetError__c  log = new tsanet_connect__TSANetError__c ();
            log.tsanet_connect__ErrorMessage__c  = ex.getMessage();
            log.tsanet_connect__Type__c       	 = ex.getTypeName();
            log.tsanet_connect__StackTrace__c 	 = ex.getStackTraceString();
            log.tsanet_connect__Context__c    	 = context;
            //insert log;
        } catch (Exception e) {
            System.debug('Failed to log error: ' + e.getMessage());
        }
    }

    public static void logError(String message, String context) {
        try {
            tsanet_connect__TSANetError__c log = new tsanet_connect__TSANetError__c();
            log.tsanet_connect__ErrorMessage__c = message;
            log.tsanet_connect__Context__c = context;
            //insert log;
        } catch (Exception e) {
            System.debug('Failed to log error: ' + e.getMessage());
        }
    }
    
    public static tsanet_connect__TSANetError__c getLogError(String message, String context) {
        tsanet_connect__TSANetError__c log = new tsanet_connect__TSANetError__c();
        log.tsanet_connect__ErrorMessage__c = message;
        log.tsanet_connect__Context__c = context;
        return log;
    }
    
    public static void logErrors(tsanet_connect__TSANetError__c[] errors) {
        try {
            insert errors;
        } catch (Exception e) {
            System.debug('Failed to log error: ' + e.getMessage());
        }
    }
}