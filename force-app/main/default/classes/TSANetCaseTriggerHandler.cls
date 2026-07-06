/**
 * Handles before-insert trigger logic for TSANetCase records.
 *
 * NOTE: The parent-Case linking logic previously implemented here has been
 * moved to the "TSANet: Inbound: Find Parent Case" record-triggered flow.
 * The original Apex implementation is retained below (commented out) for
 * reference only and is no longer invoked.
 */
public with sharing class TSANetCaseTriggerHandler {

    /**
     * Entry point for the before-insert trigger on TSANetCase.
     * Intentionally a no-op: logic moved to the Find Parent Case flow.
     * @param cases list of TSANetCase records being inserted
     */
    public static void handleBeforeInsert(tsanetconnect__TSANetCase__c[] cases){
        // No-op. See class header.
    }

    /*
    // Moved to the "TSANet: Inbound: Find Parent Case" flow.
    */
}
