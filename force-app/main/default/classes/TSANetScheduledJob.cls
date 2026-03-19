global class TSANetScheduledJob implements Schedulable, Database.AllowsCallouts {
    
    public class TSANetScheduledJobException extends Exception {}

    global void execute(SchedulableContext sc){
        System.enqueueJob(new TSANetQueueableJob(0, null, null, null, null));
    }
}