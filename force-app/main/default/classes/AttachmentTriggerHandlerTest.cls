/**
*
* Author:       Daniel Sarchiz
* Date:         12/11/2017
* Description:  Test class for AttachmentTriggerHandler
*
**/

@isTest 
public with sharing class AttachmentTriggerHandlerTest {
    
    public static Account testAccount;
    public static Contact testContact;
    public static Opportunity testOpportunity;
    public static Case testCase;
    public static ContentVersion testContentVersion;
    public static dsfs__DocuSign_Status__c testDocuSignStatus;
    public static Attachment testAttachment;
    
    public static void createTestData() {
        
        testAccount = DataFactory_CM.createAccount(Constants.ACCOUNT_RECORD_TYPE_1, true);
        testContact = DataFactory_CM.createContact(testAccount.Id, true);
        testOpportunity = DataFactory_SL.createOpportunity(testAccount.Id, true);
        testCase = DataFactory.createCase(testAccount.Id, testContact.Id, testOpportunity.Id, true);
        testContentVersion = DataFactory_CM.createFile('Test File 1', testCase.Id, 'I',  true);
        testDocuSignStatus = DataFactory.createDocuSignStatus(testAccount.Id, null, testCase.Id, true);
    }
    
    public static testMethod void updateRelatedCasesFileTest() {
        
        List<ContentVersion> testConventVersionsList;
        
        createTestData();
        
        Test.startTest();
        
        testAttachment = DataFactory_CM.createAttachment('Test Attachment 1', testDocuSignStatus.Id, true);
        
        testConventVersionsList = [SELECT Id FROM ContentVersion WHERE ContentDocumentId =: testContentVersion.ContentDocumentId];
        
        System.assertEquals(testConventVersionsList.size(), 2);
        
        Test.stopTest();
    }
}