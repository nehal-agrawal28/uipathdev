@IsTest(IsParallel=false)
public with sharing class QuoteSendPSEmailQueueableTest_SL {
  @TestSetup
  static void makeData() {
    SBQQ.TriggerControl.disable();
    Account account = DataFactory_CM.createAccount('Customer', true);
    Opportunity opp = DataFactory_SL.createOpportunity(account.Id, true);
    SBQQ__Quote__c quote = DataFactory_SL.createCPQQuote(account.Id, opp.Id, true);
  }

  @IsTest
  private static void sendPSEmailTest() {
    SBQQ__Quote__c q = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
    Test.startTest();
    new QuoteSendPSEmailQueueable_SL(new List<SBQQ__Quote__c>{ q }, 'Deal_Edited').work();
    new QuoteSendPSEmailQueueable_SL(new List<SBQQ__Quote__c>{ q }, 'Deal_Booked').work();
    Test.stopTest();
  }
}