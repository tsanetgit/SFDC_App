@isTest
public class TSANetInvocableCreateCollaborationTest {
    
	@testSetup static void testSetup() {

        User user = TSANetDataFactory.createAdminUser();
        System.runAs(user){
            TSANetDataFactory.createCredentials();
            Account account = TSANetDataFactory.createAccount();
            Contact contact = TSANetDataFactory.createContact(account.Id);
            Case caseRecord = TSANetDataFactory.createCase(account.Id, contact.Id);
            TSANetDataFactory.createTSANetCase(caseRecord.Id);
        }
	}

    @isTest
    public static void createCollaborationCaseTest(){
        String body = '{"id":2735,"submitCompanyName":"Demo - Cisco","submitCompanyId":1071,"submitterCaseNumber":"00001008","receiveCompanyName":"Demo - VMware","receiveCompanyId":1072,"receiverCaseNumber":"","summary":"Customer service for portable generators needs beefing up","description":"test","priority":"LOW","status":"OPEN","token":"UNHd8HyqFB1cADcwOj","createdAt":"2024-07-16T16:15:10Z","updatedAt":null,"deletedAt":null,"responded":false,"respondBy":"2024-07-17T16:15:10Z","feedbackRequested":false,"reminderSent":false,"priorityNote":"<p>Priority 3 (24 Hours)</p>","escalationInstructions":"<p>test Vmware escalation</p>","testCase":false,"customFields":[{"id":17585,"section":"PROBLEM_SECTION","fieldName":"Product Area","value":"Cloud (Other Non-Platform Products):Authomize"},{"id":17577,"section":"COMMON_CUSTOMER_SECTION","fieldName":"Customer Company","value":"Grand Hotels & Resorts Ltd"},{"id":17578,"section":"COMMON_CUSTOMER_SECTION","fieldName":"Customer Name","value":"Tim Barr"},{"id":17579,"section":"COMMON_CUSTOMER_SECTION","fieldName":"Customer Email","value":"barr_tim@grandhotels.com"},{"id":17580,"section":"COMMON_CUSTOMER_SECTION","fieldName":"Customer Phone Including Country Code","value":"(312) 596-1000"},{"id":17581,"section":"COMMON_CUSTOMER_SECTION","fieldName":"Customer Case # with Demo - VMware (Optional)","value":""},{"id":17582,"section":"PROBLEM_SECTION","fieldName":"Version","value":"1"},{"id":17583,"section":"COMMON_CUSTOMER_SECTION","fieldName":"Serial Number","value":"1"},{"id":17584,"section":"COMMON_CUSTOMER_SECTION","fieldName":"Region","value":"Americas"}],"submittedBy":{"id":8705,"username":null,"firstName":"John","lastName":"Smith","email":"John.Smith@cisco.com","phone":"4155551212","phoneCountryCode":"VG","city":"Baton Rouge"},"caseNotes":[],"caseResponses":[]}';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, body, null));
        Test.startTest();
            Case caseRecord = [SELECT Id FROM Case LIMIT 1];
            TSANetInvocableCreateCollaborationCase.TSANetInput input = new TSANetInvocableCreateCollaborationCase.TSANetInput();
            TSANetCompanyForm form = new TSANetCompanyForm();
            input.caseRecord = caseRecord;
            input.form = form;
            
            TSANetInvocableCreateCollaborationCase.TSANetCollaborationCaseResult[] data = TSANetInvocableCreateCollaborationCase.createCollaborationCase(new TSANetInvocableCreateCollaborationCase.TSANetInput[]{ input });
            System.assertEquals(true, data[0].caseRecord != NULL);
        Test.stopTest();
    }
}