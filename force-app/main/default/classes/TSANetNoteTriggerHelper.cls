/** Helper methods for TSANetNote__c trigger logic. */
public with sharing class TSANetNoteTriggerHelper {


    /**
     * Links notes to their parent TSANetCase records and assigns ownership.
     * @param notes list of notes to process
     */
    public static void findRelationships(tsanetconnect__TSANetNote__c[] notes){
        try {
            String[] tsaNetExternalCaseIds = new String[]{};

                for(tsanetconnect__TSANetNote__c note : notes){
                    tsaNetExternalCaseIds.add(note.tsanetconnect__CaseId__c);
                }

            if(tsaNetExternalCaseIds.size() == 0){ return; }

            tsanetconnect__TSANetCase__c[] tsaNetCases = TSANetCaseSelector.getByExternalCaseIds(new Set<String>(tsaNetExternalCaseIds));

            Map<String, tsanetconnect__TSANetCase__c> externalIdToCase = new Map<String, tsanetconnect__TSANetCase__c>();
            for(tsanetconnect__TSANetCase__c tsaNetCase : tsaNetCases){
                externalIdToCase.put(tsaNetCase.tsanetconnect__tsaNetCaseId__c, tsaNetCase);
            }

            for(tsanetconnect__TSANetNote__c note : notes){
                if(externalIdToCase.containsKey(note.tsanetconnect__CaseId__c)){
                    tsanetconnect__TSANetCase__c tsaNetCase = externalIdToCase.get(note.tsanetconnect__CaseId__c);
                    note.tsanetconnect__TSANetCase__c = tsaNetCase.Id;
                    note.OwnerId = tsaNetCase.OwnerId;
                }
            }
        } catch(Exception e){
            ErrorLogger.logError(e, 'TSANET_NOTE_FIND_RELATIONSHIPS_ERROR');
        }
    }

    /**
     * Creates Chatter feed items on linked Cases for the given notes.
     * @param notes list of notes to create feed items for
     */
    public static void createFeedItems(tsanetconnect__TSANetNote__c[] notes){
        Id[] tsaNetCaseIds = new Id[]{};

        for(tsanetconnect__TSANetNote__c note : notes){
            if(note.tsanetconnect__isCaseFeed__c == true){
                tsaNetCaseIds.add(note.tsanetconnect__TSANetCase__c);
            }
        }
        if(tsaNetCaseIds.size() == 0){ return; }

        Map<Id, tsanetconnect__TSANetCase__c> tsaNetCases = new Map<Id, tsanetconnect__TSANetCase__c>(TSANetCaseSelector.getByIds(new Set<Id>(tsaNetCaseIds)));

        Id[] caseIds = new Id[]{};
        for(tsanetconnect__TSANetCase__c tsaNetCase : tsaNetCases.values()){
            if(tsaNetCase.tsanetconnect__Case__c != NULL){
                caseIds.add(tsaNetCase.tsanetconnect__Case__c);
            }
        }

        FeedItem[] items = [SELECT Id, Title, Body FROM FeedItem WHERE ParentId IN:caseIds AND Title LIKE '%TSANet Note - %' WITH SECURITY_ENFORCED ];

        Map<String, FeedItem> sortedItems = new Map<String, FeedItem>();
        for(FeedItem item : items){
            if(item.Title != NULL){
                String[] strs = item.Title.split(' - ');
                String token = strs[1];
                sortedItems.put(token, item);
            }
        }

        FeedItem[] feedItems = new FeedItem[]{};
        for(tsanetconnect__TSANetNote__c note : notes){
            if(!sortedItems.containsKey(note.tsanetconnect__Token__c)){
                String summary = note.tsanetconnect__Summary__c;
                String description = note.tsanetconnect__Description__c;
                String creatorName = note.tsanetconnect__CreatorName__c;
                String companyName = note.tsanetconnect__CompanyName__c;

                if(description != NULL && description.contains('<strong>')){
                    description = description.replaceAll('<strong>', '<b>');
                    description = description.replaceAll('</strong>', '</b>');
                }

                if(description != NULL && description.contains('<br>')){
                	description = description.replaceAll('<br>', '<p>&nbsp;</p>');
                }

                String refactoredSummary = TSANetHelper.stripAllHtml(summary);
                String refactoredDescription = TSANetHelper.stripAllHtml(description);

                tsanetconnect__TSANetCase__c tsaNetCase = tsaNetCases.get(note.tsanetconnect__TSANetCase__c);

                String message = '<p>Note Details:</p>';
                if(String.isNotBlank(companyName)){
                    message += '<p>Company Name: ' + companyName + '</p>';
                }
                message += '<p>Created By: ' + creatorName + '</p>' +
                    '<p>Summary: ' + refactoredSummary + '</p>';
                if (String.isNotBlank(refactoredDescription)) {
                    message += '<p>Description: ' + refactoredDescription + '</p>';
                }



                if(tsaNetCase != NULL && tsaNetCase.tsanetconnect__Case__c != NULL){
                    tsanetconnect__TSANet_Credentials__c cred = CredentialManager.getCredentials();
                    FeedItem f = new FeedItem(
                        ParentId = tsaNetCase.tsanetconnect__Case__c,
                        CreatedById = cred.tsanetconnect__IntegrationUser__c,
                        IsRichText = true,
                        Title = 'TSANet Note - ' + note.tsanetconnect__Token__c,
                        Body = message
                    );

                    feedItems.add(f);
                }

            }
        }

        try {
            Database.SaveResult[] results = Database.insert(feedItems, false, AccessLevel.USER_MODE);

            for (Integer i = 0; i < results.size(); i++) {
                if (!results[i].isSuccess()) {
                    for (Database.Error err : results[i].getErrors()) {
                        ErrorLogger.logError(err.getMessage(), 'TSANET_NOTE_FEED_ITEM_MAPPING_ERROR');
                    }
                }
            }
        } catch(Exception e){
            ErrorLogger.logError(e.getMessage(), 'TSANET_NOTE_FEED_ITEM_ERROR');
        }
    }
}