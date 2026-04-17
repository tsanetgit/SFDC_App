/** Legacy case trigger handler. @deprecated Replaced by TSANetCaseOwnerChangeHandler flow + TSANetInvocableChangeOwnerService. */
public with sharing class CaseTriggerHandler {

    /**
     * Handles post-update logic for Case records (deprecated).
     * @param cases updated Case records
     * @param oldCases map of old Case versions keyed by Id
     */
    public static void handleAfterUpdate(Case[] cases, Map<Id, Case> oldCases){
        // Deprecated — logic moved to TSANetCaseOwnerChangeHandler flow
    }
}
