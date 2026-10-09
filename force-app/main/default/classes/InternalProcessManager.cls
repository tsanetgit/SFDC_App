/** Manages internal TSANet setup processes such as account sync and job scheduling. */
public with sharing class InternalProcessManager {

    /**
     * Starts TSANet initialization. Jobs are scheduled only after the account probe succeeds.
     * @param credential the TSANet credential record to initialize
     */
    public static void execute(tsanetconnect__TSANet_Credentials__c credential){
        syncAccount(credential.Id);
    }

    /**
     * Syncs company information and webhooks over the Named Credential, and on success
     * enqueues and schedules the sync jobs. Callouts are authorized by the External
     * Credential, so there is no login response and no token to persist.
     * @param credentialId the Id of the TSANet credential to sync
     */
    @Future(callout=true)
    public static void syncAccount(Id credentialId){
        tsanetconnect__TSANet_Credentials__c credential = CredentialManager.getCredentialById(credentialId);

        if(!AuthModeManager.usesNamedCredential(credential)){
            ErrorLogger.logError(
                new TSANetHttpRouter.TSANetHttpRouterException(TSANetConstants.NOT_CONFIGURED_ERROR),
                'TSANET_ACCOUNT_SYNC'
            );
            markDisconnected(credential);
            return;
        }

        try {
            TSANetCompanyInfo info = TSANetAPIService.getCompanyInformation();
            if(info != NULL && info.company != NULL){
                credential.tsanetconnect__CompanyId__c = info.company.id;
                credential.tsanetconnect__CompanyName__c = info.company.name;
            }

            List<tsanetconnect__TSANetWebhook__c> webhookRecords = fetchWebhooks(credential.Id);

            markConnectedAndStartJobs(credential);
            if(!webhookRecords.isEmpty()){
                Database.upsert(webhookRecords, tsanetconnect__TSANetWebhook__c.tsanetconnect__WebhookId__c, false, AccessLevel.USER_MODE);
            }
        } catch (Exception e) {
            ErrorLogger.logError(e, 'TSANET_ACCOUNT_SYNC');
            markDisconnected(credential);
        }
    }

    /**
     * Marks the credential as connected and starts the one-off and recurring sync jobs.
     * @param credential the credential that just passed the account probe
     */
    private static void markConnectedAndStartJobs(tsanetconnect__TSANet_Credentials__c credential){
        credential.tsanetconnect__isConnected__c = true;
        Database.update(credential, AccessLevel.USER_MODE);
        TSANetQueueableJob.enqueueIfConnected(null);
        scheduleTSANetJobs(credential.Id);
    }

    /**
     * Marks the credential as disconnected and aborts its scheduled sync jobs.
     * @param credential the credential whose TSANet connection failed
     */
    public static void markDisconnected(tsanetconnect__TSANet_Credentials__c credential){
        credential.tsanetconnect__isConnected__c = false;
        Database.update(credential, AccessLevel.USER_MODE);
        abortTSANetJobs(credential.Id);
    }

    /** Fetches all webhooks from the TSANet API and returns them as TSANetWebhook__c records (no DML). */
    private static List<tsanetconnect__TSANetWebhook__c> fetchWebhooks(Id credentialId){
        try {
            String response = TSANetWebhookService.getWebhooks();
            List<TSANetWebhookService.WebhookResponse> webhooks =
                (List<TSANetWebhookService.WebhookResponse>) JSON.deserialize(response, List<TSANetWebhookService.WebhookResponse>.class);

            List<tsanetconnect__TSANetWebhook__c> records = new List<tsanetconnect__TSANetWebhook__c>();
            for(TSANetWebhookService.WebhookResponse wh : webhooks){
                tsanetconnect__TSANetWebhook__c record = new tsanetconnect__TSANetWebhook__c();
                record.tsanetconnect__WebhookId__c = wh.id;
                record.tsanetconnect__CallbackUrl__c = wh.callbackUrl;
                record.tsanetconnect__EventTypes__c = wh.eventTypes != null ? String.join(wh.eventTypes, ';') : '';
                record.tsanetconnect__Active__c = wh.active;
                record.tsanetconnect__TSANetCredential__c = credentialId;
                records.add(record);
            }
            return records;
        } catch(Exception e){
            ErrorLogger.logError(e, 'TSANET_WEBHOOK_SYNC');
            return new List<tsanetconnect__TSANetWebhook__c>();
        }
    }

    /**
     * Schedules four recurring TSANet sync jobs (every 15 minutes) if not already scheduled.
     * Looks up the :00/:15/:30/:45 job names; the previous exact-name query never matched
     * and caused AsyncException on re-activate.
     * @param credentialId the Id of the TSANet credential
     */
    public static void scheduleTSANetJobs(Id credentialId){
        String jobFilter = '%TSANetScheduledJob - ' + credentialId + '%';
        Integer existingJobs = [
            SELECT COUNT()
            FROM CronTrigger
            WHERE CronJobDetail.Name LIKE :jobFilter
            WITH USER_MODE
        ];
        if(existingJobs == 4){
            return;
        }

        abortTSANetJobs(credentialId);

        String jobPrefix = 'TSANetScheduledJob - ' + credentialId + ' - ';
        System.schedule(jobPrefix + '00', '0 0 * * * ?',  new TSANetScheduledJob());
        System.schedule(jobPrefix + '15', '0 15 * * * ?', new TSANetScheduledJob());
        System.schedule(jobPrefix + '30', '0 30 * * * ?', new TSANetScheduledJob());
        System.schedule(jobPrefix + '45', '0 45 * * * ?', new TSANetScheduledJob());
    }

    /**
     * Aborts all scheduled TSANet sync jobs for the given credential.
     * @param credentialId the Id of the TSANet credential
     */
    public static void abortTSANetJobs(Id credentialId){
        String jonName = '%TSANetScheduledJob - ' + credentialId + '%';
        CronTrigger[] cronTriggers = [ SELECT Id, CronJobDetail.Name FROM CronTrigger WHERE  CronJobDetail.Name LIKE :jonName WITH USER_MODE ];

        for(CronTrigger cron : cronTriggers){
            System.abortJob(cron.Id);
        }
    }
}
