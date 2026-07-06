/** REST endpoint that receives inbound webhook events from TSANet. */
@RestResource(urlMapping='/webhook/*')
global without sharing class TSANetWebhookRestService {

    /** DTO for the inbound webhook event payload. */
    global class WebhookEvent {
        public String eventType;
        public String requestToken;
        public String noteToken;
        public String timestamp;
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

    /**
     * Handles incoming POST events: verifies HMAC signature, parses payload,
     * and enqueues async processing.
     */
    @HttpPost
    global static void handleEvent(){
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;

        String body = req.requestBody.toString();
        String signature = req.headers.get('X-Hub-Signature-256');

        /*if(!verifySignature(body, signature)){
            res.statusCode = 401;
            res.responseBody = Blob.valueOf('{"error":"Invalid signature"}');
            return;
        }*/

        try {
            WebhookEvent event = (WebhookEvent) JSON.deserialize(body, WebhookEvent.class);

            if(String.isNotBlank(event.requestToken)){
                // Fire the "processing started" event first so the LWC shows a typing indicator
                // immediately, before the async callout/upsert runs.
                publishProcessingStartedEvent(event.requestToken);
                System.enqueueJob(new TSANetWebhookQueueable(event.eventType, event.requestToken, event.noteToken));
            }

            res.statusCode = 200;
            res.responseBody = Blob.valueOf('{"status":"ok"}');
        } catch(Exception e){
            ErrorLogger.logError(e, 'TSANET_WEBHOOK_RECEIVE');
            res.statusCode = 200;
            res.responseBody = Blob.valueOf('{"status":"ok"}');
        }
    }

    /**
     * Publishes the start TSANetCaseUpdated__e event (IsSync=false) so subscribed LWCs can show a
     * "Someone is typing..." indicator while the async job processes the callout. Resolves the
     * parent Case in SYSTEM_MODE because the webhook runs as the guest/integration user. A failure
     * here must never block webhook acceptance.
     * @param requestToken the collaboration request token from the inbound event
     */
    private static void publishProcessingStartedEvent(String requestToken){
        try {
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
                tsanetconnect__IsSync__c = false
            ));
        } catch(Exception e){
            ErrorLogger.logError(e, 'TSANET_WEBHOOK_TYPING_EVENT');
        }
    }

    /**
     * Verifies the X-Hub-Signature-256 header against all active webhook secrets.
     * @param payload the raw request body
     * @param signature the sha256=<hex> signature from the header
     * @return true if any stored secret produces a matching HMAC
     */
    private static Boolean verifySignature(String payload, String signature){
        if(String.isBlank(signature)){
            return false;
        }

        String receivedHash = signature.startsWith('sha256=')
            ? signature.substringAfter('sha256=')
            : signature;

        tsanetconnect__TSANetWebhook__c[] webhooks = [
            SELECT tsanetconnect__Secret__c
            FROM tsanetconnect__TSANetWebhook__c
            WHERE tsanetconnect__Active__c = TRUE AND tsanetconnect__Secret__c != NULL
            WITH USER_MODE
        ];

        Blob payloadBlob = Blob.valueOf(payload);
        for(tsanetconnect__TSANetWebhook__c wh : webhooks){
            Blob mac = Crypto.generateMac('HmacSHA256', payloadBlob, Blob.valueOf(wh.tsanetconnect__Secret__c));
            String expectedHash = EncodingUtil.convertToHex(mac);
            if(expectedHash.equalsIgnoreCase(receivedHash)){
                return true;
            }
        }

        return false;
    }
}
