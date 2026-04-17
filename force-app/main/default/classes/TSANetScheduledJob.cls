/** Scheduled job that enqueues TSANet collaboration-case synchronisation. */
global inherited sharing class TSANetScheduledJob implements Schedulable, Database.AllowsCallouts {

    /** Custom exception for TSANetScheduledJob errors. */
    public class TSANetScheduledJobException extends Exception {}

    /**
     * Enqueues a TSANetQueueableJob to refresh collaboration cases.
     * @param sc schedulable context provided by the platform
     */
    global void execute(SchedulableContext sc){
        System.enqueueJob(new TSANetQueueableJob(0, null, null, null, null, null));
    }
}