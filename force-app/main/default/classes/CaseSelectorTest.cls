/** Unit tests for CaseSelector, covering the bounded recent-cases and SOSL search paths. */
@IsTest
public class CaseSelectorTest {

    @TestSetup
    static void testSetup() {
        User user = TSANetDataFactory.createAdminUser();
        System.runAs(user) {
            Account account = TSANetDataFactory.createAccount();
            Contact contact = TSANetDataFactory.createContact(account.Id);
            TSANetDataFactory.createCase(account.Id, contact.Id);
        }
    }

    @IsTest
    static void testGetRecentIsBounded() {
        Test.startTest();
            Case[] recent = CaseSelector.getRecent();
        Test.stopTest();

        System.assertNotEquals(null, recent, 'Recent cases should never be null');
        System.assertEquals(true, recent.size() <= 10, 'getRecent must never return more than 10 rows');
    }

    @IsTest
    static void testSearchReturnsTheIndexedMatch() {
        Case existing = [SELECT Id, CaseNumber FROM Case WITH USER_MODE LIMIT 1];
        Test.setFixedSearchResults(new Id[]{ existing.Id });

        Test.startTest();
            Case[] results = CaseSelector.search(existing.CaseNumber);
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Expected the fixed search result');
        System.assertEquals(existing.Id, results[0].Id, 'Expected the matching Case');
        System.assertEquals(existing.CaseNumber, results[0].CaseNumber, 'CaseNumber should be selected');
    }

    @IsTest
    static void testSearchRejectsTermsBelowTheMinimum() {
        Test.startTest();
            Case[] blank = CaseSelector.search('');
            Case[] nullTerm = CaseSelector.search(null);
            Case[] single = CaseSelector.search('a');
        Test.stopTest();

        System.assertEquals(0, blank.size(), 'A blank term must not hit the search index');
        System.assertEquals(0, nullTerm.size(), 'A null term must not hit the search index');
        System.assertEquals(0, single.size(), 'A single character is below the search minimum');
    }

    @IsTest
    static void testSearchEscapesSoslOperators() {
        Case existing = [SELECT Id FROM Case WITH USER_MODE LIMIT 1];
        Test.setFixedSearchResults(new Id[]{ existing.Id });

        Test.startTest();
            // Unescaped, these characters would make the FIND clause invalid.
            Case[] results = CaseSelector.search('a?b&c|d!e{f}');
        Test.stopTest();

        System.assertEquals(1, results.size(), 'SOSL operators in the term must be escaped, not executed');
    }
}
