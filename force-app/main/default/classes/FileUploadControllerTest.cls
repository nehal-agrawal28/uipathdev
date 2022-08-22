@IsTest(isParallel=true)
public class FileUploadControllerTest {

	public static Account testAccount;
    public static Contact testContact;
    public static Case testCase;
    public static final String CASE_RECORD_TYPE_3 = 'Incident';
    
    @testSetup 
    public static void setUpData (){
        Account newAccount = new Account (Name = 'Raj');
        newAccount.RecordTypeId = Utilities.getRecordTypeId('Customer', 'Account');
        newAccount.BillingStreet = 'Test  Street';
        newAccount.BillingCity = 'Test City';
        newAccount.BillingPostalCode = '123abc';
        newAccount.BillingCountry = 'United Kingdom';
        newAccount.Phone = '12345678';
        newAccount.Industry = 'Others';
        newAccount.name='productsupportlicensecode';
        insert newAccount;
        
        Contact c = new Contact (LastName = 'Tesr', Email='test@test.com', AccountId = newAccount.Id, Department__c = 'IT');
        insert c;
        
        Case ca = new Case (AccountId = newAccount.Id, ContactId = c.Id, Origin = 'Web');
        insert ca;


        License_Code__c lc = new License_Code__c ();
        lc.CompanyID__c = '10101';
        lc.CompanyName__c = 'Fujitsu Japan';
        lc.LicenseCode__c = '386777107028492530';
        insert lc;

    }
    
    
    public static testMethod void testValidLicense_Null () {
        Test.startTest();
        mockCallout fakeResponse = new mockCallout(200,
                                                   'Complete',
                                                   '{"license":{"id":630580,"licenseDuration":"INTERVAL","name":"Enterprise","description":null,"duration":0,"startDate":"2019-06-28","endDate":"2020-07-03","enabled":true,"allowedActivations":1,"activationCount":0,"checkIntervalOnline":7,"checkIntervalOffline":365,"gracePeriod":14,"bundle":{"id":3367044,"code":"UIP","name":"UiPath Platform / Server","description":null,"licenseModel":"INSTANCE","products":[{"id":25580776,"code":"STDNU","name":"Studio Named User","description":null,"features":[{"id":4977025,"code":"EDT","name":"Editable","description":null,"type":"BOOL","value":"true"}],"quantity":0,"type":"STANDARD"},{"id":25580780,"code":"STDPRONU","name":"StudioPro Named User ","description":null,"features":[{"id":4977026,"code":"EDT","name":"Editable","description":null,"type":"BOOL","value":"true"}],"quantity":0,"type":"STANDARD"},{"id":25580777,"code":"UNATT","name":"Unattended Robot","description":null,"features":[],"quantity":25,"type":"STANDARD"},{"id":25580782,"code":"APPS","name":"UiPath Apps","description":null,"features":[],"quantity":0,"type":"STANDARD"},{"id":25580781,"code":"STDPROCU","name":"StudioPro Concurrent User ","description":"StudioPro Concurrent User ","features":[{"id":4977027,"code":"EDT","name":"Editable","description":null,"type":"BOOL","value":"true"}],"quantity":0,"type":"STANDARD"},{"id":25580771,"code":"ATTCU","name":"Attended Robot Concurrent User/ NL","description":null,"features":[],"quantity":0,"type":"STANDARD"},{"id":25580773,"code":"STDXNU","name":"StudioX Named User","description":null,"features":[],"quantity":0,"type":"STANDARD"},{"id":25580784,"code":"ANL","name":"Insights","description":null,"features":[],"quantity":0,"type":"STANDARD"},{"id":25580778,"code":"ORCH","name":"Orchestrator","description":null,"features":[],"quantity":1,"type":"STANDARD"},{"id":25580785,"code":"STDCU","name":"Studio Concurrent User/ NL","description":null,"features":[{"id":4977028,"code":"EDT","name":"Editable","description":null,"type":"BOOL","value":"true"}],"quantity":0,"type":"STANDARD"},{"id":25580775,"code":"ABBYY","name":"Abbyy Document OCR","description":null,"features":[],"quantity":0,"type":"CONSUMPTION"},{"id":25580783,"code":"TAUNATT","name":"TestAutomation Robot","description":"TestAutomation Robot","features":[],"quantity":0,"type":"STANDARD"},{"id":25580779,"code":"ATTNU","name":"Attended Robot Named User","description":null,"features":[],"quantity":0,"type":"STANDARD"},{"id":25580772,"code":"STDXCU","name":"StudioX Concurrent User/ NL","description":null,"features":[],"quantity":0,"type":"STANDARD"},{"id":25580774,"code":"NONPR","name":"NonProduction Robot","description":null,"features":[],"quantity":0,"type":"STANDARD"}]},"licenseCode":"386756370353798704","pendingUpdate":null,"subscriptionCode":"ENT","bundleCode":"UIP","createdDateTime":"2019-12-03T05:32:03.977","owner":{"identifier":null,"externalReference":"QBE Group Services Pty Limited Australia 047035","internalReference":null,"email":"","countryCode":null},"tags":[{"id":13,"name":"host"},{"id":22,"name":"nalpeiron"}]},"accountId":"0011Q000024ksbmQAA","accountName":"QBE Group Services Pty Limited","accountCountry":"Australia"}',
                                                   null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        String res = FileUploadController.validateLicenseCode ('');
        Map<String, Object> resMap =  (Map<String, Object>)(JSON.deserializeUntyped(res));
        System.assertEquals('ERROR', String.valueOf(resMap.get ('status')));
        Test.stopTest();
    }
    
   
    public static testMethod void testInitFileUploadWithCase () {
        Test.startTest();
        FileUploadController cntl = new FileUploadController ();
        Attachment attach = cntl.getObjAttachment ();
        Case c  = [SELECT Id from Case LIMIT 1];
        
        attach.Name='Unit Test Attachment';
        Blob bodyBlob=Blob.valueOf('Unit Test Attachment Body');
        attach.body=bodyBlob;
        attach.ParentId = c.Id;
        cntl.uploadFile ();
        
        cntl.message='File was uploaded successfully';
        cntl.messageType = 'success';
        cntl.fileUploadProcessed = true;
        
        
        Test.stopTest();
    }
    
    
   
    
    //added by WarpDrive:Deepali
    //Purpose: To cover the methods that dynamically fetch picklists in fileUploaderController	
    public static TestMethod void testpicklistMethods(){
        Test.startTest();
        mockCallout fakeResponse = new mockCallout(200,
                                                   'Complete',
                                                   '{"license":{"id":630580,"licenseDuration":"INTERVAL","name":"Enterprise","description":null,"duration":0,"startDate":"2019-06-28","endDate":"2020-07-03","enabled":true,"allowedActivations":1,"activationCount":0,"checkIntervalOnline":7,"checkIntervalOffline":365,"gracePeriod":14,"bundle":{"id":3367044,"code":"UIP","name":"UiPath Platform / Server","description":null,"licenseModel":"INSTANCE","products":[{"id":25580776,"code":"STDNU","name":"Studio Named User","description":null,"features":[{"id":4977025,"code":"EDT","name":"Editable","description":null,"type":"BOOL","value":"true"}],"quantity":0,"type":"STANDARD"},{"id":25580780,"code":"STDPRONU","name":"StudioPro Named User ","description":null,"features":[{"id":4977026,"code":"EDT","name":"Editable","description":null,"type":"BOOL","value":"true"}],"quantity":0,"type":"STANDARD"},{"id":25580777,"code":"UNATT","name":"Unattended Robot","description":null,"features":[],"quantity":25,"type":"STANDARD"},{"id":25580782,"code":"APPS","name":"UiPath Apps","description":null,"features":[],"quantity":0,"type":"STANDARD"},{"id":25580781,"code":"STDPROCU","name":"StudioPro Concurrent User ","description":"StudioPro Concurrent User ","features":[{"id":4977027,"code":"EDT","name":"Editable","description":null,"type":"BOOL","value":"true"}],"quantity":0,"type":"STANDARD"},{"id":25580771,"code":"ATTCU","name":"Attended Robot Concurrent User/ NL","description":null,"features":[],"quantity":0,"type":"STANDARD"},{"id":25580773,"code":"STDXNU","name":"StudioX Named User","description":null,"features":[],"quantity":0,"type":"STANDARD"},{"id":25580784,"code":"ANL","name":"Insights","description":null,"features":[],"quantity":0,"type":"STANDARD"},{"id":25580778,"code":"ORCH","name":"Orchestrator","description":null,"features":[],"quantity":1,"type":"STANDARD"},{"id":25580785,"code":"STDCU","name":"Studio Concurrent User/ NL","description":null,"features":[{"id":4977028,"code":"EDT","name":"Editable","description":null,"type":"BOOL","value":"true"}],"quantity":0,"type":"STANDARD"},{"id":25580775,"code":"ABBYY","name":"Abbyy Document OCR","description":null,"features":[],"quantity":0,"type":"CONSUMPTION"},{"id":25580783,"code":"TAUNATT","name":"TestAutomation Robot","description":"TestAutomation Robot","features":[],"quantity":0,"type":"STANDARD"},{"id":25580779,"code":"ATTNU","name":"Attended Robot Named User","description":null,"features":[],"quantity":0,"type":"STANDARD"},{"id":25580772,"code":"STDXCU","name":"StudioX Concurrent User/ NL","description":null,"features":[],"quantity":0,"type":"STANDARD"},{"id":25580774,"code":"NONPR","name":"NonProduction Robot","description":null,"features":[],"quantity":0,"type":"STANDARD"}]},"licenseCode":"386777107028492330","pendingUpdate":null,"subscriptionCode":"ENT","bundleCode":"UIP","createdDateTime":"2019-12-03T05:32:03.977","owner":{"identifier":null,"externalReference":"QBE Group Services Pty Limited Australia 047035","internalReference":null,"email":"","countryCode":null},"tags":[{"id":13,"name":"host"},{"id":22,"name":"nalpeiron"}]},"accountId":"0011Q000024ksbmQAA","accountName":"QBE Group Services Pty Limited","accountCountry":"Australia"}',
                                                   null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        String res = FileUploadController.validateLicenseCode ('386777107028492330');
        String jsonStr = string.valueof(res);
        Map<String, Object> resMap =  (Map<String, Object>)(JSON.deserializeUntyped(res));
        System.assertEquals('SUCCESS', String.valueOf(resMap.get ('status')));
        
        
        FileUploadController.getOrchestratorPickListValues();
		FileUploadController.getStudioPickListValues();
		FileUploadController.getNumRobPickListValues();
		FileUploadController.getEnvironmentPickListValues();
		FileUploadController.getRelatedPickListValues();
        FileUploadController.getWhatFeatureIsThisRelatedToPickListValues();
		FileUploadController.getPriorityPickListValues();
        FileUploadController.getIssueTypePickListValues();
		FileUploadController.getCountryPickListValues();
        FileUploadController.getRelatedPickListByRecordTypeId(SupportConstants.jsAcademyRtId);
        FileUploadController.getExpertisePickListValues();
        FileUploadController.getJobLevelPickListValues();
        FileUploadController.getRequestPickListValues();
        FileUploadController.getLicenseCatgryPickListValues();
        FileUploadController.getIssueCatgryPickListValues();
        
        
        testAccount = [Select id,name from Account limit 1];
        testcontact = [Select id from Contact where AccountId =:testAccount.Id limit 1];
        
        Case obj = [Select id from Case where AccountId =:testAccount.Id AND ContactId=:testcontact.id AND Origin = 'Web' limit 1];
        
        Account newAc = new Account (Name = 'Test' + String.valueOf(System.now()));
        newAc.RecordTypeId = Utilities.getRecordTypeId('Customer', 'Account');
        newAc.BillingStreet = 'Test  Street';
        newAc.BillingCity = 'London';
        newAc.BillingPostalCode = '111222';
        newAc.Legal__c = 'Test' + String.valueOf(System.now());
        newAc.DNBoptimizer__DNB_D_U_N_S_Number__c = '1234567';
        newAc.BillingCountry = 'United Kingdom';
        newAc.Country__c = 'United Kingdom';
        newAc.Phone = '12345678';
        newAc.Industry = 'Others';
        newAc.name='productsupportlicensecode';
        insert newAc;
        
        Contact c = new Contact (LastName = 'Tesr', Email='test@test55505.com', AccountId = newAc.Id, Department__c = 'IT');
        insert c;
        
        
        try{
            Case ca = new Case (AccountId = newAc.Id, ContactId = c.Id, Origin = 'Web');
            FileUploadController.createERCase(ca);
        }catch(Exception ex){
            system.debug('ex.getMessage()'+ ex.getMessage());
            system.debug('ex.getLineNumber()'+ ex.getLineNumber());
        }       
        
        FileUploadController.getCountryCodePickListValues(obj,'asda', 'asdda');
        FileUploadController.getJobDependentPickListValues(obj,'asda', 'asdda');
        FileUploadController.getproductRecordTypes();
        FileUploadController.getLicensingMessages();
        DependentPickListUtil.decimalToBinary(2);
        DependentPickListUtil.base64ToBits('test');
        FileUploadController.getBlackListDomains ();
        FileUploadController.getTimeZoneList();
        FileUploadController.expertRequest(obj.id);
       
        Case_JSON_Data__c obj3 = new Case_JSON_Data__c();
        insert obj3;
        DependentPickListUtil.getDependentMap(obj3,'Type__c', 'Type__c');
        
        FileUploadController.saveChunk(obj.Id, 'Unit Test Attachment','base64', 'attachment', '');
        
        
        Apex_Callouts.cloudRPAValidated crv = new Apex_Callouts.cloudRPAValidated();
        Cloud_RPA_Settings__c setting = new Cloud_RPA_Settings__c();
        setting.Name = 'Cloud_Rpa';
        setting.Audience__c='https://uipath.eu.auth0.com/api/v2/';
        setting.Auth0_Client_ID__c='abc';
        setting.Auth0_Client_Secret__c='xyz';
        setting.Auth0_Domain__c='https://uipath.eu.auth0.com/oauth/token';
        setting.Service_Endpoint__c='https://bluegreenproduction.trafficmanager.net/location/api/requestrouting/location/VARIABLE1/portal';
        insert setting;
        Test.stopTest();
    }
    
    
    
    private class Mock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'application/JSON');
            res.setBody('{"access_token":"eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6IlJUTkVOMEl5T1RWQk1UZEVRVEEzUlRZNE16UkJPVU00UVRRM016TXlSalUzUmpnMk4wSTBPQSJ9.eyJpc3MiOiJodHRwczovL3VpcGF0aC5ldS5hdXRoMC5jb20vIiwic3ViIjoiNXNrMDdtYnRMQk8yWHc2emtFOElUZEVTU0lFMHlLcHlAY2xpZW50cyIsImF1ZCI6Imh0dHBzOi8vdWlwYXRoLmV1LmF1dGgwLmNvbS9hcGkvdjIvIiwiaWF0IjoxNTg3OTY4MzEzLCJleHAiOjE1ODgwNTQ3MTMsImF6cCI6IjVzazA3bWJ0TEJPMlh3NnprRThJVGRFU1NJRTB5S3B5Iiwic2NvcGUiOiJyZWFkOmNsaWVudF9ncmFudHMiLCJndHkiOiJjbGllbnQtY3JlZGVudGlhbHMifQ.F7yohDGNKL-qdcRJ-TQGIAjsbrqjBTttMtZ2wd1v_TdBs8HoAC6S6mWF_w4GWBZ7V6-m0U_A4BT7nhsTQ1AoRfo1JFE4JLI6yYAqan6ErakLixvWt_tyab1gd3TxXyd0ueB0gfsdPfNUzdcjH5zgiJWDEHn_V0qj2B8CHERRCmcWZTh7zlgmF3hRtABvIKLas2vYNdDYwD9S248kyIN6lGixtDl2gY7YMzlumV0FBahiKOnQDAkZg4UWHjNjvSuAB0KMeTeA1p8w2Z3YiuqnjUyG2FaQROM_0FtVyiUIsjey0RMqEl4ap0vQqqgDxEbOty_SzrwcJOP5mTTVbiRZiw","scope":"read:client_grants","expires_in":86400,"token_type":"Bearer"}');
            res.setStatusCode(201);
            return res;
        }
    }
    
    public static TestMethod void Apex_Callouts_cloudRPAValidated(){
        testAccount = [Select id,name from Account limit 1]; 
        Apex_Callouts.cloudRPAValidated crv = new Apex_Callouts.cloudRPAValidated();
        Cloud_RPA_Settings__c setting = new Cloud_RPA_Settings__c();
        setting.Name = 'Cloud_Rpa';
        setting.Audience__c='https://uipath.eu.auth0.com/api/v2/';
        setting.Auth0_Client_ID__c='abc';
        setting.Auth0_Client_Secret__c='xyz';
        setting.Auth0_Domain__c='https://uipath.eu.auth0.com/oauth/token';
        setting.Service_Endpoint__c='https://platform.uipath.com/discovery/account/VARIABLE1';
        insert setting;
        
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new Mock()); 
        FileUploadController.cloudRPAAccount('http://servcloud3-uipath-survey.cs21.force.com/'+testAccount.name+''); 
        test.stopTest();
       
    }
    
    
    public static testMethod void testAttachmentsMethods(){
    	Test.startTest();

        testAccount = [Select id from Account limit 1];
        testcontact = [Select id from Contact where AccountId =:testAccount.Id limit 1];
        
        Case ca = [Select id from Case where AccountId =:testAccount.Id AND ContactId=:testcontact.id AND Origin = 'Web' limit 1];
        
        
        Attachment attach=new Attachment();   	
        attach.Name='Unit Test Attachment';
        Blob bodyBlob=Blob.valueOf('Unit Test Attachment Body');
        attach.body=bodyBlob;
        attach.parentId=ca.id;
        insert attach;
        
        FileUploadController.saveTheFile(ca.Id, 'Unit Test Attachment','base64', 'attachment');
        FileUploadController.saveCase('{"case":"case"}');
        FileUploadController.saveChunk(ca.Id, 'Unit Test Attachment','base64', 'attachment', attach.Id);
        
        Test.stopTest();
        
    }
}