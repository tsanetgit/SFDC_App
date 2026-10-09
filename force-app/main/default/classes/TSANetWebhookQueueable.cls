/** Async processor for inbound webhook events — fetches full data from TSANet API and upserts locally by external Id. */
public with sharing class TSANetWebhookQueueable implements Queueable, Database.AllowsCallouts {

    private static final String LOG_CONTEXT = 'TSANET_WEBHOOK_QUEUEABLE';
    private static final String CASE_PATH = '/v1/collaboration-requests/{token}';

    /** A single inbound webhook event to process. */
    public class WebhookEvent {
        /** The webhook event type (e.g. collaboration-request.created). */
        public String eventType;
        /** The collaboration request token. */
        public String requestToken;
        /** The note token (nullable). */
        public String noteToken;

        /**
         * @param eventType the webhook event type
         * @param requestToken the collaboration request token
         * @param noteToken the note token (nullable)
         */
        public WebhookEvent(String eventType, String requestToken, String noteToken){
            this.eventType = eventType;
            this.requestToken = requestToken;
            this.noteToken = noteToken;
        }
    }

    private WebhookEvent[] events;

    /**
     * @param eventType the webhook event type (e.g. collaboration-request.created)
     * @param requestToken the collaboration request token
     * @param noteToken the note token (nullable)
     */
    public TSANetWebhookQueueable(String eventType, String requestToken, String noteToken){
        this(new WebhookEvent[]{ new WebhookEvent(eventType, requestToken, noteToken) });
    }

    /**
     * Processes a batch of webhook events in a single job, so a batch of platform
     * events does not consume one queueable slot per event.
     * @param events the webhook events to process
     */
    public TSANetWebhookQueueable(WebhookEvent[] events){
        this.events = events != null ? events : new WebhookEvent[]{};
    }

    public void execute(QueueableContext context){
        try {
            String domain = AuthModeManager.getCalloutBase();
            if(domain == null){
                logFailure(TSANetConstants.NOT_CONFIGURED_ERROR, null, null);
                return;
            }

            for(WebhookEvent event : events){
                processEvent(event, domain);
            }
        } catch(Exception e){
            ErrorLogger.logError(e, LOG_CONTEXT);
        }
    }

    /** Processes one event; a failure is logged and never stops the rest of the batch. */
    private void processEvent(WebhookEvent event, String domain){
        try {
            if(shouldSyncCollaborationRequest(event.eventType)){
                syncCollaborationRequest(event, domain);
            }
        } catch(Exception e){
            ErrorLogger.logError(e, LOG_CONTEXT, new Map<String, String>{
                'eventType' => event.eventType,
                'requestToken' => event.requestToken,
                'noteToken' => event.noteToken
            });
        }
    }

    /**
     * True for V1 short names and V2 CloudEvent types that refresh the collaboration request.
     * @param eventType inbound event type
     * @return true when the event should trigger a GET-by-token sync
     */
    private static Boolean shouldSyncCollaborationRequest(String eventType){
        if(String.isBlank(eventType)){
            return false;
        }
        return eventType.contains('collaboration-request') || eventType.startsWith('note.');
    }

    /** Fetches the full collaboration request payload and upserts cases/notes/responses by their external Ids. */
    private void syncCollaborationRequest(WebhookEvent event, String domain){
        String endpoint = domain + CASE_PATH.replace('{token}', event.requestToken);
        HttpResponse res = sendGet(endpoint);

        if(res.getStatusCode() != TSANetConstants.SUCCESS_CODE){
            logFailure(
                'GET collaboration-request returned HTTP ' + res.getStatusCode() + ' | body=' + res.getBody(),
                null,
                event
            );
            return;
        }

        TSANetData data = ParserManager.parseTSANetCases('[' + res.getBody() + ']', null);
        upsertAndLog(data);
        publishCaseUpdatedEvent(event);
    }

    /**
     * Publishes the completion TSANetCaseUpdated__e Platform Event (IsSync=true) for the affected
     * Salesforce Case so subscribed LWCs refresh and clear the typing indicator. PublishAfterCommit
     * ensures the event only fires once this job's upsert DML is committed.
     */
    private void publishCaseUpdatedEvent(WebhookEvent event){
        try {
            Id caseId = TSANetWebhookNotifier.getCaseIdByToken(event.requestToken);
            if(caseId == null){
                return;
            }

            TSANetWebhookNotifier.publishCaseUpdated(caseId, event.requestToken, true);
        } catch(Exception e){
            // A failed real-time notification must not fail webhook processing; users can still refresh manually.
            ErrorLogger.logError(e, LOG_CONTEXT, new Map<String, String>{
                'eventType' => event.eventType,
                'requestToken' => event.requestToken
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
        UpsertExecutor.execute(data.cases, tsanetconnect__TSANetCase__c.tsanetconnect__Token__c, AccessLevel.USER_MODE);
        UpsertExecutor.execute(data.notes, tsanetconnect__TSANetNote__c.tsanetconnect__Token__c, AccessLevel.USER_MODE);
        UpsertExecutor.execute(data.responses, tsanetconnect__TSANetResponse__c.tsanetconnect__tsaNetResponseId__c, AccessLevel.USER_MODE);
    }

    /** Persists a webhook-processing failure with full execution context and the current Apex stack. */
    private void logFailure(String message, Exception cause, WebhookEvent event){
        String stack = (cause != null)
            ? cause.getStackTraceString()
            : new DmlException().getStackTraceString();

        // Pack full context + stack into ErrorMessage__c (LongTextArea 10000); StackTrace__c is Text(255).
        String richMessage = message
            + ' | eventType=' + (event != null ? event.eventType : null)
            + ' | requestToken=' + (event != null ? event.requestToken : null)
            + ' | noteToken=' + (event != null ? event.noteToken : null)
            + '\n--- Caller stack ---\n' + stack;

        tsanetconnect__TSANetError__c log = ErrorLogger.getLogError(richMessage, LOG_CONTEXT);
        log.tsanetconnect__Type__c = (cause != null) ? cause.getTypeName() : 'WebhookProcessingError';
        log.tsanetconnect__StackTrace__c = (stack != null && stack.length() > 255) ? stack.substring(0, 255) : stack;
        ErrorLogger.logErrors(new tsanetconnect__TSANetError__c[]{ log });
    }

    /**
     * Sends a GET request, self-contained to avoid EndpointManager static init in the
     * webhook context. Named Credential callouts get their authorization from the
     * External Credential, so no header is set here.
     */
    private HttpResponse sendGet(String endpoint){
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('GET');
        req.setHeader('Content-Type', 'application/json');
        req.setTimeout(TSANetConstants.DEFAULT_TIMEOUT);

        Http http = new Http();
        return http.send(req);
    }
}
