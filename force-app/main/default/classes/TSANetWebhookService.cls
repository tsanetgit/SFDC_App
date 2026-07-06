/** Service layer for TSANet webhook subscription management. */
public with sharing class TSANetWebhookService {

    public class TSANetWebhookServiceException extends Exception {}

    /** DTO for the webhook registration API response. */
    public class WebhookResponse {
        public Integer id;
        public String callbackUrl;
        public String[] eventTypes;
        public Boolean active;
        public String secret;
        public String createdAt;
    }

    /**
     * Registers a new webhook subscription with the TSANet API and persists it locally.
     * @param callbackUrl the URL TSANet will POST events to
     * @param eventTypes list of event types to subscribe to
     * @param token access token for authentication
     * @return raw API response body
     */
    @AuraEnabled
    public static String registerWebhook(String callbackUrl, String[] eventTypes, String token){
        String endpoint = EndpointManager.getWebhooksPath();
        String body = JSON.serialize(new Map<String, Object>{
            'callbackUrl' => callbackUrl,
            'eventTypes' => eventTypes
        });

        HttpResponse res = HttpClient.sendPost(endpoint, token, body);

        try {
            WebhookResponse webhook = (WebhookResponse) JSON.deserialize(res.getBody(), WebhookResponse.class);

            tsanetconnect__TSANetWebhook__c record = new tsanetconnect__TSANetWebhook__c();
            record.tsanetconnect__WebhookId__c = webhook.id;
            record.tsanetconnect__CallbackUrl__c = webhook.callbackUrl;
            record.tsanetconnect__EventTypes__c = String.join(webhook.eventTypes, ';');
            record.tsanetconnect__Secret__c = webhook.secret;
            record.tsanetconnect__Active__c = webhook.active;
            record.tsanetconnect__TSANetCredential__c = CredentialManager.getCredentials().Id;
            if(String.isNotBlank(webhook.createdAt)){
                record.tsanetconnect__CreatedAt__c = parseDateTime(webhook.createdAt);
            }

            Database.upsert(record, tsanetconnect__TSANetWebhook__c.tsanetconnect__WebhookId__c, false, AccessLevel.USER_MODE);
        } catch(Exception e){
            ErrorLogger.logError(e, 'TSANET_WEBHOOK_REGISTER');
        }

        return res.getBody();
    }

    /**
     * Lists all webhook subscriptions from the TSANet API.
     * @param token access token for authentication
     * @return raw API response body
     */
    @AuraEnabled
    public static String getWebhooks(String token){
        String endpoint = EndpointManager.getWebhooksPath();
        HttpResponse res = HttpClient.sendGet(endpoint, token);
        return res.getBody();
    }

    /**
     * Registers webhooks via the TSANet API for records created through the UI (trigger context).
     * @param recordIds set of TSANetWebhook__c record IDs to register
     */
    @Future(callout=true)
    public static void registerWebhooksAsync(Set<Id> recordIds){
        String token = TSANetService.getTSANetAccessToken();
        if(token == null) {
            ErrorLogger.logError('Unable to obtain access token for webhook registration', 'TSANET_WEBHOOK_REGISTER_ASYNC');
            return;
        }

        tsanetconnect__TSANetWebhook__c[] records = [
            SELECT Id, tsanetconnect__CallbackUrl__c, tsanetconnect__EventTypes__c
            FROM tsanetconnect__TSANetWebhook__c
            WHERE Id IN :recordIds
            WITH USER_MODE
        ];

        String endpoint = EndpointManager.getWebhooksPath();

        for(tsanetconnect__TSANetWebhook__c record : records){
            try {
                String[] eventTypes = String.isNotBlank(record.tsanetconnect__EventTypes__c)
                    ? record.tsanetconnect__EventTypes__c.split(';')
                    : new String[]{};

                String body = JSON.serialize(new Map<String, Object>{
                    'callbackUrl' => record.tsanetconnect__CallbackUrl__c,
                    'eventTypes' => eventTypes
                });

                HttpResponse res = HttpClient.sendPost(endpoint, token, body);
                WebhookResponse webhook = (WebhookResponse) JSON.deserialize(res.getBody(), WebhookResponse.class);

                record.tsanetconnect__WebhookId__c = webhook.id;
                record.tsanetconnect__Secret__c = webhook.secret;
                record.tsanetconnect__Active__c = webhook.active;
                if(String.isNotBlank(webhook.createdAt)){
                    record.tsanetconnect__CreatedAt__c = parseDateTime(webhook.createdAt);
                }
            } catch(Exception e){
                ErrorLogger.logError(e, 'TSANET_WEBHOOK_REGISTER_ASYNC', new Map<String, String>{
                    'recordId' => record.Id
                });
            }
        }

        Database.update(records, AccessLevel.USER_MODE);
    }

    /**
     * Deletes a webhook subscription from the TSANet API.
     * @param webhookId external webhook ID to delete
     * @param token access token for authentication
     */
    public static void deleteWebhook(Integer webhookId, String token){
        String endpoint = EndpointManager.getWebhookPathById(EndpointManager.webhook_by_id, webhookId);
        HttpClient.sendWithTimeout('DELETE', endpoint, token, null, TSANetConstants.SHORT_TIMEOUT);
    }

    /**
     * Deletes webhooks from the TSANet API asynchronously (for trigger context).
     * @param webhookIds set of external webhook IDs to delete
     */
    @Future(callout=true)
    public static void deleteWebhooksAsync(Set<Integer> webhookIds){
        String token = TSANetService.getTSANetAccessToken();
        for(Integer webhookId : webhookIds){
            try {
                deleteWebhook(webhookId, token);
            } catch(Exception e){
                ErrorLogger.logError(e, 'TSANET_WEBHOOK_DELETE', new Map<String, String>{
                    'webhookId' => String.valueOf(webhookId)
                });
            }
        }
    }

    /**
     * Retrieves the delivery log for a webhook subscription.
     * @param webhookId external webhook ID
     * @param token access token for authentication
     * @return raw API response body
     */
    @AuraEnabled
    public static String getDeliveryLog(Integer webhookId, String token){
        String endpoint = EndpointManager.getWebhookPathById(EndpointManager.webhook_deliveries, webhookId);
        HttpResponse res = HttpClient.sendGet(endpoint, token);
        return res.getBody();
    }

    private static DateTime parseDateTime(String dt){
        if(String.isBlank(dt)) return null;
        dt = dt.replace('T', ' ');
        if(dt.contains('.')){
            dt = dt.substringBefore('.');
        } else if(dt.endsWith('Z')){
            dt = dt.removeEnd('Z');
        }
        return DateTime.valueOfGmt(dt);
    }
}
