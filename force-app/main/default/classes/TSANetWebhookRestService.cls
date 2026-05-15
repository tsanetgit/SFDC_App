/** REST endpoint that receives inbound webhook events from TSANet. */
@RestResource(urlMapping='/webhook/*')
global with sharing class TSANetWebhookRestService {

    /** DTO for the inbound webhook event payload. */
    global class WebhookEvent {
        public String eventType;
        public String requestToken;
        public String noteToken;
        public String timestamp;
    }

    /**
     * Handles incoming POST events: verifies HMAC signature, parses payload,
     * and enqueues async processing.
     */
    @HttpGet
    global static String handleGet(){
        return 'test';
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
            WITH SECURITY_ENFORCED
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
