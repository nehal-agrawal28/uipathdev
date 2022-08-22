/*
* Developer : Maanas 
* Class: Ui_PathValidateLicenseCode
* Test Class: 
* Description: AAPI logic for portal licencse code valdiation
* 
*/
public class Ui_PathValidateLicenseCode {
    
    public static Boon_API_Credentials__mdt APICredentials = [SELECT Id, OauthTokenURL__c,Audience__c,Client_Id__c,Client_Secret__c,RestAPIURL__c FROM Boon_API_Credentials__mdt LIMIT 1];
    public static final string Application_Json='application/json';
    public static final string Content_Type='Content-Type';
    public static final string GET ='GET';
    public static final string POST = 'POST';
    
    public static String validateLicenseCode(String licenseCode){
        
        String APIURL = APICredentials.RestAPIURL__c;
        String accessToken = getAccessToken();
        String restAPIURL = APIURL + licenseCode;
        HttpRequest httpRequest = new HttpRequest();
        httpRequest.setMethod(GET);
        httpRequest.setHeader(Content_Type, Application_Json);
        httpRequest.setHeader('Authorization', 'Bearer '+accessToken);	
        httpRequest.setEndpoint(restAPIURL);
        
        try {
            Http http = new Http();
            HttpResponse httpResponse = http.send(httpRequest);
            if(httpResponse.getStatusCode() == 200)
            	return httpResponse.getBody();
            else
                return ('Status Code' + httpResponse.getStatusCode() + 'Respnse Body : '+ httpResponse.getBody());
        } catch( System.Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        
        
    }
    
    
    public static String getAccessToken(){
        
        
        String restAPIURL1 = APICredentials.OauthTokenURL__c;
        String jsonBody = generateJsonStringBoon();
        HttpRequest httpRequest = new HttpRequest();
        httpRequest.setMethod(POST);
        httpRequest.setHeader(Content_Type, Application_Json);
        httpRequest.setBody(jsonBody);
        httpRequest.setEndpoint(restAPIURL1);
        Http httpObj = new Http();
        HttpResponse httpResponse = httpObj.send(httpRequest);
        
        responseWrapper wResp = (responseWrapper) JSON.deserialize(httpResponse.getBody(), responseWrapper.class);
        return wResp.access_token;
        
    }
    
    public class responseWrapper {
        public string access_token;
        
    } 
    
    //Generate Necessary Body
    public Static string generateJsonStringBoon(){
        
        String clientid = APICredentials.Client_Id__c;
        String Clientsecret = APICredentials.Client_Secret__c;
        string Audience =  APICredentials.Audience__c;
        String requestJson;
        JSONGenerator gen = JSON.createGenerator(true);
        gen.writeStartObject(); 
        gen.writeStringField('client_id',clientid); 
        gen.writeStringField('client_secret',Clientsecret);
        gen.writeStringField('audience',Audience);
        gen.writeStringField('grant_type','client_credentials');
        gen.writeEndObject();
        requestJson = gen.getAsString();
        return requestJson; 
    }
}