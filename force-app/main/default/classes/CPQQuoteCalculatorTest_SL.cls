@IsTest(isParallel=false)
global with sharing class CPQQuoteCalculatorTest_SL {
  @TestSetup
  static void makeData() {
    //Setup
    Account account = DataFactory_CM.createAccount('Customer', false);
    insert account;

    Opportunity opp = DataFactory_SL.createOpportunity(account.Id, true);

    SBQQ__Quote__c quote = DataFactory_SL.createCPQQuote(account.Id, opp.Id, false);
    quote.SBQQ__EndDate__c = System.today().addMonths(12).addDays(-1);
    insert quote;

    //create product
    Product2 prod = new Product2(
      Name = 'FixedPriceProduct',
      IsActive = true,
      SBQQ__SubscriptionPricing__c = 'Fixed Price',
      SBQQ__SubscriptionTerm__c = 12,
      SBQQ__SubscriptionType__c = 'Renewable'
    );
    insert prod;
    //

    Id standardPricebookId = Test.getStandardPricebookId();

    PricebookEntry pbe = new PricebookEntry(
      Pricebook2Id = standardPricebookId,
      Product2Id = prod.Id,
      UnitPrice = 1000.00,
      IsActive = true
    );
    insert new List<PricebookEntry>{ pbe };

    SBQQ__QuoteLine__c qli = DataFactory_SL.createCPQQuoteLine(prod.Id, quote.Id, false);
    qli.SBQQ__Quantity__c = 2;
    insert qli;
    //
  }

  @isTest
  public static void testCalculate() {
    //Fetch
    Id quoteId = [SELECT Id FROM SBQQ__Quote__c LIMIT 1].Id;
    //

    //Act
    CPQQuoteCalculator_SL cpqQuoteCalc = new CPQQuoteCalculator_SL();
    CPQModel_Quote_SL cpqQmod = cpqQuoteCalc.read(quoteId);
    System.assertEquals(40000, cpqQmod.netTotal);
    cpqQmod.lineItems.clear();
    CPQModel_Quote_SL calcQmod = cpqQuoteCalc.calculate(cpqQmod);
    //

    //Assert

    System.assertEquals(0, calcQmod.netTotal);
    //
  }

  @isTest
  public static void testSave() {
    //Fetch
    Id quoteId = [SELECT Id FROM SBQQ__Quote__c LIMIT 1].Id;
    //

    //Act
    CPQQuoteCalculator_SL cpqQuoteCalc = new CPQQuoteCalculator_SL();
    CPQModel_Quote_SL cpqQmod = cpqQuoteCalc.read(quoteId);
    cpqQmod.lineItems.get(0).record.SBQQ__Quantity__c = 4;
    CPQModel_Quote_SL calcdCpqQmod = cpqQuoteCalc.calculate(cpqQmod);
    CPQModel_Quote_SL savedCpqQmod = cpqQuoteCalc.save(calcdCpqQmod);
    //

    //Assert
    System.assertEquals(1, [SELECT Id FROM SBQQ__Quote__c].size());
    SBQQ__Quote__c quote = [SELECT Id, SBQQ__NetAmount__c FROM SBQQ__Quote__c LIMIT 1];
    System.assertEquals(80000, quote.SBQQ__NetAmount__c);
    //
  }

  @isTest
  public static void testCalculateWithCallbackClass() {
    //Fetch
    Id quoteId = [SELECT Id FROM SBQQ__Quote__c LIMIT 1].Id;
    //

    //Act
    CPQQuoteCalculator_SL cpqQuoteCalc = new CPQQuoteCalculator_SL();
    CPQModel_Quote_SL cpqQmod = cpqQuoteCalc.read(quoteId);
    System.assertEquals(40000, cpqQmod.netTotal);
    cpqQmod.lineItems.get(0).record.SBQQ__Quantity__c = 4;
    Test.startTest();
    cpqQuoteCalc.calculate(cpqQmod, 'CPQQuoteCalculatorTest_SL.CallbackTest');
    Test.stopTest();
    //

    //Assert
    System.assertEquals(1, [SELECT Id FROM SBQQ__Quote__c].size());
    SBQQ__Quote__c quote = [SELECT Id, SBQQ__NetAmount__c FROM SBQQ__Quote__c LIMIT 1];
    System.assertEquals(80000, quote.SBQQ__NetAmount__c);
    //
  }

  global with sharing class CallbackTest implements SBQQ.CalculateCallback {
    global void callback(String quoteJSON) {
      SBQQ.ServiceRouter.save('SBQQ.QuoteAPI.QuoteSaver', quoteJSON);
    }
  }
}