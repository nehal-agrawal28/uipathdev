@isTest
public with sharing class OppSuggestAccountFunctionTest_SL {
  @TestSetup
  static void createTestData() {
    Id customerRT = AccountMetadata.getAccountRecordTypeId('Customer');
    Account testAccount = DataFactory_CM.createAccount(customerRT, false);
    testAccount.name = 'Test Customer Account';
    testAccount.BillingCountry = 'Korea, Republic of';
    insert testAccount;
  }

  @isTest
  private static void setExistingAccountWithNoBillingCityTest() {
    Account testAccount = [SELECT id FROM Account LIMIT 1];
    Opportunity testOpp = DataFactory_SL.createOpportunity(testAccount.id, false);
    testOpp.Account_Name__c = 'Test Customer Account';
    testOpp.Account_Country__c = 'Korea, Republic of';
    fflib_SObjectDomain.Test.Database.onInsert(new List<Opportunity>{ testOpp });
    fflib_SObjectDomain.triggerHandler(Opportunities_SL.class);

    System.assertEquals(testAccount.id, testOpp.Suggested_Account__c);
  }

  @isTest
  private static void setExistingAccountWithBillingCityTest() {
    Account testAccount = [SELECT id FROM Account LIMIT 1];
    testAccount.BillingCity = 'Ansan';
    update testAccount;

    Opportunity testOpp = DataFactory_SL.createOpportunity(testAccount.id, false);
    testOpp.Account_Name__c = 'Test Customer Account';
    testOpp.Account_Country__c = 'Korea, Republic of';
    testOpp.Account_City__c = 'Ansan';
    fflib_SObjectDomain.Test.Database.onInsert(new List<Opportunity>{ testOpp });
    fflib_SObjectDomain.triggerHandler(Opportunities_SL.class);

    System.assertEquals(testAccount.id, testOpp.Suggested_Account__c);
  }

  @isTest
  private static void setExistingAccountWithNoAccountNameTest() {
    Account testAccount = [SELECT id FROM Account LIMIT 1];
    testAccount.BillingCity = 'Ansan';
    update testAccount;

    Opportunity testOpp = DataFactory_SL.createOpportunity(testAccount.id, false);
    testOpp.Account_Country__c = 'Korea, Republic of';
    testOpp.Account_City__c = 'Ansan';
    fflib_SObjectDomain.Test.Database.onInsert(new List<Opportunity>{ testOpp });
    fflib_SObjectDomain.triggerHandler(Opportunities_SL.class);

    System.assertEquals(null, testOpp.Suggested_Account__c);
  }
}