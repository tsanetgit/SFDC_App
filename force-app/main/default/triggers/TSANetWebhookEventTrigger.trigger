trigger TSANetWebhookEventTrigger on tsanetconnect__TSANetWebhookEvent__e (after insert) {
    // High Volume PEs can leave Trigger.newMap empty; always read Trigger.new.
    TSANetWebhookEventTriggerHandler.handleEvents(Trigger.new);
}
