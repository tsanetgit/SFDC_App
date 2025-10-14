public class TSANetService {
    
    public class TSANetServiceException extends Exception {}
    
    public static  tsanet_connect__TSANet_Credentials__c credential = CredentialManager.getCredentials();
    
    public static TSANetCompanyInfo getCompanyInformation(String token){
        
        String accessToken = token != NULL ? ( 'Bearer ' + token ) : AuthManager.getBearerToken();
        String companyEndpoint = EndpointManager.getTSANetCompanyPath();
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(companyEndpoint);
        req.setHeader('Authorization', accessToken);
        req.setMethod('GET');
        
        Http http = new Http();
        HTTPResponse res = http.send(req);
        System.debug(res.getBody());
        
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
        
        String accessToken = token != NULL ? ( 'Bearer ' + token ) : AuthManager.getBearerToken();
        String noteEndpoint = EndpointManager.getEndpointWithToken(EndpointManager.notes, caseToken);
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(noteEndpoint);
        req.setHeader('Authorization', accessToken);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setTimeout(10000);
        req.setBody(json);
        
        Http http = new Http();
        HTTPResponse res = http.send(req);
        System.debug(res.getBody());
        
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
        
        if(!Test.isRunningTest()){
            getRelatedCollaborationCases(null, token);
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
        req.setBody('{"username": "' + credential.tsanet_connect__UserName__c + '","password": "' + credential.tsanet_connect__Password__c + '"}');
        
        Http http = new Http();
        HTTPResponse res = http.send(req);
        System.debug(res.getBody());
        
        if(res.getStatusCode() != 200){ return null; }
        
        AuthManager.AccessTokenResponse response = (AuthManager.AccessTokenResponse) System.JSON.deserialize(res.getBody(), AuthManager.AccessTokenResponse.class);
        System.debug(response.accessToken);
        
        return response.accessToken;
    }
    
    @AuraEnabled
    public static tsanet_connect__TSANetCase__c[] getRelatedCollaborationCases(String caseId, String token){

        String getCasesPath = EndpointManager.getCollaborationCasesPath(caseId);
        String accessToken = token != NULL ? ( 'Bearer ' + token ) : AuthManager.getBearerToken();
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(getCasesPath);
        req.setHeader('Authorization', accessToken);
        req.setMethod('GET');
        req.setHeader('Content-Type', 'application/json');
        
        Http http = new Http();

        HTTPResponse res = http.send(req);
        System.debug(res.getBody());
        
        if(res.getStatusCode() != 200){
            if(ErrorManager.isUnautorized(res.getBody())){
                String newAccessToken = getTSANetAccessToken();
                tsanet_connect__TSANetCase__c[] cases = getRelatedCollaborationCases(caseId, newAccessToken);
                CredentialManager.updateToken(newAccessToken);
                return cases;
            } else {
                ErrorManager.handleResponseErrors(res);
            }
        }  
        
        TSANetData data = ParserManager.parseTSANetCases(res.getBody(), caseId);
        
        System.debug('data.cases : ' + data.cases);
        System.debug('data.cases : ' + data.notes);
        System.debug('data.cases : ' + data.responses);
        
        Database.UpsertResult[] tsaNetCaseResult = Database.upsert(data.cases, tsanet_connect__TSANetCase__c.tsanet_connect__CaseToken__c, false);
        Database.UpsertResult[] tsaNetNoteResult = Database.upsert(data.notes, tsanet_connect__TSANetNote__c.tsanet_connect__Token__c, false);
        Database.UpsertResult[] tsaNetResponseResult = Database.upsert(data.responses, tsanet_connect__TSANetResponse__c.tsanet_connect__tsaNetResponseId__c, false);
        
        tsanet_connect__TSANetError__c[] errors = new tsanet_connect__TSANetError__c[]{};

        errors.addAll(ErrorManager.collectErrors(tsaNetCaseResult, data.cases, tsanet_connect__TSANetCase__c.tsanet_connect__CaseToken__c));
        errors.addAll(ErrorManager.collectErrors(tsaNetNoteResult, data.notes, tsanet_connect__TSANetNote__c.tsanet_connect__Token__c));
        errors.addAll(ErrorManager.collectErrors(tsaNetResponseResult, data.responses, tsanet_connect__TSANetResponse__c.tsanet_connect__tsaNetResponseId__c));
        
        ErrorLogger.logErrors(errors);
        
        return [SELECT Id, Name, tsanet_connect__Name__c, tsanet_connect__customFields__c, tsanet_connect__TSANetContact__c, tsanet_connect__FirstName__c, tsanet_connect__LastName__c, tsanet_connect__Phone__c, tsanet_connect__EngineerName__c, tsanet_connect__EngineerEmail__c, tsanet_connect__TSANetEmail__c, tsanet_connect__EngineerPhone__c, tsanet_connect__Email__c, tsanet_connect__Case__c, tsanet_connect__Case__r.CaseNumber, Partner__c, tsanet_connect__SubmittedCompanyName__c, tsanet_connect__SubmittedCompanyId__c, tsanet_connect__receivedCompanyName__c, tsanet_connect__receivedCompanyId__c, tsanet_connect__FullSummary__c, tsanet_connect__Description__c, tsanet_connect__Status__c, tsanet_connect__Token__c, tsanet_connect__Responded__c, tsanet_connect__FeedbackRequested__c, tsanet_connect__ReminderSent__c, tsanet_connect__Priority__c, tsanet_connect__tsaNetCaseId__c, tsanet_connect__RequestDate__c, tsanet_connect__ResponseDate__c, tsanet_connect__PriorityNote__c, tsanet_connect__Type__c,
                    (SELECT Id, Name, tsanet_connect__TSANetCase__c, tsanet_connect__Type__c, tsanet_connect__EngineerName__c, tsanet_connect__EngineerPhone__c, tsanet_connect__EngineerEmail__c, tsanet_connect__Note__c, tsanet_connect__tsaNetCaseId__c, tsanet_connect__tsaNetResponseId__c FROM tsanet_connect__TSANetResponses__r ORDER BY tsanet_connect__CreatedAt__c DESC)
                    FROM tsanet_connect__TSANetCase__c 
                    WHERE tsanet_connect__Case__r.CaseNumber =:caseId 
                    ORDER BY tsanet_connect__RequestDate__c DESC];
    }
    
    @AuraEnabled
    public static String getFormByCompanyId(String companyId, String mode, String token){

        String companiesEndpoint = EndpointManager.getCompaniesPath(companyId, mode);
        String accessToken = token != NULL ? ( 'Bearer ' + token ) : AuthManager.getBearerToken();
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(companiesEndpoint);
        req.setHeader('Authorization', accessToken);
        req.setMethod('GET');

        Http http = new Http();
        HTTPResponse res = http.send(req);
        System.debug(res.getBody());
        System.debug(res.getStatusCode());
        
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
        
        Http http = new Http();
        HTTPResponse res = http.send(req);
        System.debug(res.getBody());
        
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
        System.debug(res.getBody());
        System.debug(res.getStatusCode());

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
            getRelatedCollaborationCases(caseId, token);
		}

        Map<String, Object> response = (Map<String, Object>) System.JSON.deserializeUntyped(res.getBody());
        TSANetHelper.createCaseFeedItem(caseId, response);
             
        return res.getBody();
    }
    
    @AuraEnabled
    public static String approveIncomingRequest(String caseToken, String json, String token){
        
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
        System.debug(res.getBody());
        System.debug(res.getStatusCode());
        
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
            getRelatedCollaborationCases(null, token);
        }
        return res.getBody();
    }
    
    
    @AuraEnabled
    public static String rejectTSANetCase(String tsaNetCaseId, String json, String token){
        
        tsanet_connect__TSANetCase__c tsaNetCase = [SELECT Id, tsanet_connect__tsaNetCaseId__c, tsanet_connect__Token__c FROM tsanet_connect__TSANetCase__c WHERE Id =:tsaNetCaseId];
        
        String accessToken = token != NULL ? ( 'Bearer ' + token ) : AuthManager.getBearerToken();
        String rejectPath = EndpointManager.getEndpointWithToken(EndpointManager.reject, tsaNetCase.tsanet_connect__Token__c);
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(rejectPath);
        req.setHeader('Authorization', accessToken);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(json);
        
        Http http = new Http();
        HTTPResponse res = http.send(req);
        System.debug(res.getBody());
        System.debug(res.getStatusCode());
        
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
            getRelatedCollaborationCases(null, token);
        }
        
        return res.getBody();
    }
    
        
    @AuraEnabled
    public static String closeTSANetCase(String tsaNetCaseId, String token){
        
        tsanet_connect__TSANetCase__c tsaNetCase = [SELECT Id, tsanet_connect__Token__c, tsanet_connect__tsaNetCaseId__c FROM tsanet_connect__TSANetCase__c WHERE Id =:tsaNetCaseId];
        
        String accessToken = token != NULL ? ( 'Bearer ' + token ) : AuthManager.getBearerToken();
        String closePath = EndpointManager.getEndpointWithToken(EndpointManager.close, tsaNetCase.tsanet_connect__Token__c);
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(closePath);
        req.setHeader('Authorization', accessToken);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody('');
        
        Http http = new Http();
        HTTPResponse res = http.send(req);
        System.debug(res.getBody());
        System.debug(res.getStatusCode());
        
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
            getRelatedCollaborationCases(null, token);
        }
        
        return res.getBody();
    }
    
    @AuraEnabled
    public static String requestAdditionalInformation(String tsaNetCaseId, String json, String token){
        
        tsanet_connect__TSANetCase__c tsaNetCase = [SELECT Id, tsanet_connect__Token__c, tsanet_connect__tsaNetCaseId__c FROM tsanet_connect__TSANetCase__c WHERE Id =:tsaNetCaseId];
        
        String accessToken = token != NULL ? ( 'Bearer ' + token ) : AuthManager.getBearerToken();
        String requestAdditionalInfoPath = EndpointManager.getEndpointWithToken(EndpointManager.informationRequest, tsaNetCase.tsanet_connect__Token__c);
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(requestAdditionalInfoPath);
        req.setHeader('Authorization', accessToken);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(json);
        
        Http http = new Http();
        HTTPResponse res = http.send(req);
        System.debug(res.getBody());
        System.debug(res.getStatusCode());
        
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
            getRelatedCollaborationCases(null, token);
        }
        
        return res.getBody();
    }
    
    @AuraEnabled
    public static String sendAdditionalInformation(String tsaNetCaseId, String json, String token){
        
        tsanet_connect__TSANetCase__c tsaNetCase = [SELECT Id, tsanet_connect__Token__c, tsanet_connect__tsaNetCaseId__c FROM tsanet_connect__TSANetCase__c WHERE Id =:tsaNetCaseId];
        
        String accessToken = token != NULL ? ( 'Bearer ' + token ) : AuthManager.getBearerToken();
        String sendAdditionalInfoPath = EndpointManager.getEndpointWithToken(EndpointManager.informationResponse, tsaNetCase.tsanet_connect__Token__c);
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(sendAdditionalInfoPath);
        req.setHeader('Authorization', accessToken);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(json);
        
        Http http = new Http();
        HTTPResponse res = http.send(req);
        System.debug(res.getBody());
        System.debug(res.getStatusCode());
        
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
            getRelatedCollaborationCases(null, token);
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
        //req.setTimeout(120000);
        
        Http http = new Http();

        HTTPResponse res;
        //if(!Test.isRunningTest()){
             res = http.send(req);
            
            //HTTPResponse res = http.send(req);
            System.debug(res.getBody());
            
        	if(res.getStatusCode() != 200){
                ErrorManager.handleResponseErrors(res);
            }
        //}
        
        return res.getBody();
    }
    
    @AuraEnabled
    public static String sendAttachment(String token, List<Map<String, Object>> files){
        
        tsanet_connect__TSANetCase__c tsaNetCase = [SELECT Id FROM tsanet_connect__TSANetCase__c WHERE tsanet_connect__Token__c =:token];
        
        Id[] contentVersionIds = new Id[]{};
        for(Map<String, Object> fileData : files){
            String base64String = (String) fileData.get('base64');
            if(base64String == NULL){
                String fileId = (String) fileData.get('fileId');
                contentVersionIds.add(fileId);
            }
        }
        
        ContentVersion[] selectedContentVersions = [SELECT Id, Title, FileType, VersionData FROM ContentVersion WHERE Id IN:contentVersionIds];
        
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
            
            System.debug('base64String : ' + base64String);
            System.debug('fileName : ' + fileName);
            
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
        
        System.debug('STATUS: ' + res.getStatusCode());
        System.debug('BODY: ' + res.getBody());
        
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
        
        insert versions;
        
        Id[] versionIds = new Id[]{};
        for(ContentVersion version : versions){
			versionIds.add(version.Id);
        }
        
        ContentVersion[] contentVersions = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id IN:versionIds];
		
        ContentDocumentLink[] links = new ContentDocumentLink[]{};
        for(ContentVersion cv : contentVersions){
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.ContentDocumentId = cv.ContentDocumentId;
            cdl.LinkedEntityId = tsaNetCase.Id; 
            cdl.ShareType = 'V'; 
            cdl.Visibility = 'AllUsers';
            links.add(cdl);
        }
        
        insert links;
        
        return res.getBody();
    }
    
    @future(callout=true)
    public static void changeTSANetOwner(Id caseId, String token){
        tsanet_connect__TSANetCase__c caseRecord = [SELECT Id, tsanet_connect__Case__c, tsanet_connect__Token__c FROM tsanet_connect__TSANetCase__c WHERE Id =:caseId];
        
        String accessToken = token != NULL ? ( 'Bearer ' + token ) : AuthManager.getBearerToken();
        String noteEndpoint = EndpointManager.getEndpointWithToken(EndpointManager.updateCase, caseRecord.tsanet_connect__Token__c);

        Case sfCase = [SELECT Id, CaseNumber, OwnerId, Owner.Name, Owner.Phone, Owner.Email FROM Case WHERE Id =:caseRecord.tsanet_connect__Case__c];

        String json = '{"internalCaseNumber": "' + sfCase.CaseNumber + '","submitterContactDetails": {"name": "' + sfCase.Owner.Name + '","email": "' + sfCase.Owner.Email + '","phone": "' + sfCase.Owner.Phone + '"}}';
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(noteEndpoint);
        req.setHeader('Authorization', accessToken);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setTimeout(10000);
        req.setBody(json);
        
        Http http = new Http();
        HTTPResponse res = http.send(req);
        System.debug(res.getBody());
        
        if(res.getStatusCode() != 200){
            if(ErrorManager.isUnautorized(res.getBody())){
                String newAccessToken = TSANetService.getTSANetAccessToken();
                changeTSANetOwner(caseId, newAccessToken);
                CredentialManager.updateToken(newAccessToken);
            } else {
                ErrorManager.handleResponseErrors(res);
            }
        }  
        
        if(!Test.isRunningTest()){
            TSANetService.getRelatedCollaborationCases(null, token);
        }
    }
}