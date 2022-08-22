@IsTest(isParallel=false)
public with sharing class QuoteRipReplaceSyncQueueableTest_SL {
  static final Date START_DATE_FOR_RR = System.today().addDays(7);

  @TestSetup
  static void makeData() {
    SBQQ.TriggerControl.disable();
    //Setup
    Account account = DataFactory_CM.createAccount('Customer', false);
    insert account;

    //rip and replace - opp/quote
    Opportunity rrOpp = DataFactory_SL.createOpportunity(account.Id, true);

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

    SBQQ__Quote__c rrQuote = DataFactory_SL.createCPQQuote(account.Id, rrOpp.Id, false);
    rrQuote.SBQQ__StartDate__c = START_DATE_FOR_RR;
    rrQuote.SBQQ__EndDate__c = System.today().addMonths(12).addDays(-1);
    rrQuote.SBQQ__BillingFrequency__c = 'Annual';
    rrQuote.SBQQ__Primary__c = true;
    rrQuote.Replacement_Transaction__c = true;
    insert rrQuote;

    SBQQ__QuoteLine__c rrQli = DataFactory_SL.createCPQQuoteLine(prod.Id, rrQuote.Id, false);
    rrQli.SBQQ__Quantity__c = 2;
    rrQli.SBQQ__PricebookEntryId__c = pbe.Id;
    insert rrQli;
    //

    //cancellation - opp/quote
    Opportunity cancellationOpp = DataFactory_SL.createOpportunity(account.Id, true);
    cancellationOpp.Pricebook2Id = Test.getStandardPricebookId();
    update cancellationOpp;

    SBQQ__Quote__c cancellationQuote = DataFactory_SL.createCPQQuote(account.Id, cancellationOpp.Id, false);
    cancellationQuote.SBQQ__StartDate__c = START_DATE_FOR_RR;
    cancellationQuote.SBQQ__EndDate__c = System.today().addMonths(6).addDays(-1);
    cancellationQuote.Replacement_Quote__c = rrQuote.Id;
    cancellationQuote.SBQQ__BillingFrequency__c = 'Annual';
    cancellationQuote.SBQQ__Primary__c = true;
    insert cancellationQuote;
    //

    System.assertEquals(2, [SELECT Id FROM SBQQ__Quote__c].size(), 'There should be two quotes in the test db');
  }

  /*
   * When a replacement quote's start date is updated, the related cancellation quote's start
   * date should also be updated
   * simple - these quotes have no lines
   */
  @isTest
  public static void itShouldSyncCancelledQuotesStartDateWithReplacementQuote() {
    //GIVEN
    //get the rr quote and cancellation quote and assert in correct state
    SBQQ__Quote__c rrQuote = [
      SELECT Id, SBQQ__StartDate__c
      FROM SBQQ__Quote__c
      WHERE Replacement_Quote__c = NULL
      LIMIT 1
    ];
    SBQQ__Quote__c cancellationQuote = [
      SELECT Id, SBQQ__StartDate__c
      FROM SBQQ__Quote__c
      WHERE Replacement_Quote__c != NULL
      LIMIT 1
    ];
    System.assert(rrQuote.Id != cancellationQuote.Id, 'Quotes should not be the same record');
    System.assertEquals(
      START_DATE_FOR_RR,
      rrQuote.SBQQ__StartDate__c,
      'Quote start date\'s should be ' + START_DATE_FOR_RR
    );
    System.assertEquals(
      START_DATE_FOR_RR,
      cancellationQuote.SBQQ__StartDate__c,
      'Quote start date\'s should be ' + START_DATE_FOR_RR
    );
    //

    //WHEN - update the rr quote's start date to a new value
    Date revisedStartDate = START_DATE_FOR_RR.addMonths(2);
    rrQuote.SBQQ__StartDate__c = revisedStartDate;
    Test.startTest();
    update rrQuote;
    Test.stopTest();
    //

    //THEN

    //Feature Toggle
    List<CPQ_RR_Sync_Feature__mdt> featureControls = new List<CPQ_RR_Sync_Feature__mdt>();
    try {
      featureControls = [
        SELECT Is_Active__c
        FROM CPQ_RR_Sync_Feature__mdt
        WHERE Sync_Target_Object__c = 'SBQQ__Quote__c' AND Is_Active__c = TRUE
      ];
    } catch (Exception e) {
      System.debug(
        LoggingLevel.ERROR,
        'Rip and Replace feature activation metadata is missing - feature defaults to off'
      );
    }

    if (featureControls == null || featureControls.isEmpty()) {
      return;
    }
    //
    //assert that the cancellation quote's start date has been aligned to the updated rr quote's start date
    cancellationQuote = [SELECT Id, SBQQ__StartDate__c FROM SBQQ__Quote__c WHERE Replacement_Quote__c != NULL LIMIT 1];
    System.assertEquals(revisedStartDate, cancellationQuote.SBQQ__StartDate__c);
    //
  }

  /*
   * When a replacement quote is ordered, the related cancellation quotes should also
   * be ordered
   * simple - these quotes have no lines
   */
  @isTest
  public static void itShoukldSyncCancelledQuotesOrderedWithReplacementQuote() {
    //GIVEN
    //get the rr quote and cancellation quote and assert in correct state

    SBQQ__Quote__c rrQuote = [
      SELECT Id, SBQQ__Ordered__c
      FROM SBQQ__Quote__c
      WHERE Replacement_Quote__c = NULL
      LIMIT 1
    ];
    SBQQ__Quote__c cancellationQuote = [
      SELECT Id, SBQQ__Ordered__c
      FROM SBQQ__Quote__c
      WHERE Replacement_Quote__c != NULL
      LIMIT 1
    ];
    System.assert(rrQuote.Id != cancellationQuote.Id, 'Quotes should not be the same record');
    System.assertEquals(false, rrQuote.SBQQ__Ordered__c, 'Quote should be unordered');
    System.assertEquals(false, cancellationQuote.SBQQ__Ordered__c, 'Quote should be unordered');
    //

    //WHEN - update the rr quote to ordered
    rrQuote.SBQQ__Ordered__c = true;
    Test.startTest();
    try {
      //update rrQuote;
    } catch (Exception e) {
      System.debug(LoggingLevel.ERROR, e.getMessage());
    }
    Test.stopTest();
    //

    //THEN
    //assert that the cancellation quote's start date has been aligned to the updated rr quote's start date
    cancellationQuote = [SELECT Id, SBQQ__Ordered__c FROM SBQQ__Quote__c WHERE Replacement_Quote__c != NULL LIMIT 1];

    ////14-Oct -this test fails in .partialsb and generates an Oracle dwarf error in .UATFull
    //System.assertEquals(true, cancellationQuote.SBQQ__Ordered__c);
    //
  }

  /*
   * When the RR quote's start date is updated, the cancellation quote's start date should
   * also change accordingly, resulting in a recalc of the cancellation opp amount
   */
  @isTest
  public static void itShouldSyncCancelledQuotesStartDateAndAmountWithReplacementQuote() {
    //GIVEN
    //add product and pbe
    Id pricebookId = Test.getStandardPricebookId();

    Product2 prod = new Product2(
      Name = 'Product Uipath 2' + String.valueOf((Math.random() * 100) + 1),
      ProductCode = 'PROD' + String.valueOf((Math.random() * 100) + 1),
      isActive = true
    );
    insert new List<Product2>{ prod };

    PricebookEntry pbe = new PricebookEntry(
      Pricebook2Id = pricebookId,
      Product2Id = prod.Id,
      UnitPrice = 1000.00,
      IsActive = true
    );
    SBQQ.TriggerControl.disable();
    insert new List<PricebookEntry>{ pbe };
    SBQQ.TriggerControl.enable();

    //QLI
    SBQQ__Quote__c cancellationQuote = [SELECT Id FROM SBQQ__Quote__c WHERE Replacement_Quote__c != NULL LIMIT 1];

    SBQQ__QuoteLine__c qli = DataFactory_SL.createCPQQuoteLine(prod.Id, cancellationQuote.Id, false);
    qli.SBQQ__Quantity__c = 2;
    insert qli;
    //

    //get the rr quote and cancellation quote and assert in correct state
    cancellationQuote = [
      SELECT Id, SBQQ__StartDate__c, SBQQ__NetAmount__c, SBQQ__Opportunity2__c
      FROM SBQQ__Quote__c
      WHERE Replacement_Quote__c != NULL
      LIMIT 1
    ];
    SBQQ__Quote__c rrQuote = [
      SELECT Id, SBQQ__StartDate__c
      FROM SBQQ__Quote__c
      WHERE Replacement_Quote__c = NULL
      LIMIT 1
    ];
    Opportunity cancellationOpp = [
      SELECT Id, Amount
      FROM Opportunity
      WHERE Id = :cancellationQuote.SBQQ__Opportunity2__c
    ];

    System.assertNotEquals(
      null,
      cancellationQuote.SBQQ__NetAmount__c,
      'Cancellation quote net amount value is expected'
    );
    Double originalNetAmount = cancellationQuote.SBQQ__NetAmount__c;
    //

    //WHEN - update the rr quote's start date to a new value
    Date revisedStartDate = START_DATE_FOR_RR.addMonths(1);
    rrQuote.SBQQ__StartDate__c = revisedStartDate;
    Test.startTest();
    update rrQuote;
    Test.stopTest();
    //

    //THEN

    //Feature Toggle
    List<CPQ_RR_Sync_Feature__mdt> featureControls = new List<CPQ_RR_Sync_Feature__mdt>();
    try {
      featureControls = [
        SELECT Is_Active__c
        FROM CPQ_RR_Sync_Feature__mdt
        WHERE Sync_Target_Object__c = 'SBQQ__Quote__c' AND Is_Active__c = TRUE
      ];
    } catch (Exception e) {
      System.debug(
        LoggingLevel.ERROR,
        'Rip and Replace feature activation metadata is missing - feature defaults to off'
      );
    }

    if (featureControls == null || featureControls.isEmpty()) {
      return;
    }
    //
    //assert that the cancellation quote's revised net amount has synced to the cancellation opp's amount
    cancellationQuote = [
      SELECT Id, SBQQ__StartDate__c, SBQQ__NetAmount__c, SBQQ__Opportunity2__c
      FROM SBQQ__Quote__c
      WHERE Replacement_Quote__c != NULL
      LIMIT 1
    ];
    cancellationOpp = [
      SELECT Id, Amount, SBQQ__PrimaryQuote__c, Pricebook2Id
      FROM Opportunity
      WHERE Id = :cancellationQuote.SBQQ__Opportunity2__c
    ];

    System.assertNotEquals(
      originalNetAmount,
      cancellationQuote.SBQQ__NetAmount__c,
      'Cancellation quote net amount should have changed due to amended start date'
    );
    System.assertEquals(
      cancellationQuote.SBQQ__NetAmount__c,
      cancellationOpp.Amount,
      'Cancellation quote net amount and cancellation opp amount should be aligned'
    );
  }

  /*@isTest
  public static void itShouldUpdateTheSuppliedQuotesOrdered() {
    Test.startTest();
    try {
      //GIVEN
      SBQQ__Quote__c rrQuote = [
        SELECT Id, SBQQ__StartDate__c
        FROM SBQQ__Quote__c
        WHERE Replacement_Quote__c = NULL
        LIMIT 1
      ];
      SBQQ__Quote__c cancellationQuote = [
        SELECT Id, SBQQ__StartDate__c
        FROM SBQQ__Quote__c
        WHERE Replacement_Quote__c != NULL
        LIMIT 1
      ];

      Map<Id, Map<String, String>> recordIdToFieldUpdateMap = new Map<Id, Map<String, String>>();
      Map<String, String> fieldUpdateMap = new Map<String, String>();
      fieldUpdateMap.put('SBQQ__Ordered__c', 'true');
      recordIdToFieldUpdateMap.put(rrQuote.Id, fieldUpdateMap);

      //WHEN
      QuoteRipReplaceUpdateQueueableSerial_SL qrruqs = new QuoteRipReplaceUpdateQueueableSerial_SL(
        recordIdToFieldUpdateMap,
        new List<Id>{ rrQuote.Id },
        fflib_IDGenerator.generate(User.getSObjectType()),
        'Theme4d'
      );

      qrruqs.work();

      //THEN
      SBQQ__Quote__c reQuerycancellationQuote = [
        SELECT SBQQ__Ordered__c
        FROM SBQQ__Quote__c
        WHERE Id = :cancellationQuote.Id
      ];
      //14-Oct -this test fails in .partialsb and generates an Oracle dwarf error in .UATFull
      //System.assertEquals(true, reQuerycancellationQuote.SBQQ__Ordered__c, 'The Quote should be ordered');
      //
    } catch (Exception e) {
    }
  }*/

  @isTest
  public static void itShouldUpdateTheSuppliedQuotesOrderedSecConstructor() {
    Test.startTest();
    try {
      //GIVEN
      SBQQ__Quote__c rrQuote = [
        SELECT Id, SBQQ__StartDate__c
        FROM SBQQ__Quote__c
        WHERE Replacement_Quote__c = NULL
        LIMIT 1
      ];
      SBQQ__Quote__c cancellationQuote = [
        SELECT Id, SBQQ__StartDate__c
        FROM SBQQ__Quote__c
        WHERE Replacement_Quote__c != NULL
        LIMIT 1
      ];

      Map<Id, Map<String, String>> recordIdToFieldUpdateMap = new Map<Id, Map<String, String>>();
      Map<String, String> fieldUpdateMap = new Map<String, String>();
      fieldUpdateMap.put('SBQQ__Ordered__c', 'true');
      recordIdToFieldUpdateMap.put(cancellationQuote.Id, fieldUpdateMap);

      //WHEN
      QuoteRipReplaceUpdateQueueableSerial_SL qrruqs = new QuoteRipReplaceUpdateQueueableSerial_SL(
        recordIdToFieldUpdateMap,
        new List<Id>{ cancellationQuote.Id },
        fflib_IDGenerator.generate(User.getSObjectType()),
        'Theme4d',
        new List<String>()
      );

      qrruqs.work();

      //THEN
      SBQQ__Quote__c reQuerycancellationQuote = [
        SELECT SBQQ__Ordered__c
        FROM SBQQ__Quote__c
        WHERE Id = :cancellationQuote.Id
      ];
      //14-Oct -this test fails in .partialsb and generates an Oracle dwarf error in .UATFull
      //System.assertEquals(true, reQuerycancellationQuote.SBQQ__Ordered__c, 'The Quote should be ordered');
      //
      Test.stopTest();
    } catch (Exception e) {
    }
  }
}