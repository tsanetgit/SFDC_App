trigger TSANetNoteFeedItemRequestedTrigger on tsanetconnect__TSANetNoteFeedItemRequested__e (after insert) {

    TriggerDispatcher.run(new TSANetNoteFeedItemRequestedHandler());
}
