public with sharing class EndpointManager {
    
    public static String domain = getDomain();
    
    public static String login_path = '/v1/login';
    public static String case_path = '/v1/collaboration-requests';
    public static String companies_path = '/v1/partners/';
    public static String get_form_company_path = '/v1/forms/company/';
    public static String get_form_department_path = '/v1/forms/department/';
    public static String approve = '/v1/collaboration-requests/{token}/approval';
    public static String reject = '/v1/collaboration-requests/{token}/rejection';
    public static String updateCase = '/v1/collaboration-requests/{token}';
    public static String informationRequest = '/v1/collaboration-requests/{token}/information-request';
    public static String informationResponse = '/v1/collaboration-requests/{token}/information-response';
    public static String close = '/v1/collaboration-requests/{token}/closure';
    public static String notes = '/v1/collaboration-requests/{token}/notes';
    public static String me_path = '/v1/me';

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
    
    public static String getDomain() {
        tsanetconnect__TSANet_Credentials__c creds = CredentialManager.getCredentials();
        String environment = creds.tsanetconnect__Environment__c + '_env';
        tsanetconnect__TSANetEnvironment__mdt[] environments =[SELECT Id, tsanetconnect__Endpoint__c FROM tsanetconnect__TSANetEnvironment__mdt WHERE DeveloperName =:environment WITH SECURITY_ENFORCED ];
        
        if(environments.size() > 0){
            return environments[0].tsanetconnect__Endpoint__c;
        } else {
            return null;
        }
    }
    
    public static String getTSANetCompanyPath(){
        return domain + me_path;
    }
    
    public static String getAuthPath(){
        return domain + login_path;
    }
    
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
    
    public static String getCompaniesPath(String companyName){
        companyName = EncodingUtil.urlEncode(companyName, 'UTF-8');
        if(companyName.contains('+')){
            companyName = companyName.replace('+', '%20');
        }
        return domain + companies_path + companyName;
    }
    
    public static String getCreateCollaborationCasePath(){
        return domain + case_path;
    }
    
    public static String getCollaborationCasesPath(String caseId){
        String path = domain + case_path;
        if(caseId != NULL){
            path += ( '?internalCaseNumber=' + caseId );
        }
        return path;
    }
}