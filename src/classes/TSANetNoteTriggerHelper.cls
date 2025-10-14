public class TSANetNoteTriggerHelper {

    public static tsanet_connect__TSANet_Credentials__c credential = CredentialManager.getCredentials();
    
    public static void findRelationships(tsanet_connect__TSANetNote__c[] notes){
        try {
            String[] tsaNetExternalCaseIds = new String[]{};
                
                for(tsanet_connect__TSANetNote__c note : notes){
                    tsaNetExternalCaseIds.add(note.tsanet_connect__CaseId__c);
                }
            
            if(tsaNetExternalCaseIds.size() == 0){ return; }
            
            tsanet_connect__TSANetCase__c[] tsaNetCases = [SELECT Id, Name, tsanet_connect__Case__c, tsanet_connect__tsaNetCaseId__c, tsanet_connect__Partner__c FROM tsanet_connect__TSANetCase__c WHERE tsanet_connect__tsaNetCaseId__c IN:tsaNetExternalCaseIds];
            
            Map<String, tsanet_connect__TSANetCase__c> externalIdToCase = new Map<String, tsanet_connect__TSANetCase__c>();
            for(tsanet_connect__TSANetCase__c tsaNetCase : tsaNetCases){
                externalIdToCase.put(tsaNetCase.tsanet_connect__tsaNetCaseId__c, tsaNetCase);
            }
            
            for(tsanet_connect__TSANetNote__c note : notes){
                if(externalIdToCase.containsKey(note.tsanet_connect__CaseId__c)){
                    tsanet_connect__TSANetCase__c tsaNetCase = externalIdToCase.get(note.tsanet_connect__CaseId__c);
                    note.tsanet_connect__TSANetCase__c = tsaNetCase.Id;
                }
            }  
        } catch(Exception e){
            ErrorLogger.logError(e, 'TSANET_NOTE_FIND_RELATIONSHIPS_ERROR');
        }
    }
    
    public static void createFeedItems(tsanet_connect__TSANetNote__c[] notes){
        Id[] tsaNetCaseIds = new Id[]{};
            
        for(tsanet_connect__TSANetNote__c note : notes){
            if(note.tsanet_connect__isCaseFeed__c == true && note.tsanet_connect__isApiNote__c == TRUE){
                tsaNetCaseIds.add(note.tsanet_connect__TSANetCase__c);
            }
        }
        if(tsaNetCaseIds.size() == 0){ return; }

        Map<Id, tsanet_connect__TSANetCase__c> tsaNetCases = new Map<Id, tsanet_connect__TSANetCase__c>([SELECT Id, Name, tsanet_connect__Case__c, tsanet_connect__Partner__c FROM tsanet_connect__TSANetCase__c WHERE Id IN:tsaNetCaseIds]);

        Id[] caseIds = new Id[]{};
        for(tsanet_connect__TSANetCase__c tsaNetCase : tsaNetCases.values()){
            if(tsaNetCase.tsanet_connect__Case__c != NULL){
                caseIds.add(tsaNetCase.tsanet_connect__Case__c);
            }
        }
        
        FeedItem[] items = [SELECT Id, Title, Body FROM FeedItem WHERE ParentId IN:caseIds AND Title LIKE '%TSANet Note - %'];

        Map<String, FeedItem> sortedItems = new Map<String, FeedItem>();
        for(FeedItem item : items){
            if(item.Title != NULL){
                String[] strs = item.Title.split(' - ');
                String token = strs[1];
                sortedItems.put(token, item);
            }
        }
        
        FeedItem[] feedItems = new FeedItem[]{};
        for(tsanet_connect__TSANetNote__c note : notes){
            if(!sortedItems.containsKey(note.tsanet_connect__Token__c)){
                String summary = note.tsanet_connect__FullSummary__c;
                String description = note.tsanet_connect__Description__c;
                String priority = note.tsanet_connect__Priority__c;
                String creatorName = note.tsanet_connect__CreatorName__c;
                String companyName = note.tsanet_connect__CompanyName__c;
                
                if(description != NULL && description.contains('<strong>')){
                    description = description.replaceAll('<strong>', '<b>');
                    description = description.replaceAll('</strong>', '</b>');
                }
                
                if(description != NULL && description.contains('<br>')){
                	description = description.replaceAll('<br>', '<p>&nbsp;</p>');
                }
                
                String refactoredSummary = TSANetHelper.stripAllHtml(summary);
                String refactoredDescription = TSANetHelper.stripAllHtml(description);
                
                tsanet_connect__TSANetCase__c tsaNetCase = tsaNetCases.get(note.tsanet_connect__TSANetCase__c);
                
                String message = 
                    '<p>Note Details:</p>' + 
                    '<p>Company Name: ' + companyName + '</p>' + 
                    '<p>Created By: ' + creatorName + '</p>' +
                    '<p>Summary: ' + refactoredSummary + '</p>' +
                    '<p>Description: ' + refactoredDescription + '</p>';
                
                
                
                if(tsaNetCase != NULL && tsaNetCase.tsanet_connect__Case__c != NULL){
                    FeedItem f = new FeedItem(
                        ParentId = tsaNetCase.tsanet_connect__Case__c,
                        CreatedById = credential.tsanet_connect__IntegrationUser__c,
                        IsRichText = true,
                        Title = 'TSANet Note - ' + note.tsanet_connect__Token__c,
                        Body = message
                    );
                    
                    feedItems.add(f);
                }
        
            }
        }
        
        System.debug('feedItems : ' + feedItems);
        
        Database.SaveResult[] results = Database.insert(feedItems, false);

        for (Integer i = 0; i < results.size(); i++) {
            if (!results[i].isSuccess()) {
                FeedItem failedItem = feedItems[i];
                for (Database.Error err : results[i].getErrors()) {
                    ErrorLogger.logError(err.getMessage(), 'TSANET_NOTE_FEED_ITEM_MAPPING_ERROR');
                }
            }
        }
    
    }
}