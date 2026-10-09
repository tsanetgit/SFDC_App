/**
 * HTTP callout utility for Named Credential endpoints. Salesforce injects the
 * authorization header from the External Credential, so there is no bearer token,
 * no login call, and no 401 refresh-and-retry here.
 */
public with sharing class NamedCredentialHttpClient {

    private static final String CONTENT_TYPE_HEADER = 'Content-Type';
    private static final String CONTENT_TYPE_JSON = 'application/json';
    private static final Integer NO_CONTENT_CODE = 204;

    /**
     * Sends an HTTP GET request to the specified callout endpoint.
     * @param endpoint the callout URL
     * @return the HTTP response
     */
    public static HttpResponse sendGet(String endpoint) {
        return send('GET', endpoint, null, TSANetConstants.DEFAULT_TIMEOUT);
    }

    /**
     * Sends an HTTP POST request with a JSON body.
     * @param endpoint the callout URL
     * @param body the JSON request body
     * @return the HTTP response
     */
    public static HttpResponse sendPost(String endpoint, String body) {
        return send('POST', endpoint, body, TSANetConstants.DEFAULT_TIMEOUT);
    }

    /**
     * Sends an HTTP PATCH request with a JSON body.
     * @param endpoint the callout URL
     * @param body the JSON request body
     * @return the HTTP response
     */
    public static HttpResponse sendPatch(String endpoint, String body) {
        return send('PATCH', endpoint, body, TSANetConstants.DEFAULT_TIMEOUT);
    }

    /**
     * Sends an HTTP request with a custom method and timeout.
     * @param method the HTTP method (GET, POST, PATCH, etc.)
     * @param endpoint the callout URL
     * @param body the JSON request body
     * @param timeout the request timeout in milliseconds
     * @return the HTTP response
     */
    public static HttpResponse sendWithTimeout(String method, String endpoint, String body, Integer timeout) {
        return send(method, endpoint, body, timeout);
    }

    /**
     * Builds, sends, and validates a Named Credential request.
     * @param method HTTP method (GET, POST, PATCH)
     * @param endpoint callout URL
     * @param body request body (may be null)
     * @param timeout request timeout in milliseconds
     * @return the HTTP response
     */
    private static HttpResponse send(String method, String endpoint, String body, Integer timeout) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod(method);
        req.setHeader(CONTENT_TYPE_HEADER, CONTENT_TYPE_JSON);
        req.setTimeout(timeout);

        if (body != null) {
            req.setBody(body);
        }

        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() != TSANetConstants.SUCCESS_CODE && res.getStatusCode() != NO_CONTENT_CODE) {
            ErrorManager.handleResponseErrors(res);
        }

        return res;
    }
}
