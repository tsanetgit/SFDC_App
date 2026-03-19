@isTest
public class MockHttpResponseGenerator implements HttpCalloutMock {
    public Integer code;
    public String body;
    public Blob bodyAsBlob;
    public String status;
    public Map<String, String> headers;
    
    public MockHttpResponseGenerator(){}
    public MockHttpResponseGenerator(Integer code, String body,
                                     Map<String, String> headers) {
                                         this.code = code;
                                         this.body = body;
                                         this.headers = headers;
    }

    //Implement this interface method
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