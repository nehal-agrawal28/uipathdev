public class Apex_Callouts {
	
    // Make API Callouts
    private static httpResponse makeCallout(String method, String endPoint, String body, Map<String, String> headers){
    	Http httpObj = new Http ();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(endPoint);
        request.setMethod(method);
		if (body != null) {
            request.setBody (body);
        }
        if (headers != null && headers.size () > 0) {
            for (String key : headers.keySet ()) {
                request.setHeader(key, headers.get(key));
            }
        }
        try{
            HttpResponse response = httpObj.send(request);
            return response;
        }catch (Exception e) { 
            system.debug('error in callout'+e); 
            return null;
        }
    }
    
    // Get values for Custom Settings and Get Access Token
    public static string getAccessToken(){
        Cloud_RPA_Settings__c crs = Cloud_RPA_Settings__c.getValues('Cloud_Rpa');
        if(crs != null){
            Map<String, String> headers = new Map<String, String>();
            headers.put('content-type', 'application/json');
            
            Map<String, String> body = new Map<String, String>();
            body.put('client_id', crs.Auth0_Client_ID__c);
            body.put('client_secret', crs.Auth0_Client_Secret__c);
            body.put('audience', crs.Audience__c);
            body.put('grant_type', 'client_credentials');
            httpResponse res = new httpResponse();
            res = makeCallout('POST', crs.Auth0_Domain__c+'/oauth/token', json.serialize(body), headers);
            map<String, Object> resMap = new map<String, Object>();
            resMap = (Map<String, Object>)json.deserializeUntyped(res.getBody());
            if(resMap.containsKey('access_token')){
            	return string.valueof(resMap.get('access_token'));
            }else{
               	return null;
            }
        }
        return null;
    }
    
    
    public static cloudRPAValidated validateSiteName(string accountName){
        Map<String, String> headers = new Map<String, String>();
        headers.put('authorization', 'Bearer '+getAccessToken()); 
        headers.put('content-type', 'application/json');
		
        Cloud_RPA_Settings__c crs = Cloud_RPA_Settings__c.getValues('Cloud_Rpa');
        
        String endPoint = crs.Service_Endpoint__c;// https://platform.uipath.com/discovery/account/VARIABLE1
        endPoint = endPoint.replace('VARIABLE1', accountName);
        
		httpResponse res = new httpResponse();
        
        res = makeCallout('GET', endPoint , null, headers); 
        system.debug('res.getBody()'+ res.getBody());
        map<String, Object> resMap = new map<String, Object>();
        resMap = (Map<String, Object>)json.deserializeUntyped(res.getBody());
        cloudRPAValidated crv = new cloudRPAValidated();
        if(resMap.containsKey('organizationId')){
            crv.validated = true;
            crv.email = string.valueOf(resMap.get('userEmail'));
            system.debug(crv);
            return crv;
        }else {
            system.debug(crv);
            return crv;
        }
    }
    public class cloudRPAValidated{
        @AuraEnabled
        public string email {get;set;}
        @AuraEnabled
        public boolean validated {get;set;}
        
        public cloudRPAValidated(){
            email = null;
            validated = false;
        } 
    }

}