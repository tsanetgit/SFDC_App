public class ErrorManager {
    
    public class ErrorManagerException extends Exception {}
    
    public static  tsanet_connect__TSANet_Credentials__c credential = CredentialManager.getCredentials();

    public static void handleResponseErrors(HTTPResponse response){
        System.debug('response.getStatusCode() : ' + response.getStatusCode());
        System.debug('response.getStatusCode() : ' + response.getBody());
        if(response.getStatusCode() != 200){
            if(response.getBody().contains('The authorization token provided was invalid.')){
                Database.update(new tsanet_connect__TSANet_Credentials__c(Id = credential.Id, tsanet_connect__Token__c = NULL));
                //AuthManager.updateAccessTokenFuture();
                throw new ErrorManagerException('Unauthorized');
            } else {
                //ErrorLogger.logError((String) response.getBody(), 'API_ERROR');
                throw new ErrorManagerException((String) response.getBody());
            }
        }
    } 
    
    public static tsanet_connect__TSANetError__c[] collectErrors(List<Database.UpsertResult> results, List<SObject> records, SObjectField externalIdField) {
        tsanet_connect__TSANetError__c[] errors = new tsanet_connect__TSANetError__c[]{};

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
                    
                    tsanet_connect__TSANetError__c errorLog = ErrorLogger.getLogError(errMsg, 'UPSERT_ERROR_LOG');
                    
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