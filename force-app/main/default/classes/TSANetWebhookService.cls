/** Service layer for TSANet webhook subscription management. */
public with sharing class TSANetWebhookService {

    public class TSANetWebhookServiceException extends Exception {}

    private static final String CALLBACK_AUTH_TYPE = 'OAUTH2_CLIENT_CREDENTIALS';
    private static final String CALLBACK_AUTH_METHOD = 'CLIENT_SECRET_BASIC';
    private static final String PAYLOAD_VERSION = 'V2';
    private static final String WEBHOOK_CALLBACK_PATH = '/services/apexrest/tsanetconnect/webhook';
    private static final String SALESFORCE_LOGIN_PATH = '/services/oauth2/token';
    private static final String EVENT_TYPE_CREATED_V1 = 'collaboration-request.created';
    private static final String EVENT_TYPE_NOTE_V1 = 'note.created';
    private static final String EVENT_TYPE_CREATED_V2 = 'org.tsanet.connect.collaboration-request.created';
    private static final String EVENT_TYPE_NOTE_V2 = 'org.tsanet.connect.collaboration-request.note.created';
    private static final String CLIENT_FIELDS_REQUIRED = 'Client Id and Client Secret are required.';

    /** DTO for the webhook registration API response. */
    public class WebhookResponse {
        public Integer id;
        public String callbackUrl;
        public String[] eventTypes;
        public Boolean active;
        /** Not persisted; kept because JSON.deserialize fails on fields missing from the DTO. */
        public String secret;
        public String createdAt;
    }

    /** Combobox-ready host option for the webhook Callback URL. */
    public class CallbackUrlOption {
        /** Display label (Org Domain). */
        @AuraEnabled public String label;
        /** Full Apex REST webhook URL for this host. */
        @AuraEnabled public String value;

        /**
         * @param label option label
         * @param value full callback URL
         */
        public CallbackUrlOption(String label, String value){
            this.label = label;
            this.value = value;
        }
    }

    /**
     * Default org Apex REST URL TSANet should POST authorized webhook events to.
     * @return https://{myDomain}/services/apexrest/tsanetconnect/webhook
     */
    @AuraEnabled(cacheable=true)
    public static String getDefaultCallbackUrl(){
        return URL.getOrgDomainUrl().toExternalForm() + WEBHOOK_CALLBACK_PATH;
    }

    /**
     * Org Domain callback URL as the only supported host option.
     * @return combobox options containing Org Domain
     */
    @AuraEnabled(cacheable=true)
    public static CallbackUrlOption[] getCallbackUrlOptions(){
        String orgUrl = getDefaultCallbackUrl();
        return new CallbackUrlOption[]{ new CallbackUrlOption('Org Domain', orgUrl) };
    }

    /**
     * Registers a webhook with OAuth2 client-credentials callback auth and persists it locally.
     * Client Id / Secret are sent to TSANet only and are never stored.
     * @param callbackUrl the URL TSANet will POST events to
     * @param eventTypes list of event types to subscribe to
     * @param clientId Connected App consumer key
     * @param clientSecret Connected App consumer secret
     * @param credentialId parent TSANet_Credentials__c Id, or null to use the primary credential
     * @return Salesforce record Id of the upserted webhook, or null if persist failed
     */
    @AuraEnabled
    public static String registerWebhook(String callbackUrl, String[] eventTypes, String clientId, String clientSecret, Id credentialId){
        if(String.isBlank(callbackUrl)){
            throwAura('Callback URL is required.');
        }
        if(eventTypes == null || eventTypes.isEmpty()){
            throwAura('Select at least one event type.');
        }
        if(String.isBlank(clientId) || String.isBlank(clientSecret)){
            throwAura(CLIENT_FIELDS_REQUIRED);
        }
        return registerWebhookInternal(callbackUrl, eventTypes, clientId, clientSecret, credentialId);
    }

    /**
     * Builds the TSANet register payload with OAuth2 callbackAuth, then upserts locally.
     * @return Salesforce record Id when persist succeeds
     */
    private static String registerWebhookInternal(String callbackUrl, String[] eventTypes, String clientId, String clientSecret, Id credentialId){
        String endpoint = TSANetHttpRouter.getEndpoint(EndpointManager.webhooks_path);
        System.debug(LoggingLevel.INFO, 'TSANet webhook register start endpoint=' + endpoint);

        Map<String, Object> payload = buildRegisterPayload(callbackUrl, eventTypes, clientId, clientSecret);

        String requestBody = JSON.serialize(payload);
        System.debug(LoggingLevel.INFO, 'TSANet webhook register request body=' + requestBody);

        try {
            HttpResponse res = TSANetHttpRouter.sendPost(endpoint, requestBody);
            System.debug(LoggingLevel.INFO, 'TSANet webhook register status=' + res.getStatusCode() + ' body=' + res.getBody());

            WebhookResponse webhook = (WebhookResponse) JSON.deserialize(res.getBody(), WebhookResponse.class);

            tsanetconnect__TSANetWebhook__c record = new tsanetconnect__TSANetWebhook__c();
            record.tsanetconnect__WebhookId__c = webhook.id;
            record.tsanetconnect__CallbackUrl__c = webhook.callbackUrl;
            record.tsanetconnect__EventTypes__c = webhook.eventTypes != null ? String.join(webhook.eventTypes, ';') : '';
            record.tsanetconnect__Active__c = webhook.active;
            record.tsanetconnect__TSANetCredential__c = credentialId != null
                ? credentialId
                : CredentialManager.getCredentials().Id;
            if(String.isNotBlank(webhook.createdAt)){
                record.tsanetconnect__CreatedAt__c = parseDateTime(webhook.createdAt);
            }

            Database.upsert(record, tsanetconnect__TSANetWebhook__c.tsanetconnect__WebhookId__c, false, AccessLevel.USER_MODE);
            System.debug(LoggingLevel.INFO, 'TSANet webhook register saved recordId=' + record.Id + ' webhookId=' + webhook.id);
            return record.Id;
        } catch(Exception e){
            throwRegisterError(e);
            return null;
        }
    }

    /** Writes debug + TSANetError__c, then rethrows so the New form shows the API message. */
    private static void throwRegisterError(Exception cause){
        String message = cause != null ? cause.getMessage() : 'Unable to register the webhook.';
        System.debug(LoggingLevel.ERROR, 'TSANet webhook register error: ' + message);
        if(cause != null){
            System.debug(LoggingLevel.ERROR, cause.getStackTraceString());
            ErrorLogger.logError(cause, 'TSANET_WEBHOOK_REGISTER');
        }
        throwAura(message);
    }

    /** Throws an AuraHandledException whose getMessage() matches the user-facing text. */
    private static void throwAura(String message){
        AuraHandledException ahe = new AuraHandledException(message);
        ahe.setMessage(message);
        throw ahe;
    }

    /** Salesforce token endpoint for the current org (Connected App client-credentials). */
    private static String getSalesforceTokenUrl(){
        return URL.getOrgDomainUrl().toExternalForm() + SALESFORCE_LOGIN_PATH;
    }

    /**
     * Builds the V2 subscribe body with Connected App callbackAuth.
     * oauth2Scope is omitted: empty or null values are rejected by the API.
     * @return JSON-serializable register payload
     */
    private static Map<String, Object> buildRegisterPayload(String callbackUrl, String[] eventTypes, String clientId, String clientSecret){
        return new Map<String, Object>{
            'callbackUrl' => callbackUrl,
            'eventTypes' => toV2EventTypes(eventTypes),
            'payloadVersion' => PAYLOAD_VERSION,
            'callbackAuth' => new Map<String, Object>{
                'type' => CALLBACK_AUTH_TYPE,
                'oauth2TokenUrl' => getSalesforceTokenUrl(),
                'oauth2ClientId' => clientId,
                'oauth2ClientSecret' => clientSecret,
                'oauth2ClientAuthenticationMethod' => CALLBACK_AUTH_METHOD
            }
        };
    }

    /**
     * Maps V1 short event type names to V2 CloudEvent type strings.
     * Values that are already CloudEvent types are left unchanged.
     * @param eventTypes short or CloudEvent type names
     * @return CloudEvent type names for POST /v2/webhooks
     */
    @TestVisible
    private static String[] toV2EventTypes(String[] eventTypes){
        if(eventTypes == null){
            return eventTypes;
        }
        String[] mapped = new String[]{};
        for(String eventType : eventTypes){
            mapped.add(toV2EventType(eventType));
        }
        return mapped;
    }

    /** Maps one V1 event type to its V2 CloudEvent name. */
    private static String toV2EventType(String eventType){
        if(String.isBlank(eventType)){
            return eventType;
        }
        String trimmed = eventType.trim();
        if(trimmed == EVENT_TYPE_CREATED_V1){
            return EVENT_TYPE_CREATED_V2;
        }
        if(trimmed == EVENT_TYPE_NOTE_V1){
            return EVENT_TYPE_NOTE_V2;
        }
        return trimmed;
    }

    /**
     * Lists all webhook subscriptions from the TSANet API.
     * @return raw API response body
     */
    @AuraEnabled
    public static String getWebhooks(){
        String endpoint = TSANetHttpRouter.getEndpoint(EndpointManager.webhooks_path);
        HttpResponse res = TSANetHttpRouter.sendGet(endpoint);
        return res.getBody();
    }

    /**
     * Deletes a webhook subscription from the TSANet API.
     * @param webhookId external webhook ID to delete
     */
    public static void deleteWebhook(Integer webhookId){
        String endpoint = getWebhookEndpointById(EndpointManager.webhook_by_id, webhookId);
        TSANetHttpRouter.sendWithTimeout('DELETE', endpoint, null, TSANetConstants.SHORT_TIMEOUT);
    }

    /**
     * Deletes webhooks from the TSANet API asynchronously (for trigger context).
     * @param webhookIds set of external webhook IDs to delete
     */
    @Future(callout=true)
    public static void deleteWebhooksAsync(Set<Integer> webhookIds){
        for(Integer webhookId : webhookIds){
            try {
                deleteWebhook(webhookId);
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
     * @return raw API response body
     */
    @AuraEnabled
    public static String getDeliveryLog(Integer webhookId){
        String endpoint = getWebhookEndpointById(EndpointManager.webhook_deliveries, webhookId);
        HttpResponse res = TSANetHttpRouter.sendGet(endpoint);
        return res.getBody();
    }

    /** Resolves a webhook endpoint template for the active auth mode and substitutes {id}. */
    private static String getWebhookEndpointById(String template, Integer webhookId){
        if(String.isBlank(template) || webhookId == null) {
            return template;
        }
        return TSANetHttpRouter.getEndpoint(template.replace('{id}', String.valueOf(webhookId)));
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
