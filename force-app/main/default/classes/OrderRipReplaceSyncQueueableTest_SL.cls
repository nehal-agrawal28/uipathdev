@isTest(isParallel=false)
public with sharing class OrderRipReplaceSyncQueueableTest_SL {
  //TODO Fix

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
    Account account = DataFactory_CM.createAccount('Customer', false);
    account.NS_Customer_Internal_ID__c = '121212';
    account.DNBoptimizer__DNB_D_U_N_S_Number__c = '1234567';
    account.currencyIsoCode = 'USD';
    account.VAT_Number__c = '12345';
    insert account;

    Address__c address = DataFactory_CM.createAddress(1, account.Id, false)[0];
    address.Primary_Billing__c = true;
    address.Primary_Shipping__c = true;
    address.NS_Address_Internal_ID__c = '6776';
    insert address;

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
    insert new List<PricebookEntry>{ pbe };

    List<Opportunity> opps = new List<Opportunity>();
    //rip and replace - opp/quote
    Opportunity rrOpp = DataFactory_SL.createOpportunity(account.Id, false);
    rrOpp.Name = RR_OPP_NAME;
    rrOpp.Replacement_Transaction__c = true;
    opps.add(rrOpp);

    //cancellation - opp/quote
    Opportunity cancellationOpp = DataFactory_SL.createOpportunity(account.Id, false);
    cancellationOpp.Pricebook2Id = Test.getStandardPricebookId();
    opps.add(cancellationOpp);

    //non-RR - opp/quote
    Opportunity nonScopeOpp = DataFactory_SL.createOpportunity(account.Id, false);
    nonScopeOpp.Name = NON_SCOPE_OPP_NAME;
    opps.add(nonScopeOpp);

    insert opps;

    SBQQ__Quote__c rrQuote = DataFactory_SL.createCPQQuote(account.Id, rrOpp.Id, false);
    rrQuote.SBQQ__StartDate__c = START_DATE_FOR_RR;
    rrQuote.SBQQ__EndDate__c = System.today().addMonths(12).addDays(-1);
    rrQuote.SBQQ__BillingFrequency__c = 'Annual';
    rrQuote.SBQQ__Primary__c = true;
    rrQuote.Replacement_Transaction__c = true;
    insert rrQuote;

    List<SBQQ__Quote__c> qToInsert = new List<SBQQ__Quote__c>();
    SBQQ__Quote__c cancellationQuote = DataFactory_SL.createCPQQuote(account.Id, cancellationOpp.Id, false);
    cancellationQuote.SBQQ__StartDate__c = START_DATE_FOR_RR;
    cancellationQuote.SBQQ__EndDate__c = System.today().addMonths(6).addDays(-1);
    cancellationQuote.Replacement_Quote__c = rrQuote.Id;
    cancellationQuote.SBQQ__BillingFrequency__c = 'Annual';
    cancellationQuote.SBQQ__Primary__c = true;
    qToInsert.add(cancellationQuote);

    SBQQ__Quote__c nonScopeQuote = DataFactory_SL.createCPQQuote(account.Id, nonScopeOpp.Id, false);
    nonScopeQuote.SBQQ__StartDate__c = START_DATE_FOR_NONSCOPE;
    nonScopeQuote.SBQQ__EndDate__c = START_DATE_FOR_NONSCOPE.addMonths(12).addDays(-1);
    nonScopeQuote.SBQQ__BillingFrequency__c = 'Annual';
    nonScopeQuote.SBQQ__Primary__c = true;
    qToInsert.add(nonScopeQuote);

    insert qToInsert;

    //QLIs
    List<SBQQ__QuoteLine__c> qlToInsert = new List<SBQQ__QuoteLine__c>();
    SBQQ__QuoteLine__c cancellationQli = DataFactory_SL.createCPQQuoteLine(prod.Id, cancellationQuote.Id, false);
    cancellationQli.SBQQ__Quantity__c = 2;
    cancellationQli.SBQQ__PricebookEntryId__c = pbe.Id;
    qlToInsert.add(cancellationQli);

    SBQQ__QuoteLine__c rrQli = DataFactory_SL.createCPQQuoteLine(prod.Id, rrQuote.Id, false);
    rrQli.SBQQ__Quantity__c = 2;
    rrQli.SBQQ__PricebookEntryId__c = pbe.Id;
    qlToInsert.add(rrQli);

    SBQQ__QuoteLine__c nonScopeQli = DataFactory_SL.createCPQQuoteLine(prod.Id, nonScopeQuote.Id, false);
    nonScopeQli.SBQQ__Quantity__c = 20;
    nonScopeQli.SBQQ__PricebookEntryId__c = pbe.Id;
    qlToInsert.add(nonScopeQli);

    insert qlToInsert;

    //RR order
    Order rrOrder = new Order(
      AccountId = account.Id,
      SBQQ__Quote__c = rrQuote.Id,
      OpportunityId = rrOpp.Id,
      Status = ORDER_DRAFT_STATUS,
      EffectiveDate = START_DATE_FOR_RR,
      Pricebook2Id = Test.getStandardPricebookId(),
      Replacement_Transaction__c = true
    );
    insert rrOrder;

    OrderItem rrOrderline = new OrderItem(
      OrderId = rrOrder.Id,
      Product2Id = prod.Id,
      Quantity = 2,
      SBQQ__OrderedQuantity__c = 2,
      SBQQ__QuotedQuantity__c = 2,
      SBQQ__QuoteLine__c = rrQli.Id,
      ServiceDate = START_DATE_FOR_RR,
      UnitPrice = 1000,
      PricebookEntryId = pbe.Id
    );
    insert rrOrderline;

    //cancellation order
    Order cancellationOrder = new Order(
      AccountId = account.Id,
      SBQQ__Quote__c = cancellationQuote.Id,
      OpportunityId = cancellationOpp.Id,
      Status = ORDER_DRAFT_STATUS,
      EffectiveDate = START_DATE_FOR_RR,
      Replacement_Order__c = rrOrder.Id,
      Pricebook2Id = Test.getStandardPricebookId()
    );
    insert cancellationOrder;

    OrderItem cancellationOrderline = new OrderItem(
      OrderId = cancellationOrder.Id,
      Product2Id = prod.Id,
      Quantity = 2,
      SBQQ__OrderedQuantity__c = 2,
      SBQQ__QuotedQuantity__c = 2,
      SBQQ__QuoteLine__c = cancellationQli.Id,
      ServiceDate = START_DATE_FOR_RR,
      UnitPrice = 1000,
      PricebookEntryId = pbe.Id
    );
    insert cancellationOrderline;

    Test.startTest();
    List<Order> orders = [SELECT Id, Status FROM Order];
    System.assertEquals(2, orders.size(), 'There should be two orders in the test db');
    for (Order o : orders) {
      System.assertEquals(
        ORDER_DRAFT_STATUS,
        o.Status,
        'All orders should currently be in Status: \'' +
        ORDER_DRAFT_STATUS +
        '\''
      );
    }
    Test.stopTest();

    SBQQ.TriggerControl.enable();
  }

  @IsTest
  static void testSyncCancelledOrdersWithReplacementOrdersStatus() {
    SBQQ.TriggerControl.disable();
    Test.startTest();

    //SETUP
    Order rrOrder = [
      SELECT Id, Status, AccountId, SBQQ__Quote__c
      FROM Order
      WHERE OpportunityId IN (SELECT Id FROM Opportunity WHERE Name = :RR_OPP_NAME)
      LIMIT 1
    ];
    Order cancellationOrder = [SELECT Id, Status FROM Order WHERE Replacement_Order__c = :rrOrder.Id LIMIT 1];
    System.assertNotEquals(rrOrder.Id, cancellationOrder.Id);

    //try to insert second cancelled order
    Product2 prod = [SELECT Id FROM Product2];
    PricebookEntry pbe = [SELECT Id FROM PricebookEntry WHERE Product2Id = :prod.Id];

    Opportunity cancellationOpp2 = DataFactory_SL.createOpportunity(rrOrder.AccountId, true);
    cancellationOpp2.Pricebook2Id = Test.getStandardPricebookId();
    update cancellationOpp2;

    List<SBQQ__Quote__c> qToInsert2 = new List<SBQQ__Quote__c>();
    SBQQ__Quote__c cancellationQuote2 = DataFactory_SL.createCPQQuote(rrOrder.AccountId, cancellationOpp2.Id, false);
    cancellationQuote2.SBQQ__StartDate__c = START_DATE_FOR_RR;
    cancellationQuote2.SBQQ__EndDate__c = System.today().addMonths(6).addDays(-1);
    cancellationQuote2.Replacement_Quote__c = rrOrder.SBQQ__Quote__c;
    cancellationQuote2.SBQQ__BillingFrequency__c = 'Annual';
    cancellationQuote2.SBQQ__Primary__c = true;
    insert cancellationQuote2;

    SBQQ__QuoteLine__c cancellationQli2 = DataFactory_SL.createCPQQuoteLine(prod.Id, cancellationQuote2.Id, false);
    cancellationQli2.SBQQ__Quantity__c = 2;
    cancellationQli2.SBQQ__PricebookEntryId__c = pbe.Id;
    insert cancellationQli2;

    Order cancellationOrder2 = new Order(
      AccountId = rrOrder.AccountId,
      SBQQ__Quote__c = cancellationQuote2.Id,
      OpportunityId = cancellationOpp2.Id,
      Status = ORDER_DRAFT_STATUS,
      EffectiveDate = START_DATE_FOR_RR,
      Replacement_Order__c = rrOrder.Id,
      Pricebook2Id = Test.getStandardPricebookId()
    );
    insert cancellationOrder2;

    OrderItem cancellationOrderline2 = new OrderItem(
      OrderId = cancellationOrder2.Id,
      Product2Id = prod.Id,
      Quantity = 2,
      SBQQ__OrderedQuantity__c = 2,
      SBQQ__QuotedQuantity__c = 2,
      SBQQ__QuoteLine__c = cancellationQli2.Id,
      ServiceDate = START_DATE_FOR_RR,
      UnitPrice = 1000,
      PricebookEntryId = pbe.Id
    );
    insert cancellationOrderline2;

    //

    //ACT
    rrOrder.Status = ORDER_ACTIVATED_STATUS;
    //TODO Commented 11-Oct-21 - to be investigated/remedied
    //update rrOrder;
    Test.stopTest();

    //ASSERT
    //Feature Toggle
    List<CPQ_RR_Sync_Feature__mdt> featureControls = new List<CPQ_RR_Sync_Feature__mdt>();
    try {
      featureControls = [
        SELECT Is_Active__c
        FROM CPQ_RR_Sync_Feature__mdt
        WHERE Sync_Target_Object__c = 'Order' AND Is_Active__c = TRUE
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
    Order requeryRROrder = [SELECT Id, Status FROM Order WHERE Id = :rrOrder.Id LIMIT 1];
    Order requeryCancellationOrder = [SELECT Id, Status FROM Order WHERE Id = :cancellationOrder.Id LIMIT 1];
    //TODO Commented 11-Oct-21 - to be investigated/remedied
    /*System.assertEquals(
      ORDER_ACTIVATED_STATUS,
      requeryRROrder.Status,
      'RR Order should currently be in Status: \'' +
      ORDER_ACTIVATED_STATUS +
      '\''
    );
    System.assertEquals(
      ORDER_ACTIVATED_STATUS,
      requeryCancellationOrder.Status,
      'Cancellation Order should currently be in Status: \'' +
      ORDER_ACTIVATED_STATUS +
      '\''
    );
    */
  }

  @isTest
  static void testSyncCancelledOrdersWithReplacementOrdersStatusNonScopeOrder() {
    //SETUP
    //CPQ blows soql limit inserting >2 orders
    //nonscope order
    /*SBQQ.TriggerControl.disable();
    
	Test.startTest();
    Id accountId = [SELECT Id FROM Account LIMIT 1].Id;
    //Id addressId = [SELECT Id FROM Address__c LIMIT 1].Id;
    Id nonScopeOppId = [SELECT Id FROM Opportunity WHERE Name = :NON_SCOPE_OPP_NAME LIMIT 1].Id;
    Id nonScopeQuoteId = [SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__c = :nonScopeOppId].Id;
    Id prodId = [SELECT Id FROM Product2 LIMIT 1].Id;
    Id nonScopeQliId = [SELECT Id FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c = :nonScopeQuoteId].Id;
    Id pbeId = [SELECT Id FROM PricebookEntry LIMIT 1].Id;
	Test.stopTest();
    Order nonScopeOrder = new Order(
      AccountId = accountId,
      SBQQ__Quote__c = nonScopeQuoteId,
      OpportunityId = nonScopeOppId,
      Status = ORDER_DRAFT_STATUS,
      EffectiveDate = START_DATE_FOR_NONSCOPE,
      Pricebook2Id = Test.getStandardPricebookId()
    );
    insert nonScopeOrder;
      
    OrderItem nonScopeOrderline = new OrderItem(
      OrderId = nonScopeOrder.Id,
      Product2Id = prodId,
      Quantity = 1,
      SBQQ__OrderedQuantity__c = 1,
      SBQQ__QuotedQuantity__c = 1,
      SBQQ__QuoteLine__c = nonScopeQliId,
      ServiceDate = START_DATE_FOR_NONSCOPE,
      UnitPrice = 1000,
      PricebookEntryId = pbeId
    );
    insert nonScopeOrderline;
	
    System.assertEquals(3, [SELECT Id FROM Order].size(), 'There should be three orders in the test db');*/

    /*Order rrOrder = [
      SELECT Id, Status
      FROM Order
      WHERE OpportunityId IN (SELECT Id FROM Opportunity WHERE Name = :RR_OPP_NAME)
      LIMIT 1
    ];*/
    //Order cancellationOrder = [SELECT Id, Status FROM Order WHERE Replacement_Order__c = :rrOrder.Id LIMIT 1];

    //ACT
    //rrOrder.Status = ORDER_ACTIVATED_STATUS;
    //TODO Commented 11-Oct-21 - to be investigated/remedied
    //update rrOrder;

    //ASSERT
    //Order requeryRROrder = [SELECT Id, Status FROM Order WHERE Id = :rrOrder.Id LIMIT 1];
    //Order requeryCancellationOrder = [SELECT Id, Status FROM Order WHERE Id = :cancellationOrder.Id LIMIT 1];
    //Order requeryNonScopeOrder = [SELECT Id, Status FROM Order WHERE Id = :nonScopeOrder.Id LIMIT 1];

    //TODO Commented 11-Oct-21 - to be investigated/remedied
    /*System.assertEquals(
      ORDER_ACTIVATED_STATUS,
      requeryRROrder.Status,
      'RR Order should currently be in Status: \'' +
      ORDER_ACTIVATED_STATUS +
      '\''
    );
    System.assertEquals(
      ORDER_ACTIVATED_STATUS,
      requeryCancellationOrder.Status,
      'Cancellation Order should currently be in Status: \'' +
      ORDER_ACTIVATED_STATUS +
      '\''
    );
    System.assertEquals(
      ORDER_DRAFT_STATUS,
      requeryNonScopeOrder.Status,
      'Non scope Order should currently be in Status: \'' +
      ORDER_DRAFT_STATUS +
      '\''
    );
    */
  }
}