/** Builds and manages TSANet API endpoint URLs. */
public with sharing class EndpointManager {

    /** Base domain URL resolved from credentials environment. */
    public static String domain = getDomain();

    /** Login API path. */
    public static String login_path = '/v1/login';
    /** Collaboration requests API path. */
    public static String case_path = '/v1/collaboration-requests';
    /** Partners search API path. */
    public static String companies_path = '/v1/partners/';
    /** Company-level form API path. */
    public static String get_form_company_path = '/v1/forms/company/';
    /** Department-level form API path. */
    public static String get_form_department_path = '/v1/forms/department/';
    /** Approval endpoint template. */
    public static String approve = '/v1/collaboration-requests/{token}/approval';
    /** Rejection endpoint template. */
    public static String reject = '/v1/collaboration-requests/{token}/rejection';
    /** Update collaboration request endpoint template. */
    public static String updateCase = '/v1/collaboration-requests/{token}';
    /** Information request endpoint template. */
    public static String informationRequest = '/v1/collaboration-requests/{token}/information-request';
    /** Information response endpoint template. */
    public static String informationResponse = '/v1/collaboration-requests/{token}/information-response';
    /** Closure endpoint template. */
    public static String close = '/v1/collaboration-requests/{token}/closure';
    /** Notes endpoint template. */
    public static String notes = '/v1/collaboration-requests/{token}/notes';
    /** Current user info API path. */
    public static String me_path = '/v1/me';
    /** Webhook subscriptions API path. */
    public static String webhooks_path = '/v1/webhooks';
    /** Webhook by ID template. */
    public static String webhook_by_id = '/v1/webhooks/{id}';
    /** Webhook delivery log template. */
    public static String webhook_deliveries = '/v1/webhooks/{id}/deliveries';

    /**
     * Returns endpoint with the {token} placeholder replaced by the given token.
     * @param endpoint endpoint string containing {token}
     * @param token value to replace {token} with
     * @return endpoint with token replaced
     */
    public static String getEndpointWithToken(String endpoint, String token){
        if(String.isBlank(endpoint) || String.isBlank(token)) {
            return endpoint;
        }
        String refactoredEndpoint = endpoint.replace('{token}', token);

        return domain + refactoredEndpoint;
    }

    /**
     * Resolves the API base domain from the credentials environment.
     * @return base domain URL or null if not found
     */
    public static String getDomain() {
        tsanetconnect__TSANet_Credentials__c creds = CredentialManager.getCredentials();
        String environment = creds.tsanetconnect__Environment__c + '_env';
        tsanetconnect__TSANetEnvironment__mdt[] environments =[SELECT Id, tsanetconnect__Endpoint__c FROM tsanetconnect__TSANetEnvironment__mdt WHERE DeveloperName =:environment WITH USER_MODE ];

        if(environments.size() > 0){
            return environments[0].tsanetconnect__Endpoint__c;
        } else {
            return null;
        }
    }

    /**
     * Returns the full URL for the current-user company endpoint.
     * @return company info endpoint URL
     */
    public static String getTSANetCompanyPath(){
        return domain + me_path;
    }

    /**
     * Returns the full URL for the login endpoint.
     * @return authentication endpoint URL
     */
    public static String getAuthPath(){
        return domain + login_path;
    }

    /**
     * Builds the form endpoint URL for a company or department.
     * @param companyId the company identifier
     * @param mode "company" or "department"
     * @return form endpoint URL
     */
    public static String getCompaniesPath(String companyId, String mode){
        String endpoint = domain;
        if(mode == 'company'){
            endpoint += get_form_company_path;
        } else {
            endpoint += get_form_department_path;
        }
        endpoint += companyId;
        return endpoint;
    }

    /**
     * Builds the partner search URL for a company name.
     * @param companyName the company name to search for
     * @return URL-encoded partner search endpoint URL
     */
    public static String getCompaniesPath(String companyName){
        companyName = EncodingUtil.urlEncode(companyName, 'UTF-8');
        if(companyName.contains('+')){
            companyName = companyName.replace('+', '%20');
        }
        return domain + companies_path + companyName;
    }

    /**
     * Returns the full URL for creating collaboration requests.
     * @return collaboration case creation endpoint URL
     */
    public static String getCreateCollaborationCasePath(){
        return domain + case_path;
    }

    /**
     * Returns the collaboration cases endpoint, optionally filtered by case number.
     * @param caseId internal case number to filter by, or null for all
     * @return collaboration cases endpoint URL
     */
    public static String getCollaborationCasesPath(String caseId){
        String path = domain + case_path;
        if(caseId != NULL){
            path += ( '?internalCaseNumber=' + caseId );
        }
        return path;
    }

    /**
     * Returns the full URL for the webhooks endpoint.
     * @return webhook subscriptions endpoint URL
     */
    public static String getWebhooksPath(){
        return domain + webhooks_path;
    }

    /**
     * Returns the webhook endpoint with {id} replaced by the given webhookId.
     * @param template endpoint template containing {id}
     * @param webhookId webhook identifier to substitute
     * @return resolved webhook endpoint URL
     */
    public static String getWebhookPathById(String template, Integer webhookId){
        if(String.isBlank(template) || webhookId == null) {
            return template;
        }
        return domain + template.replace('{id}', String.valueOf(webhookId));
    }
}