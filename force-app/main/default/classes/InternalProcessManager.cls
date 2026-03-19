public with sharing class InternalProcessManager {
    
    public static void execute(tsanetconnect__TSANet_Credentials__c credential){
        syncAccount(credential.Id);
        System.enqueueJob(new TSANetQueueableJob(0, null, null, null, null));
        scheduleTSANetJobs(credential.Id);
    }
    
    @future(callout=true)
    public static void syncAccount(Id credentialId){
        tsanetconnect__TSANet_Credentials__c credential = CredentialManager.getCredentialById(credentialId);
        String token = TSANetService.getTSANetAccessToken();
        TSANetCompanyInfo info = TSANetService.getCompanyInformation(token);
        if(info != NULL && info.company != NULL){
			credential.tsanetconnect__CompanyId__c = info.company.id;
        	credential.tsanetconnect__CompanyName__c = info.company.name;            
        }
        
        AccessTokenSplitter.SplitResult splitResult = AccessTokenSplitter.splitBy175(token);
        credential.tsanetconnect__AccessTokenPart1__c = splitResult.firstPart;
        credential.tsanetconnect__AccessTokenPart2__c = splitResult.restPart;
        
        Database.update(credential, AccessLevel.USER_MODE);
    }
    
    public static void scheduleTSANetJobs(Id credentialId){
        
        String jobName = 'TSANetScheduledJob - ' + credentialId;
        CronTrigger[] crons = [SELECT Id, CronJobDetailId, CronJobDetail.Name, State FROM CronTrigger WHERE CronJobDetail.Name =:jobName WITH SECURITY_ENFORCED ];
        Boolean isSchedule = crons.size() == 0;
        
        if(isSchedule){
        
            Map<String, String> cronExpressions = new Map<String, String>{
                '00' => '0 0 * * * ?',   // :00
                '15' => '0 15 * * * ?',  // :15
                '30' => '0 30 * * * ?',  // :30
                '45' => '0 45 * * * ?'   // :45
            };
            
            for (String key : cronExpressions.keySet()) {
                String cron = cronExpressions.get(key);
                System.schedule(
                    'TSANetScheduledJob - ' + credentialId + ' - ' + key,
                    cron,
                    new TSANetScheduledJob()
                );
            }
        }
    }
    
    public static void abortTSANetJobs(Id credentialId){
        String jonName = '%TSANetScheduledJob - ' + credentialId + '%';
        CronTrigger[] cronTriggers = [ SELECT Id, CronJobDetail.Name FROM CronTrigger WHERE  CronJobDetail.Name LIKE :jonName WITH SECURITY_ENFORCED ];
    
        for(CronTrigger cron : cronTriggers){
            System.abortJob(cron.Id);
        }
    }
}