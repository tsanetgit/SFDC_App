/** Helper methods for TSANetNote__c trigger logic. */
public with sharing class TSANetNoteTriggerHelper {

    private static Boolean feedItemsInProgress = false;

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
     * Runs as the end user or External Client App Run As user.
     * @param notes list of notes to create feed items for
     */
    public static void createFeedItems(tsanetconnect__TSANetNote__c[] notes){
        try {
            List<tsanetconnect__TSANetNote__c> eligibleNotes = filterEligibleNotes(notes);
            if(eligibleNotes.isEmpty()){ return; }

            if(feedItemsInProgress){ return; }
            feedItemsInProgress = true;
            insertFeedItemsForNotes(eligibleNotes);
        } catch(Exception e){
            ErrorLogger.logError(e, 'TSANET_NOTE_FEED_ITEM_ERROR');
        }
    }

    /**
     * Marks notes created before today as already notified so the note-notification flow
     * (entry condition isNotified__c = false) never fires for historical notes pulled in by
     * a full sync, e.g. right after new TSANet Credentials are connected. In-memory only.
     * @param notes notes in a before-insert or before-update context
     */
    public static void markStaleNotesAsNotified(tsanetconnect__TSANetNote__c[] notes){
        for(tsanetconnect__TSANetNote__c note : notes){
            if(note.tsanetconnect__isNotified__c != true && !isCreatedToday(note)){
                note.tsanetconnect__isNotified__c = true;
            }
        }
    }

    /** Returns notes that should produce a FeedItem (case-feed flag, linked, not yet posted, created today). */
    private static List<tsanetconnect__TSANetNote__c> filterEligibleNotes(tsanetconnect__TSANetNote__c[] notes){
        List<tsanetconnect__TSANetNote__c> eligibleNotes = new List<tsanetconnect__TSANetNote__c>();
        for(tsanetconnect__TSANetNote__c note : notes){
            if(note.tsanetconnect__isCaseFeed__c != true || note.tsanetconnect__TSANetCase__c == null){ continue; }
            if(String.isNotBlank(note.tsanetconnect__FeedItemId__c)){ continue; }
            if(!isCreatedToday(note)){ continue; }
            eligibleNotes.add(note);
        }
        return eligibleNotes;
    }

    /** True when the note's TSANet CreatedAt__c falls on or after today's midnight GMT. */
    private static Boolean isCreatedToday(tsanetconnect__TSANetNote__c note){
        return note.tsanetconnect__CreatedAt__c != null
            && note.tsanetconnect__CreatedAt__c >= todayStartGmt();
    }

    /** Midnight GMT of the current day; the cutoff for "new" notes. */
    private static DateTime todayStartGmt(){
        return DateTime.newInstanceGmt(Date.today(), Time.newInstance(0, 0, 0, 0));
    }

    /** Builds and inserts FeedItems for the given notes, then back-stamps FeedItemId__c on the notes. */
    private static void insertFeedItemsForNotes(List<tsanetconnect__TSANetNote__c> eligibleNotes){
        Set<Id> tsaNetCaseIds = new Set<Id>();
        for(tsanetconnect__TSANetNote__c note : eligibleNotes){
            tsaNetCaseIds.add(note.tsanetconnect__TSANetCase__c);
        }

        Map<Id, tsanetconnect__TSANetCase__c> tsaNetCases = new Map<Id, tsanetconnect__TSANetCase__c>(
            TSANetCaseSelector.getByIds(tsaNetCaseIds)
        );

        List<tsanetconnect__TSANetNote__c> feedNotes = new List<tsanetconnect__TSANetNote__c>();
        List<FeedItem> feedItems = buildFeedItems(eligibleNotes, tsaNetCases, feedNotes);
        if(feedItems.isEmpty()){ return; }

        feedItems = filterByAccessibleParentCases(feedItems, feedNotes);
        if(feedItems.isEmpty()){ return; }

        FeedItem[] toInsert = stripInaccessibleFeedItems(feedItems);
        if(toInsert.isEmpty()){ return; }

        Database.SaveResult[] results;
        if (canCreateCaseFeedItem()) {
            results = Database.insert(toInsert, false, AccessLevel.USER_MODE);
        } else {
            return;
        }
        List<tsanetconnect__TSANetNote__c> notesToUpdate = new List<tsanetconnect__TSANetNote__c>();
        List<FeedItem> retryItems = new List<FeedItem>();
        List<tsanetconnect__TSANetNote__c> retryNotes = new List<tsanetconnect__TSANetNote__c>();

        for(Integer i = 0; i < results.size(); i++){
            if(results[i].isSuccess()){
                notesToUpdate.add(new tsanetconnect__TSANetNote__c(
                    Id = feedNotes[i].Id,
                    tsanetconnect__FeedItemId__c = results[i].getId()
                ));
            } else if(feedItems[i].CreatedById != null){
                retryItems.add(copyFeedItemWithoutAuthor(feedItems[i]));
                retryNotes.add(feedNotes[i]);
            } else {
                for(Database.Error err : results[i].getErrors()){
                    ErrorLogger.logError(err.getMessage(), 'TSANET_NOTE_FEED_ITEM_MAPPING_ERROR');
                }
            }
        }

        if(!retryItems.isEmpty()){
            FeedItem[] retryToInsert = stripInaccessibleFeedItems(retryItems);
            if(!retryToInsert.isEmpty() && canCreateCaseFeedItem()){
                Database.SaveResult[] retryResults = Database.insert(retryToInsert, false, AccessLevel.USER_MODE);
                for(Integer i = 0; i < retryResults.size(); i++){
                    if(retryResults[i].isSuccess()){
                        notesToUpdate.add(new tsanetconnect__TSANetNote__c(
                            Id = retryNotes[i].Id,
                            tsanetconnect__FeedItemId__c = retryResults[i].getId()
                        ));
                    } else {
                        for(Database.Error err : retryResults[i].getErrors()){
                            ErrorLogger.logError(err.getMessage(), 'TSANET_NOTE_FEED_ITEM_MAPPING_ERROR');
                        }
                    }
                }
            }
        }

        if(!notesToUpdate.isEmpty()){
            Database.update(notesToUpdate, false, AccessLevel.USER_MODE);
        }
    }

    /**
     * Builds FeedItem records for notes that have a parent TSANetCase with a linked Case.
     * Populates feedNotes in lock-step with the returned list so callers can correlate
     * SaveResult indexes back to the originating notes.
     */
    private static List<FeedItem> buildFeedItems(List<tsanetconnect__TSANetNote__c> notes,
                                                 Map<Id, tsanetconnect__TSANetCase__c> tsaNetCases,
                                                 List<tsanetconnect__TSANetNote__c> feedNotes){
        Id backgroundAuthorId = backgroundFeedAuthorId();
        List<FeedItem> feedItems = new List<FeedItem>();
        for(tsanetconnect__TSANetNote__c note : notes){
            tsanetconnect__TSANetCase__c tsaNetCase = tsaNetCases.get(note.tsanetconnect__TSANetCase__c);
            if(tsaNetCase == null || tsaNetCase.tsanetconnect__Case__c == null){ continue; }

            String description = note.tsanetconnect__Description__c;
            if(description != null){
                description = sanitizeForChatter(description);
            }
            String plainSummary = TSANetHelper.stripAllHtml(note.tsanetconnect__Summary__c);

            String message = '<p><b>Note Details:</b></p>';

            if(String.isNotBlank((String) tsaNetCase.get('tsanetconnect__Partner__c'))){
                message += '<p>Member: ' + tsaNetCase.tsanetconnect__Partner__c + '</p>';
            }
            message += '<p>Created By: ' + note.tsanetconnect__CreatorName__c + '</p>' +
                '<p>Summary: ' + plainSummary + '</p>';
            if(String.isNotBlank(description)){
                message += '<p><b>Description:</b></p>' + description;
            }

            FeedItem feedItem = new FeedItem(
                ParentId = tsaNetCase.tsanetconnect__Case__c,
                IsRichText = true,
                Title = 'TSANet Note - ' + note.tsanetconnect__Token__c,
                Body = message
            );
            applyFeedItemVisibility(feedItem);
            if(backgroundAuthorId != null){
                feedItem.CreatedById = backgroundAuthorId;
            }
            feedItems.add(feedItem);
            feedNotes.add(note);
        }
        return feedItems;
    }

    /** True for queueable, scheduled, batch, or future contexts. */
    @TestVisible
    private static Boolean isBackgroundContext(){
        return System.isQueueable()
            || System.isScheduled()
            || System.isBatch()
            || System.isFuture();
    }

    /** Integration User from primary credentials when FeedItems are created in the background. */
    private static Id backgroundFeedAuthorId(){
        if(!isBackgroundContext()){
            return null;
        }
        try {
            return CredentialManager.getCredentials().tsanetconnect__IntegrationUser__c;
        } catch(Exception e){
            return null;
        }
    }

    /** Child FeedItem + Case parent CRUD/FLS Checkmarx needs next to FeedItem DML. */
    private static Boolean canCreateCaseFeedItem(){
        return Schema.sObjectType.FeedItem.isCreateable()
            && Schema.sObjectType.FeedItem.fields.ParentId.isCreateable()
            && Schema.sObjectType.FeedItem.fields.Title.isCreateable()
            && Schema.sObjectType.FeedItem.fields.Body.isCreateable()
            && Schema.sObjectType.FeedItem.fields.IsRichText.isCreateable()
            && Schema.sObjectType.Case.isAccessible()
            && Schema.sObjectType.Case.isCreateable();
    }

    /** Drops FeedItems whose Case parent the running user cannot query. */
    private static List<FeedItem> filterByAccessibleParentCases(
        List<FeedItem> feedItems,
        List<tsanetconnect__TSANetNote__c> feedNotes
    ){
        Set<Id> parentIds = new Set<Id>();
        for(FeedItem fi : feedItems){
            parentIds.add(fi.ParentId);
        }
        Set<Id> accessibleParentIds = new Set<Id>();
        if(Schema.sObjectType.Case.isAccessible()){
            for(Case c : [SELECT Id FROM Case WHERE Id IN :parentIds WITH USER_MODE]){
                accessibleParentIds.add(c.Id);
            }
        }
        List<FeedItem> allowedItems = new List<FeedItem>();
        List<tsanetconnect__TSANetNote__c> allowedNotes = new List<tsanetconnect__TSANetNote__c>();
        for(Integer i = 0; i < feedItems.size(); i++){
            if(accessibleParentIds.contains(feedItems[i].ParentId)){
                allowedItems.add(feedItems[i]);
                allowedNotes.add(feedNotes[i]);
            }
        }
        feedNotes.clear();
        feedNotes.addAll(allowedNotes);
        return allowedItems;
    }

    /** Strips inaccessible fields then returns a typed FeedItem list for DML. */
    private static FeedItem[] stripInaccessibleFeedItems(List<FeedItem> feedItems){
        SObjectAccessDecision decision = Security.stripInaccessible(AccessType.CREATABLE, feedItems);
        FeedItem[] typed = new FeedItem[]{};
        for(SObject rec : decision.getRecords()){
            typed.add((FeedItem) rec);
        }
        return typed;
    }

    /** Rebuilds a FeedItem without CreatedById so insert can fall back to the running user. */
    private static FeedItem copyFeedItemWithoutAuthor(FeedItem source){
        FeedItem copy = new FeedItem(
            ParentId = source.ParentId,
            IsRichText = source.IsRichText,
            Title = source.Title,
            Body = source.Body
        );
        applyFeedItemVisibility(copy);
        return copy;
    }

    /**
     * Sets Chatter Visibility when Communities exposes the field.
     * Typed FeedItem.Visibility does not compile in packaging orgs without Communities.
     */
    private static void applyFeedItemVisibility(FeedItem feedItem){
        if(!Schema.SObjectType.FeedItem.fields.getMap().containsKey('Visibility')){
            return;
        }
        String visibility = UserInfo.getUserType() == 'Standard' ? 'InternalUsers' : 'AllUsers';
        feedItem.put('Visibility', visibility);
    }

    /** Converts HTML from TSANet into the limited tag set Chatter FeedItem supports. */
    @TestVisible
    private static String sanitizeForChatter(String html){
        html = html.replaceAll('<strong>', '<b>');
        html = html.replaceAll('</strong>', '</b>');
        html = html.replaceAll('<em>', '<i>');
        html = html.replaceAll('</em>', '</i>');
        html = html.replaceAll('<div>', '<p>');
        html = html.replaceAll('</div>', '</p>');
        html = html.replaceAll('<br\\s*/?>', '<p>&nbsp;</p>');
        html = html.replaceAll('</?span[^>]*>', '');
        html = html.replaceAll('<style[^>]*>[\\s\\S]*?</style>', '');
        html = html.replaceAll('<a[^>]+href="(?!https?://).*?"[^>]*>(.*?)</a>', '$1');
        html = html.replaceAll('</?(?!p|b|i|u|a|ul|ol|li|br|img|s)\\w[^>]*>', '');
        html = html.replaceAll('(?i)\\s+(?!href|src)\\w[\\w-]*\\s*=\\s*"[^"]*"', '');
        html = html.replaceAll('(?i)\\s+(?!href|src)\\w[\\w-]*\\s*=\\s*\'[^\']*\'', '');
        return html;
    }
}
