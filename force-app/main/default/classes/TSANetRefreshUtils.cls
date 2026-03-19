public class TSANetRefreshUtils {

    public static tsanetconnect__TSANet_Credentials__c credential = CredentialManager.getCredentials();

    public TSANetRefreshUtils(ApexPages.StandardController controller) {}

    public PageReference refresh() {
        try {
            System.enqueueJob(new TSANetQueueableJob(0, null, null, null, null));
            PageReference returnPage = goBack();
            return returnPage; 
            
        } catch(Exception e){
            PageReference returnPage = goBack();
            return returnPage; 
        }
    }
    
    public PageReference goBack() {
        return new PageReference('/lightning/o/tsanetconnect__TSANetCase__c/list'); 
    }
    
    @AuraEnabled
    public static Boolean refreshOnCase(Id caseId) {
        try {
            TSANetService.getRelatedCollaborationCases(caseId, null);
            return true; 
        } catch(Exception e){
            return true; 
        }
    }

}