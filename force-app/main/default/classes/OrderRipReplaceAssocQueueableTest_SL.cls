@isTest(isParallel=false)
public with sharing class OrderRipReplaceAssocQueueableTest_SL {
  static final Date START_DATE_FOR_RR = System.today().addDays(7);

  @TestSetup
  static void makeData() {
    SBQQ.TriggerControl.disable();
    //Setup
    Account account = DataFactory_CM.createAccount('Customer', false);
    insert account;

    //rip and replace - opp/quote
    Opportunity rrOpp = DataFactory_SL.createOpportunity(account.Id, true);

    SBQQ__Quote__c rrQuote = DataFactory_SL.createCPQQuote(account.Id, rrOpp.Id, false);
    rrQuote.SBQQ__StartDate__c = START_DATE_FOR_RR;
    rrQuote.SBQQ__EndDate__c = System.today().addMonths(12).addDays(-1);
    rrQuote.SBQQ__BillingFrequency__c = 'Annual';
    rrQuote.SBQQ__Primary__c = true;
    insert rrQuote;
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

    //setup
    //add product and pbe
    Id standardPricebookId = Test.getStandardPricebookId();

    Product2 prod = new Product2(
      Name = 'Product Uipath 1' + String.valueOf((Math.random() * 100) + 1),
      ProductCode = 'PROD' + String.valueOf((Math.random() * 100) + 1),
      isActive = true
    );
    insert new List<Product2>{ prod };

    //QLI
    SBQQ__QuoteLine__c qli = DataFactory_SL.createCPQQuoteLine(prod.Id, cancellationQuote.Id, false);
    qli.SBQQ__Quantity__c = 2;
    insert qli;
    //
    SBQQ.TriggerControl.enable();
  }

  /*
   * When an order is associated to a cancellation quote, the order should self identify
   * as a cancellation transaction
   */
  @isTest
  public static void cancellationOrderSelfIdentificationTest() {
    SBQQ__Quote__c cancellationQuote = [
      SELECT Id, SBQQ__Account__c, Replacement_Quote__c
      FROM SBQQ__Quote__c
      WHERE Replacement_Quote__c != NULL
      LIMIT 1
    ];
    Order cancellationOrder = new Order(
      AccountId = cancellationQuote.SBQQ__Account__c,
      SBQQ__Quote__c = cancellationQuote.Id,
      EffectiveDate = Date.today(),
      Status = 'Draft'
    );
    insert cancellationOrder;

    Order requeryCancellationOrder = [
      SELECT Id, Cancellation_Transaction__c
      FROM Order
      WHERE Id = :cancellationOrder.Id
    ];

    System.assertEquals(
      true,
      requeryCancellationOrder.Cancellation_Transaction__c,
      'Cancellation order should self ID as a cancellation transaction'
    );
  }

  /*
   * When a cancellation order is created the order should be associated
   * with the replacement order
   */
  @isTest
  public static void cancellationOrderAssociationTest() {
    //SETUP
    SBQQ__Quote__c replacementQuote = [
      SELECT Id, SBQQ__Account__c, Replacement_Quote__c
      FROM SBQQ__Quote__c
      WHERE Replacement_Quote__c = NULL
      LIMIT 1
    ];
    Order replacementOrder = new Order(
      AccountId = replacementQuote.SBQQ__Account__c,
      SBQQ__Quote__c = replacementQuote.Id,
      EffectiveDate = Date.today(),
      Status = 'Draft'
    );
    insert replacementOrder;

    SBQQ__Quote__c cancellationQuote = [
      SELECT Id, SBQQ__Account__c, Replacement_Quote__c
      FROM SBQQ__Quote__c
      WHERE Replacement_Quote__c != NULL
      LIMIT 1
    ];

    Order cancellationOrder = new Order(
      AccountId = cancellationQuote.SBQQ__Account__c,
      SBQQ__Quote__c = cancellationQuote.Id,
      EffectiveDate = Date.today(),
      Status = 'Draft'
    );
    //

    //ACT
    Test.startTest();
    insert cancellationOrder;
    Test.stopTest();
    //

    //ASSERT
    Order requeryCancellationOrder = [
      SELECT Id, SBQQ__Quote__c, Replacement_Order__c
      FROM Order
      WHERE Id = :cancellationOrder.Id
    ];
    SBQQ__Quote__c requeryCancellationQuote = [
      SELECT Id, Replacement_Quote__c
      FROM SBQQ__Quote__c
      WHERE Id = :requeryCancellationOrder.SBQQ__Quote__c
    ];
    Order requeryReplacementOrder = [
      SELECT Id
      FROM Order
      WHERE SBQQ__Quote__c = :requeryCancellationQuote.Replacement_Quote__c
    ];

    //1. cancellation order to cancellation quote
    System.debug('1. requeryCancellationOrder.SBQQ__Quote__c: ' + requeryCancellationOrder.SBQQ__Quote__c);
    //2. cancellation quote to parent quote
    System.debug('2. requeryCancellationQuote.Replacement_Quote__c: ' + requeryCancellationQuote.Replacement_Quote__c);
    //3. replacement order
    System.debug('3 replacementOrder: ' + replacementOrder);

    System.assertEquals(
      replacementOrder.Id,
      requeryCancellationOrder.Replacement_Order__c,
      'Cancellation order should be associated to replacement order'
    );
    //
  }
}