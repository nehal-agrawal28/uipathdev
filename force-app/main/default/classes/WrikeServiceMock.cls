@isTest
global class WrikeServiceMock implements HttpCalloutMock {
	global httpResponse respond(HTTPrequest req) {
        //System.assertEquals('http://sfdc-wrike-uat.eastus.cloudapp.azure.com', req.getEndpoint());
        //System.assertEquals('POST', req.getMethod());
        
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setStatusCode(200);
        res.setStatus('OK');
        return res;
    }
}