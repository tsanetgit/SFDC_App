/**
 * REST endpoint that receives inbound webhook events from TSANet.
 *
 * Runs as the External Client App Run As user (Integration User).
 * It publishes TSANetWebhookEvent__e for subscribers and enqueues TSANetWebhookQueueable
 * so Named Credential callouts run as that user rather than Automated Process.
 */
@RestResource(urlMapping='/webhook/*')
global with sharing class TSANetWebhookRestService {

    /** DTO for inbound V1 flat JSON and V2 CloudEvents payloads. */
    global class WebhookEvent {
        public String eventType;
        public String requestToken;
        public String noteToken;
        public String timestamp;
        /** CloudEvent type; copied onto eventType when the body is V2. */
        public String type;
        /** CloudEvent data envelope used by V2 deliveries. */
        public CloudEventData data;
    }

    /** Token fields nested under CloudEvent data. */
    global class CloudEventData {
        public String requestToken;
        public String noteToken;
    }

    /**
     * Health check endpoint for webhook availability monitoring.
     * @return JSON payload with status and current UTC timestamp
     */
    @HttpGet
    global static String handleGet(){
        return JSON.serialize(new Map<String, String>{
            'status' => 'ok',
            'timestamp' => Datetime.now().formatGmt('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'')
        });
    }

    /** Handles incoming POST events by publishing them and enqueueing asynchronous processing. */
    @HttpPost
    global static void handleEvent(){
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;

        try {
            String body = req.requestBody.toString();
            WebhookEvent event = parseEvent(body);

            if(event != null && String.isNotBlank(event.requestToken)){
                TSANetWebhookNotifier.notifyProcessingStarted(event.requestToken);
                EventBus.publish(new tsanetconnect__TSANetWebhookEvent__e(
                    tsanetconnect__EventType__c = event.eventType,
                    tsanetconnect__RequestToken__c = event.requestToken,
                    tsanetconnect__NoteToken__c = event.noteToken
                ));
                System.enqueueJob(new TSANetWebhookQueueable(event.eventType, event.requestToken, event.noteToken));
            }
        } catch(Exception e){
            ErrorLogger.logError(e, 'TSANET_WEBHOOK_REST');
        }

        res.statusCode = 200;
        res.responseBody = Blob.valueOf('{"status":"ok"}');
    }

    /**
     * Accepts V1 flat JSON or a V2 CloudEvent. CloudEvent tokens live under data;
     * the CloudEvent type is copied to eventType for downstream processing.
     * @param body raw POST body
     * @return normalized webhook event
     */
    @TestVisible
    private static WebhookEvent parseEvent(String body){
        WebhookEvent event = (WebhookEvent) JSON.deserialize(body, WebhookEvent.class);
        if(event == null || event.data == null){
            return event;
        }
        if(String.isBlank(event.eventType)){
            event.eventType = event.type;
        }
        if(String.isBlank(event.requestToken)){
            event.requestToken = event.data.requestToken;
        }
        if(String.isBlank(event.noteToken)){
            event.noteToken = event.data.noteToken;
        }
        return event;
    }
}
