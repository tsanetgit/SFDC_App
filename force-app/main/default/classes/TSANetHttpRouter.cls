/**
 * Resolves TSANet API endpoints against the Named Credential of the primary credential
 * and sends them through NamedCredentialHttpClient. Salesforce injects the authorization
 * from the External Credential, so no token is ever handled here.
 */
public with sharing class TSANetHttpRouter {

    /** Raised when no Named Credential is configured on the primary credential. */
    public class TSANetHttpRouterException extends Exception {}

    /**
     * Returns the callout base of the primary credential's Named Credential.
     * @return the callout base, for example "callout:tsanetconnect__TSANetAPI"
     */
    public static String getBaseUrl(){
        String base = AuthModeManager.getCalloutBase();
        if(String.isBlank(base)){
            throw new TSANetHttpRouterException(TSANetConstants.NOT_CONFIGURED_ERROR);
        }
        return base;
    }

    /**
     * Prefixes an API path with the callout base.
     * @param path the API path, for example /v2/webhooks
     * @return the full callout endpoint
     */
    public static String getEndpoint(String path){
        return getBaseUrl() + path;
    }

    /**
     * Sends an HTTP GET request through the Named Credential.
     * @param endpoint the callout URL
     * @return the HTTP response
     */
    public static HttpResponse sendGet(String endpoint){
        return NamedCredentialHttpClient.sendGet(endpoint);
    }

    /**
     * Sends an HTTP POST request through the Named Credential.
     * @param endpoint the callout URL
     * @param body the JSON request body
     * @return the HTTP response
     */
    public static HttpResponse sendPost(String endpoint, String body){
        return NamedCredentialHttpClient.sendPost(endpoint, body);
    }

    /**
     * Sends an HTTP request with a custom method and timeout through the Named Credential.
     * @param method the HTTP method
     * @param endpoint the callout URL
     * @param body the JSON request body
     * @param timeout the request timeout in milliseconds
     * @return the HTTP response
     */
    public static HttpResponse sendWithTimeout(String method, String endpoint, String body, Integer timeout){
        return NamedCredentialHttpClient.sendWithTimeout(method, endpoint, body, timeout);
    }
}
