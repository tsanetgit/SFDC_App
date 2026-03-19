public without sharing class TSANetUtils {
    
    public static tsanetconnect__TSANet_Credentials__c credential = CredentialManager.getCredentials();
    
    public class CaseInformation {
        @AuraEnabled
        public Case caseRecord;
        @AuraEnabled
        public tsanetconnect__TSANetCase__c[] relatedCases;
        @AuraEnabled
        public User user = getCurrentUserInfo();
        
        public CaseInformation(Case caseRecord){
            this.caseRecord = caseRecord;
            this.relatedCases = getTSANetCasesByCaseId(caseRecord.Id);
        }
    }

    @AuraEnabled
    public static CaseInformation getCaseInformation(Id caseId){
        
        if(caseId == NULL){ return new CaseInformation(null); }
        
        Case caseRecord = [SELECT Id, Subject, CaseNumber, Description, Owner.Name, Owner.FirstName, Owner.LastName, Owner.Phone, Owner.Email, AccountId, Account.Name, ContactId, Contact.Name, Contact.FirstName, Contact.LastName, Contact.Email, Contact.Phone FROM Case WHERE Id =:caseId WITH SECURITY_ENFORCED ];
        return new CaseInformation(caseRecord);
    }
    
    @AuraEnabled
    public static tsanetconnect__TSANetCase__c[] getTSANetCasesByCaseId(Id caseId){

        return [SELECT Id, Name, tsanetconnect__Name__c, tsanetconnect__customFields__c, tsanetconnect__EscalationInstructions__c, tsanetconnect__TSANetContact__c, tsanetconnect__FirstName__c, tsanetconnect__LastName__c, tsanetconnect__Phone__c, tsanetconnect__EngineerName__c, tsanetconnect__EngineerEmail__c, tsanetconnect__TSANetEmail__c, tsanetconnect__EngineerPhone__c, tsanetconnect__Email__c, tsanetconnect__Case__c, tsanetconnect__Case__r.CaseNumber, Partner__c, tsanetconnect__SubmittedCompanyName__c, tsanetconnect__SubmittedCompanyId__c, tsanetconnect__receivedCompanyName__c, tsanetconnect__receivedCompanyId__c, tsanetconnect__Summary__c, tsanetconnect__Description__c, tsanetconnect__Status__c, tsanetconnect__Token__c, tsanetconnect__Responded__c, tsanetconnect__FeedbackRequested__c, tsanetconnect__ReminderSent__c, tsanetconnect__Priority__c, tsanetconnect__tsaNetCaseId__c, tsanetconnect__RequestDate__c, tsanetconnect__ResponseDate__c, tsanetconnect__PriorityNote__c, tsanetconnect__Direction__c,
                    (SELECT Id, Name, tsanetconnect__TSANetCase__c, tsanetconnect__Type__c, tsanetconnect__EngineerName__c, tsanetconnect__EngineerPhone__c, tsanetconnect__EngineerEmail__c, tsanetconnect__Note__c, tsanetconnect__tsaNetCaseId__c, tsanetconnect__tsaNetResponseId__c FROM tsanetconnect__TSANetResponses__r ORDER BY tsanetconnect__CreatedAt__c DESC)
                    FROM tsanetconnect__TSANetCase__c 
                    WHERE tsanetconnect__Case__c =:caseId 
                	WITH SECURITY_ENFORCED
                    ORDER BY tsanetconnect__RequestDate__c DESC];
    }
    
    @AuraEnabled
    public static tsanetconnect__TSANetCase__c[] getTSANetCases(Id caseId){
        return TSANetService.getRelatedCollaborationCases(caseId, null);
    }
    
    @future(callout=true)
    public static void futureRefresh(Id caseId){ 
        TSANetService.getRelatedCollaborationCases(caseId, null);
    }
    
    @AuraEnabled
    public static Boolean updateUserCredentials(String username, String password){
        credential.tsanetconnect__UserName__c = username;
        credential.tsanetconnect__Password__c = password;
        return Database.update(credential, AccessLevel.USER_MODE).isSuccess();
    }
    
    public class TSANetCaseInfo {
        @AuraEnabled
        public Case caseRecord;
        @AuraEnabled
        public tsanetconnect__TSANetCase__c record;
        @AuraEnabled
        public User user = getCurrentUserInfo();
        
        public TSANetCaseInfo(tsanetconnect__TSANetCase__c tsaNetCase, Case caseRecord){
            this.caseRecord = caseRecord;
            this.record = tsaNetCase;
        }
    }
    
    @AuraEnabled
    public static User getCurrentUserInfo(){
        return [SELECT Id, Name, FirstName, LastName, Email, Phone FROM User WHERE Id =:UserInfo.getUserId() WITH SECURITY_ENFORCED LIMIT 1];
    }

    @AuraEnabled
    public static TSANetCaseInfo getTSANetInfo(Id recordId){
        tsanetconnect__TSANetCase__c[] tsaNetCase = [SELECT Id, tsanetconnect__SubmittedCompanyName__c, tsanetconnect__receivedCompanyName__c, tsanetconnect__Case__c, tsanetconnect__Token__c, tsanetconnect__tsaNetCaseId__c FROM tsanetconnect__TSANetCase__c WHERE Id =:recordId WITH SECURITY_ENFORCED ];
    	Case caseRecord;
        if(tsaNetCase.size() > 0 && tsaNetCase[0].tsanetconnect__Case__c != NULL){
             caseRecord = [SELECT Id, Subject, CaseNumber, Description, 
                            Owner.Name, Owner.FirstName, Owner.LastName, Owner.Phone, Owner.Email,
                            AccountId, Account.Name, ContactId, Contact.Name, Contact.FirstName, Contact.LastName, Contact.Email, Contact.Phone
                            FROM Case 
                            WHERE Id =:tsaNetCase[0].tsanetconnect__Case__c WITH SECURITY_ENFORCED ];
        }
    
        return new TSANetCaseInfo(tsaNetCase[0], caseRecord);
    }
    
    @AuraEnabled
    public static Boolean getNewAccessToken(){
        return AuthManager.updateAccessToken();
    }
    
    @AuraEnabled
    public static tsanetconnect__TSANetCase__c getTSANetRecordPageInfo(Id caseId){
        return [SELECT Id, Name, tsanetconnect__tsaNetCaseId__c, tsanetconnect__customFields__c, tsanetconnect__Case__r.Id, tsanetconnect__Case__r.CaseNumber FROM tsanetconnect__TSANetCase__c WHERE Id =:caseId WITH SECURITY_ENFORCED ];    
    }
    
    @AuraEnabled
    public static Case[] getCases(String searchText){
        Case[] cases = new Case[]{};
            if(searchText == NULL || searchText == ''){
                cases = [SELECT Id, CaseNumber, Subject FROM Case WITH SECURITY_ENFORCED ORDER BY LastViewedDate DESC LIMIT 10];    
            } else {
                cases = [SELECT Id, CaseNumber, Subject FROM Case WHERE (CaseNumber =:searchText OR Subject =:searchText) WITH SECURITY_ENFORCED ];    
            }
        return cases;
    }
    
    @AuraEnabled
    public static Boolean updateTSANetCase(tsanetconnect__TSANetCase__c tsaNetCase){
        return Database.update(tsaNetCase, AccessLevel.USER_MODE).isSuccess();
    }
    
    @AuraEnabled
    public static tsanetconnect__TSANetCase__c getOneTSANetCase(Id caseId){
        return [SELECT Id, tsanetconnect__tsaNetCaseId__c FROM tsanetconnect__TSANetCase__c WHERE Id =:caseId WITH SECURITY_ENFORCED ];
    }
    
    @AuraEnabled
    public static ContentVersion[] getAllRelatedFiles(Id caseId){
        tsanetconnect__TSANetCase__c tsaNetCase = [SELECT Id, tsanetconnect__tsaNetCaseId__c, tsanetconnect__Case__c FROM tsanetconnect__TSANetCase__c WHERE Id =:caseId WITH SECURITY_ENFORCED ];
        
        ContentDocumentLink[] links = [SELECT Id, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId =:tsaNetCase.Id OR LinkedEntityId =:tsaNetCase.tsanetconnect__Case__c WITH SECURITY_ENFORCED ];
        
        Id[] contentDocumentIds = new Id[]{};
        for(ContentDocumentLink link : links){
        	contentDocumentIds.add(link.ContentDocumentId);
        }
        
        ContentVersion[] contentVersions = [SELECT Id, ContentDocumentId, Title FROM ContentVersion WHERE ContentDocumentId IN:contentDocumentIds WITH SECURITY_ENFORCED ];
        
        return contentVersions;
    }
    
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