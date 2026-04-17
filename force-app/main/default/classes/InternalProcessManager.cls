/** Manages internal TSANet setup processes such as account sync and job scheduling. */
public with sharing class InternalProcessManager {

    /**
     * Runs the full TSANet initialization: syncs account, enqueues jobs, and schedules recurring jobs.
     * @param credential the TSANet credential record to initialize
     */
    public static void execute(tsanetconnect__TSANet_Credentials__c credential){
        syncAccount(credential.Id);
        System.enqueueJob(new TSANetQueueableJob(0, null, null, null, null, null));
        scheduleTSANetJobs(credential.Id);
    }

    /**
     * Syncs company information from TSANet and updates the credential record.
     * @param credentialId the Id of the TSANet credential to sync
     */
    @Future(callout=true)
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

    /**
     * Schedules four recurring TSANet sync jobs (every 15 minutes) if not already scheduled.
     * @param credentialId the Id of the TSANet credential
     */
    public static void scheduleTSANetJobs(Id credentialId){

        String jobName = 'TSANetScheduledJob - ' + credentialId;
        CronTrigger[] crons = [SELECT Id, CronJobDetailId, CronJobDetail.Name, State FROM CronTrigger WHERE CronJobDetail.Name =:jobName WITH SECURITY_ENFORCED ];
        Boolean isSchedule = crons.size() == 0;

        if(isSchedule){

            String jobPrefix = 'TSANetScheduledJob - ' + credentialId + ' - ';
            System.schedule(jobPrefix + '00', '0 0 * * * ?',  new TSANetScheduledJob());
            System.schedule(jobPrefix + '15', '0 15 * * * ?', new TSANetScheduledJob());
            System.schedule(jobPrefix + '30', '0 30 * * * ?', new TSANetScheduledJob());
            System.schedule(jobPrefix + '45', '0 45 * * * ?', new TSANetScheduledJob());
        }
    }

    /**
     * Aborts all scheduled TSANet sync jobs for the given credential.
     * @param credentialId the Id of the TSANet credential
     */
    public static void abortTSANetJobs(Id credentialId){
        String jonName = '%TSANetScheduledJob - ' + credentialId + '%';
        CronTrigger[] cronTriggers = [ SELECT Id, CronJobDetail.Name FROM CronTrigger WHERE  CronJobDetail.Name LIKE :jonName WITH SECURITY_ENFORCED ];

        for(CronTrigger cron : cronTriggers){
            System.abortJob(cron.Id);
        }
    }
}