/** Centralized SOQL for Case. */
public with sharing class CaseSelector {

    private static final Integer RECENT_LIMIT = 10;
    private static final Integer SEARCH_LIMIT = 25;
    private static final Integer MIN_SEARCH_LENGTH = 2;

    /**
     * Full detail including Owner, Account, and Contact relationship fields.
     * @param caseId the Case record Id
     * @return Case with all detail fields populated
     */
    public static Case getFullDetailById(Id caseId) {
        return [
            SELECT Id, Subject, CaseNumber, Description,
                   OwnerId, Owner.Name, Owner.FirstName, Owner.LastName, Owner.Phone, Owner.Email,
                   AccountId, Account.Name,
                   ContactId, Contact.Name, Contact.FirstName, Contact.LastName, Contact.Email, Contact.Phone
            FROM Case
            WHERE Id = :caseId
            WITH USER_MODE
        ];
    }

    /**
     * Minimal fields for collaboration-case lookup.
     * @param caseId the Case record Id
     * @return Case with Id and CaseNumber
     */
    public static Case getById(Id caseId) {
        return [
            SELECT Id, CaseNumber
            FROM Case
            WHERE Id = :caseId
            WITH USER_MODE
        ];
    }

    /**
     * Owner detail for PATCH sync back to TSANet.
     * @param caseId the Case record Id
     * @return Case with owner detail fields
     */
    public static Case getOwnerDetailById(Id caseId) {
        return [
            SELECT Id, CaseNumber, OwnerId, Owner.Name, Owner.Phone, Owner.Email
            FROM Case
            WHERE Id = :caseId
            WITH USER_MODE
        ];
    }

    /**
     * Bulk lookup by case numbers (trigger use).
     * @param caseNumbers set of case numbers to query
     * @return list of matching Case records
     */
    public static Case[] getByCaseNumbers(Set<String> caseNumbers) {
        return [
            SELECT Id, OwnerId, CaseNumber
            FROM Case
            WHERE CaseNumber IN :caseNumbers
            WITH USER_MODE
        ];
    }

    /**
     * Recently-viewed cases for picklist.
     * Driven off RecentlyViewed rather than ORDER BY LastViewedDate on Case, which has no
     * WHERE clause and therefore scans the whole table on large Case volumes.
     * @return up to RECENT_LIMIT recently viewed Case records, most recent first
     */
    public static Case[] getRecent() {
        Id[] recentIds = new Id[]{};
        for (RecentlyViewed viewed : [
            SELECT Id
            FROM RecentlyViewed
            WHERE Type = 'Case'
            WITH USER_MODE
            ORDER BY LastViewedDate DESC
            LIMIT :RECENT_LIMIT
        ]) {
            recentIds.add(viewed.Id);
        }

        if (recentIds.isEmpty()) { return new Case[]{}; }

        Map<Id, Case> casesById = new Map<Id, Case>([
            SELECT Id, CaseNumber, Subject
            FROM Case
            WHERE Id IN :recentIds
            WITH USER_MODE
        ]);

        // Re-apply the RecentlyViewed order, which the Id IN bind does not preserve.
        Case[] recent = new Case[]{};
        for (Id recentId : recentIds) {
            Case caseRecord = casesById.get(recentId);
            if (caseRecord != null) { recent.add(caseRecord); }
        }
        return recent;
    }

    /**
     * Case search by number or subject.
     * Uses SOSL so the search index does the work: the previous SOQL ORed an indexed
     * CaseNumber against an unindexed Subject with no LIMIT, which forced a full scan.
     * @param searchText case number or subject to match
     * @return up to SEARCH_LIMIT matching Case records
     */
    public static Case[] search(String searchText) {
        if (String.isBlank(searchText) || searchText.trim().length() < MIN_SEARCH_LENGTH) {
            return new Case[]{};
        }

        String term = escapeSosl(searchText.trim()) + '*';
        List<List<SObject>> results = [
            FIND :term
            IN ALL FIELDS
            RETURNING Case(Id, CaseNumber, Subject)
            WITH USER_MODE
            LIMIT :SEARCH_LIMIT
        ];

        return results.isEmpty() ? new Case[]{} : (Case[]) results[0];
    }

    /** Escapes the characters SOSL treats as operators so a search term stays a literal. */
    private static String escapeSosl(String term) {
        return term.replaceAll('([?&|!{}\\[\\]()^~*:\\\\"\'+\\-])', '\\\\$1');
    }
}
