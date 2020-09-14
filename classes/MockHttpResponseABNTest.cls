/*
* @author:              Sidney Garcia
* @description:         HttpCalloutMock Class for NZBN web service callouts
*/
@isTest
global class MockHttpResponseABNTest implements HttpCalloutMock {
    // Implement this interface method
    global HTTPResponse respond(HTTPRequest req) {
        // Optionally, only send a mock response for a specific endpoint
        // and method.
        //System.assertEquals('https://sandbox.api.business.govt.nz/services/v3/nzbn/entities?search-term=Test', req.getEndpoint());
        System.assertEquals('GET', req.getMethod());
        
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody(CONSTANTS.MOCK_HTTP_RESPONSE_BODY_ABN);
        res.setStatusCode(200);
        res.setStatus(CONSTANTS.SUCCESS);
        
        
        
        return res;
    }
}