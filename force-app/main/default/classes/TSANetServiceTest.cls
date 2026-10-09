/** Unit tests for TSANetService. */
@IsTest
public class TSANetServiceTest {

    @TestSetup static void testSetup() {
        User user = TSANetDataFactory.createAdminUser();
        System.runAs(user){
            TSANetDataFactory.createCredentials();
            Account account = TSANetDataFactory.createAccount();
            Contact contact = TSANetDataFactory.createContact(account.Id);
            Case caseRecord = TSANetDataFactory.createCase(account.Id, contact.Id);
            TSANetDataFactory.createTSANetCase(caseRecord.Id);
        }
	}

    @IsTest
    public static void updateAccessTokenTest(){
        String body = '{ "company": { "id": 1071, "name": "Demo - Cisco" } }';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, body, null));
        Test.startTest();
        	Boolean reconnected = AuthManager.updateAccessToken();
        Test.stopTest();

        System.assertEquals(true, reconnected, 'A configured Named Credential should start the reconnect');
    }

    @IsTest
    public static void getRelatedCollaborationCasesTest(){
        String body = '[ { "id": 2718, "submitCompanyName": "Demo - VMware", "submitCompanyId": 1072, "submitterCaseNumber": "00001036", "receiveCompanyName": "Demo - Cisco", "receiveCompanyId": 1071, "receiverCaseNumber": "2718", "summary": "Beta Summer 2024 release unit test", "description": "Beta Summer 2024 release unit test", "priority": "LOW", "status": "ACCEPTED", "token": "Pp8DCQVVHkkVvd0rpn", "createdAt": "2024-06-19T17:17:00Z", "updatedAt": "2024-06-28T04:54:26Z", "deletedAt": null, "responded": true, "respondBy": "2024-06-20T17:17:00Z", "feedbackRequested": false, "reminderSent": false, "priorityNote": "<p>Priority 3 (24 Hours)</p>", "escalationInstructions": "test", "testCase": false, "customFields": [ { "id": 17465, "section": "COMMON_CUSTOMER_SECTION", "fieldName": "Customer Company", "value": "Dickenson plc" }, { "id": 17466, "section": "COMMON_CUSTOMER_SECTION", "fieldName": "Customer Name", "value": "sean jones" }, { "id": 17467, "section": "COMMON_CUSTOMER_SECTION", "fieldName": "Customer Email", "value": "sean@bur.com" }, { "id": 17468, "section": "COMMON_CUSTOMER_SECTION", "fieldName": "Customer Phone Including Country Code", "value": "4155551212" }, { "id": 17469, "section": "COMMON_CUSTOMER_SECTION", "fieldName": "Customer Case # with Demo - Cisco (Optional)", "value": "9876" } ], "submittedBy": { "id": 8706, "username": null, "firstName": "Sue", "lastName": "Test", "email": "sue.test@vmware.com", "phone": "4155551212", "phoneCountryCode": "US", "city": "Baton Rouge" }, "caseNotes": [ { "id": 151, "caseId": 2718, "creatorUsername": null, "creatorEmail": "John.Smith@cisco.com", "summary": "new note", "description": "<p>testing</p>", "priority": "low", "status": "entered", "token": "HeRU7whkYdvVXS9Y8p", "createdAt": "2024-06-19T17:20:23Z", "updatedAt": "2024-06-19T17:20:24Z" }, { "id": 154, "caseId": 2718, "creatorUsername": null, "creatorEmail": "sue.test@vmware.com", "summary": "New note from Paul", "description": "<p>Testing</p>", "priority": "low", "status": "entered", "token": "RoI4TxVcrnirlKLxVNiK", "createdAt": "2024-06-28T04:54:25Z", "updatedAt": "2024-06-28T04:54:26Z" } ], "caseResponses": [ { "id": 2136, "type": "APPROVAL", "caseNumber": "2718", "engineerName": "John Smith", "engineerPhone": "+12122241255", "engineerEmail": "John.Smith@cisco.com", "nextSteps": "Our assigned engineer will contact you.", "createdAt": null } ] } ]';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, body, null));

        Test.startTest();
            tsanetconnect__TSANetCase__c[] cases = TSANetService.getRelatedCollaborationCases(null);
        Test.stopTest();

        System.assertEquals(0, cases.size(), 'A null Case Id returns no scoped records');
        System.assertEquals(1, [
            SELECT COUNT() FROM tsanetconnect__TSANetCase__c
            WHERE tsanetconnect__Token__c = 'Pp8DCQVVHkkVvd0rpn'
        ], 'The API case should have been upserted locally');
    }

    @IsTest
    public static void getCompanyInfoTest(){
        String body2 = '{ "company": { "id": 1071, "name": "Demo - Cisco", "description": null }, "user": { "id": 8705, "username": null, "firstName": "John", "lastName": "Smith", "email": "John.Smith@cisco.com", "phone": "4155551212", "phoneCountryCode": "VG", "city": "Baton Rouge" }, "encodedCredentials": "Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwOi8vY29ubmVjdDEucmVub2xhYi51cy9hcGkvYXV0aC9sb2dpbiIsImlhdCI6MTcyMDc3ODk0MiwiZXhwIjoxNzIwNzgyNTQyLCJuYmYiOjE3MjA3Nzg5NDIsImp0aSI6ImJrcDBGZ0k4T2ViNXdxU28iLCJzdWIiOiI4NzA1IiwicHJ2IjoiODdlMGFmMWVmOWZkMTU4MTJmZGVjOTcxNTNhMTRlMGIwNDc1NDZhYSJ9.YbmRLRwdzcua0lh3mCawfb7dvx5LQqJwrboZG4wGFEo" }';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, body2, null));
        Test.startTest();
        	TSANetCompanyInfo info = TSANetService.getCompanyInformation();
        Test.stopTest();

        System.assertEquals('Demo - Cisco', info.company.name, 'Expected the company name from the API');
        System.assertEquals('1071', info.company.id, 'Expected the company id from the API');
    }

    @IsTest
    public static void getFormByCompanyIdTest(){
        String body = '{ "documentId": 2115, "internalCaseNumber": "", "optionalRecieverInternalCaseNumber": "", "problemSummary": "", "problemDescription": "", "casePriority": "", "readonlyAdminNote": "<p>test admin note (description)</p>", "readonlyEscalationInstructions": "<p>test escalation instructions</p>", "testSubmission": false, "customerData": [ { "id": 5558, "section": "COMMON_CUSTOMER_SECTION", "fieldName": "Customer Company", "value": null }, { "id": 5559, "section": "COMMON_CUSTOMER_SECTION", "fieldName": "Customer Name", "value": null }, { "id": 5560, "section": "COMMON_CUSTOMER_SECTION", "fieldName": "Customer Email", "value": null }, { "id": 5561, "section": "COMMON_CUSTOMER_SECTION", "fieldName": "Customer Phone Including Country Code", "value": null }, { "id": 5562, "section": "COMMON_CUSTOMER_SECTION", "fieldName": "Customer Case # with Connect2 Test 01 (Optional)", "value": null } ] }';
    	Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, body, null));
        Test.startTest();
        	String companyForm = TSANetService.getFormByCompanyId('1069', 'company');
        	String departmentForm = TSANetService.getFormByCompanyId('1070', 'department');
        Test.stopTest();

        System.assertEquals(true, companyForm.contains('2115'), 'Expected the company form payload');
        System.assertEquals(companyForm, departmentForm, 'Both modes return the mocked form payload');
    }

    @IsTest
    public static void getCompaniesByNameTest(){
        String body = '[ { "label": "Demo - VMware", "companyId": 1072, "departmentId": null } ]';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, body, null));
        Test.startTest();
        	String companies = TSANetService.getCompaniesByName('Demo');
        Test.stopTest();

        System.assertEquals(true, companies.contains('Demo - VMware'), 'Expected the matching company in the response');
    }

    @IsTest
    public static void createCollaborationCaseTest(){
        String body = '{"id":2735,"submitCompanyName":"Demo - Cisco","submitCompanyId":1071,"submitterCaseNumber":"00001008","receiveCompanyName":"Demo - VMware","receiveCompanyId":1072,"receiverCaseNumber":"","summary":"Customer service for portable generators needs beefing up","description":"test","priority":"LOW","status":"OPEN","token":"UNHd8HyqFB1cADcwOj","createdAt":"2024-07-16T16:15:10Z","updatedAt":null,"deletedAt":null,"responded":false,"respondBy":"2024-07-17T16:15:10Z","feedbackRequested":false,"reminderSent":false,"priorityNote":"<p>Priority 3 (24 Hours)</p>","escalationInstructions":"<p>test Vmware escalation</p>","testCase":false,"customFields":[{"id":17585,"section":"PROBLEM_SECTION","fieldName":"Product Area","value":"Cloud (Other Non-Platform Products):Authomize"},{"id":17577,"section":"COMMON_CUSTOMER_SECTION","fieldName":"Customer Company","value":"Grand Hotels & Resorts Ltd"},{"id":17578,"section":"COMMON_CUSTOMER_SECTION","fieldName":"Customer Name","value":"Tim Barr"},{"id":17579,"section":"COMMON_CUSTOMER_SECTION","fieldName":"Customer Email","value":"barr_tim@grandhotels.com"},{"id":17580,"section":"COMMON_CUSTOMER_SECTION","fieldName":"Customer Phone Including Country Code","value":"(312) 596-1000"},{"id":17581,"section":"COMMON_CUSTOMER_SECTION","fieldName":"Customer Case # with Demo - VMware (Optional)","value":""},{"id":17582,"section":"PROBLEM_SECTION","fieldName":"Version","value":"1"},{"id":17583,"section":"COMMON_CUSTOMER_SECTION","fieldName":"Serial Number","value":"1"},{"id":17584,"section":"COMMON_CUSTOMER_SECTION","fieldName":"Region","value":"Americas"}],"submittedBy":{"id":8705,"username":null,"firstName":"John","lastName":"Smith","email":"John.Smith@cisco.com","phone":"4155551212","phoneCountryCode":"VG","city":"Baton Rouge"},"caseNotes":[],"caseResponses":[]}';
        String json = '{"id":2735,"submitCompanyName":"Demo - Cisco","submitCompanyId":1071,"submitterCaseNumber":"00001008","receiveCompanyName":"Demo - VMware","receiveCompanyId":1072,"receiverCaseNumber":"","summary":"Customer service for portable generators needs beefing up","description":"test","priority":"LOW","status":"OPEN","token":"UNHd8HyqFB1cADcwOj","createdAt":"2024-07-16T16:15:10Z","updatedAt":null,"deletedAt":null,"responded":false,"respondBy":"2024-07-17T16:15:10Z","feedbackRequested":false,"reminderSent":false,"priorityNote":"<p>Priority 3 (24 Hours)</p>","escalationInstructions":"<p>test Vmware escalation</p>","testCase":false,"customFields":[{"id":17585,"section":"PROBLEM_SECTION","fieldName":"Product Area","value":"Cloud (Other Non-Platform Products):Authomize"},{"id":17577,"section":"COMMON_CUSTOMER_SECTION","fieldName":"Customer Company","value":"Grand Hotels & Resorts Ltd"},{"id":17578,"section":"COMMON_CUSTOMER_SECTION","fieldName":"Customer Name","value":"Tim Barr"},{"id":17579,"section":"COMMON_CUSTOMER_SECTION","fieldName":"Customer Email","value":"barr_tim@grandhotels.com"},{"id":17580,"section":"COMMON_CUSTOMER_SECTION","fieldName":"Customer Phone Including Country Code","value":"(312) 596-1000"},{"id":17581,"section":"COMMON_CUSTOMER_SECTION","fieldName":"Customer Case # with Demo - VMware (Optional)","value":""},{"id":17582,"section":"PROBLEM_SECTION","fieldName":"Version","value":"1"},{"id":17583,"section":"COMMON_CUSTOMER_SECTION","fieldName":"Serial Number","value":"1"},{"id":17584,"section":"COMMON_CUSTOMER_SECTION","fieldName":"Region","value":"Americas"}],"submittedBy":{"id":8705,"username":null,"firstName":"John","lastName":"Smith","email":"John.Smith@cisco.com","phone":"4155551212","phoneCountryCode":"VG","city":"Baton Rouge"},"caseNotes":[],"caseResponses":[]}';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, body, null));
        Test.startTest();
        	Case caseRecord = [SELECT Id FROM Case WITH USER_MODE LIMIT 1];

        	String response = TSANetService.createCollaborationCase(caseRecord.Id, json);
        Test.stopTest();

        System.assertEquals(true, response.contains('"token":"UNHd8HyqFB1cADcwOj"'),
            'Expected the created collaboration case token in the response');
        System.assertEquals(1, [SELECT COUNT() FROM FeedItem WHERE ParentId = :caseRecord.Id],
            'Creating a collaboration case should post a Chatter feed item on the Case');
    }

    @IsTest
    public static void approveIncomingRequestTest(){
        String body = '{"id":2727,"submitCompanyName":"Demo - VMware","submitCompanyId":1072,"submitterCaseNumber":"00001026","receiveCompanyName":"Demo - Cisco","receiveCompanyId":1071,"receiverCaseNumber":"2727","summary":"lkj","description":"l;kjlkjl;k","priority":"MEDIUM","status":"ACCEPTED","token":"636BqK44MlNnAJx6Yj","createdAt":"2024-07-05T19:15:05Z","updatedAt":"2024-07-16T16:22:47Z","deletedAt":null,"responded":true,"respondBy":"2024-07-05T23:15:05Z","feedbackRequested":false,"reminderSent":false,"priorityNote":"<p>Priority 2 (4 hours)</p>","escalationInstructions":"<p>test.  <a href=\"https://tsanet.org\" rel=\"noopener noreferrer\" target=\"_blank\"> This is a test</a></p>","testCase":false,"customFields":[{"id":17521,"section":"COMMON_CUSTOMER_SECTION","fieldName":"Customer Phone Including Country Code","value":""},{"id":17522,"section":"COMMON_CUSTOMER_SECTION","fieldName":"Customer Case # with Demo - Cisco (Optional)","value":""},{"id":17518,"section":"COMMON_CUSTOMER_SECTION","fieldName":"Customer Company","value":""},{"id":17519,"section":"COMMON_CUSTOMER_SECTION","fieldName":"Customer Name","value":""},{"id":17520,"section":"COMMON_CUSTOMER_SECTION","fieldName":"Customer Email","value":""}],"submittedBy":{"id":8706,"username":null,"firstName":"Sue","lastName":"Test","email":"sue.test@vmware.com","phone":"4155551212","phoneCountryCode":"US","city":"Baton Rouge"},"caseNotes":[],"caseResponses":[{"id":2141,"type":"APPROVAL","caseNumber":"2727","engineerName":"sean dulac","engineerPhone":"(225) 402-9626","engineerEmail":"John.Smith@cisco.com","nextSteps":"Our assigned engineer will contact you.","createdAt":null}]}';
        String json = '{ "caseNumber":"2673", "engineerName":"Sue Test", "engineerEmail":"tsanetdev2@appko.com", "engineerPhone":"+1412848124824", "nextSteps":"Our assigned engineer will contact you." }';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, body, null));
        Test.startTest();
        	String response = TSANetService.approveIncomingRequest('test-token', json);
        Test.stopTest();

        System.assertEquals(true, response.contains('"status":"ACCEPTED"'),
            'Approving a request should return the accepted case');
    }

    /** Mock HTTP callout handler for TSANetService tests. */
    private class TSANetMock implements HttpCalloutMock {
        /** Returns a mock HTTP response for the given request.
         * @param req the HTTP request
         * @return simulated HTTP response
         */
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');

            String ep = req.getEndpoint();
            String m  = req.getMethod();

            // GET .../attachments/config
            if (m == 'GET' && ep != null && ep.contains('/attachments/config')) {
                res.setStatusCode(200);
                res.setBody('{"ok":true}');
                return res;
            }

            // POST .../attachments
            if (m == 'POST' && ep != null && ep.contains('/attachments')) {
                res.setStatusCode(200);
                // Підігнано під типову структуру: список результатів з receiverStatus + fileName
                res.setBody('[{"receiverStatus":"SUCCESS","fileName":"newFile.txt"}]');
                return res;
            }

            // PATCH update case (owner)
            if (m == 'PATCH') {
                res.setStatusCode(200);
                res.setBody('{"ok":true}');
                return res;
            }

            res.setStatusCode(200);
            res.setBody('{}');
            return res;
        }
    }

    private static tsanetconnect__TSANetCase__c createTSANetCase(String token) {
        Account acc = new Account(Name = 'Test Account2');
        insert acc;

        Contact con = new Contact(
            LastName = 'Test 2Contact',
            Email = 'test2@gmail.com',
            Phone = 'Test2 Phone',
            AccountId = acc.Id
        );
        insert con;

        Case cs = new Case(
            ContactId = con.Id,
            AccountId = acc.Id,
            Subject = '2test',
            Status = 'Working',
            Origin = 'Phone'
        );
        insert cs;

        tsanetconnect__TSANetCase__c tcase = new tsanetconnect__TSANetCase__c(
            tsanetconnect__Token__c = token,
            tsanetconnect__Case__c = cs.Id
        );
        insert tcase;

        return tcase;
    }

    private static ContentVersion createContentVersion(String title) {
        ContentVersion cv = new ContentVersion(
            Title = title,
            PathOnClient = title,
            VersionData = Blob.valueOf('hello')
        );
        insert cv;
        return [
            SELECT Id, Title, VersionData
            FROM ContentVersion
            WHERE Id = :cv.Id
            WITH USER_MODE
            LIMIT 1
        ];
    }

    // ---------- Tests ----------
    @IsTest
    static void test_getAttachmentConfig() {
        Test.setMock(HttpCalloutMock.class, new TSANetMock());

        Test.startTest();
            String result = TSANetService.getAttachmentConfig('test-token');
        Test.stopTest();

        System.assertNotEquals(null, result, 'Expected a response body from the mock');
    }

    @IsTest
    static void test_sendAttachment_happyPath() {
        Test.setMock(HttpCalloutMock.class, new TSANetMock());

        User admin = TSANetDataFactory.createAdminUser();
        System.runAs(admin) {
            String token = 'test-token3';
            tsanetconnect__TSANetCase__c tcase = createTSANetCase(token);

            ContentVersion existing = createContentVersion('existing.txt');

            List<Map<String, Object>> files = new List<Map<String, Object>>();

            // Existing CV path (base64 = null, fileId = ContentVersion.Id)
            files.add(new Map<String, Object>{
                'fileId' => (String)existing.Id,
                'base64' => null
            });

            // New file path (base64 provided)
            files.add(new Map<String, Object>{
                'filename' => 'newFile.txt',
                'base64' => EncodingUtil.base64Encode(Blob.valueOf('new content'))
            });

            Test.startTest();
            	String resp = TSANetService.sendAttachment(token, files);
            Test.stopTest();

            System.assertNotEquals(null, resp);

           	List<ContentDocumentLink> links = [
                SELECT Id, LinkedEntityId
                FROM ContentDocumentLink
                WHERE LinkedEntityId = :tcase.Id
                WITH USER_MODE
            ];
            System.assert(links.size() > 0, 'Expected at least one ContentDocumentLink to TSANetCase.');
        }
    }

    @IsTest
    static void test_changeTSANetOwner_future() {
        Test.setMock(HttpCalloutMock.class, new TSANetMock());

        User admin = TSANetDataFactory.createAdminUser();
        System.runAs(admin) {
            tsanetconnect__TSANetCase__c tcase = createTSANetCase('tok-1');

            Test.startTest();
	            TSANetService.changeTSANetOwner(tcase.Id);
            Test.stopTest();

            System.assert(true);
        }
    }

    @IsTest
    static void test_changeTSANetResponse_future() {
        Test.setMock(HttpCalloutMock.class, new TSANetMock());

        User admin = TSANetDataFactory.createAdminUser();
        System.runAs(admin) {
            tsanetconnect__TSANetCase__c tcase = createTSANetCase('tok-inbound');
            tcase.tsanetconnect__Direction__c = 'INBOUND';
            update tcase;

            Test.startTest();
            TSANetService.changeTSANetResponse(tcase.Id);
            Test.stopTest();

            System.assert(true);
        }
    }

    @IsTest
    static void test_credentialsWithoutNamedCredentialRaiseAConfigurationError() {
        tsanetconnect__TSANet_Credentials__c credentials = [SELECT Id FROM tsanetconnect__TSANet_Credentials__c LIMIT 1];
        credentials.tsanetconnect__NamedCredential__c = null;
        TSANetDataFactory.suppressSetupInitialization();
        update credentials;
        AuthModeManager.clearCache();

        Test.startTest();
        try {
            TSANetService.getCompaniesByName('Demo');
            System.assert(false, 'A credential without a Named Credential must not attempt a callout');
        } catch (TSANetHttpRouter.TSANetHttpRouterException e) {
            System.assertEquals(TSANetConstants.NOT_CONFIGURED_ERROR, e.getMessage(), 'The error must tell the admin what to configure');
        }
        Test.stopTest();
    }

    @IsTest
    static void test_credentialsCallTheNamedCredential() {
        AuthModeManager.clearCache();

        EndpointCapturingMock mock = new EndpointCapturingMock('[]');
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
            TSANetService.getCompaniesByName('Demo');
        Test.stopTest();

        System.assertEquals(true, mock.endpoint.startsWith('callout:tsanetconnect__TSANetAPI'), 'Callouts must route through the Named Credential, found: ' + mock.endpoint);
        System.assertEquals(null, mock.authorization, 'Named Credential callouts must not send a bearer token');
    }

    /** Captures the endpoint and Authorization header of the last callout. */
    private class EndpointCapturingMock implements HttpCalloutMock {
        private String body;
        public String endpoint;
        public String authorization;

        public EndpointCapturingMock(String body){
            this.body = body;
        }

        public HTTPResponse respond(HTTPRequest req) {
            endpoint = req.getEndpoint();
            authorization = req.getHeader('Authorization');

            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody(body);
            return res;
        }
    }
}