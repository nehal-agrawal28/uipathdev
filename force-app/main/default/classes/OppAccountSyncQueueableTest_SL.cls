@IsTest(IsParallel=false)
public with sharing class OppAccountSyncQueueableTest_SL {
  @testSetup
  static void setup() {
    Account testAccount = DataFactory_CM.createAccount('Customer', false);
    testAccount.BillingCountry = 'United Kingdom';
    testAccount.Country__c = 'United Kingdom';
    testAccount.Industry = 'Others';
    testAccount.Validation_Status__c = CommonsConstants.ACC_SYNC_STATUS_PENDING;
    insert testAccount;

    DataFactory_SL.createOpportunity(testAccount.Id, true);
  }

  @isTest
  private static void updateAccountValidationStatusToReadyForReviewTest() {
    List<Opportunity> opps = [SELECT Id, AccountId, Sold_to_Partner__c FROM Opportunity LIMIT 1];
    opps[0].StageName = 'Negotiation';

    Test.startTest();
    update opps;
    OppAccountSyncQueueable_SL oppQueueable = new OppAccountSyncQueueable_SL(opps);
    oppQueueable.work();
    Test.stopTest();
    Account acc = [SELECT id, Validation_Status__c FROM Account WHERE id = :opps[0].accountId];
    System.assertEquals(CommonsConstants.ACC_VALIDATION_STATUS_READY_FOR_REVIEW, acc.Validation_Status__c);
  }
}