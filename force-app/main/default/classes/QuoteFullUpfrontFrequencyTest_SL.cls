@IsTest(IsParallel=false)
public with sharing class QuoteFullUpfrontFrequencyTest_SL {
  @TestSetup
  static void makeData() {
    SBQQ.TriggerControl.disable();
    Account account = DataFactory_CM.createAccount('Customer', true);
    Opportunity opp = DataFactory_SL.createOpportunity(account.Id, true);

    insert new CPQ_Order_Integration_Features__c(SetupOwnerId = UserInfo.getOrganizationId(), Active__c = true);

    SBQQ__Quote__c quote = DataFactory_SL.createCPQQuote(account.Id, opp.Id, false);
    quote.SBQQ__Primary__c = true;
    quote.SBQQ__BillingFrequency__c = 'Upfront';
    insert quote;
  }

  @IsTest
  static void onInsert_updateBillingCycle() {
    SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];

    Test.startTest();
    new QuoteFullUpfrontFrequencyQueueable_SL(new List<SBQQ__Quote__c>{ quote }).work();
    Test.stopTest();

    Opportunity opp = [SELECT Id, Payment_Cycle__c FROM Opportunity LIMIT 1];
    System.assertEquals(opp.Payment_Cycle__c, 'Upfront', 'Payment Cycle is set correct on insert');
  }

  @IsTest
  static void onUpdate_updateBillingCycle() {
    SBQQ__Quote__c quote = [
      SELECT Id, SBQQ__Account__c, SBQQ__Account__r.Id, SBQQ__Opportunity2__r.Id, SBQQ__Opportunity2__c
      FROM SBQQ__Quote__c
      LIMIT 1
    ];

    SBQQ__Quote__c updatedQuote = DataFactory_SL.createCPQQuote(
      quote.SBQQ__Account__r.Id,
      quote.SBQQ__Opportunity2__r.Id,
      false
    );
    updatedQuote.Id = quote.Id;
    updatedQuote.SBQQ__BillingFrequency__c = 'Annual';
    updatedQuote.SBQQ__EndDate__c = System.Date.today().addYears(2);
    update updatedQuote;

    Test.startTest();
    new QuoteFullUpfrontFrequencyQueueable_SL(new List<SBQQ__Quote__c>{ updatedQuote }).work();
    Test.stopTest();

    Opportunity opp = [SELECT Id, Payment_Cycle__c FROM Opportunity LIMIT 1];
    System.assertEquals(opp.Payment_Cycle__c, 'Annual', 'Payment Cycle is set correct on update');
  }
}