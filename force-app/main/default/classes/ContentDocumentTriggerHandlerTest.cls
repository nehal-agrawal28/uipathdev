@isTest 
public with sharing class ContentDocumentTriggerHandlerTest {
    
    public static DocuSign_Settings__c testDocuSignSettings;
    public static Account testAccount;
    public static Contact testContact;
    public static Opportunity testOpportunity;
    public static Case testCase;
    public static ContentVersion testContentVersion;
    
    public static void createTestData() {
        
        testDocuSignSettings = DataFactory.createDocusignSettings();
        testAccount = DataFactory_CM.createAccount(Constants.ACCOUNT_RECORD_TYPE_1, true);
        testContact = DataFactory_CM.createContact(testAccount.Id, true);
        testOpportunity = DataFactory_SL.createOpportunity(testAccount.Id, true);
        testCase = DataFactory.createCase(testAccount.Id, testContact.Id, testOpportunity.Id, true);
    }
    
    public static testMethod void populateDocumentIdTest() {
        
        String concatenatedDocumentIds;
        
        createTestData();
        
        Test.startTest();
        
        testContentVersion = DataFactory_CM.createFile('Test File 1', testCase.Id, 'V',  true);
        
        concatenatedDocumentIds = testContentVersion.ContentDocumentId;
        
        testCase = [SELECT Document_Id__c FROM Case WHERE Id =: testCase.Id];
        
        System.assertEquals(testCase.Document_Id__c, testContentVersion.ContentDocumentId);
        
        delete new ContentDocument(Id = testContentVersion.ContentDocumentId);
        
        testCase = [SELECT Document_Id__c FROM Case WHERE Id =: testCase.Id];
        
        System.assertEquals(testCase.Document_Id__c, null);
        
        Test.stopTest();
    }
}