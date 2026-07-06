/** Shared HTTP callout utility with automatic 401 retry and token refresh. */
public with sharing class HttpClient {

    private static final String AUTH_HEADER = 'Authorization';
    private static final String CONTENT_TYPE_HEADER = 'Content-Type';
    private static final String CONTENT_TYPE_JSON = 'application/json';
    private static final String BEARER_PREFIX = 'Bearer ';

    /**
     * Sends an HTTP GET request to the specified endpoint.
     * @param endpoint the URL to call
     * @param token the access token for authorization
     * @return the HTTP response
     */
    public static HttpResponse sendGet(String endpoint, String token) {
        return send('GET', endpoint, token, null, TSANetConstants.DEFAULT_TIMEOUT);
    }

    /**
     * Sends an HTTP POST request with a JSON body.
     * @param endpoint the URL to call
     * @param token the access token for authorization
     * @param body the JSON request body
     * @return the HTTP response
     */
    public static HttpResponse sendPost(String endpoint, String token, String body) {
        return send('POST', endpoint, token, body, TSANetConstants.DEFAULT_TIMEOUT);
    }

    /**
     * Sends an HTTP PATCH request with a JSON body.
     * @param endpoint the URL to call
     * @param token the access token for authorization
     * @param body the JSON request body
     * @return the HTTP response
     */
    public static HttpResponse sendPatch(String endpoint, String token, String body) {
        return send('PATCH', endpoint, token, body, TSANetConstants.DEFAULT_TIMEOUT);
    }

    /**
     * Sends an HTTP request with a custom method and timeout.
     * @param method the HTTP method (GET, POST, PATCH, etc.)
     * @param endpoint the URL to call
     * @param token the access token for authorization
     * @param body the JSON request body
     * @param timeout the request timeout in milliseconds
     * @return the HTTP response
     */
    public static HttpResponse sendWithTimeout(String method, String endpoint, String token, String body, Integer timeout) {
        return send(method, endpoint, token, body, timeout);
    }

    /**
     * Builds, sends, and validates an HTTP request.
     * On 401 (invalid token) automatically refreshes and retries once.
     * @param method HTTP method (GET, POST, PATCH)
     * @param endpoint target URL
     * @param token OAuth bearer token
     * @param body request body (may be null)
     * @param timeout request timeout in milliseconds
     * @return the HTTP response
     */
    private static HttpResponse send(String method, String endpoint, String token, String body, Integer timeout) {
        HttpRequest req = buildRequest(method, endpoint, token, body, timeout);
        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() != TSANetConstants.SUCCESS_CODE && res.getStatusCode() != 204) {
            if (ErrorManager.isUnauthorized(res.getBody())) {
                AuthManager.AccessTokenResponse loginResponse = TSANetService.login();
                String newToken = loginResponse != null ? loginResponse.accessToken : null;
                req = buildRequest(method, endpoint, newToken, body, timeout);
                res = http.send(req);
                if (String.isNotBlank(newToken)) {
                    TokenManager.updateToken(newToken, loginResponse.expiresIn);
                }
            }

            if (res.getStatusCode() != TSANetConstants.SUCCESS_CODE && res.getStatusCode() != 204) {
                ErrorManager.handleResponseErrors(res);
            }
        }

        TokenManager.commitTokenIfPending();
        return res;
    }

    private static HttpRequest buildRequest(String method, String endpoint, String token, String body, Integer timeout) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setHeader(AUTH_HEADER, resolveToken(token));
        req.setMethod(method);
        req.setHeader(CONTENT_TYPE_HEADER, CONTENT_TYPE_JSON);
        req.setTimeout(timeout);

        if (body != null) {
            req.setBody(body);
        }
        return req;
    }

    private static String resolveToken(String token) {
        return token != null ? (BEARER_PREFIX + token) : AuthManager.getBearerToken();
    }
}
