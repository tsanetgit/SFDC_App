/** Mock HTTP response generator for testing callouts. */
@IsTest

public class MockHttpResponseGenerator implements HttpCalloutMock {
    /** HTTP status code to return. */
    public Integer code;
    /** Response body string to return. */
    public String body;
    /** Response body as a Blob. */
    public Blob bodyAsBlob;
    /** HTTP status text to return. */
    public String status;
    /** Response headers to include. */
    public Map<String, String> headers;

    /** Default constructor. */
    public MockHttpResponseGenerator(){
        // Default constructor
    }
    /**
     * Constructs a mock with the given status code, body, and headers.
     * @param code the HTTP status code
     * @param body the response body
     * @param headers map of response headers
     */
    public MockHttpResponseGenerator(Integer code, String body,
                                     Map<String, String> headers) {
                                         this.code = code;
                                         this.body = body;
                                         this.headers = headers;
    }

    /**
     * Returns a fabricated HTTP response for the given request.
     * @param req the outbound HTTP request
     * @return the mock HTTP response
     */
    public HTTPResponse respond(HTTPRequest req) {
        // Create a fake response
        HttpResponse res = new HttpResponse();
        if(headers != null){
            for(STRING key : headers.keySet()) {
                res.setHeader(key, headers.get(key));
            }
        }
        res.setBody(body);

        res.setStatusCode(code);

        return res;
    }
}