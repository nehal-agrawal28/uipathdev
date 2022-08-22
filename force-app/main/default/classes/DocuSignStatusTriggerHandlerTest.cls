/**
*
* Author:       Daniel Sarchiz
* Date:         12/11/2017
* Description:  Test class for DocuSignTriggerHandler
*
**/

@isTest 
public with sharing class DocuSignStatusTriggerHandlerTest {
    
    public static Account testAccount;
    public static Contact testContact; 
    public static Opportunity testOpportunity;
    public static Case testCase;
    public static SBQQ__Quote__c testQuote;
    public static dsfs__DocuSign_Status__c testDocuSignStatus;
    
    public static void createTestData() { 
        
        testAccount = DataFactory_CM.createAccount(Constants.ACCOUNT_RECORD_TYPE_1, true);
        testContact = DataFactory_CM.createContact(testAccount.Id, true);
        testOpportunity = DataFactory_SL.createOpportunity(testAccount.Id, true);
        testCase = DataFactory.createCase(testAccount.Id, testContact.Id, testOpportunity.Id, true);
        testQuote = DataFactory_SL.createCPQQuote(testAccount.Id, testOpportunity.Id, true);
    }
    
    public static testMethod void populateObjectLookupFieldsTest() {
        
        createTestData();
        
        Test.startTest();
        
        testDocuSignStatus = DataFactory.createDocuSignStatusQuote(testAccount.Id, null, testCase.Id, null, true);
        
        testDocuSignStatus = [SELECT dsfs__Opportunity__c, dsfs__Contact__c FROM dsfs__DocuSign_Status__c WHERE Id =: testDocuSignStatus.Id];
        
        System.assertEquals(testDocuSignStatus.dsfs__Opportunity__c, testOpportunity.Id);
        System.assertEquals(testDocuSignStatus.dsfs__Contact__c, testContact.Id);
        
        Test.stopTest();
    }
    
    public static testMethod void populateObjectLookupFieldsTest2() {
        
        createTestData();
        
        Test.startTest();
        
        testDocuSignStatus = DataFactory.createDocuSignStatusQuote(testAccount.Id, null, null, testQuote.Id, true);
        
        testDocuSignStatus = [SELECT dsfs__Opportunity__c FROM dsfs__DocuSign_Status__c WHERE Id =: testDocuSignStatus.Id];
        
        System.assertEquals(testDocuSignStatus.dsfs__Opportunity__c, testOpportunity.Id);
        
        Test.stopTest();
    }
    
    public static testMethod void updateCaseStatusTest() {
        
        createTestData();
        
        Test.startTest();
        
        testDocuSignStatus = DataFactory.createDocuSignStatusQuote(testAccount.Id, null, testCase.Id, null, true);
        
        testCase.Status = Constants.CASE_STATUS_6;
        
        update testCase;
        
        testDocuSignStatus.dsfs__Envelope_Status__c = Constants.DOCUSIGN_ENVELOPE_STATUS_2;
        
        update testDocuSignStatus;
        
        testCase = [SELECT Status FROM Case WHERE Id =: testCase.Id];
        
        System.assertEquals(testCase.Status, Constants.CASE_STATUS_3);
        
        Test.stopTest();
    }
    
    public static testMethod void updateQuoteStatusTest() {
        
        createTestData();
        
        Test.startTest();
        
        testDocuSignStatus = DataFactory.createDocuSignStatusQuote(testAccount.Id, null, null, testQuote.Id, true);
        
        testQuote.SBQQ__Status__c = Constants.QUOTE_STATUS_1;
        
        update testQuote;
        
        testDocuSignStatus.dsfs__Envelope_Status__c = Constants.DOCUSIGN_ENVELOPE_STATUS_1;
        
        update testDocuSignStatus;
        
        testQuote = [SELECT SBQQ__Status__c FROM SBQQ__Quote__c  WHERE Id =: testQuote.Id];
        
        //System.assertEquals(testQuote.SBQQ__Status__c, Constants.QUOTE_STATUS_3);
        
        Test.stopTest();
    }
}