/**
 * Publishes TSANetCaseUpdated__e notifications for inbound webhook processing so subscribed
 * LWCs can show a typing indicator while the refresh runs and clear it once it completes.
 */
public with sharing class TSANetWebhookNotifier {

    /**
     * Resolves the Salesforce Case behind a collaboration request token.
     * @param requestToken the collaboration request token
     * @return the related Case Id, or null when the case is not linked locally
     */
    public static Id getCaseIdByToken(String requestToken){
        if(requestToken == null){
            return null;
        }
        tsanetconnect__TSANetCase__c[] cases = [
            SELECT Id, tsanetconnect__Case__c
            FROM tsanetconnect__TSANetCase__c
            WHERE tsanetconnect__Token__c = :requestToken
            WITH USER_MODE
            LIMIT 1
        ];

        return cases.isEmpty() ? null : cases[0].tsanetconnect__Case__c;
    }

    /**
     * Publishes the typing indicator for the related case; never throws to callers.
     * @param requestToken the collaboration request token being processed
     */
    public static void notifyProcessingStarted(String requestToken){
        try {
            Id caseId = getCaseIdByToken(requestToken);
            if(caseId != null){
                publishCaseUpdated(caseId, requestToken, false);
            }
        } catch(Exception e){
            ErrorLogger.logError(e, 'TSANET_WEBHOOK_EVENT_HANDLER', new Map<String, String>{ 'requestToken' => requestToken });
        }
    }

    /**
     * Publishes a case-updated notification for the given Case.
     * @param caseId the Salesforce Case the notification belongs to
     * @param requestToken the collaboration request token being processed
     * @param isSync false when processing starts, true once the data is refreshed
     */
    public static void publishCaseUpdated(Id caseId, String requestToken, Boolean isSync){
        EventBus.publish(new tsanetconnect__TSANetCaseUpdated__e(
            tsanetconnect__CaseId__c = caseId,
            tsanetconnect__RequestToken__c = requestToken,
            tsanetconnect__IsSync__c = isSync
        ));
    }
}
