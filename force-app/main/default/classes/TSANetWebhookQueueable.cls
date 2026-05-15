/** Async processor for inbound webhook events — fetches full data from TSANet API and upserts locally by external Id. */
public without sharing class TSANetWebhookQueueable implements Queueable, Database.AllowsCallouts {

    private static final String LOG_CONTEXT = 'TSANET_WEBHOOK_QUEUEABLE';
    private static final String CASE_PATH = '/v1/collaboration-requests/{token}';
    private static final String LOGIN_PATH = '/v1/login';

    private String eventType;
    private String requestToken;
    private String noteToken;

    /**
     * @param eventType the webhook event type (e.g. collaboration-request.created)
     * @param requestToken the collaboration request token
     * @param noteToken the note token (nullable)
     */
    public TSANetWebhookQueueable(String eventType, String requestToken, String noteToken){
        this.eventType = eventType;
        this.requestToken = requestToken;
        this.noteToken = noteToken;
    }

    public void execute(QueueableContext context){
        System.debug('TSANetWebhookQueueable.execute START | eventType=' + eventType + ' | requestToken=' + requestToken + ' | noteToken=' + noteToken);
        try {
            String domain = getDomain();
            if(domain == null){
                logFailure('Unable to resolve API domain for webhook processing', null);
                return;
            }

            String token = getAccessToken(domain);
            if(token == null){
                logFailure('Unable to obtain access token for webhook processing', null);
                return;
            }

            if(eventType != null && (eventType.startsWith('collaboration-request.') || eventType.startsWith('note.'))){
                syncCollaborationRequest(domain, token);
            } else {
                System.debug(LoggingLevel.WARN, 'TSANetWebhookQueueable: Unknown eventType=' + eventType);
            }
        } catch(Exception e){
            System.debug(LoggingLevel.ERROR, 'TSANetWebhookQueueable: Exception — ' + e.getMessage() + ' | ' + e.getStackTraceString());
            ErrorLogger.logError(e, LOG_CONTEXT, new Map<String, String>{
                'eventType' => eventType,
                'requestToken' => requestToken,
                'noteToken' => noteToken
            });
        }
        System.debug('TSANetWebhookQueueable.execute END');
    }

    /** Fetches the full collaboration request payload and upserts cases/notes/responses by their external Ids. */
    private void syncCollaborationRequest(String domain, String token){
        String endpoint = domain + CASE_PATH.replace('{token}', requestToken);
        HttpResponse res = sendGet(endpoint, token);
        System.debug('TSANetWebhookQueueable.syncCollaborationRequest: status=' + res.getStatusCode() + ' | body=' + res.getBody());

        if(res.getStatusCode() != TSANetConstants.SUCCESS_CODE){
            logFailure(
                'GET ' + endpoint + ' returned HTTP ' + res.getStatusCode() + ' | body=' + res.getBody(),
                null
            );
            return;
        }

        TSANetData data = ParserManager.parseTSANetCases('[' + res.getBody() + ']', null);
        System.debug('TSANetWebhookQueueable.syncCollaborationRequest: parsed cases=' + data.cases.size() + ' | notes=' + data.notes.size() + ' | responses=' + data.responses.size());

        upsertAndLog(data);
    }

    /**
     * Upserts each list by its external Id via the shared race-safe utility.
     *
     * Note: when an upsert resolves to UPDATE (record already exists), the trigger fires
     * beforeUpdate (not beforeInsert). TSANetNoteTriggerHandler.beforeUpdate self-heals
     * the TSANetCase__c lookup for any note that is still missing it.
     */
    private void upsertAndLog(TSANetData data){
        UpsertExecutor.execute(data.cases, tsanetconnect__TSANetCase__c.tsanetconnect__Token__c, AccessLevel.SYSTEM_MODE);
        UpsertExecutor.execute(data.notes, tsanetconnect__TSANetNote__c.tsanetconnect__Token__c, AccessLevel.SYSTEM_MODE);
        UpsertExecutor.execute(data.responses, tsanetconnect__TSANetResponse__c.tsanetconnect__tsaNetResponseId__c, AccessLevel.SYSTEM_MODE);

        System.debug('TSANetWebhookQueueable.upsertAndLog: complete');
    }

    /** Persists a webhook-processing failure with full execution context and the current Apex stack. */
    private void logFailure(String message, Exception cause){
        System.debug(LoggingLevel.ERROR, 'TSANetWebhookQueueable: ' + message);

        String stack = (cause != null)
            ? cause.getStackTraceString()
            : new DmlException().getStackTraceString();

        // Pack full context + stack into ErrorMessage__c (LongTextArea 10000); StackTrace__c is Text(255).
        String richMessage = message
            + ' | eventType=' + eventType
            + ' | requestToken=' + requestToken
            + ' | noteToken=' + noteToken
            + '\n--- Caller stack ---\n' + stack;

        tsanetconnect__TSANetError__c log = ErrorLogger.getLogError(richMessage, LOG_CONTEXT);
        log.tsanetconnect__Type__c = (cause != null) ? cause.getTypeName() : 'WebhookProcessingError';
        log.tsanetconnect__StackTrace__c = (stack != null && stack.length() > 255) ? stack.substring(0, 255) : stack;
        ErrorLogger.logErrors(new tsanetconnect__TSANetError__c[]{ log });
    }

    /** Authenticates against TSANet API in system mode. */
    private String getAccessToken(String domain){
        tsanetconnect__TSANet_Credentials__c[] credentials = [
            SELECT tsanetconnect__UserName__c, tsanetconnect__Password__c
            FROM tsanetconnect__TSANet_Credentials__c
            WHERE tsanetconnect__isPrimary__c = TRUE
        ];

        if(credentials.isEmpty()){
            System.debug(LoggingLevel.ERROR, 'TSANetWebhookQueueable.getAccessToken: No credentials found');
            return null;
        }

        tsanetconnect__TSANet_Credentials__c cred = credentials[0];

        HttpRequest req = new HttpRequest();
        req.setEndpoint(domain + LOGIN_PATH);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(JSON.serialize(new Map<String, String>{
            'username' => cred.tsanetconnect__UserName__c,
            'password' => cred.tsanetconnect__Password__c
        }));
        req.setTimeout(TSANetConstants.DEFAULT_TIMEOUT);

        Http http = new Http();
        HttpResponse res = http.send(req);

        System.debug('TSANetWebhookQueueable.getAccessToken: status=' + res.getStatusCode());

        if(res.getStatusCode() != TSANetConstants.SUCCESS_CODE){ return null; }

        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        return (String) responseMap.get('accessToken');
    }

    /** Resolves the API domain in system mode. */
    private String getDomain(){
        tsanetconnect__TSANet_Credentials__c[] credentials = [
            SELECT tsanetconnect__Environment__c
            FROM tsanetconnect__TSANet_Credentials__c
            WHERE tsanetconnect__isPrimary__c = TRUE
        ];

        if(credentials.isEmpty()) return null;

        String environment = credentials[0].tsanetconnect__Environment__c + '_env';
        tsanetconnect__TSANetEnvironment__mdt[] environments = [
            SELECT tsanetconnect__Endpoint__c
            FROM tsanetconnect__TSANetEnvironment__mdt
            WHERE DeveloperName = :environment
        ];

        return environments.isEmpty() ? null : environments[0].tsanetconnect__Endpoint__c;
    }

    /** Sends a GET request with bearer token, self-contained to avoid EndpointManager/HttpClient static init. */
    private HttpResponse sendGet(String endpoint, String token){
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('GET');
        req.setHeader('Authorization', 'Bearer ' + token);
        req.setHeader('Content-Type', 'application/json');
        req.setTimeout(TSANetConstants.DEFAULT_TIMEOUT);

        Http http = new Http();
        return http.send(req);
    }
}
