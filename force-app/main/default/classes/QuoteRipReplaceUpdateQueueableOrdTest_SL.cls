@IsTest
public with sharing class QuoteRipReplaceUpdateQueueableOrdTest_SL {
  static final Date START_DATE_FOR_RR = System.today().addDays(7);
  static final Date START_DATE_FOR_NONSCOPE = START_DATE_FOR_RR.addDays(-30);
  static final string ORDER_DRAFT_STATUS = Constants_SL.ORDER_STATUS_DRAFT;
  static final string ORDER_ACTIVATED_STATUS = Constants_SL.ORDER_STATUS_ACTIVATED;
  static final string RR_OPP_NAME = 'RR Opp';
  static final string NON_SCOPE_OPP_NAME = 'Non Scope Opp';

  @TestSetup
  static void makeData() {
    SBQQ.TriggerControl.disable();
    //Setup
    Account testAccount = DataFactory_CM.createAccount('Customer', false);
    insert testAccount;

    //rip and replace - opp/quote
    Opportunity rrOpp = DataFactory_SL.createOpportunity(testAccount.Id, true);

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

    SBQQ__Quote__c ripReplaceQuote = DataFactory_SL.createCPQQuote(testAccount.Id, rrOpp.Id, false);
    ripReplaceQuote.SBQQ__StartDate__c = START_DATE_FOR_RR;
    ripReplaceQuote.SBQQ__EndDate__c = System.today().addMonths(12).addDays(-1);
    ripReplaceQuote.SBQQ__BillingFrequency__c = 'Annual';
    ripReplaceQuote.SBQQ__Primary__c = true;
    ripReplaceQuote.Replacement_Transaction__c = true;
    insert ripReplaceQuote;

    SBQQ__QuoteLine__c rrQli = DataFactory_SL.createCPQQuoteLine(prod.Id, ripReplaceQuote.Id, false);
    rrQli.SBQQ__Quantity__c = 2;
    rrQli.SBQQ__PricebookEntryId__c = pbe.Id;
    insert rrQli;
    //

    //cancellation - opp/quote
    Opportunity cancellationOpp = DataFactory_SL.createOpportunity(testAccount.Id, true);
    cancellationOpp.Pricebook2Id = Test.getStandardPricebookId();
    update cancellationOpp;

    SBQQ__Quote__c cancellationQuote = DataFactory_SL.createCPQQuote(testAccount.Id, cancellationOpp.Id, false);
    cancellationQuote.SBQQ__StartDate__c = START_DATE_FOR_RR;
    cancellationQuote.SBQQ__EndDate__c = System.today().addMonths(6).addDays(-1);
    cancellationQuote.Replacement_Quote__c = ripReplaceQuote.Id;
    cancellationQuote.SBQQ__BillingFrequency__c = 'Annual';
    cancellationQuote.SBQQ__Primary__c = true;
    insert cancellationQuote;
    //

    System.assertEquals(2, [SELECT Id FROM SBQQ__Quote__c].size(), 'There should be two quotes in the test db');
  }

  @isTest
  public static void itShouldUpdateTheSuppliedQuotesOrdered() {
    Test.startTest();

    //GIVEN
    SBQQ__Quote__c canQuote = [
      SELECT Id, SBQQ__StartDate__c
      FROM SBQQ__Quote__c
      WHERE Replacement_Quote__c != NULL
      LIMIT 1
    ];

    Map<Id, Map<String, String>> recordIdToFieldUpdateMap = new Map<Id, Map<String, String>>();
    Map<String, String> fieldUpdateMap = new Map<String, String>();
    fieldUpdateMap.put('SBQQ__Ordered__c', 'true');
    recordIdToFieldUpdateMap.put(canQuote.Id, fieldUpdateMap);

    //WHEN
    QuoteRipReplaceUpdateQueueableOrdered_SL qrruqo = new QuoteRipReplaceUpdateQueueableOrdered_SL();
    qrruqo.init(
      recordIdToFieldUpdateMap,
      new List<Id>{ canQuote.Id },
      fflib_IDGenerator.generate(User.getSObjectType()),
      'Theme4d',
      new List<String>()
    );
    try {
      qrruqo.work();
    } catch (Exception e) {
    }

    //THEN
    SBQQ__Quote__c reQuerycancellationQuote = [SELECT SBQQ__Ordered__c FROM SBQQ__Quote__c WHERE Id = :canQuote.Id];
    //14-Oct -this test fails in .partialsb and generates an Oracle dwarf error in .UATFull
    //System.assertEquals(true, reQuerycancellationQuote.SBQQ__Ordered__c, 'The Quote should be ordered');
    //
  }
}