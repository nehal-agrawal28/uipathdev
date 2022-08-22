/**
*
* Author:       Daniel Sarchiz
* Date:         12/11/2017
* Description:  Test class for ContentDocumentLinkTriggerHandler
*
**/

@isTest 
public with sharing class ContentDocumentLinkTriggerHandlerTest {
    
    public static DocuSign_Settings__c testDocuSignSettings;
    public static Account testAccount;
    public static Contact testContact;
    public static Opportunity testOpportunity;
    public static Case testCase;
    public static SBQQ__Quote__c testQuote;
    public static ContentVersion testContentVersion;
    public static ContentVersion testContentVersion2;
    
    public static void createTestData() {
        
        testDocuSignSettings = DataFactory.createDocusignSettings();
        testAccount = DataFactory_CM.createAccount(Constants.ACCOUNT_RECORD_TYPE_1, true);
        testContact = DataFactory_CM.createContact(testAccount.Id, true);
        testOpportunity = DataFactory_SL.createOpportunity(testAccount.Id, true);
        testCase = DataFactory.createCase(testAccount.Id, testContact.Id, testOpportunity.Id, true);
        testQuote = DataFactory_SL.createCPQQuote(testAccount.Id, testOpportunity.Id, true);
    }
    
    public static testMethod void updateShareTypeToInheritTest() {
        
        ContentDocumentLink testContentDocumentLink;
        
        createTestData();
        
        Test.startTest();
        
        testContentVersion = DataFactory_CM.createFile('Test File 1', testCase.Id, 'V',  true);
        
        testContentDocumentLink = [SELECT shareType FROM ContentDocumentLink WHERE LinkedEntityId =: testCase.Id];
        
        System.assertEquals(testContentDocumentLink.shareType, 'I');
        
        Test.stopTest();
    }
    
    
    public static testMethod void populateDocumentIdTest() {
        
        String concatenatedDocumentIds;
        
        createTestData();
        
        Test.startTest();
        
        testContentVersion = DataFactory_CM.createFile('Test File 1', testCase.Id, 'V',  true);
        
        concatenatedDocumentIds = testContentVersion.ContentDocumentId;
        
        testCase = [SELECT Document_Id__c FROM Case WHERE Id =: testCase.Id];
        
        System.assertEquals(testCase.Document_Id__c, testContentVersion.ContentDocumentId);
        
        testContentVersion = DataFactory_CM.createFile('Test File 2', testCase.Id, 'V',  true);
        
        concatenatedDocumentIds = concatenatedDocumentIds + ',' + testContentVersion.ContentDocumentId;
        
        testCase = [SELECT Document_Id__c FROM Case WHERE Id =: testCase.Id];
        
        System.assertEquals(testCase.Document_Id__c, concatenatedDocumentIds);
        
        Test.stopTest();
    }
    
    public static testMethod void populateDocumentIdTest2() {
        
        String concatenatedDocumentIds;
        
        createTestData();
        
        Test.startTest();
        
        testContentVersion = DataFactory_CM.createFile('Test File 1', testQuote.Id, 'V',  true);
        
        concatenatedDocumentIds = testContentVersion.ContentDocumentId;
        
        testQuote = [SELECT Document_ID__c FROM SBQQ__Quote__c  WHERE Id =: testQuote.Id];
        
        System.assertEquals(testQuote.Document_ID__c, testContentVersion.ContentDocumentId);
        
        testContentVersion = DataFactory_CM.createFile('Test File 2', testQuote.Id, 'V',  true);
        
        concatenatedDocumentIds = concatenatedDocumentIds + ',' + testContentVersion.ContentDocumentId;
        
        testQuote = [SELECT Document_ID__c FROM SBQQ__Quote__c  WHERE Id =: testQuote.Id];
        
        System.assertEquals(testQuote.Document_ID__c, concatenatedDocumentIds);
        
        Test.stopTest();
    }
    
    public static testMethod void createNewContentDocumentLinksTest() {
        
        ContentDocumentLink testContentDocumentLink;
        
        createTestData();
        
        Test.startTest();
        
        testContentVersion = DataFactory_CM.createFile('Test File 1', testCase.Id, 'V',  true);
        
        testContentDocumentLink = [SELECT shareType FROM ContentDocumentLink WHERE LinkedEntityId =: testOpportunity.Id];
        
        System.assertNotEquals(testContentDocumentLink, null);
        
        Test.stopTest();
    }
    
    public static testMethod void createNewContentDocumentLinksTest2() {
        
        ContentDocumentLink testContentDocumentLink;
        
        createTestData();
        
        Test.startTest();
        
        testContentVersion = DataFactory_CM.createFile('Test File 2', testQuote.Id, 'V',  true);
        
        testContentDocumentLink = [SELECT shareType FROM ContentDocumentLink WHERE LinkedEntityId =: testOpportunity.Id];
        
        System.assertNotEquals(testContentDocumentLink, null);
        
        Test.stopTest();
    }
}