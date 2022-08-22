@IsTest(isParallel=false)
public with sharing class QuoteRipReplaceUpdQLIsQueueableTest_SL {
  @IsTest
  public static void testUpdateQuoteLines() {
    SBQQ.TriggerControl.disable();
    //Setup
    Account account = DataFactory_CM.createAccount('Customer', false);
    insert account;

    //opp - quote 1
    Opportunity opp = DataFactory_SL.createOpportunity(account.Id, true);

    SBQQ__Quote__c quote = DataFactory_SL.createCPQQuote(account.Id, opp.Id, false);
    quote.SBQQ__EndDate__c = System.today().addMonths(12).addDays(-1);
    insert quote;
    //

    //opp - quote 2
    Opportunity opp2 = DataFactory_SL.createOpportunity(account.Id, true);

    SBQQ__Quote__c quote2 = DataFactory_SL.createCPQQuote(account.Id, opp2.Id, false);
    quote2.SBQQ__EndDate__c = System.today().addMonths(24).addDays(-1);
    insert quote2;
    Id replacementQuoteId = quote2.Id;
    //

    Id standardPricebookId = Test.getStandardPricebookId();

    Product2 prod = new Product2(
      Name = 'Product Uipath 1' + String.valueOf((Math.random() * 100) + 1),
      ProductCode = 'PROD' + String.valueOf((Math.random() * 100) + 1),
      isActive = true
    );
    insert new List<Product2>{ prod };

    PricebookEntry pbe = new PricebookEntry(
      Pricebook2Id = standardPricebookId,
      Product2Id = prod.Id,
      UnitPrice = 3000.00,
      IsActive = true
    );
    insert new List<PricebookEntry>{ pbe };

    SBQQ__QuoteLine__c qli = DataFactory_SL.createCPQQuoteLine(prod.Id, quote.Id, false);
    qli.SBQQ__Quantity__c = 2;
    insert qli;

    List<SBQQ__QuoteLine__c> qlis = new List<SBQQ__QuoteLine__c>{ qli };
    //
    SBQQ.TriggerControl.enable();

    //Act
    System.assertEquals(0, [SELECT Id FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c = :replacementQuoteId].size());
    CPQConsolidateReplacementLines_SL cpqCrl = new CPQConsolidateReplacementLines_SL(
      new Set<String>{ '123' },
      replacementQuoteId,
      Logger.getTransactionId()
    );
    List<SBQQ__QuoteLine__c> clonedQlis = cpqCrl.cloneQuoteLinesIntoReplacementQuote(qlis, quote2);
    QuoteRipReplaceUpdQLIsQueueable_SL qrruqq = new QuoteRipReplaceUpdQLIsQueueable_SL(
      JSON.serialize(clonedQlis),
      'xyz123'
    );
    Test.startTest();
    Id jobId = System.enqueueJob(qrruqq);
    Test.stopTest();
    //

    //Assert
    System.assertEquals(1, [SELECT Id FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c = :replacementQuoteId].size());
    //
  }
}