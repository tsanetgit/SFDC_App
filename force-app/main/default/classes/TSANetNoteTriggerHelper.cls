public with sharing class TSANetNoteTriggerHelper {

    public static tsanetconnect__TSANet_Credentials__c credential = CredentialManager.getCredentials();
    
    public static void findRelationships(tsanetconnect__TSANetNote__c[] notes){
        try {
            String[] tsaNetExternalCaseIds = new String[]{};
                
                for(tsanetconnect__TSANetNote__c note : notes){
                    tsaNetExternalCaseIds.add(note.tsanetconnect__CaseId__c);
                }
            
            if(tsaNetExternalCaseIds.size() == 0){ return; }
            
            tsanetconnect__TSANetCase__c[] tsaNetCases = [SELECT Id, Name, OwnerId, tsanetconnect__Case__c, tsanetconnect__tsaNetCaseId__c, tsanetconnect__Partner__c FROM tsanetconnect__TSANetCase__c WHERE tsanetconnect__tsaNetCaseId__c IN:tsaNetExternalCaseIds WITH SECURITY_ENFORCED ];
            
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
    
    public static void createFeedItems(tsanetconnect__TSANetNote__c[] notes){
        Id[] tsaNetCaseIds = new Id[]{};
            
        for(tsanetconnect__TSANetNote__c note : notes){
            if(note.tsanetconnect__isCaseFeed__c == true){
                tsaNetCaseIds.add(note.tsanetconnect__TSANetCase__c);
            }
        }
        if(tsaNetCaseIds.size() == 0){ return; }

        Map<Id, tsanetconnect__TSANetCase__c> tsaNetCases = new Map<Id, tsanetconnect__TSANetCase__c>([SELECT Id, Name, tsanetconnect__Case__c, tsanetconnect__Partner__c FROM tsanetconnect__TSANetCase__c WHERE Id IN:tsaNetCaseIds WITH SECURITY_ENFORCED ]);

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
                String priority = note.tsanetconnect__Priority__c;
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
                
                String message = 
                    '<p>Note Details:</p>' + 
                    '<p>Company Name: ' + companyName + '</p>' + 
                    '<p>Created By: ' + creatorName + '</p>' +
                    '<p>Summary: ' + refactoredSummary + '</p>' +
                    '<p>Description: ' + refactoredDescription + '</p>';
                
                
                
                if(tsaNetCase != NULL && tsaNetCase.tsanetconnect__Case__c != NULL){
                    FeedItem f = new FeedItem(
                        ParentId = tsaNetCase.tsanetconnect__Case__c,
                        CreatedById = credential.tsanetconnect__IntegrationUser__c,
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
                    FeedItem failedItem = feedItems[i];
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