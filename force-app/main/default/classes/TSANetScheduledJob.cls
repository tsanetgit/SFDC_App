/** Scheduled job that enqueues TSANet collaboration-case synchronisation. Explicit with sharing: this is a platform entry point. */
global with sharing class TSANetScheduledJob implements Schedulable, Database.AllowsCallouts {

    /** Custom exception for TSANetScheduledJob errors. */
    public class TSANetScheduledJobException extends Exception {}

    /**
     * Enqueues a TSANetQueueableJob to refresh collaboration cases.
     * @param sc schedulable context provided by the platform
     */
    global void execute(SchedulableContext sc){
        TSANetQueueableJob.enqueueIfConnected(null);
    }
}