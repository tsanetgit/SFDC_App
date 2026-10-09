/**
 * Service layer for TSANet Connect API operations over a Named Credential.
 *
 * Mirrors TSANetService, but Salesforce supplies the authorization from the External
 * Credential, so the access-token parameters of TSANetService are omitted here and no
 * login, token storage or 401 retry takes place. TSANetService routes to this class
 * when the primary credential uses the OAuth 2.0 auth type.
 */
public with sharing class TSANetAPIService {

    /**
     * Retrieves the current company information from the TSANet API.
     * @return deserialised TSANetCompanyInfo
     */
    public static TSANetCompanyInfo getCompanyInformation(){
        HttpResponse res = NamedCredentialHttpClient.sendGet(buildEndpoint(EndpointManager.me_path));
        return (TSANetCompanyInfo) System.JSON.deserialize(res.getBody(), TSANetCompanyInfo.class);
    }

    /**
     * Creates a note on a TSANet collaboration case via the API.
     * @param caseToken unique token of the TSANet case
     * @param json serialised note payload
     * @return raw API response body
     */
    public static String createTSANetNote(String caseToken, String json){
        HttpResponse res = NamedCredentialHttpClient.sendPost(buildEndpointWithToken(EndpointManager.notes, caseToken), json);

        try {
            tsanetconnect__TSANetNote__c noteRecord = ParserManager.parseTSANetNote(res.getBody());
            Database.upsert(noteRecord, tsanetconnect__TSANetNote__c.tsanetconnect__Token__c, false, AccessLevel.USER_MODE);
        } catch(Exception e) {
            ErrorLogger.logError(e, 'CREATE_TSANET_NOTE_UPSERT', new Map<String, String>{ 'caseToken' => caseToken, 'response' => res.getBody() });
        }

        TSANetCaseRefreshService.enqueueByToken(caseToken);

        return res.getBody();
    }

    /**
     * Fetches collaboration cases from the TSANet API and upserts them locally.
     * @param caseId Salesforce Case Id to scope results (nullable for all)
     * @return list of related TSANetCase__c records for the given Case
     */
    public static tsanetconnect__TSANetCase__c[] getRelatedCollaborationCases(String caseId){
        String caseNumber = null;
        if(caseId != null){
            Case caseRecord = CaseSelector.getById(caseId);
            caseNumber = caseRecord.CaseNumber;
        }

        HttpResponse res = NamedCredentialHttpClient.sendGet(getCollaborationCasesPath(caseNumber));

        TSANetData data = ParserManager.parseTSANetCases(res.getBody(), caseId);
        TSANetService.upsertTSANetData(data);

        if(caseId != null){
            return TSANetCaseSelector.getDetailWithResponsesByCaseId(caseId);
        }
        return new tsanetconnect__TSANetCase__c[]{};
    }

    /**
     * Fetches a single collaboration request from the TSANet API.
     * @param caseToken the collaboration request token
     * @return raw API response body for the collaboration request
     */
    public static String getCollaborationCaseByToken(String caseToken){
        return NamedCredentialHttpClient.sendGet(buildEndpointWithToken(EndpointManager.updateCase, caseToken)).getBody();
    }

    /**
     * Fetches a page of collaboration cases from the TSANet API.
     * @param caseNumber internal case number to filter by, or null for all
     * @param page page number to retrieve
     * @return raw API response body with the paginated payload
     */
    public static String getCollaborationCasesPage(String caseNumber, Integer page){
        // V2 paginates by default, so the V1 paginated=true switch is gone.
        String path = buildCasesEndpoint(EndpointManager.cases_paged_path, caseNumber);
        path += (caseNumber != null ? '&' : '?');
        path += 'page=' + page + '&size=' + TSANetConstants.PAGE_SIZE;

        return NamedCredentialHttpClient.sendGet(path).getBody();
    }

    /**
     * Retrieves the collaboration form definition for a given company.
     * @param companyId TSANet company identifier
     * @param mode form mode (e.g. "company" or "department")
     * @return raw API response body containing the form definition
     */
    public static String getFormByCompanyId(String companyId, String mode){
        String path = mode == 'company' ? EndpointManager.get_form_company_path : EndpointManager.get_form_department_path;
        HttpResponse res = NamedCredentialHttpClient.sendGet(buildEndpoint(path + companyId));
        return res.getBody();
    }

    /**
     * Searches TSANet companies by name.
     * @param companyName search term for the company name
     * @return raw API response body with matching companies
     */
    public static String getCompaniesByName(String companyName){
        String encodedName = EncodingUtil.urlEncode(companyName, 'UTF-8');
        if(encodedName.contains('+')){
            encodedName = encodedName.replace('+', '%20');
        }
        HttpResponse res = NamedCredentialHttpClient.sendGet(buildEndpoint(EndpointManager.companies_path + encodedName));
        return res.getBody();
    }

    /**
     * Submits a new collaboration case to the TSANet API.
     * @param caseId Salesforce Case Id linked to the collaboration
     * @param json serialised case payload
     * @return raw API response body
     */
    public static String createCollaborationCase(Id caseId, String json){
        HttpResponse res = NamedCredentialHttpClient.sendPost(buildEndpoint(EndpointManager.case_path), json);

        TSANetCaseRefreshService.enqueueFromResponse(res.getBody(), caseId);

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
     * @return raw API response body
     */
    public static String approveIncomingRequest(String caseToken, String json){
        HttpResponse res = NamedCredentialHttpClient.sendPost(buildEndpointWithToken(EndpointManager.approve, caseToken), json);

        TSANetCaseRefreshService.enqueueByToken(caseToken);
        return res.getBody();
    }

    /**
     * Rejects a TSANet collaboration case via the API.
     * @param tsaNetCaseId Id of the TSANetCase__c record
     * @param json serialised rejection payload
     * @return raw API response body
     */
    public static String rejectTSANetCase(String tsaNetCaseId, String json){
        tsanetconnect__TSANetCase__c tsaNetCase = TSANetCaseSelector.getById(tsaNetCaseId);
        HttpResponse res = NamedCredentialHttpClient.sendPost(buildEndpointWithToken(EndpointManager.reject, tsaNetCase.tsanetconnect__Token__c), json);

        refreshCase(tsaNetCase);
        return res.getBody();
    }

    /**
     * Closes a TSANet collaboration case via the API.
     * @param tsaNetCaseId Id of the TSANetCase__c record
     * @return raw API response body
     */
    public static String closeTSANetCase(String tsaNetCaseId){
        tsanetconnect__TSANetCase__c tsaNetCase = TSANetCaseSelector.getById(tsaNetCaseId);
        HttpResponse res = NamedCredentialHttpClient.sendPost(buildEndpointWithToken(EndpointManager.close, tsaNetCase.tsanetconnect__Token__c), '');

        refreshCase(tsaNetCase);
        return res.getBody();
    }

    /**
     * Sends an additional-information request on a TSANet case.
     * @param tsaNetCaseId Id of the TSANetCase__c record
     * @param json serialised information-request payload
     * @return raw API response body
     */
    public static String requestAdditionalInformation(String tsaNetCaseId, String json){
        tsanetconnect__TSANetCase__c tsaNetCase = TSANetCaseSelector.getById(tsaNetCaseId);
        HttpResponse res = NamedCredentialHttpClient.sendPost(buildEndpointWithToken(EndpointManager.informationRequest, tsaNetCase.tsanetconnect__Token__c), json);

        refreshCase(tsaNetCase);
        return res.getBody();
    }

    /**
     * Sends an additional-information response on a TSANet case.
     * @param tsaNetCaseId Id of the TSANetCase__c record
     * @param json serialised information-response payload
     * @return raw API response body
     */
    public static String sendAdditionalInformation(String tsaNetCaseId, String json){
        tsanetconnect__TSANetCase__c tsaNetCase = TSANetCaseSelector.getById(tsaNetCaseId);
        HttpResponse res = NamedCredentialHttpClient.sendPost(buildEndpointWithToken(EndpointManager.informationResponse, tsaNetCase.tsanetconnect__Token__c), json);

        refreshCase(tsaNetCase);
        return res.getBody();
    }

    /**
     * Retrieves the attachment configuration for a TSANet case.
     * @param caseToken unique case token
     * @return raw API response body with attachment config
     */
    public static String getAttachmentConfig(String caseToken){
        String path = EndpointManager.case_path + '/' + caseToken + '/attachments/config';
        HttpResponse res = NamedCredentialHttpClient.sendGet(buildEndpoint(path));
        return res.getBody();
    }

    /**
     * Uploads file attachments to a TSANet case and links them locally.
     * @param caseToken unique case token
     * @param files list of file-data maps (base64, filename, fileId)
     * @return raw API response body with upload results
     */
    public static String sendAttachment(String caseToken, List<Map<String, Object>> files){
        if (caseToken == null) {
            throw new TSANetService.TSANetServiceException('A case token is required to upload attachments.');
        }
        if (!AttachmentUploadHelper.canUpload()) {
            throw new TSANetService.TSANetServiceException('Insufficient permissions to upload attachments.');
        }

        tsanetconnect__TSANetCase__c tsaNetCase = TSANetCaseSelector.getIdByToken(caseToken);
        List<Map<String, Object>> newFiles = AttachmentUploadHelper.prepareFiles(files);
        AttachmentUploadHelper.MultipartPayload payload = AttachmentUploadHelper.buildBody(newFiles);

        HttpRequest req = new HttpRequest();
        req.setEndpoint(buildEndpoint(EndpointManager.case_path + '/' + caseToken + '/attachments'));
        req.setMethod('POST');
        req.setHeader('Accept', 'application/problem+json');
        req.setHeader('Content-Length', String.valueOf(payload.body.length()));
        req.setHeader('Content-Type', 'multipart/form-data; boundary=' + payload.boundary);
        req.setHeader('boundary', payload.boundary);
        req.setHeader('Accept', '*/*');
        req.setBody(payload.body);
        req.setTimeout(TSANetConstants.DEFAULT_TIMEOUT);

        Http http = new Http();
        HttpResponse res = http.send(req);

        AttachmentUploadHelper.linkFiles(res.getBody(), newFiles, tsaNetCase.Id);

        return res.getBody();
    }

    /**
     * Sends an owner-change update to the TSANet API for an outbound case.
     * Not annotated with @Future: it is called from the future context of TSANetService.
     * @param caseId Id of the TSANetCase__c record
     */
    public static void changeTSANetOwner(Id caseId){
        tsanetconnect__TSANetCase__c caseRecord = TSANetCaseSelector.getById(caseId);
        Case sfCase = CaseSelector.getOwnerDetailById(caseRecord.tsanetconnect__Case__c);

        Map<String, Object> payload = new Map<String, Object>{
            TSANetConstants.KEY_INTERNAL_CASE_NUMBER => sfCase.CaseNumber,
            TSANetConstants.KEY_SUBMITTER_CONTACT_DETAILS => new Map<String, Object>{
                TSANetConstants.KEY_NAME => sfCase.Owner.Name,
                TSANetConstants.KEY_EMAIL => sfCase.Owner.Email,
                TSANetConstants.KEY_PHONE => sfCase.Owner.Phone
            }
        };

        try {
            NamedCredentialHttpClient.sendWithTimeout(
                'PATCH',
                buildEndpointWithToken(EndpointManager.updateCase, caseRecord.tsanetconnect__Token__c),
                JSON.serialize(payload),
                TSANetConstants.SHORT_TIMEOUT
            );
            refreshCase(caseRecord);
        } catch(Exception e){
            ErrorLogger.logError(e, 'CHANGE_TSANET_OWNER', new Map<String, String>{ 'caseId' => sfCase?.Id, 'tsaNetCaseId' => caseRecord?.Id });
        }
    }

    /**
     * Updates an approved inbound collaboration request via PATCH /approval (engineer + case details).
     * Not annotated with @Future: it is called from the future context of TSANetService.
     * @param tsaNetCaseId tsanetconnect__TSANetCase__c Id
     */
    public static void changeTSANetResponse(Id tsaNetCaseId){
        tsanetconnect__TSANetCase__c caseRecord = TSANetCaseSelector.getById(tsaNetCaseId);
        Case sfCase = CaseSelector.getFullDetailById(caseRecord.tsanetconnect__Case__c);

        Map<String, Object> payload = new Map<String, Object>{
            TSANetConstants.KEY_CASE_NUMBER => sfCase.CaseNumber,
            TSANetConstants.KEY_ENGINEER_NAME => sfCase.Owner != null ? sfCase.Owner.Name : '',
            TSANetConstants.KEY_ENGINEER_PHONE => sfCase.Owner != null ? sfCase.Owner.Phone : '',
            TSANetConstants.KEY_ENGINEER_EMAIL => sfCase.Owner != null ? sfCase.Owner.Email : '',
            TSANetConstants.KEY_NEXT_STEPS => ''
        };

        try {
            NamedCredentialHttpClient.sendWithTimeout(
                'PATCH',
                buildEndpointWithToken(EndpointManager.approve, caseRecord.tsanetconnect__Token__c),
                JSON.serialize(payload),
                TSANetConstants.SHORT_TIMEOUT
            );
            refreshCase(caseRecord);
        } catch(Exception e){
            ErrorLogger.logError(e, 'CHANGE_TSANET_RESPONSE', new Map<String, String>{ 'caseId' => sfCase?.Id, 'tsaNetCaseId' => caseRecord?.Id });
        }
    }

    /** Queues a background refresh for the single collaboration request just acted on. */
    private static void refreshCase(tsanetconnect__TSANetCase__c tsaNetCase){
        TSANetCaseRefreshService.enqueueByToken(tsaNetCase.tsanetconnect__Token__c);
    }

    /** Returns the collaboration cases list endpoint, optionally filtered by case number. */
    private static String getCollaborationCasesPath(String caseNumber){
        return buildCasesEndpoint(EndpointManager.cases_list_path, caseNumber);
    }

    /**
     * Prefixes a collaboration cases path with the callout base and applies the
     * optional internal case number filter, shared by the list and paged reads.
     * @param path the collaboration cases API path
     * @param caseNumber internal case number to filter by, or null for all
     * @return the full callout endpoint
     */
    private static String buildCasesEndpoint(String path, String caseNumber){
        String endpoint = buildEndpoint(path);
        if(caseNumber != NULL){
            endpoint += ( '?internalCaseNumber=' + caseNumber );
        }
        return endpoint;
    }

    /**
     * Prefixes an API path with the Named Credential callout base. Resolving through the
     * router means a missing Named Credential raises a readable configuration error instead
     * of producing a "null/v1/..." endpoint and an opaque callout failure.
     */
    private static String buildEndpoint(String path){
        return TSANetHttpRouter.getEndpoint(path);
    }

    /** Prefixes an API path with the callout base and replaces its {token} placeholder. */
    private static String buildEndpointWithToken(String template, String token){
        if(String.isBlank(template) || String.isBlank(token)) {
            return template;
        }
        return buildEndpoint(template.replace('{token}', token));
    }
}
