/** Async processor for inbound webhook events — fetches full data from TSANet API and upserts locally by external Id. */
@SuppressWarnings('PMD.ApexSharingViolations')
public without sharing class TSANetWebhookQueueable implements Queueable, Database.AllowsCallouts {

    private static final String LOG_CONTEXT = 'TSANET_WEBHOOK_QUEUEABLE';
    private static final String CASE_PATH = '/v1/collaboration-requests/{token}';

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
        try {
            String domain = getDomain();
            if(domain == null){
                logFailure('Unable to resolve API domain for webhook processing', null);
                return;
            }

            String token = TokenManager.getAccessToken();
            if(token == null){
                logFailure('Unable to obtain access token for webhook processing', null);
                return;
            }

            if(eventType != null && (eventType.startsWith('collaboration-request.') || eventType.startsWith('note.'))){
                syncCollaborationRequest(domain, token);
            }

            TokenManager.commitTokenIfPending();
        } catch(Exception e){
            ErrorLogger.logError(e, LOG_CONTEXT, new Map<String, String>{
                'eventType' => eventType,
                'requestToken' => requestToken,
                'noteToken' => noteToken
            });
        }
    }

    /** Fetches the full collaboration request payload and upserts cases/notes/responses by their external Ids. */
    private void syncCollaborationRequest(String domain, String token){
        String endpoint = domain + CASE_PATH.replace('{token}', requestToken);
        HttpResponse res = sendGetWithAuthRetry(endpoint, token);

        if(res.getStatusCode() != TSANetConstants.SUCCESS_CODE){
            logFailure(
                'GET ' + endpoint + ' returned HTTP ' + res.getStatusCode() + ' | body=' + res.getBody(),
                null
            );
            return;
        }

        TSANetData data = ParserManager.parseTSANetCases('[' + res.getBody() + ']', null);
        upsertAndLog(data);
        publishCaseUpdatedEvent();
    }

    /**
     * Publishes the completion TSANetCaseUpdated__e Platform Event (IsSync=true) for the affected
     * Salesforce Case so subscribed LWCs refresh and clear the typing indicator. PublishAfterCommit
     * ensures the event only fires once this job's upsert DML is committed.
     */
    private void publishCaseUpdatedEvent(){
        try {
            // SYSTEM_MODE: the webhook runs as the integration/guest user which may lack FLS,
            // mirroring the other system-context lookups in this job (e.g. getDomain()).
            tsanetconnect__TSANetCase__c[] cases = [
                SELECT Id, tsanetconnect__Case__c
                FROM tsanetconnect__TSANetCase__c
                WHERE tsanetconnect__Token__c = :requestToken
                WITH SYSTEM_MODE
                LIMIT 1
            ];

            if(cases.isEmpty() || cases[0].tsanetconnect__Case__c == null){
                return;
            }

            EventBus.publish(new tsanetconnect__TSANetCaseUpdated__e(
                tsanetconnect__CaseId__c = cases[0].tsanetconnect__Case__c,
                tsanetconnect__RequestToken__c = requestToken,
                tsanetconnect__IsSync__c = true
            ));
        } catch(Exception e){
            // A failed real-time notification must not fail webhook processing; users can still refresh manually.
            ErrorLogger.logError(e, LOG_CONTEXT, new Map<String, String>{
                'eventType' => eventType,
                'requestToken' => requestToken
            });
        }
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
    }

    /** Persists a webhook-processing failure with full execution context and the current Apex stack. */
    private void logFailure(String message, Exception cause){
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

    /** Resolves the API domain in system mode. */
    private String getDomain(){
        tsanetconnect__TSANet_Credentials__c[] credentials = [
            SELECT tsanetconnect__Environment__c
            FROM tsanetconnect__TSANet_Credentials__c
            WHERE tsanetconnect__isPrimary__c = TRUE
            WITH SYSTEM_MODE
        ];

        if(credentials.isEmpty()) return null;

        String environment = credentials[0].tsanetconnect__Environment__c + '_env';
        tsanetconnect__TSANetEnvironment__mdt[] environments = [
            SELECT tsanetconnect__Endpoint__c
            FROM tsanetconnect__TSANetEnvironment__mdt
            WHERE DeveloperName = :environment
            WITH SYSTEM_MODE
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

    /**
     * GET with automatic 401 refresh-and-retry. Callout phase only — no DML.
     * On invalid token, logs in via TokenManager.refreshAccessToken() and retries once.
     */
    private HttpResponse sendGetWithAuthRetry(String endpoint, String token){
        HttpResponse res = sendGet(endpoint, token);

        if(isUnauthorizedResponse(res)){
            String refreshed = TokenManager.refreshAccessToken();
            if(String.isNotBlank(refreshed)){
                res = sendGet(endpoint, refreshed);
            }
        }

        return res;
    }

    /** True when the API response indicates an invalid or expired bearer token. */
    private Boolean isUnauthorizedResponse(HttpResponse res){
        return res != null && (
            res.getStatusCode() == 401
            || ErrorManager.isUnauthorized(res.getBody())
        );
    }
}
