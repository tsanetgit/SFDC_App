/** Utility methods and wrapper DTOs for TSANet LWC controllers. */
public with sharing class TSANetUtils {

    /** Wrapper holding a Case, its related TSANet cases, and the current user. */
    public class CaseInformation {
        /** The Salesforce Case record. */
        @AuraEnabled
        public Case caseRecord;
        /** TSANet collaboration cases linked to the Case. */
        @AuraEnabled
        public tsanetconnect__TSANetCase__c[] relatedCases;
        /** Current running user. */
        @AuraEnabled
        public User user = getCurrentUserInfo();

        /**
         * Constructs a CaseInformation with related TSANet cases.
         * @param caseRecord the Salesforce Case record
         */
        public CaseInformation(Case caseRecord){
            this.caseRecord = caseRecord;
            this.relatedCases = getTSANetCasesByCaseId(caseRecord.Id);
        }
    }

    /**
     * Loads Case details and related TSANet cases for an LWC.
     * @param caseId Salesforce Case Id
     * @return CaseInformation wrapper
     */
    @AuraEnabled
    public static CaseInformation getCaseInformation(Id caseId){
        if(caseId == NULL){ return new CaseInformation(null); }
        Case caseRecord = CaseSelector.getFullDetailById(caseId);
        return new CaseInformation(caseRecord);
    }

    /**
     * Returns locally stored TSANet cases linked to a Salesforce Case.
     * @param caseId Salesforce Case Id
     * @return list of TSANetCase__c records with responses
     */
    @AuraEnabled
    public static tsanetconnect__TSANetCase__c[] getTSANetCasesByCaseId(Id caseId){
        if(caseId == null){
            return new tsanetconnect__TSANetCase__c[]{};
        }
        return TSANetCaseSelector.getDetailWithResponsesByCaseId(caseId);
    }

    /**
     * Fetches and upserts TSANet collaboration cases from the API for a given Case.
     * @param caseId Salesforce Case Id
     * @return refreshed list of TSANetCase__c records
     */
    @AuraEnabled
    public static tsanetconnect__TSANetCase__c[] getTSANetCases(Id caseId){
        return TSANetService.getRelatedCollaborationCases(caseId);
    }

    /**
     * Asynchronously enqueues a collaboration-case refresh job.
     * @param caseId Salesforce Case Id to scope the refresh (nullable)
     */
    @Future(callout=true)
    public static void futureRefresh(Id caseId){
        if(!TSANetService.isRefreshEnabled()){ return; }

        String caseNumber = null;
        if(caseId != null){
            Case sfCase = CaseSelector.getById(caseId);
            caseNumber = sfCase.CaseNumber;
        }
        TSANetQueueableJob.enqueueIfConnected(caseNumber);
    }

    /** Wrapper holding a TSANetCase__c, its linked Case, and the current user. */
    public class TSANetCaseInfo {
        /** The linked Salesforce Case record. */
        @AuraEnabled
        public Case caseRecord;
        /** The TSANetCase__c record. */
        @AuraEnabled
        public tsanetconnect__TSANetCase__c record;
        /** Current running user. */
        @AuraEnabled
        public User user = getCurrentUserInfo();

        /**
         * Constructs a TSANetCaseInfo wrapper.
         * @param tsaNetCase the TSANetCase__c record
         * @param caseRecord the linked Salesforce Case record
         */
        public TSANetCaseInfo(tsanetconnect__TSANetCase__c tsaNetCase, Case caseRecord){
            this.caseRecord = caseRecord;
            this.record = tsaNetCase;
        }
    }

    /**
     * Returns the currently logged-in user's basic info.
     * @return User record with Id, Name, Email, Phone
     */
    @AuraEnabled
    public static User getCurrentUserInfo(){
        return [SELECT Id, Name, FirstName, LastName, Email, Phone FROM User WHERE Id =:UserInfo.getUserId() WITH USER_MODE LIMIT 1];
    }

    /**
     * Loads a TSANetCase__c and its linked Case for the record-detail page.
     * @param recordId TSANetCase__c record Id
     * @return TSANetCaseInfo wrapper
     */
    @AuraEnabled
    public static TSANetCaseInfo getTSANetInfo(Id recordId){
        if(recordId == null){
            return null;
        }
        tsanetconnect__TSANetCase__c[] tsaNetCase = TSANetCaseSelector.getInfoById(recordId);
    	Case caseRecord;
        if(tsaNetCase.size() > 0 && tsaNetCase[0].tsanetconnect__Case__c != NULL){
             caseRecord = CaseSelector.getFullDetailById(tsaNetCase[0].tsanetconnect__Case__c);
        }

        return new TSANetCaseInfo(tsaNetCase[0], caseRecord);
    }

    /**
     * Reconnects the TSANet integration by re-running the setup sync.
     * @return true if the reconnect was started
     */
    @AuraEnabled
    public static Boolean getNewAccessToken(){
        return AuthManager.updateAccessToken();
    }

    /**
     * Returns minimal record-page info for a TSANetCase__c.
     * @param caseId TSANetCase__c record Id
     * @return TSANetCase__c with record-page fields
     */
    @AuraEnabled
    public static tsanetconnect__TSANetCase__c getTSANetRecordPageInfo(Id caseId){
        if(caseId == null){
            return null;
        }
        return TSANetCaseSelector.getRecordPageInfo(caseId);
    }

    /**
     * Searches or returns recent Cases for the case-picker component.
     * @param searchText search term (nullable for recent cases)
     * @return matching Case records
     */
    @AuraEnabled(cacheable=true)
    public static Case[] getCases(String searchText){
        if(searchText == NULL || searchText == ''){
            return CaseSelector.getRecent();
        }
        return CaseSelector.search(searchText);
    }

    /**
     * Returns a minimal TSANetCase__c by its record Id.
     * @param caseId TSANetCase__c record Id
     * @return TSANetCase__c with minimal fields
     */
    @AuraEnabled
    public static tsanetconnect__TSANetCase__c getOneTSANetCase(Id caseId){
        if(caseId == null){
            return null;
        }
        return TSANetCaseSelector.getMinimalById(caseId);
    }

    /**
     * Returns all ContentVersion files linked to a TSANet case and its Salesforce Case.
     * @param caseId TSANetCase__c record Id
     * @return list of ContentVersion records
     */
    @AuraEnabled
    public static ContentVersion[] getAllRelatedFiles(Id caseId){
        tsanetconnect__TSANetCase__c tsaNetCase = TSANetCaseSelector.getMinimalById(caseId);

        ContentDocumentLink[] links = [SELECT Id, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId =:tsaNetCase.Id OR LinkedEntityId =:tsaNetCase.tsanetconnect__Case__c WITH USER_MODE ];

        Id[] contentDocumentIds = new Id[]{};
        for(ContentDocumentLink link : links){
        	contentDocumentIds.add(link.ContentDocumentId);
        }

        ContentVersion[] contentVersions = [SELECT Id, ContentDocumentId, Title FROM ContentVersion WHERE ContentDocumentId IN:contentDocumentIds WITH USER_MODE ];

        return contentVersions;
    }

    /**
     * Strips HTML tags and decodes common HTML entities from a string.
     * @param input raw HTML string
     * @return plain-text version of the input
     */
    public static String stripHtml(String input) {
        if (String.isBlank(input)) {
            return input;
        }

        String result = input.replaceAll('<[^>]*>', '');
        result = result
            .replace('&nbsp;', ' ')
            .replace('&amp;', '&')
            .replace('&lt;', '<')
            .replace('&gt;', '>')
            .replace('&quot;', '"')
            .replace('&#39;', '\'');

        return result.trim();
    }
}
