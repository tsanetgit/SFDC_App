/** Trigger handler for TSANetWebhook__c — deletes subscriptions from TSANet API on record removal. */
public inherited sharing class TSANetWebhookTriggerHandler implements ITriggerHandler {

    public void beforeInsert(List<SObject> newItems) {
    }

    public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    }

    /** Collects webhook IDs and fires async API delete before records are removed. */
    public void beforeDelete(Map<Id, SObject> oldItems){
        Map<Id, tsanetconnect__TSANetWebhook__c> webhooks = (Map<Id, tsanetconnect__TSANetWebhook__c>) oldItems;

        Set<Integer> webhookIds = new Set<Integer>();
        for(tsanetconnect__TSANetWebhook__c wh : webhooks.values()){
            if(wh.tsanetconnect__WebhookId__c != null && isSalesforceWebhook(wh)){
                webhookIds.add(Integer.valueOf(wh.tsanetconnect__WebhookId__c));
            }
        }

        if(!webhookIds.isEmpty() && !System.isFuture() && !System.isBatch()){
            TSANetWebhookService.deleteWebhooksAsync(webhookIds);
        }
    }

    /** Registers new webhooks with the TSANet API after record creation. */
    public void afterInsert(Map<Id, SObject> newItems){
        Map<Id, tsanetconnect__TSANetWebhook__c> webhooks = (Map<Id, tsanetconnect__TSANetWebhook__c>) newItems;

        Set<Id> recordIds = new Set<Id>();
        for(tsanetconnect__TSANetWebhook__c wh : webhooks.values()){
            if(wh.tsanetconnect__WebhookId__c == null){
                recordIds.add(wh.Id);
            }
        }

        if(!recordIds.isEmpty() && !System.isFuture() && !System.isBatch()){
            TSANetWebhookService.registerWebhooksAsync(recordIds);
        }
    }

    public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
    }

    public void afterDelete(Map<Id, SObject> oldItems){
    }

    public void afterUndelete(Map<Id, SObject> newItems){
    }

    private static Boolean isSalesforceWebhook(tsanetconnect__TSANetWebhook__c wh){
        return String.isNotBlank(wh.tsanetconnect__CallbackUrl__c)
            && wh.tsanetconnect__CallbackUrl__c.endsWith('/services/apexrest/tsanetconnect/webhook');
    }

    public Boolean isDisabled(){
        return false;
    }
}
