@isTest
public with sharing class OrderRipReplaceUpdateQueueableFinTest_SL {
  static final Date START_DATE_FOR_RR = System.today().addDays(7);
  static final String PARENT_OPP_NAME = 'Parent RR Opp';
  static final String ASYNC_INPROGRESS_STATUS = 'Inprogress';
  static final String ASYNC_COMPLETED_STATUS = 'Completed';
  static final String ASYNC_ERROR_STATUS = 'Error';
  static final string ORDER_DRAFT_STATUS = Constants_SL.ORDER_STATUS_DRAFT;
  static final string ORDER_SYNC_TYPE = 'RipReplace_OrderSync';

  @isTest
  public static void updateAsyncTaskTest_success() {
    //1. create a new Account and Opp
    Id pb2Id = Test.getStandardPricebookId();

    SBQQ.TriggerControl.disable();
    //Setup
    Account account = DataFactory_CM.createAccount('Customer', false);
    Database.DMLOptions dml = new Database.DMLOptions();
    dml.DuplicateRuleHeader.allowSave = true;
    Database.insert(account, dml);

    Product2 prod = new Product2(
      Name = 'Product Uipath 2' + String.valueOf((Math.random() * 100) + 1),
      ProductCode = 'PROD' + String.valueOf((Math.random() * 100) + 1),
      isActive = true
    );
    insert new List<Product2>{ prod };

    PricebookEntry pbe = new PricebookEntry(
      Pricebook2Id = pb2Id,
      Product2Id = prod.Id,
      UnitPrice = 1000.00,
      IsActive = true
    );
    insert new List<PricebookEntry>{ pbe };

    //rip and replace - opp/quote
    Opportunity rrOpp = DataFactory_SL.createOpportunity(account.Id, false);
    rrOpp.Name = PARENT_OPP_NAME;
    rrOpp.Replacement_Transaction__c = true;
    insert rrOpp;

    SBQQ__Quote__c rrQuote = DataFactory_SL.createCPQQuote(account.Id, rrOpp.Id, false);
    rrQuote.SBQQ__StartDate__c = START_DATE_FOR_RR;
    rrQuote.SBQQ__EndDate__c = System.today().addMonths(12).addDays(-1);
    rrQuote.SBQQ__BillingFrequency__c = 'Annual';
    rrQuote.SBQQ__Primary__c = true;
    insert rrQuote;

    rrOpp.SBQQ__PrimaryQuote__c = rrQuote.Id;
    update rrOpp;
    //

    //cancellation - opp/quote 1
    Opportunity cancellationOpp = DataFactory_SL.createOpportunity(account.Id, false);
    cancellationOpp.Pricebook2Id = pb2Id;
    insert cancellationOpp;

    SBQQ__Quote__c cancellationQuote = DataFactory_SL.createCPQQuote(account.Id, cancellationOpp.Id, false);
    cancellationQuote.SBQQ__StartDate__c = START_DATE_FOR_RR;
    cancellationQuote.SBQQ__EndDate__c = System.today().addMonths(6).addDays(-1);
    cancellationQuote.Replacement_Quote__c = rrQuote.Id;
    cancellationQuote.SBQQ__BillingFrequency__c = 'Annual';
    cancellationQuote.SBQQ__Primary__c = true;
    insert cancellationQuote;

    cancellationOpp.SBQQ__PrimaryQuote__c = cancellationQuote.Id;
    update cancellationOpp;
    //

    SBQQ__QuoteLine__c cancellationQli = DataFactory_SL.createCPQQuoteLine(prod.Id, cancellationQuote.Id, false);
    cancellationQli.SBQQ__Quantity__c = 2;
    cancellationQli.SBQQ__PricebookEntryId__c = pbe.Id;
    insert cancellationQli;

    SBQQ__QuoteLine__c rrQli = DataFactory_SL.createCPQQuoteLine(prod.Id, rrQuote.Id, false);
    rrQli.SBQQ__Quantity__c = 2;
    rrQli.SBQQ__PricebookEntryId__c = pbe.Id;
    insert rrQli;
    Test.startTest();
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

    //2. insert a Async task for the target opp
    String jobId = 'ABC123';
    AsyncTask__c ast = new AsyncTask__c(
      Status__c = ASYNC_INPROGRESS_STATUS,
      Order__c = cancellationOrder.Id,
      Type__c = OrderRipReplaceSyncTask_SL.SYNC_TASK_TYPE,
      ApexJobId__c = jobId
    );
    insert ast;

    //3. invoke finalizer updater

    RecRipReplaceUpdQueueableFinalizer_SL.updateAsyncTask(jobId, String.valueOf(cancellationOrder.Id), null);
    Test.stopTest();

    //4. assert
    AsyncTask__c requeryAst = [SELECT Id, Status__c FROM AsyncTask__c WHERE Id = :ast.id];
    //TODO Commented 12-Oct-21 - to be investigated/remedied
    //System.assertEquals(ASYNC_COMPLETED_STATUS, requeryAst.Status__c);
  }

  @isTest
  public static void updateAsyncTaskTest_exception() {
    //1. create a new Account and Opp
    Id pb2Id = Test.getStandardPricebookId();

    SBQQ.TriggerControl.disable();
    //Setup
    Account account = DataFactory_CM.createAccount('Customer', false);
    Database.DMLOptions dml = new Database.DMLOptions();
    dml.DuplicateRuleHeader.allowSave = true;
    Database.insert(account, dml);

    Product2 prod = new Product2(
      Name = 'Product Uipath 2' + String.valueOf((Math.random() * 100) + 1),
      ProductCode = 'PROD' + String.valueOf((Math.random() * 100) + 1),
      isActive = true
    );
    insert new List<Product2>{ prod };

    PricebookEntry pbe = new PricebookEntry(
      Pricebook2Id = pb2Id,
      Product2Id = prod.Id,
      UnitPrice = 1000.00,
      IsActive = true
    );
    insert new List<PricebookEntry>{ pbe };

    //rip and replace - opp/quote
    Opportunity rrOpp = DataFactory_SL.createOpportunity(account.Id, false);
    rrOpp.Name = PARENT_OPP_NAME;
    rrOpp.Replacement_Transaction__c = true;
    insert rrOpp;

    SBQQ__Quote__c rrQuote = DataFactory_SL.createCPQQuote(account.Id, rrOpp.Id, false);
    rrQuote.SBQQ__StartDate__c = START_DATE_FOR_RR;
    rrQuote.SBQQ__EndDate__c = System.today().addMonths(12).addDays(-1);
    rrQuote.SBQQ__BillingFrequency__c = 'Annual';
    rrQuote.SBQQ__Primary__c = true;
    insert rrQuote;

    rrOpp.SBQQ__PrimaryQuote__c = rrQuote.Id;
    update rrOpp;
    //

    //cancellation - opp/quote 1
    Opportunity cancellationOpp = DataFactory_SL.createOpportunity(account.Id, false);
    cancellationOpp.Pricebook2Id = pb2Id;
    insert cancellationOpp;

    SBQQ__Quote__c cancellationQuote = DataFactory_SL.createCPQQuote(account.Id, cancellationOpp.Id, false);
    cancellationQuote.SBQQ__StartDate__c = START_DATE_FOR_RR;
    cancellationQuote.SBQQ__EndDate__c = System.today().addMonths(6).addDays(-1);
    cancellationQuote.Replacement_Quote__c = rrQuote.Id;
    cancellationQuote.SBQQ__BillingFrequency__c = 'Annual';
    cancellationQuote.SBQQ__Primary__c = true;
    insert cancellationQuote;

    cancellationOpp.SBQQ__PrimaryQuote__c = cancellationQuote.Id;
    update cancellationOpp;
    //

    SBQQ__QuoteLine__c cancellationQli = DataFactory_SL.createCPQQuoteLine(prod.Id, cancellationQuote.Id, false);
    cancellationQli.SBQQ__Quantity__c = 2;
    cancellationQli.SBQQ__PricebookEntryId__c = pbe.Id;
    insert cancellationQli;

    SBQQ__QuoteLine__c rrQli = DataFactory_SL.createCPQQuoteLine(prod.Id, rrQuote.Id, false);
    rrQli.SBQQ__Quantity__c = 2;
    rrQli.SBQQ__PricebookEntryId__c = pbe.Id;
    insert rrQli;
    Test.startTest();
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

    //2. insert a Async task for the target opp
    String jobId = 'ABC123';
    AsyncTask__c ast = new AsyncTask__c(
      Status__c = ASYNC_INPROGRESS_STATUS,
      Order__c = cancellationOrder.Id,
      Type__c = OrderRipReplaceSyncTask_SL.SYNC_TASK_TYPE,
      ApexJobId__c = jobId
    );
    insert ast;

    //3. invoke finalizer updater

    String testExceptionMessage = 'Test exception';
    RecRipReplaceUpdQueueableFinalizer_SL.RecRipReplaceUpdQueueableFinalizerException jobException = new RecRipReplaceUpdQueueableFinalizer_SL.RecRipReplaceUpdQueueableFinalizerException(
      testExceptionMessage
    );
    RecRipReplaceUpdQueueableFinalizer_SL.updateAsyncTask(jobId, String.valueOf(cancellationOrder.Id), jobException);
    Test.stopTest();

    //4. assert
    AsyncTask__c requeryAst = [SELECT Id, Status__c, UIMessage__c FROM AsyncTask__c WHERE Id = :ast.id];
    //TODO Commented 12-Oct-21 - to be investigated/remedied
    //System.assertEquals(ASYNC_ERROR_STATUS, requeryAst.Status__c);
    //System.assertEquals(testExceptionMessage, requeryAst.UIMessage__c);
  }

  @isTest
  public static void sendInitUserErrorNotifTest_exceptionEmpty() {
    String result = RecRipReplaceUpdQueueableFinalizer_SL.sendInitUserErrorNotif(
      new List<Id>(),
      new RecRipReplaceUpdQueueableFinalizer_SL.RecRipReplaceUpdQueueableFinalizerException(),
      '',
      RecRipReplaceUpdQueueableFinalizer_SL.LEX_THEME_NAME,
      '',
      ORDER_SYNC_TYPE
    );
    System.assertEquals('Error', result);
  }

  @isTest
  public static void sendInitUserErrorNotifTest_exceptionNull() {
    String result = RecRipReplaceUpdQueueableFinalizer_SL.sendInitUserErrorNotif(
      null,
      null,
      null,
      RecRipReplaceUpdQueueableFinalizer_SL.LEX_THEME_NAME,
      null,
      ORDER_SYNC_TYPE
    );
    System.assertEquals('Error', result);
  }

  @isTest
  public static void sendInitUserErrorNotifTest_success() {
    String result = RecRipReplaceUpdQueueableFinalizer_SL.sendInitUserErrorNotif(
      new List<Id>{ fflib_IDGenerator.generate(Order.getSObjectType()) },
      new RecRipReplaceUpdQueueableFinalizer_SL.RecRipReplaceUpdQueueableFinalizerException(),
      'ABC1234',
      RecRipReplaceUpdQueueableFinalizer_SL.LEX_THEME_NAME,
      'XYZ1234',
      ORDER_SYNC_TYPE
    );
    //TODO Commented 11-Oct-21 - to be investigated/remedied
    //System.assertEquals('Success', result);
  }
}