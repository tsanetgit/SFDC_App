/**
 * Refreshes a single TSANet collaboration request instead of re-syncing every case behind a
 * Salesforce Case.
 *
 * Every action (create, approve, reject, close, request/send information, note, owner change)
 * already knows the token it acted on, so GET /v1/collaboration-requests/{token} brings the
 * local case, notes and responses up to date with one callout, replacing the paged full sync
 * that TSANetService.retrieveCollaborationCases performs. The full sync stays for the
 * scheduled job and the manual refresh, where no single token is known.
 */
public with sharing class TSANetCaseRefreshService {

    private static final String LOG_CONTEXT = 'TSANET_CASE_REFRESH';

    /**
     * Queues a refresh for one collaboration request.
     * @param caseToken the collaboration request token to refresh
     */
    public static void enqueueByToken(String caseToken){
        if(String.isBlank(caseToken) || !TSANetService.isRefreshEnabled()){ return; }
        System.enqueueJob(new TSANetCaseRefreshQueueable(caseToken));
    }

    /**
     * Queues a refresh for the collaboration request described by an action response.
     * Falls back to the Case-scoped sync when the response carries no token, so a payload
     * change upstream degrades to the old behaviour rather than skipping the refresh.
     * @param responseBody raw API response body for the collaboration request
     * @param fallbackCaseId Salesforce Case Id to sync when no token can be read
     */
    public static void enqueueFromResponse(String responseBody, Id fallbackCaseId){
        String caseToken = readToken(responseBody);
        if(String.isNotBlank(caseToken)){
            enqueueByToken(caseToken);
            return;
        }
        TSANetService.retrieveCollaborationCases(fallbackCaseId);
    }

    /**
     * Fetches one collaboration request and upserts its case, notes and responses.
     * @param caseToken the collaboration request token to refresh
     */
    public static void refreshByToken(String caseToken){
        if(String.isBlank(caseToken)){ return; }

        try {
            String body = TSANetService.getCollaborationCaseByToken(caseToken);
            if(String.isBlank(body)){ return; }

            TSANetData data = ParserManager.parseTSANetCases(toJsonArray(body), null);
            if(data.cases == null || data.cases.isEmpty()){ return; }

            TSANetService.upsertTSANetData(data);
            notifyCaseUpdated(caseToken);
        } catch(Exception e){
            ErrorLogger.logError(e, LOG_CONTEXT);
        }
    }

    /**
     * Tells subscribed LWCs the case is in sync so they reload without polling.
     * A failed notification must not fail the refresh: the data is already committed.
     */
    private static void notifyCaseUpdated(String caseToken){
        try {
            Id caseId = TSANetWebhookNotifier.getCaseIdByToken(caseToken);
            if(caseId == null){ return; }

            TSANetWebhookNotifier.publishCaseUpdated(caseId, caseToken, true);
        } catch(Exception e){
            ErrorLogger.logError(e, LOG_CONTEXT);
        }
    }

    /** Reads the collaboration request token from an action response body. */
    private static String readToken(String responseBody){
        if(String.isBlank(responseBody)){ return null; }

        try {
            Object parsed = System.JSON.deserializeUntyped(responseBody);
            if(!(parsed instanceof Map<String, Object>)){ return null; }

            return (String) ((Map<String, Object>) parsed).get('token');
        } catch(Exception e){
            return null;
        }
    }

    /** The single-case endpoint returns one object; the parser consumes an array. */
    private static String toJsonArray(String body){
        String trimmed = body.trim();
        return trimmed.startsWith('[') ? trimmed : '[' + trimmed + ']';
    }
}
