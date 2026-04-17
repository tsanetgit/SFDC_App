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

        for (Integer i = 0; i < results.size(); i++) {
            Database.UpsertResult ur = results[i];
            if (ur == null) {
                continue;
            }

            if (!ur.isSuccess()) {
                String extIdValue = null;
                try {
                    if (records != null && i < records.size()) {
                        extIdValue = String.valueOf(records[i].get(externalIdField));
                    }
                } catch (Exception e) {
                    System.debug(LoggingLevel.WARN, 'ErrorManager.collectErrors: ' + e.getMessage());
                }

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

    /**
     * Checks whether the response body indicates an invalid authorization token.
     * @param body HTTP response body
     * @return true if the body contains the unauthorized message
     */
    public static Boolean isUnauthorized(String body){
        return body.contains('The authorization token provided was invalid');
    }
}