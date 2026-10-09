/**
 * Service layer for TSANet Connect API operations.
 *
 * Remains the single entry point for every caller (LWC, Aura, invocables, jobs) and
 * delegates each operation to TSANetAPIService, which calls the API through the
 * Named Credential of the primary credential record.
 */
public with sharing class TSANetService {

    /** Custom exception for TSANetService errors. */
    public class TSANetServiceException extends Exception {}

    /**
     * Single switch for the follow-up refresh that every action fires. On by default, so tests
     * exercise the same refresh chain as production; the few tests that would exceed the
     * queueable-depth limit turn it off explicitly.
     */
    @TestVisible
    private static Boolean refreshAfterAction = true;

    /**
     * True when actions should queue a collaboration-case refresh after they succeed.
     * @return whether the post-action refresh is enabled for this transaction
     */
    public static Boolean isRefreshEnabled(){
        return refreshAfterAction;
    }

    /**
     * Retrieves the current company information from the TSANet API.
     * @return deserialised TSANetCompanyInfo
     */
    public static TSANetCompanyInfo getCompanyInformation(){
        return TSANetAPIService.getCompanyInformation();
    }

    /**
     * Creates a note on a TSANet collaboration case via the API.
     * @param caseToken unique token of the TSANet case
     * @param json serialised note payload
     * @return raw API response body
     */
    @AuraEnabled
    public static String createTSANetNote(String caseToken, String json){
        return TSANetAPIService.createTSANetNote(caseToken, json);
    }

    /**
     * Fetches a single collaboration request from the TSANet API.
     * @param caseToken the collaboration request token
     * @return raw API response body for the collaboration request
     */
    public static String getCollaborationCaseByToken(String caseToken){
        return TSANetAPIService.getCollaborationCaseByToken(caseToken);
    }

    /**
     * Fetches collaboration cases from the TSANet API and upserts them locally.
     * @param caseId Salesforce Case Id to scope results (nullable for all)
     * @return list of related TSANetCase__c records for the given Case
     */
    @AuraEnabled
    public static tsanetconnect__TSANetCase__c[] getRelatedCollaborationCases(String caseId){
        return TSANetAPIService.getRelatedCollaborationCases(caseId);
    }

    /**
     * Retrieves the collaboration form definition for a given company.
     * @param companyId TSANet company identifier
     * @param mode form mode (e.g. "company" or "department")
     * @return raw API response body containing the form definition
     */
    @AuraEnabled
    public static String getFormByCompanyId(String companyId, String mode){
        return TSANetAPIService.getFormByCompanyId(companyId, mode);
    }

    /**
     * Searches TSANet companies by name.
     * @param companyName search term for the company name
     * @return raw API response body with matching companies
     */
    @AuraEnabled
    public static String getCompaniesByName(String companyName){
        return TSANetAPIService.getCompaniesByName(companyName);
    }

    /**
     * Submits a new collaboration case to the TSANet API.
     * @param caseId Salesforce Case Id linked to the collaboration
     * @param json serialised case payload
     * @return raw API response body
     */
    @AuraEnabled
    public static String createCollaborationCase(Id caseId, String json){
        return TSANetAPIService.createCollaborationCase(caseId, json);
    }

    /**
     * Approves an incoming TSANet collaboration request.
     * @param caseToken unique token of the TSANet case
     * @param json serialised approval payload with engineer details
     * @return raw API response body
     */
    @AuraEnabled
    public static String approveIncomingRequest(String caseToken, String json){
        return TSANetAPIService.approveIncomingRequest(caseToken, json);
    }

    /**
     * Rejects a TSANet collaboration case via the API.
     * @param tsaNetCaseId Id of the TSANetCase__c record
     * @param json serialised rejection payload
     * @return raw API response body
     */
    @AuraEnabled
    public static String rejectTSANetCase(String tsaNetCaseId, String json){
        return TSANetAPIService.rejectTSANetCase(tsaNetCaseId, json);
    }

    /**
     * Closes a TSANet collaboration case via the API.
     * @param tsaNetCaseId Id of the TSANetCase__c record
     * @return raw API response body
     */
    @AuraEnabled
    public static String closeTSANetCase(String tsaNetCaseId){
        return TSANetAPIService.closeTSANetCase(tsaNetCaseId);
    }

    /**
     * Sends an additional-information request on a TSANet case.
     * @param tsaNetCaseId Id of the TSANetCase__c record
     * @param json serialised information-request payload
     * @return raw API response body
     */
    @AuraEnabled
    public static String requestAdditionalInformation(String tsaNetCaseId, String json){
        return TSANetAPIService.requestAdditionalInformation(tsaNetCaseId, json);
    }

    /**
     * Sends additional-information response on a TSANet case.
     * @param tsaNetCaseId Id of the TSANetCase__c record
     * @param json serialised information-response payload
     * @return raw API response body
     */
    @AuraEnabled
    public static String sendAdditionalInformation(String tsaNetCaseId, String json){
        return TSANetAPIService.sendAdditionalInformation(tsaNetCaseId, json);
    }

    /**
     * Retrieves the attachment configuration for a TSANet case.
     * @param token unique case token
     * @return raw API response body with attachment config
     */
    @AuraEnabled
    public static String getAttachmentConfig(String token){
        return TSANetAPIService.getAttachmentConfig(token);
    }

    /**
     * Uploads file attachments to a TSANet case and links them locally.
     * @param token unique case token
     * @param files list of file-data maps (base64, filename, fileId)
     * @return raw API response body with upload results
     */
    @AuraEnabled
    public static String sendAttachment(String token, List<Map<String, Object>> files){
        return TSANetAPIService.sendAttachment(token, files);
    }

    /**
     * Sends an owner-change update to the TSANet API for an outbound case.
     * @param caseId Id of the TSANetCase__c record
     */
    @Future(callout=true)
    public static void changeTSANetOwner(Id caseId){
        TSANetAPIService.changeTSANetOwner(caseId);
    }

    /**
     * Updates an approved inbound collaboration request via PATCH /approval (engineer + case details).
     * @param tsaNetCaseId tsanetconnect__TSANetCase__c Id
     */
    @Future(callout=true)
    public static void changeTSANetResponse(Id tsaNetCaseId){
        TSANetAPIService.changeTSANetResponse(tsaNetCaseId);
    }

    /**
     * Enqueues a background refresh of collaboration cases (optionally scoped by CaseNumber).
     * No-op when the refresh is disabled for this transaction.
     * @param caseId Salesforce Case Id to scope the refresh (nullable)
     */
    public static void retrieveCollaborationCases(Id caseId){
        if(!refreshAfterAction){ return; }

        String caseNumber = null;
        if(caseId != null){
            Case sfCase = CaseSelector.getById(caseId);
            caseNumber = sfCase.CaseNumber;
        }
        TSANetQueueableJob.enqueueIfConnected(caseNumber);
    }

    /**
     * Shared upsert + error-collection for TSANet cases, notes, and responses.
     * Uses UpsertExecutor to transparently recover from concurrent-insert DUPLICATE_VALUE
     * races (the periodic sync, the LWC related-list refresh, and the inbound webhook
     * can all touch the same external Id at the same time).
     * @param data parsed TSANet data containing cases, notes, and responses
     */
    public static void upsertTSANetData(TSANetData data){
        UpsertExecutor.execute(data.cases, tsanetconnect__TSANetCase__c.tsanetconnect__Token__c, AccessLevel.USER_MODE);
        UpsertExecutor.execute(data.notes, tsanetconnect__TSANetNote__c.tsanetconnect__Token__c, AccessLevel.USER_MODE);
        UpsertExecutor.execute(data.responses, tsanetconnect__TSANetResponse__c.tsanetconnect__tsaNetResponseId__c, AccessLevel.USER_MODE);
    }
}
