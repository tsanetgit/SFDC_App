public with sharing class TSANetService {
    
    public class TSANetServiceException extends Exception {}

    public class TSANetNoteResponse {
        public Integer id;
        public Integer caseId;
        public String companyName;
        public String creatorUsername;
        public String creatorEmail;
        public String creatorName;
        public String summary;
        public String description;
        public String priority;
        public String status;
        public String token;
        public String createdAt;
        public String updatedAt;
    }
    
    public static  tsanetconnect__TSANet_Credentials__c credential = CredentialManager.getCredentials();
    
    public static TSANetCompanyInfo getCompanyInformation(String token){
        
        String accessToken = token != NULL ? ( 'Bearer ' + token ) : AuthManager.getBearerToken();
        String companyEndpoint = EndpointManager.getTSANetCompanyPath();
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(companyEndpoint);
        req.setHeader('Authorization', accessToken);
        req.setMethod('GET');
        
        Http http = new Http();
        HTTPResponse res = http.send(req);
        
        if(res.getStatusCode() != 200){
            if(ErrorManager.isUnautorized(res.getBody())){
                String newAccessToken = getTSANetAccessToken();
                TSANetCompanyInfo info = getCompanyInformation(newAccessToken);
                CredentialManager.updateToken(newAccessToken);
                return info;
            } else {
                ErrorManager.handleResponseErrors(res);
            }
        }  
        
        TSANetCompanyInfo info = (TSANetCompanyInfo) System.JSON.deserialize(res.getBody(), TSANetCompanyInfo.class);
		return info;
    }
    
    @AuraEnabled
    public static String createTSANetNote(String caseToken, String json, String token){
        
        tsanetconnect__TSANetCase__c caseRecord = [SELECT Id, Name, tsanetconnect__Token__c, tsanetconnect__Case__c FROM tsanetconnect__TSANetCase__c WHERE tsanetconnect__Token__c =:caseToken WITH SECURITY_ENFORCED ];
        
        String accessToken = token != NULL ? ( 'Bearer ' + token ) : AuthManager.getBearerToken();
        String noteEndpoint = EndpointManager.getEndpointWithToken(EndpointManager.notes, caseToken);
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(noteEndpoint);
        req.setHeader('Authorization', accessToken);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(json);
        
        Http http = new Http();
        HTTPResponse res = http.send(req);
        
        if(res.getStatusCode() != 200){
            if(ErrorManager.isUnautorized(res.getBody())){
                String newAccessToken = getTSANetAccessToken();
                String body = createTSANetNote(caseToken, json, newAccessToken);
                CredentialManager.updateToken(newAccessToken);
                return body;
            } else {
                ErrorManager.handleResponseErrors(res);
            }
        }  

        try {
            tsanetconnect__TSANetNote__c noteRecord = ParserManager.parseTSANetNote(res.getBody());
            Database.upsert(noteRecord, tsanetconnect__TSANetNote__c.tsanetconnect__Token__c, false, AccessLevel.USER_MODE);
        } catch(Exception e) {
            ErrorLogger.logError(e, 'CREATE_TSANET_NOTE_UPSERT', new Map<String, String>{ 'caseToken' => caseToken, 'response' => res.getBody() });
        }
        
        if(!Test.isRunningTest()){
            System.enqueueJob(new TSANetQueueableJob(0, null, null, null, null));
        }
        
        return res.getBody();
    }
    
    @AuraEnabled
    public static String getTSANetAccessToken(){
        
        String authEndpoint = EndpointManager.getAuthPath();

        HttpRequest req = new HttpRequest();
        req.setEndpoint(authEndpoint);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody('');
        req.setBody('{"username": "' + credential.tsanetconnect__UserName__c + '","password": "' + credential.tsanetconnect__Password__c + '"}');
        
        Http http = new Http();
        HTTPResponse res = http.send(req);
        
        if(res.getStatusCode() != 200){ return null; }
        
        AuthManager.AccessTokenResponse response = (AuthManager.AccessTokenResponse) System.JSON.deserialize(res.getBody(), AuthManager.AccessTokenResponse.class);
        return response.accessToken;
    }
    
    @AuraEnabled
    public static tsanetconnect__TSANetCase__c[] getRelatedCollaborationCases(String caseId, String token){
        
        Case caseRecord = new Case();
        if(caseId != null){
            caseRecord = [SELECT Id, CaseNumber FROM Case WHERE Id =:caseId WITH SECURITY_ENFORCED ];
        }
        
        String getCasesPath = EndpointManager.getCollaborationCasesPath(caseRecord.Id != NULL ? caseRecord.CaseNumber : null);
        String accessToken = token != NULL ? ( 'Bearer ' + token ) : AuthManager.getBearerToken();
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(getCasesPath);
        req.setHeader('Authorization', accessToken);
        req.setMethod('GET');
        req.setHeader('Content-Type', 'application/json');
        
        Http http = new Http();

        HTTPResponse res = http.send(req);
        
        if(res.getStatusCode() != 200){
            if(ErrorManager.isUnautorized(res.getBody())){
                String newAccessToken = getTSANetAccessToken();
                tsanetconnect__TSANetCase__c[] cases = getRelatedCollaborationCases(caseId, newAccessToken);
                CredentialManager.updateToken(newAccessToken);
                return cases;
            } else {
                ErrorManager.handleResponseErrors(res);
            }
        }  
        
        TSANetData data = ParserManager.parseTSANetCases(res.getBody(), caseId);
        
        Database.UpsertResult[] tsaNetCaseResult = Database.upsert(data.cases, tsanetconnect__TSANetCase__c.tsanetconnect__Token__c, false, AccessLevel.USER_MODE);
        
        Database.UpsertResult[] tsaNetNoteResult = Database.upsert(data.notes, tsanetconnect__TSANetNote__c.tsanetconnect__Token__c, false, AccessLevel.USER_MODE);
        
        Database.UpsertResult[] tsaNetResponseResult = Database.upsert(data.responses, tsanetconnect__TSANetResponse__c.tsanetconnect__tsaNetResponseId__c, false, AccessLevel.USER_MODE);
        
        tsanetconnect__TSANetError__c[] errors = new tsanetconnect__TSANetError__c[]{};

        errors.addAll(ErrorManager.collectErrors(tsaNetCaseResult, data.cases, tsanetconnect__TSANetCase__c.tsanetconnect__Token__c));
        errors.addAll(ErrorManager.collectErrors(tsaNetNoteResult, data.notes, tsanetconnect__TSANetNote__c.tsanetconnect__Token__c));
        errors.addAll(ErrorManager.collectErrors(tsaNetResponseResult, data.responses, tsanetconnect__TSANetResponse__c.tsanetconnect__tsaNetResponseId__c));
        ErrorLogger.logErrors(errors);
        
        return [SELECT Id, Name, tsanetconnect__Name__c, tsanetconnect__customFields__c, tsanetconnect__TSANetContact__c, tsanetconnect__FirstName__c, tsanetconnect__LastName__c, tsanetconnect__Phone__c, tsanetconnect__EngineerName__c, tsanetconnect__EngineerEmail__c, tsanetconnect__TSANetEmail__c, tsanetconnect__EngineerPhone__c, tsanetconnect__Email__c, tsanetconnect__Case__c, tsanetconnect__Case__r.CaseNumber, Partner__c, tsanetconnect__SubmittedCompanyName__c, tsanetconnect__SubmittedCompanyId__c, tsanetconnect__receivedCompanyName__c, tsanetconnect__receivedCompanyId__c, tsanetconnect__Summary__c, tsanetconnect__Description__c, tsanetconnect__Status__c, tsanetconnect__Token__c, tsanetconnect__Responded__c, tsanetconnect__FeedbackRequested__c, tsanetconnect__ReminderSent__c, tsanetconnect__Priority__c, tsanetconnect__tsaNetCaseId__c, tsanetconnect__RequestDate__c, tsanetconnect__ResponseDate__c, tsanetconnect__PriorityNote__c, tsanetconnect__Direction__c,
                    (SELECT Id, Name, tsanetconnect__TSANetCase__c, tsanetconnect__Type__c, tsanetconnect__EngineerName__c, tsanetconnect__EngineerPhone__c, tsanetconnect__EngineerEmail__c, tsanetconnect__Note__c, tsanetconnect__tsaNetCaseId__c, tsanetconnect__tsaNetResponseId__c FROM tsanetconnect__TSANetResponses__r ORDER BY tsanetconnect__CreatedAt__c DESC)
                    FROM tsanetconnect__TSANetCase__c 
                    WHERE tsanetconnect__Case__r.CaseNumber =:caseId 
                    WITH SECURITY_ENFORCED
                    ORDER BY tsanetconnect__RequestDate__c DESC];
    }
    
    @AuraEnabled
    public static String getFormByCompanyId(String companyId, String mode, String token){

        String companiesEndpoint = EndpointManager.getCompaniesPath(companyId, mode);
        String accessToken = token != NULL ? ( 'Bearer ' + token ) : AuthManager.getBearerToken();
       
        HttpRequest req = new HttpRequest();
        req.setEndpoint(companiesEndpoint);
        req.setHeader('Authorization', accessToken);
        req.setMethod('GET');
        req.setTimeout(120000);

        Http http = new Http();
        HTTPResponse res = http.send(req);
        
        if(res.getStatusCode() != 200){
            if(ErrorManager.isUnautorized(res.getBody())){
                String newAccessToken = getTSANetAccessToken();
                String body = getFormByCompanyId(companyId, mode, newAccessToken);
                CredentialManager.updateToken(newAccessToken);
                return body;
            } else {
                ErrorManager.handleResponseErrors(res);
            }
        }  
        
        return res.getBody();
    }
    
    @AuraEnabled
    public static String getCompaniesByName(String companyName, String token){

        String companiesEndpoint = EndpointManager.getCompaniesPath(companyName);
        String accessToken = token != NULL ? ( 'Bearer ' + token ) : AuthManager.getBearerToken();

        HttpRequest req = new HttpRequest();
        req.setEndpoint(companiesEndpoint);
        req.setHeader('Authorization', accessToken);
        req.setMethod('GET');
        req.setTimeout(120000);
        
        Http http = new Http();
        HTTPResponse res = http.send(req);
        
        if(res.getStatusCode() != 200){
            if(ErrorManager.isUnautorized(res.getBody())){
                String newAccessToken = getTSANetAccessToken();
                String body = getCompaniesByName(companyName, newAccessToken);
                CredentialManager.updateToken(newAccessToken);
                return body;
            } else {
                ErrorManager.handleResponseErrors(res);
            }
        }
        return res.getBody();
    }
    
    @AuraEnabled
    public static String createCollaborationCase(Id caseId, String json, String token){
        
        String casePath = EndpointManager.getCreateCollaborationCasePath();
        String accessToken = token != NULL ? ( 'Bearer ' + token ) : AuthManager.getBearerToken();

        HttpRequest req = new HttpRequest();
        req.setEndpoint(casePath);
        req.setHeader('Authorization', accessToken);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(json);

        Http http = new Http();
        HTTPResponse res = http.send(req);

        if(res.getStatusCode() != 200){
            if(ErrorManager.isUnautorized(res.getBody())){
                String newAccessToken = getTSANetAccessToken();
                String body = createCollaborationCase(caseId, json, newAccessToken);
                CredentialManager.updateToken(newAccessToken);
                return body;
            } else {
                ErrorManager.handleResponseErrors(res);
            }
        }
                
        if(!Test.isRunningTest()){
            retrieveCollaborationCases(caseId, token);
		}

        try {
            Map<String, Object> response = (Map<String, Object>) System.JSON.deserializeUntyped(res.getBody());
            TSANetHelper.createCaseFeedItem(caseId, response);
        } catch(Exception e){}
        
             
        return res.getBody();
    }
    
    @AuraEnabled
    public static String approveIncomingRequest(String caseToken, String json, String token){

        tsanetconnect__TSANetCase__c tsaNetCase = [SELECT Id, tsanetconnect__Case__c, tsanetconnect__tsaNetCaseId__c, tsanetconnect__Token__c FROM tsanetconnect__TSANetCase__c WHERE tsanetconnect__Token__c =:caseToken WITH SECURITY_ENFORCED ];
        
        String accessToken = token != NULL ? ( 'Bearer ' + token ) : AuthManager.getBearerToken();
        String approvePath = EndpointManager.getEndpointWithToken(EndpointManager.approve, caseToken);
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(approvePath);
        req.setHeader('Authorization', accessToken);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(json);
        
        Http http = new Http();
        HTTPResponse res = http.send(req);
        
        if(res.getStatusCode() != 200){
            if(ErrorManager.isUnautorized(res.getBody())){
                String newAccessToken = getTSANetAccessToken();
                String body = approveIncomingRequest(caseToken, json, newAccessToken);
                CredentialManager.updateToken(newAccessToken);
                return body;
            } else {
                ErrorManager.handleResponseErrors(res);
            }
        }
        
        if(!Test.isRunningTest()){
            retrieveCollaborationCases(tsaNetCase.tsanetconnect__Case__c, token);
        }
        return res.getBody();
    }
    
    
    @AuraEnabled
    public static String rejectTSANetCase(String tsaNetCaseId, String json, String token){
        
        tsanetconnect__TSANetCase__c tsaNetCase = [SELECT Id, tsanetconnect__Case__c, tsanetconnect__tsaNetCaseId__c, tsanetconnect__Token__c FROM tsanetconnect__TSANetCase__c WHERE Id =:tsaNetCaseId WITH SECURITY_ENFORCED ];
        
        String accessToken = token != NULL ? ( 'Bearer ' + token ) : AuthManager.getBearerToken();
        String rejectPath = EndpointManager.getEndpointWithToken(EndpointManager.reject, tsaNetCase.tsanetconnect__Token__c);
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(rejectPath);
        req.setHeader('Authorization', accessToken);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(json);
        
        Http http = new Http();
        HTTPResponse res = http.send(req);
        
        if(res.getStatusCode() != 200){
            if(ErrorManager.isUnautorized(res.getBody())){
                String newAccessToken = getTSANetAccessToken();
                String body = rejectTSANetCase(tsaNetCaseId, json, newAccessToken);
                CredentialManager.updateToken(newAccessToken);
                return body;
            } else {
                ErrorManager.handleResponseErrors(res);
            }
        }
        
        if(!Test.isRunningTest()){
            retrieveCollaborationCases(tsaNetCase.tsanetconnect__Case__c, token);
        }
        
        return res.getBody();
    }
    
        
    @AuraEnabled
    public static String closeTSANetCase(String tsaNetCaseId, String token){
        
        tsanetconnect__TSANetCase__c tsaNetCase = [SELECT Id, tsanetconnect__Case__c, tsanetconnect__Token__c, tsanetconnect__tsaNetCaseId__c FROM tsanetconnect__TSANetCase__c WHERE Id =:tsaNetCaseId WITH SECURITY_ENFORCED ];
        
        String accessToken = token != NULL ? ( 'Bearer ' + token ) : AuthManager.getBearerToken();
        String closePath = EndpointManager.getEndpointWithToken(EndpointManager.close, tsaNetCase.tsanetconnect__Token__c);
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(closePath);
        req.setHeader('Authorization', accessToken);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody('');
        
        Http http = new Http();
        HTTPResponse res = http.send(req);
        
        if(res.getStatusCode() != 200){
            if(ErrorManager.isUnautorized(res.getBody())){
                String newAccessToken = getTSANetAccessToken();
                String body = closeTSANetCase(tsaNetCaseId, newAccessToken);
                CredentialManager.updateToken(newAccessToken);
                return body;
            } else {
                ErrorManager.handleResponseErrors(res);
            }
        }
        
        if(!Test.isRunningTest()){
            retrieveCollaborationCases(tsaNetCase.tsanetconnect__Case__c, token);
        }
        
        return res.getBody();
    }
    
    @AuraEnabled
    public static String requestAdditionalInformation(String tsaNetCaseId, String json, String token){
        
        tsanetconnect__TSANetCase__c tsaNetCase = [SELECT Id, tsanetconnect__Case__c, tsanetconnect__Token__c, tsanetconnect__tsaNetCaseId__c FROM tsanetconnect__TSANetCase__c WHERE Id =:tsaNetCaseId WITH SECURITY_ENFORCED ];
        
        String accessToken = token != NULL ? ( 'Bearer ' + token ) : AuthManager.getBearerToken();
        String requestAdditionalInfoPath = EndpointManager.getEndpointWithToken(EndpointManager.informationRequest, tsaNetCase.tsanetconnect__Token__c);
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(requestAdditionalInfoPath);
        req.setHeader('Authorization', accessToken);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(json);
        
        Http http = new Http();
        HTTPResponse res = http.send(req);
        
        if(res.getStatusCode() != 200){
            if(ErrorManager.isUnautorized(res.getBody())){
                String newAccessToken = getTSANetAccessToken();
                String body = requestAdditionalInformation(tsaNetCaseId, json, newAccessToken);
                CredentialManager.updateToken(newAccessToken);
                return body;
            } else {
                ErrorManager.handleResponseErrors(res);
            }
        }
        
        if(!Test.isRunningTest()){
            retrieveCollaborationCases(tsaNetCase.tsanetconnect__Case__c, token);
        }
        
        return res.getBody();
    }
    
    @AuraEnabled
    public static String sendAdditionalInformation(String tsaNetCaseId, String json, String token){
        
        tsanetconnect__TSANetCase__c tsaNetCase = [SELECT Id, tsanetconnect__Case__c, tsanetconnect__Token__c, tsanetconnect__tsaNetCaseId__c FROM tsanetconnect__TSANetCase__c WHERE Id =:tsaNetCaseId WITH SECURITY_ENFORCED ];
        
        String accessToken = token != NULL ? ( 'Bearer ' + token ) : AuthManager.getBearerToken();
        String sendAdditionalInfoPath = EndpointManager.getEndpointWithToken(EndpointManager.informationResponse, tsaNetCase.tsanetconnect__Token__c);
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(sendAdditionalInfoPath);
        req.setHeader('Authorization', accessToken);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(json);
        
        Http http = new Http();
        HTTPResponse res = http.send(req);
        
        if(res.getStatusCode() != 200){
            if(ErrorManager.isUnautorized(res.getBody())){
                String newAccessToken = getTSANetAccessToken();
                String body = sendAdditionalInformation(tsaNetCaseId, json, newAccessToken);
                CredentialManager.updateToken(newAccessToken);
                return body;
            } else {
                ErrorManager.handleResponseErrors(res);
            }
        }
        
        if(!Test.isRunningTest()){
            retrieveCollaborationCases(tsaNetCase.tsanetconnect__Case__c, token);
        }
        
        return res.getBody();
    }

    @AuraEnabled
    public static String getAttachmentConfig(String token){
        
        String path = EndpointManager.domain + EndpointManager.case_path + '/' + token + '/attachments/config';
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(path);
        req.setHeader('Authorization', AuthManager.getBearerToken());
        req.setMethod('GET');
        req.setHeader('Content-Type', 'application/json');
        req.setTimeout(120000);
        
        Http http = new Http();

        HTTPResponse res;
        if(!Test.isRunningTest()){
            res = http.send(req);
            
        	if(res.getStatusCode() != 200){
                ErrorManager.handleResponseErrors(res);
            }
        }
        
        return res.getBody();
    }
    
    @AuraEnabled
    public static String sendAttachment(String token, List<Map<String, Object>> files){
        
        tsanetconnect__TSANetCase__c tsaNetCase = [SELECT Id FROM tsanetconnect__TSANetCase__c WHERE tsanetconnect__Token__c =:token WITH SECURITY_ENFORCED ];
        
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
        
        //ContentVersion[] versions = new ContentVersion[]{};
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
        req.setEndpoint(EndpointManager.domain + '/v1/collaboration-requests/' + token + '/attachments');
        req.setMethod('POST');
        req.setHeader('Authorization', AuthManager.getBearerToken());
        req.setHeader('Accept', 'application/problem+json');
        req.setHeader('Content-Length', contentLength);
        req.setHeader('Content-Type', 'multipart/form-data; boundary=' + boundary);
        req.setHeader('boundary', boundary);
        req.setHeader('Accept', '*/*');
        req.setBody(body);
        req.setTimeout(120000);
        
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
                    if(result.receiverStatus == 'SUCCESS' && result.fileName == fileName){
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
            cdl.ShareType = 'V'; 
            cdl.Visibility = 'AllUsers';
            links.add(cdl);
        }
        
        Database.insert(links, AccessLevel.USER_MODE);
        
        return res.getBody();
    }
    
    @future(callout=true)
    public static void changeTSANetOwner(Id caseId, String token){
        
        tsanetconnect__TSANetCase__c caseRecord = [SELECT Id, tsanetconnect__Case__c, tsanetconnect__Token__c FROM tsanetconnect__TSANetCase__c WHERE Id =:caseId WITH SECURITY_ENFORCED ];
         
        token = TSANetService.getTSANetAccessToken();
        String accessToken = token != NULL ? ( 'Bearer ' + token ) : AuthManager.getBearerToken();
        String noteEndpoint = EndpointManager.getEndpointWithToken(EndpointManager.updateCase, caseRecord.tsanetconnect__Token__c);
        
        Case sfCase = [SELECT Id, CaseNumber, OwnerId, Owner.Name, Owner.Phone, Owner.Email FROM Case WHERE Id =:caseRecord.tsanetconnect__Case__c WITH SECURITY_ENFORCED ];
        
        String json = '{"internalCaseNumber": "' + sfCase.CaseNumber + '","submitterContactDetails": {"name": "' + sfCase.Owner.Name + '","email": "' + 'test@democisco.com' + '","phone": "' + sfCase.Owner.Phone + '"}}'; //sfCase.Owner.Email

        
        try {
                      
            HttpRequest req = new HttpRequest();
            req.setEndpoint(noteEndpoint);
            req.setHeader('Authorization', accessToken);
            req.setMethod('PATCH');
            req.setHeader('Content-Type', 'application/json');
            req.setTimeout(10000);
            req.setBody(json);
            
            Http http = new Http();
            HTTPResponse res = http.send(req);
            
            if(res.getStatusCode() != 200){
                ErrorManager.handleResponseErrors(res);
            }  
            
            if(!Test.isRunningTest()){
                retrieveCollaborationCases(caseRecord.tsanetconnect__Case__c, token);
            }
        } catch(Exception e){
            ErrorLogger.logError(e, 'CHANGE_TSANET_OWNER', new Map<String, String>{ 'caseId' => sfCase?.Id, 'tsaNetCaseId' => caseRecord?.Id });
        }
    }

    public static void retrieveCollaborationCases(Id caseId, String token){
        if(caseId != null){
            getRelatedCollaborationCases(caseId, token);
        } else {
            System.enqueueJob(new TSANetQueueableJob(0, null, null, null, null));
        }
    }
}