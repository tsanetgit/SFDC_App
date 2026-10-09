/** Queueable that refreshes a single TSANet collaboration request by its token. */
public inherited sharing class TSANetCaseRefreshQueueable implements Queueable, Database.AllowsCallouts {

    private final String caseToken;

    /**
     * @param caseToken the collaboration request token to refresh
     */
    public TSANetCaseRefreshQueueable(String caseToken){
        this.caseToken = caseToken;
    }

    /**
     * Fetches and upserts the single collaboration request.
     * @param context queueable context provided by the platform
     */
    public void execute(QueueableContext context){
        TSANetCaseRefreshService.refreshByToken(this.caseToken);
    }
}
