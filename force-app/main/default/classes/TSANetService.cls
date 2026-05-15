/** Service layer for TSANet Connect API operations. */
public with sharing class TSANetService {

    /** Custom exception for TSANetService errors. */
    public class TSANetServiceException extends Exception {}

    /**
     * Retrieves the current company information from the TSANet API.
     * @param token access token for authentication
     * @return deserialised TSANetCompanyInfo
     */
    public static TSANetCompanyInfo getCompanyInformation(String token){
        String endpoint = EndpointManager.getTSANetCompanyPath();
        HttpResponse res = HttpClient.sendGet(endpoint, token);
        return (TSANetCompanyInfo) System.JSON.deserialize(res.getBody(), TSANetCompanyInfo.class);
    }

    /**
     * Creates a note on a TSANet collaboration case via the API.
     * @param caseToken unique token of the TSANet case
     * @param json serialised note payload
     * @param token access token for authentication
     * @return raw API response body
     */
    @AuraEnabled
    public static String createTSANetNote(String caseToken, String json, String token){
        tsanetconnect__TSANetCase__c caseRecord = TSANetCaseSelector.getByToken(caseToken);
        String noteEndpoint = EndpointManager.getEndpointWithToken(EndpointManager.notes, caseToken);
        HttpResponse res = HttpClient.sendPost(noteEndpoint, token, json);

        try {
            tsanetconnect__TSANetNote__c noteRecord = ParserManager.parseTSANetNote(res.getBody());
            Database.upsert(noteRecord, tsanetconnect__TSANetNote__c.tsanetconnect__Token__c, false, AccessLevel.USER_MODE);
        } catch(Exception e) {
            ErrorLogger.logError(e, 'CREATE_TSANET_NOTE_UPSERT', new Map<String, String>{ 'caseToken' => caseToken, 'response' => res.getBody() });
        }

        if(!Test.isRunningTest()){
            retrieveCollaborationCases(caseRecord.tsanetconnect__Case__c, token);
        }

        return res.getBody();
    }

    /**
     * Authenticates against the TSANet API and returns an access token.
     * @return JWT access token, or null on failure
     */
    @AuraEnabled
    public static String getTSANetAccessToken(){
        tsanetconnect__TSANet_Credentials__c credential = CredentialManager.getCredentials();
        String authEndpoint = EndpointManager.getAuthPath();

        HttpRequest req = new HttpRequest();
        req.setEndpoint(authEndpoint);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(JSON.serialize(new Map<String, String>{
            'username' => credential.tsanetconnect__UserName__c,
            'password' => credential.tsanetconnect__Password__c
        }));

        Http http = new Http();
        HTTPResponse res = http.send(req);

        if(res.getStatusCode() != TSANetConstants.SUCCESS_CODE){ return null; }

        AuthManager.AccessTokenResponse response = (AuthManager.AccessTokenResponse) System.JSON.deserialize(res.getBody(), AuthManager.AccessTokenResponse.class);
        return response.accessToken;
    }

    /**
     * Fetches collaboration cases from the TSANet API and upserts them locally.
     * @param caseId Salesforce Case Id to scope results (nullable for all)
     * @param token access token for authentication
     * @return list of related TSANetCase__c records for the given Case
     */
    @AuraEnabled
    public static tsanetconnect__TSANetCase__c[] getRelatedCollaborationCases(String caseId, String token){
        String caseNumber = null;
        if(caseId != null){
            Case caseRecord = CaseSelector.getById(caseId);
            caseNumber = caseRecord.CaseNumber;
        }

        String getCasesPath = EndpointManager.getCollaborationCasesPath(caseNumber);
        HttpResponse res = HttpClient.sendGet(getCasesPath, token);

        TSANetData data = ParserManager.parseTSANetCases(res.getBody(), caseId);
        upsertTSANetData(data);

        if(caseId != null){
            return TSANetCaseSelector.getDetailWithResponsesByCaseId(caseId);
        }
        return new tsanetconnect__TSANetCase__c[]{};
    }

    /**
     * Retrieves the collaboration form definition for a given company.
     * @param companyId TSANet company identifier
     * @param mode form mode (e.g. "company" or "department")
     * @param token access token for authentication
     * @return raw API response body containing the form definition
     */
    @AuraEnabled
    public static String getFormByCompanyId(String companyId, String mode, String token){
        String companiesEndpoint = EndpointManager.getCompaniesPath(companyId, mode);
        HttpResponse res = HttpClient.sendGet(companiesEndpoint, token);
        return res.getBody();
    }

    /**
     * Searches TSANet companies by name.
     * @param companyName search term for the company name
     * @param token access token for authentication
     * @return raw API response body with matching companies
     */
    @AuraEnabled
    public static String getCompaniesByName(String companyName, String token){
        String companiesEndpoint = EndpointManager.getCompaniesPath(companyName);
        HttpResponse res = HttpClient.sendGet(companiesEndpoint, token);
        return res.getBody();
    }

    /**
     * Submits a new collaboration case to the TSANet API.
     * @param caseId Salesforce Case Id linked to the collaboration
     * @param json serialised case payload
     * @param token access token for authentication
     * @return raw API response body
     */
    @AuraEnabled
    public static String createCollaborationCase(Id caseId, String json, String token){
        String casePath = EndpointManager.getCreateCollaborationCasePath();
        HttpResponse res = HttpClient.sendPost(casePath, token, json);

        if(!Test.isRunningTest()){
            retrieveCollaborationCases(caseId, token);
		}

        try {
            Map<String, Object> response = (Map<String, Object>) System.JSON.deserializeUntyped(res.getBody());
            TSANetHelper.createCaseFeedItem(caseId, response);
        } catch(Exception e){
            ErrorLogger.logError(e, 'CREATE_COLLABORATION_CASE_FEED_ITEM');
        }

        return res.getBody();
    }

    /**
     * Approves an incoming TSANet collaboration request.
     * @param caseToken unique token of the TSANet case
     * @param json serialised approval payload with engineer details
     * @param token access token for authentication
     * @return raw API response body
     */
    @AuraEnabled
    public static String approveIncomingRequest(String caseToken, String json, String token){
        tsanetconnect__TSANetCase__c tsaNetCase = TSANetCaseSelector.getByToken(caseToken);
        String approvePath = EndpointManager.getEndpointWithToken(EndpointManager.approve, caseToken);
        HttpResponse res = HttpClient.sendPost(approvePath, token, json);

        if(!Test.isRunningTest()){
            retrieveCollaborationCases(tsaNetCase.tsanetconnect__Case__c, token);
        }
        return res.getBody();
    }


    /**
     * Rejects a TSANet collaboration case via the API.
     * @param tsaNetCaseId Id of the TSANetCase__c record
     * @param json serialised rejection payload
     * @param token access token for authentication
     * @return raw API response body
     */
    @AuraEnabled
    public static String rejectTSANetCase(String tsaNetCaseId, String json, String token){
        tsanetconnect__TSANetCase__c tsaNetCase = TSANetCaseSelector.getById(tsaNetCaseId);
        String rejectPath = EndpointManager.getEndpointWithToken(EndpointManager.reject, tsaNetCase.tsanetconnect__Token__c);
        HttpResponse res = HttpClient.sendPost(rejectPath, token, json);

        if(!Test.isRunningTest()){
            retrieveCollaborationCases(tsaNetCase.tsanetconnect__Case__c, token);
        }

        return res.getBody();
    }


    /**
     * Closes a TSANet collaboration case via the API.
     * @param tsaNetCaseId Id of the TSANetCase__c record
     * @param token access token for authentication
     * @return raw API response body
     */
    @AuraEnabled
    public static String closeTSANetCase(String tsaNetCaseId, String token){
        tsanetconnect__TSANetCase__c tsaNetCase = TSANetCaseSelector.getById(tsaNetCaseId);
        String closePath = EndpointManager.getEndpointWithToken(EndpointManager.close, tsaNetCase.tsanetconnect__Token__c);
        HttpResponse res = HttpClient.sendPost(closePath, token, '');

        if(!Test.isRunningTest()){
            retrieveCollaborationCases(tsaNetCase.tsanetconnect__Case__c, token);
        }

        return res.getBody();
    }

    /**
     * Sends an additional-information request on a TSANet case.
     * @param tsaNetCaseId Id of the TSANetCase__c record
     * @param json serialised information-request payload
     * @param token access token for authentication
     * @return raw API response body
     */
    @AuraEnabled
    public static String requestAdditionalInformation(String tsaNetCaseId, String json, String token){
        tsanetconnect__TSANetCase__c tsaNetCase = TSANetCaseSelector.getById(tsaNetCaseId);
        String requestPath = EndpointManager.getEndpointWithToken(EndpointManager.informationRequest, tsaNetCase.tsanetconnect__Token__c);
        HttpResponse res = HttpClient.sendPost(requestPath, token, json);

        if(!Test.isRunningTest()){
            retrieveCollaborationCases(tsaNetCase.tsanetconnect__Case__c, token);
        }

        return res.getBody();
    }

    /**
     * Sends additional-information response on a TSANet case.
     * @param tsaNetCaseId Id of the TSANetCase__c record
     * @param json serialised information-response payload
     * @param token access token for authentication
     * @return raw API response body
     */
    @AuraEnabled
    public static String sendAdditionalInformation(String tsaNetCaseId, String json, String token){
        tsanetconnect__TSANetCase__c tsaNetCase = TSANetCaseSelector.getById(tsaNetCaseId);
        String sendPath = EndpointManager.getEndpointWithToken(EndpointManager.informationResponse, tsaNetCase.tsanetconnect__Token__c);
        HttpResponse res = HttpClient.sendPost(sendPath, token, json);

        if(!Test.isRunningTest()){
            retrieveCollaborationCases(tsaNetCase.tsanetconnect__Case__c, token);
        }

        return res.getBody();
    }

    /**
     * Retrieves the attachment configuration for a TSANet case.
     * @param token unique case token
     * @return raw API response body with attachment config
     */
    @AuraEnabled
    public static String getAttachmentConfig(String token){
        String path = EndpointManager.domain + EndpointManager.case_path + '/' + token + '/attachments/config';
        HttpResponse res = HttpClient.sendGet(path, null);
        return res.getBody();
    }

    /**
     * Uploads file attachments to a TSANet case and links them locally.
     * @param token unique case token
     * @param files list of file-data maps (base64, filename, fileId)
     * @return raw API response body with upload results
     */
    @AuraEnabled
    public static String sendAttachment(String token, List<Map<String, Object>> files){
        tsanetconnect__TSANetCase__c tsaNetCase = TSANetCaseSelector.getIdByToken(token);

        Id[] contentVersionIds = new Id[]{};
        for(Map<String, Object> fileData : files){
            String base64String = (String) fileData.get('base64');
            if(base64String == NULL){
                String fileId = (String) fileData.get('fileId');
                contentVersionIds.add(fileId);
            }
        }

        ContentVersion[] selectedContentVersions = [SELECT Id, Title, FileType, VersionData FROM ContentVersion WHERE Id IN:contentVersionIds WITH SECURITY_ENFORCED ];

        List<Map<String, Object>> newFiles = new List<Map<String, Object>>();
        for(Map<String, Object> fileData : files){
            String base64String = (String) fileData.get('base64');
            if(base64String == NULL){
                String fileId = (String) fileData.get('fileId');
                for(ContentVersion cv : selectedContentVersions){
                    if(cv.Id == fileId){
                        Map<String, Object> newFileData = new Map<String, Object>();
                        newFileData.put('fileId', fileId);
                        newFileData.put('filename', cv.Title);
                        newFileData.put('base64', EncodingUtil.base64Encode(cv.VersionData));
                        newFileData.put('isCV', true);
                        newFiles.add(newFileData);
                    }
                }
            } else {
                newFiles.add(fileData);
            }
        }

        String boundary = 'EWG3x2i19rjSk310MA4YWxkTrZu0gW';
        String lineBreak = '\r\n';

        String body = '';

        body += '--' + boundary + lineBreak;
        body += 'Content-Disposition: form-data; name="description"' + lineBreak + lineBreak;
        body += '' + lineBreak;

        for(Map<String, Object> fileData : newFiles){
            String base64String = (String) fileData.get('base64');
            String fileName = (String) fileData.get('filename');

            body += '--' + boundary + lineBreak;
            body += 'Content-Disposition: form-data; name="files"; filename="' + fileName + '"' + lineBreak;
            body += 'Content-Type: multipart/form-data' + lineBreak + lineBreak;
            body += EncodingUtil.base64Decode(base64String) + lineBreak;
        }

        body += '--' + boundary + '--' + lineBreak;

        String contentLength = String.valueOf(body.length());

        HttpRequest req = new HttpRequest();
        req.setEndpoint(EndpointManager.domain + EndpointManager.case_path + '/' + token + '/attachments');
        req.setMethod('POST');
        req.setHeader('Authorization', AuthManager.getBearerToken());
        req.setHeader('Accept', 'application/problem+json');
        req.setHeader('Content-Length', contentLength);
        req.setHeader('Content-Type', 'multipart/form-data; boundary=' + boundary);
        req.setHeader('boundary', boundary);
        req.setHeader('Accept', '*/*');
        req.setBody(body);
        req.setTimeout(TSANetConstants.DEFAULT_TIMEOUT);

        Http http = new Http();
        HttpResponse res = http.send(req);

        TSANetFileUploadResult[] results = TSANetFileUploadResult.parse(res.getBody());

        ContentVersion[] versions = new ContentVersion[]{};
        for(Map<String, Object> fileData : newFiles){
            String fileName = (String) fileData.get('filename');
            String base64String = (String) fileData.get('base64');
            Boolean isCV = (Boolean) fileData.get('isCV');
            if(isCV == NULL || !isCV){
                for(TSANetFileUploadResult result : results){
                    if(result.receiverStatus == TSANetConstants.UPLOAD_STATUS_SUCCESS && result.fileName == fileName){
                        ContentVersion cv = new ContentVersion();
                        cv.Title = fileName;
                        cv.PathOnClient = fileName;
                        cv.VersionData = EncodingUtil.base64Decode(base64String);
                        versions.add(cv);
                    }
                }
            }
        }
        Database.insert(versions, AccessLevel.USER_MODE);

        Id[] versionIds = new Id[]{};
        for(ContentVersion version : versions){
			versionIds.add(version.Id);
        }

        ContentVersion[] contentVersions = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id IN:versionIds WITH SECURITY_ENFORCED ];

        ContentDocumentLink[] links = new ContentDocumentLink[]{};
        for(ContentVersion cv : contentVersions){
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.ContentDocumentId = cv.ContentDocumentId;
            cdl.LinkedEntityId = tsaNetCase.Id;
            cdl.ShareType = TSANetConstants.SHARE_TYPE_VIEWER;
            cdl.Visibility = TSANetConstants.VISIBILITY_ALL;
            links.add(cdl);
        }

        Database.insert(links, AccessLevel.USER_MODE);

        return res.getBody();
    }

    /**
     * Sends an owner-change update to the TSANet API for an outbound case.
     * @param caseId Id of the TSANetCase__c record
     * @param token access token for authentication (re-fetched inside)
     */
    @Future(callout=true)
    public static void changeTSANetOwner(Id caseId, String token){
        tsanetconnect__TSANetCase__c caseRecord = TSANetCaseSelector.getById(caseId);

        token = TSANetService.getTSANetAccessToken();
        Case sfCase = CaseSelector.getOwnerDetailById(caseRecord.tsanetconnect__Case__c);

        Map<String, Object> payload = new Map<String, Object>{
            'internalCaseNumber' => sfCase.CaseNumber,
            'submitterContactDetails' => new Map<String, Object>{
                'name' => sfCase.Owner.Name,
                'email' => sfCase.Owner.Email,
                'phone' => sfCase.Owner.Phone
            }
        };

        String noteEndpoint = EndpointManager.getEndpointWithToken(EndpointManager.updateCase, caseRecord.tsanetconnect__Token__c);

        try {
            HttpClient.sendWithTimeout('PATCH', noteEndpoint, token, JSON.serialize(payload), TSANetConstants.SHORT_TIMEOUT);
            if(!Test.isRunningTest()){
                retrieveCollaborationCases(caseRecord.tsanetconnect__Case__c, token);
            }
        } catch(Exception e){
            ErrorLogger.logError(e, 'CHANGE_TSANET_OWNER', new Map<String, String>{ 'caseId' => sfCase?.Id, 'tsaNetCaseId' => caseRecord?.Id });
        }
    }

    /**
     * Updates an approved inbound collaboration request via PATCH /approval (engineer + case details).
     * @param tsaNetCaseId tsanetconnect__TSANetCase__c Id
     * @param token access token for authentication (re-fetched inside)
     */
    @Future(callout=true)
    public static void changeTSANetResponse(Id tsaNetCaseId, String token){
        tsanetconnect__TSANetCase__c caseRecord = TSANetCaseSelector.getById(tsaNetCaseId);

        token = TSANetService.getTSANetAccessToken();
        Case sfCase = CaseSelector.getFullDetailById(caseRecord.tsanetconnect__Case__c);

        Map<String, Object> payload = new Map<String, Object>{
            'caseNumber' => sfCase.CaseNumber,
            'engineerName' => sfCase.Owner != null ? sfCase.Owner.Name : '',
            'engineerPhone' => sfCase.Owner != null ? sfCase.Owner.Phone : '',
            'engineerEmail' => sfCase.Owner != null ? sfCase.Owner.Email : '',
            'nextSteps' => ''
        };

        String approvalEndpoint = EndpointManager.getEndpointWithToken(EndpointManager.approve, caseRecord.tsanetconnect__Token__c);

        try {
            HttpClient.sendWithTimeout('PATCH', approvalEndpoint, token, JSON.serialize(payload), TSANetConstants.SHORT_TIMEOUT);
            if(!Test.isRunningTest()){
                retrieveCollaborationCases(caseRecord.tsanetconnect__Case__c, token);
            }
        } catch(Exception e){
            ErrorLogger.logError(e, 'CHANGE_TSANET_RESPONSE', new Map<String, String>{ 'caseId' => sfCase?.Id, 'tsaNetCaseId' => caseRecord?.Id });
        }
    }

    /**
     * Enqueues a background refresh of collaboration cases (optionally scoped by CaseNumber).
     * @param caseId Salesforce Case Id to scope the refresh (nullable)
     * @param token access token (unused; refresh is queued)
     */
    public static void retrieveCollaborationCases(Id caseId, String token){
        String caseNumber = null;
        if(caseId != null){
            Case sfCase = CaseSelector.getById(caseId);
            caseNumber = sfCase.CaseNumber;
        }
        System.enqueueJob(new TSANetQueueableJob(0, null, null, null, null, caseNumber));
    }

    /**
     * Shared upsert + error-collection for TSANet cases, notes, and responses.
     * Uses UpsertExecutor to transparently recover from concurrent-insert DUPLICATE_VALUE
     * races (the periodic sync, the LWC related-list refresh, and the inbound webhook
     * can all touch the same external Id at the same time).
     * @param data parsed TSANet data containing cases, notes, and responses
     */
    public static void upsertTSANetData(TSANetData data){
        UpsertExecutor.execute(data.cases, tsanetconnect__TSANetCase__c.tsanetconnect__Token__c, AccessLevel.USER_MODE);
        UpsertExecutor.execute(data.notes, tsanetconnect__TSANetNote__c.tsanetconnect__Token__c, AccessLevel.USER_MODE);
        UpsertExecutor.execute(data.responses, tsanetconnect__TSANetResponse__c.tsanetconnect__tsaNetResponseId__c, AccessLevel.USER_MODE);
    }
}
