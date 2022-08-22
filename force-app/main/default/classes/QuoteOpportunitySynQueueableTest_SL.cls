@IsTest(IsParallel=false)
public with sharing class QuoteOpportunitySynQueueableTest_SL {
  @TestSetup
  static void makeData() {
    SBQQ.TriggerControl.disable();
    Account account = DataFactory_CM.createAccount('Customer', true);
    DataFactory_SL.createOpportunity(account.Id, true);

    Product2 prod = new Product2(
      Name = 'Product Uipath 2' + String.valueOf((Math.random() * 100) + 1),
      ProductCode = 'PROD' + String.valueOf((Math.random() * 100) + 1),
      isActive = true
    );
    insert new List<Product2>{ prod };

    PricebookEntry pbe = new PricebookEntry(
      Pricebook2Id = Test.getStandardPricebookId(),
      Product2Id = prod.Id,
      UnitPrice = 1000.00,
      IsActive = true
    );
    insert new List<PricebookEntry>{ pbe };
  }

  @IsTest
  static void onInsert_syncOpportunities() {
    Account account = [SELECT Id FROM Account LIMIT 1];
    Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
    SBQQ__Quote__c quote = DataFactory_SL.createCPQQuote(account.Id, opp.Id, false);
    quote.SBQQ__Primary__c = true;
    insert quote;

    Test.startTest();
    new QuoteOpportunitySynQueueable_SL(new List<SBQQ__Quote__c>{ quote }).work();
    Test.stopTest();

    opp = [SELECT Id, Contract_Start_Date__c FROM Opportunity LIMIT 1];
    System.assertEquals(quote.SBQQ__StartDate__c, opp.Contract_Start_Date__c, 'Opportunity is not synced on insert');
  }

  @IsTest
  static void onUpdate_syncOpportunities() {
    Account account = [SELECT Id FROM Account LIMIT 1];
    Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
    SBQQ__Quote__c quote = DataFactory_SL.createCPQQuote(account.Id, opp.Id, false);
    quote.CPQ_QuoteACV_val__c = 1000;
    insert quote;

    SBQQ__Quote__c updatedQuote = DataFactory_SL.createCPQQuote(account.Id, opp.Id, false);
    updatedQuote.Id = quote.Id;
    updatedQuote.SBQQ__Primary__c = true;
    updatedQuote.CPQ_QuoteACV_val__c = 2000;
    update updatedQuote;

    Test.startTest();
    new QuoteOpportunitySynQueueable_SL(new List<SBQQ__Quote__c>{ updatedQuote }).work();
    Test.stopTest();

    opp = [SELECT Id, CPQ_OpportunityACV__c FROM Opportunity LIMIT 1];
    System.assertEquals(
      updatedQuote.CPQ_QuoteACV_val__c,
      opp.CPQ_OpportunityACV__c,
      'Opportunity is not synced on update'
    );
  }
}