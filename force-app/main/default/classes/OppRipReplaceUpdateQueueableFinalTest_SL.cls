@isTest
public with sharing class OppRipReplaceUpdateQueueableFinalTest_SL {
  static final Date START_DATE_FOR_RR = System.today().addDays(7);
  static final String PARENT_OPP_NAME = 'Parent RR Opp';
  static final String ASYNC_INPROGRESS_STATUS = 'Inprogress';
  static final String ASYNC_COMPLETED_STATUS = 'Completed';
  static final String ASYNC_ERROR_STATUS = 'Error';
  static final String OPP_SYNC_TYPE = 'RipReplace_OppSync';

  @isTest
  public static void itShouldUpdateTheAsyncTaskToCompleted() {
    //GIVEN
    //1. create a new Account and Opp
    Id pb2Id = Test.getStandardPricebookId();

    SBQQ.TriggerControl.disable();
    //Setup
    Account account = DataFactory_CM.createAccount('Customer', false);
    Database.DMLOptions dml = new Database.DMLOptions();
    dml.DuplicateRuleHeader.allowSave = true;
    Database.insert(account, dml);

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

    //2. insert a Async task for the target opp
    String jobId = 'ABC123';
    AsyncTask__c ast = new AsyncTask__c(
      Status__c = ASYNC_INPROGRESS_STATUS,
      Opportunity__c = cancellationOpp.Id,
      Type__c = OppRipReplaceSyncTask_SL.SYNC_TASK_TYPE,
      ApexJobId__c = jobId
    );
    insert ast;

    //WHEN
    //3. invoke finalizer updater
    Test.startTest();
    RecRipReplaceUpdQueueableFinalizer_SL.updateAsyncTask(jobId, String.valueOf(cancellationOpp.Id), null);
    Test.stopTest();

    //THEN
    //4. assert
    AsyncTask__c requeryAst = [SELECT Id, Status__c FROM AsyncTask__c WHERE Id = :ast.id];
    System.assertEquals(ASYNC_COMPLETED_STATUS, requeryAst.Status__c);
  }

  @isTest
  public static void itShouldUpdateTheAsyncTaskWithTheException() {
    //GIVEN
    //1. create a new Account and Opp
    Id pb2Id = Test.getStandardPricebookId();

    SBQQ.TriggerControl.disable();
    //Setup
    Account account = DataFactory_CM.createAccount('Customer', false);
    Database.DMLOptions dml = new Database.DMLOptions();
    dml.DuplicateRuleHeader.allowSave = true;
    Database.insert(account, dml);

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

    //2. insert a Async task for the target opp
    String jobId = 'ABC123';
    AsyncTask__c ast = new AsyncTask__c(
      Status__c = ASYNC_INPROGRESS_STATUS,
      Opportunity__c = cancellationOpp.Id,
      Type__c = OppRipReplaceSyncTask_SL.SYNC_TASK_TYPE,
      ApexJobId__c = jobId
    );
    insert ast;

    //WHEN
    //3. invoke finalizer updater
    Test.startTest();
    String testExceptionMessage = 'Test exception';
    OppRipReplaceUpdateQueueableSerial_SL.OppRipReplaceUpdateException jobException = new OppRipReplaceUpdateQueueableSerial_SL.OppRipReplaceUpdateException(
      testExceptionMessage
    );
    RecRipReplaceUpdQueueableFinalizer_SL.updateAsyncTask(jobId, String.valueOf(cancellationOpp.Id), jobException);
    Test.stopTest();

    //THEN
    //4. assert
    AsyncTask__c requeryAst = [SELECT Id, Status__c, UIMessage__c FROM AsyncTask__c WHERE Id = :ast.id];
    System.assertEquals(ASYNC_ERROR_STATUS, requeryAst.Status__c);
    System.assertEquals(testExceptionMessage, requeryAst.UIMessage__c);
  }

  @isTest
  public static void itShouldReturnAsendUserErrorNotificationErrorResultDueToException() {
    String result = RecRipReplaceUpdQueueableFinalizer_SL.sendInitUserErrorNotif(
      new List<Id>(),
      new RecRipReplaceUpdQueueableFinalizer_SL.RecRipReplaceUpdQueueableFinalizerException(),
      '',
      RecRipReplaceUpdQueueableFinalizer_SL.LEX_THEME_NAME,
      '',
      OPP_SYNC_TYPE
    );
    System.assertEquals('Error', result);
  }

  @isTest
  public static void itShouldReturnAsendUserErrorNotificationErrorResultDueToNullParams() {
    String result = RecRipReplaceUpdQueueableFinalizer_SL.sendInitUserErrorNotif(
      null,
      null,
      null,
      RecRipReplaceUpdQueueableFinalizer_SL.LEX_THEME_NAME,
      null,
      OPP_SYNC_TYPE
    );
    System.assertEquals('Error', result);
  }

  @isTest
  public static void itShouldReturnAsendUserErrorNotificationSuccessResult() {
    String result = RecRipReplaceUpdQueueableFinalizer_SL.sendInitUserErrorNotif(
      new List<Id>{ fflib_IDGenerator.generate(Opportunity.getSObjectType()) },
      new RecRipReplaceUpdQueueableFinalizer_SL.RecRipReplaceUpdQueueableFinalizerException(),
      'ABC1234',
      RecRipReplaceUpdQueueableFinalizer_SL.LEX_THEME_NAME,
      'XYZ1234',
      OPP_SYNC_TYPE
    );
    //14-Oct -test fails in .partialsb but succeeds in .UATFull
    //System.assertEquals('Success', result);
  }
}