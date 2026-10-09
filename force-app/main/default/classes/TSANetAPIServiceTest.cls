/** Unit tests for TSANetAPIService — asserts every call goes to callout: without a bearer token. */
@IsTest
public class TSANetAPIServiceTest {

    /** Captures the last request so tests can assert the endpoint and headers. */
    private class CapturingMock implements HttpCalloutMock {
        private String body;
        public HttpRequest lastRequest;
        /** The action's own callout, before any follow-up refresh callout overwrites lastRequest. */
        public HttpRequest firstRequest;

        public CapturingMock(String body){
            this.body = body;
        }

        public HttpResponse respond(HttpRequest req){
            lastRequest = req;
            if(firstRequest == null){ firstRequest = req; }

            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody(body);
            return res;
        }
    }

    @TestSetup
    static void testSetup() {
        User admin = TSANetDataFactory.createAdminUser();
        System.runAs(admin) {
            TSANetDataFactory.createOAuthCredentials();
        }
    }

    @IsTest
    static void testGetCompanyInformationUsesNamedCredential() {
        CapturingMock mock = new CapturingMock('{"company":{"id":"1","name":"Test Company"}}');
        Test.setMock(HttpCalloutMock.class, mock);
        AuthModeManager.clearCache();

        Test.startTest();
            TSANetCompanyInfo info = TSANetAPIService.getCompanyInformation();
        Test.stopTest();

        System.assertNotEquals(null, info, 'Expected company information from the mock');
        assertNamedCredentialRequest(mock.lastRequest);
    }

    @IsTest
    static void testGetCompaniesByNameEncodesTheSearchTerm() {
        CapturingMock mock = new CapturingMock('[]');
        Test.setMock(HttpCalloutMock.class, mock);
        AuthModeManager.clearCache();

        Test.startTest();
            TSANetAPIService.getCompaniesByName('Test Company');
        Test.stopTest();

        assertNamedCredentialRequest(mock.lastRequest);
        System.assert(mock.lastRequest.getEndpoint().contains('Test%20Company'), 'Spaces must be percent-encoded, found: ' + mock.lastRequest.getEndpoint());
    }

    @IsTest
    static void testGetFormByCompanyIdUsesNamedCredential() {
        CapturingMock mock = new CapturingMock('{}');
        Test.setMock(HttpCalloutMock.class, mock);
        AuthModeManager.clearCache();

        Test.startTest();
            String form = TSANetAPIService.getFormByCompanyId('1', 'company');
        Test.stopTest();

        System.assertEquals('{}', form, 'Expected the mocked form payload to be returned verbatim');
        assertNamedCredentialRequest(mock.lastRequest);
    }

    @IsTest
    static void testGetAttachmentConfigUsesNamedCredential() {
        CapturingMock mock = new CapturingMock('{"maxFileSize":100}');
        Test.setMock(HttpCalloutMock.class, mock);
        AuthModeManager.clearCache();

        Test.startTest();
            TSANetAPIService.getAttachmentConfig('case-token');
        Test.stopTest();

        assertNamedCredentialRequest(mock.lastRequest);
        System.assert(mock.lastRequest.getEndpoint().endsWith('/case-token/attachments/config'), 'Expected the attachment config path, found: ' + mock.lastRequest.getEndpoint());
    }

    @IsTest
    static void testGetCollaborationCasesPageIsPaginated() {
        CapturingMock mock = new CapturingMock('{"content":[],"totalPages":1}');
        Test.setMock(HttpCalloutMock.class, mock);
        AuthModeManager.clearCache();

        Test.startTest();
            TSANetAPIService.getCollaborationCasesPage('00001000', 0);
        Test.stopTest();

        assertNamedCredentialRequest(mock.lastRequest);
        System.assert(mock.lastRequest.getEndpoint().contains('/v2/collaboration-requests?'), 'Paged reads must use the V2 endpoint, found: ' + mock.lastRequest.getEndpoint());
        System.assert(mock.lastRequest.getEndpoint().contains('internalCaseNumber=00001000'), 'Expected the case number filter, found: ' + mock.lastRequest.getEndpoint());
        System.assert(mock.lastRequest.getEndpoint().contains('page=0&size='), 'Expected pagination parameters, found: ' + mock.lastRequest.getEndpoint());
        System.assert(!mock.lastRequest.getEndpoint().contains('paginated='), 'V2 paginates by default, the paginated flag must be gone: ' + mock.lastRequest.getEndpoint());
    }

    @IsTest
    static void testGetRelatedCollaborationCasesUsesV2ListEndpoint() {
        CapturingMock mock = new CapturingMock('[]');
        Test.setMock(HttpCalloutMock.class, mock);
        AuthModeManager.clearCache();

        Test.startTest();
            TSANetAPIService.getRelatedCollaborationCases(null);
        Test.stopTest();

        assertNamedCredentialRequest(mock.firstRequest);
        System.assert(mock.firstRequest.getEndpoint().endsWith('/v2/collaboration-requests/list'), 'List reads must use the V2 list endpoint, found: ' + mock.firstRequest.getEndpoint());
    }

    @IsTest
    static void testCreateCollaborationCaseUsesNamedCredential() {
        Account account = TSANetDataFactory.createAccount();
        Contact contact = TSANetDataFactory.createContact(account.Id);
        Case supportCase = TSANetDataFactory.createCase(account.Id, contact.Id);

        CapturingMock mock = new CapturingMock('{"token":"tok1"}');
        Test.setMock(HttpCalloutMock.class, mock);
        AuthModeManager.clearCache();

        Test.startTest();
            String response = TSANetAPIService.createCollaborationCase(supportCase.Id, '{}');
        Test.stopTest();

        System.assertNotEquals(null, response, 'Expected the raw API response');
        assertNamedCredentialRequest(mock.firstRequest);
        System.assertEquals('POST', mock.firstRequest.getMethod(), 'Creating a case must POST');
    }

    @IsTest
    static void testCloseTSANetCaseUsesNamedCredential() {
        Account account = TSANetDataFactory.createAccount();
        Contact contact = TSANetDataFactory.createContact(account.Id);
        Case supportCase = TSANetDataFactory.createCase(account.Id, contact.Id);
        tsanetconnect__TSANetCase__c tsaNetCase = TSANetDataFactory.createTSANetCase(supportCase.Id);

        CapturingMock mock = new CapturingMock('{}');
        Test.setMock(HttpCalloutMock.class, mock);
        AuthModeManager.clearCache();

        Test.startTest();
            TSANetAPIService.closeTSANetCase(tsaNetCase.Id);
        Test.stopTest();

        assertNamedCredentialRequest(mock.firstRequest);
        System.assert(mock.firstRequest.getEndpoint().contains('test-token'), 'The case token must be substituted into the path, found: ' + mock.firstRequest.getEndpoint());
    }

    /** Asserts the request went to the Named Credential and carried no bearer token. */
    private static void assertNamedCredentialRequest(HttpRequest req){
        System.assertNotEquals(null, req, 'Expected a callout to be made');
        System.assert(req.getEndpoint().startsWith('callout:tsanetconnect__TSANetAPI'), 'Endpoint must use the Named Credential, found: ' + req.getEndpoint());
        System.assertEquals(null, req.getHeader('Authorization'), 'Named Credential callouts must not set an Authorization header');
    }
}
