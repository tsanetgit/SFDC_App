/** Helper methods for TSANetNote__c trigger logic. */
@SuppressWarnings('PMD.ApexSharingViolations')
public without sharing class TSANetNoteTriggerHelper {

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
     * Guest-user contexts (e.g. inbound webhooks running as the Site Guest User) cannot
     * insert FeedItem at the entity level, so we publish a Platform Event and let the
     * subscriber trigger create the FeedItem in a non-Guest context.
     * @param notes list of notes to create feed items for
     */
    public static void createFeedItems(tsanetconnect__TSANetNote__c[] notes){
        try {
            List<tsanetconnect__TSANetNote__c> eligibleNotes = filterEligibleNotes(notes);
            if(eligibleNotes.isEmpty()){ return; }

            if(isGuestUser()){
                publishFeedItemRequests(eligibleNotes);
                return;
            }

            // Recursion guard only for the path that actually inserts FeedItems and updates
            // notes (which would re-fire this trigger). The publish path issues no DML
            // against TSANetNote__c, so it doesn't need the guard.
            if(feedItemsInProgress){ return; }
            feedItemsInProgress = true;
            insertFeedItemsForNotes(eligibleNotes);
        } catch(Exception e){
            ErrorLogger.logError(e, 'TSANET_NOTE_FEED_ITEM_ERROR');
        }
    }

    /** Returns notes that should produce a FeedItem (case-feed flag, linked, not yet posted, created today). */
    private static List<tsanetconnect__TSANetNote__c> filterEligibleNotes(tsanetconnect__TSANetNote__c[] notes){
        DateTime todayStart = DateTime.newInstanceGmt(Date.today(), Time.newInstance(0, 0, 0, 0));
        List<tsanetconnect__TSANetNote__c> eligibleNotes = new List<tsanetconnect__TSANetNote__c>();
        for(tsanetconnect__TSANetNote__c note : notes){
            if(note.tsanetconnect__isCaseFeed__c != true || note.tsanetconnect__TSANetCase__c == null){ continue; }
            if(String.isNotBlank(note.tsanetconnect__FeedItemId__c)){ continue; }
            if(note.tsanetconnect__CreatedAt__c == null || note.tsanetconnect__CreatedAt__c < todayStart){ continue; }
            eligibleNotes.add(note);
        }
        return eligibleNotes;
    }

    /** Publishes one Platform Event per eligible note so the subscriber can insert FeedItems off-Guest. */
    private static void publishFeedItemRequests(List<tsanetconnect__TSANetNote__c> eligibleNotes){
        List<tsanetconnect__TSANetNoteFeedItemRequested__e> events =
            new List<tsanetconnect__TSANetNoteFeedItemRequested__e>();
        for(tsanetconnect__TSANetNote__c note : eligibleNotes){
            events.add(new tsanetconnect__TSANetNoteFeedItemRequested__e(
                tsanetconnect__NoteId__c = note.Id
            ));
        }
        if(events.isEmpty()){ return; }

        Database.SaveResult[] results = EventBus.publish(events);
        for(Database.SaveResult result : results){
            if(result.isSuccess()){ continue; }
            for(Database.Error err : result.getErrors()){
                ErrorLogger.logError(err.getMessage(), 'TSANET_NOTE_FEED_ITEM_PE_PUBLISH_ERROR');
            }
        }
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

        if (!Schema.sObjectType.FeedItem.isCreateable()) { return; }

        // SYSTEM_MODE: this is system-level Chatter mirroring done by a trigger; the initiating
        // user does not need — and may not have — direct CRUD on FeedItem.
        Database.SaveResult[] results = Database.insert(feedItems, false, AccessLevel.SYSTEM_MODE);
        List<tsanetconnect__TSANetNote__c> notesToUpdate = new List<tsanetconnect__TSANetNote__c>();

        for(Integer i = 0; i < results.size(); i++){
            if(results[i].isSuccess()){
                notesToUpdate.add(new tsanetconnect__TSANetNote__c(
                    Id = feedNotes[i].Id,
                    tsanetconnect__FeedItemId__c = results[i].getId()
                ));
            } else {
                for(Database.Error err : results[i].getErrors()){
                    ErrorLogger.logError(err.getMessage(), 'TSANET_NOTE_FEED_ITEM_MAPPING_ERROR');
                }
            }
        }

        if(!notesToUpdate.isEmpty()){
            Database.update(notesToUpdate, false, AccessLevel.SYSTEM_MODE);
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
        List<FeedItem> feedItems = new List<FeedItem>();
        for(tsanetconnect__TSANetNote__c note : notes){
            tsanetconnect__TSANetCase__c tsaNetCase = tsaNetCases.get(note.tsanetconnect__TSANetCase__c);
            if(tsaNetCase == null || tsaNetCase.tsanetconnect__Case__c == null){ continue; }

            String description = note.tsanetconnect__Description__c;
            if(description != null){
                description = sanitizeForChatter(description);
            }
            String plainSummary = TSANetHelper.stripAllHtml(note.tsanetconnect__Summary__c);
            String companyName = note.tsanetconnect__CompanyName__c;

            String message = '<p><b>Note Details:</b></p>';

            if(String.isNotBlank(companyName)){
                message += '<p>Company Name: ' + companyName + '</p>';
            }
            if(String.isNotBlank((String) tsaNetCase.get('tsanetconnect__Partner__c'))){
                message += '<p>Member: ' + tsaNetCase.tsanetconnect__Partner__c + '</p>';
            }
            message += '<p>Created By: ' + note.tsanetconnect__CreatorName__c + '</p>' +
                '<p>Summary: ' + plainSummary + '</p>';
            if(String.isNotBlank(description)){
                message += '<p><b>Description:</b></p>' + description;
            }

            feedItems.add(new FeedItem(
                ParentId = tsaNetCase.tsanetconnect__Case__c,
                IsRichText = true,
                Title = 'TSANet Note - ' + note.tsanetconnect__Token__c,
                Body = message
            ));
            feedNotes.add(note);
        }
        return feedItems;
    }

    @TestVisible
    private static Boolean treatAsGuestForTest = false;

    /** True when the running user is a Site Guest User (no Chatter / FeedItem insert rights). */
    @TestVisible
    private static Boolean isGuestUser(){
        return treatAsGuestForTest || UserInfo.getUserType() == 'Guest';
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