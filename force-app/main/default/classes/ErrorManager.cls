public with sharing class ErrorManager {
    
    public class ErrorManagerException extends Exception {}
    
    public static  tsanetconnect__TSANet_Credentials__c credential = CredentialManager.getCredentials();
    
    public class TSANetError {
        String message;
        String detail;
    }

    public static void handleResponseErrors(HTTPResponse response){
        if(response.getStatusCode() != 200){
            if(response.getBody().contains('The authorization token provided was invalid.')){
                Database.update(new tsanetconnect__TSANet_Credentials__c(Id = credential.Id, tsanetconnect__Token__c = NULL), AccessLevel.USER_MODE);
                throw new ErrorManagerException('Unauthorized');
            } else {
                TSANetError parsedError = (TSANetError) System.JSON.deserialize(response.getBody(), TSANetError.class);
                String errorMessage = parsedError.message != NULL ? parsedError.message : parsedError.detail;
                throw new ErrorManagerException(errorMessage);
            }
        }
    } 
    
    public static tsanetconnect__TSANetError__c[] collectErrors(List<Database.UpsertResult> results, List<SObject> records, SObjectField externalIdField) {
        tsanetconnect__TSANetError__c[] errors = new tsanetconnect__TSANetError__c[]{};

        if (results == null || results.isEmpty()) return errors;

        for (Integer i = 0; i < results.size(); i++) {
            Database.UpsertResult ur = results[i];
            if (ur == null) continue;

            if (!ur.isSuccess()) {
                String extIdValue = null;
                try {
                    if (records != null && i < records.size()) {
                        extIdValue = String.valueOf(records[i].get(externalIdField));
                    }
                } catch (Exception ignore) {}

                for (Database.Error e : ur.getErrors()) {
                    String errMsg = 
                        'Upsert failed [' + (extIdValue == null ? '(no externalId)' : extIdValue) + ']' +
                        ' | Status: ' + e.getStatusCode() +
                        ' | Message: ' + e.getMessage() +
                        (e.getFields().isEmpty() ? '' : ' | Fields: ' + String.join(e.getFields(), ','));
                    
                    tsanetconnect__TSANetError__c errorLog = ErrorLogger.getLogError(errMsg, 'UPSERT_ERROR_LOG');
                    errors.add(errorLog);
                }
            }
        }
        return errors;
    }
    
    public static Boolean isUnautorized(String body){
        return body.contains('The authorization token provided was invalid');
    }
}