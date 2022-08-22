/* Tests Opportunity Rip Replace Sync and Aysnc Task generation
 * SOQL usage profiling based on UAT benchmarking, Oct-21
 */
@isTest
public with sharing class OppRipReplaceSyncQueueableTest_SL {
  static final Date START_DATE_FOR_RR = System.today().addDays(7);
  static final String PARENT_OPP_NAME = 'Parent RR Opp';
  static final String ASYNC_INPROGRESS_STATUS = 'Inprogress';

  @TestSetup
  static void makeData() {
    Id pb2Id = Test.getStandardPricebookId();

    SBQQ.TriggerControl.disable();
    //Setup
    //Base account
    Account account = DataFactory_CM.createAccount('Customer', false);
    Database.DMLOptions dml = new Database.DMLOptions();
    dml.DuplicateRuleHeader.allowSave = true;
    Database.insert(account, dml); //SOQL cumulative count: 2/100 (insert account +2)

    //parent opp
    Opportunity rrOpp = DataFactory_SL.createOpportunity(account.Id, false);
    rrOpp.Name = PARENT_OPP_NAME;
    rrOpp.Replacement_Transaction__c = true;
    insert rrOpp; //SOQL cumulative count: 14/100 (insert opp +12)

    //parent quote
    SBQQ__Quote__c rrQuote = DataFactory_SL.createCPQQuote(account.Id, rrOpp.Id, false);
    rrQuote.SBQQ__StartDate__c = START_DATE_FOR_RR;
    rrQuote.SBQQ__EndDate__c = System.today().addMonths(12).addDays(-1);
    rrQuote.SBQQ__BillingFrequency__c = 'Annual';
    rrQuote.SBQQ__Primary__c = true;
    insert rrQuote; //SOQL cumulative count: 41/100 (insert quote +27)

    rrOpp.SBQQ__PrimaryQuote__c = rrQuote.Id;
    update rrOpp; //SOQL cumulative count: 51/100 (update opp +10)
    //

    //child opp
    Opportunity cancellationOpp = DataFactory_SL.createOpportunity(account.Id, false);
    cancellationOpp.Pricebook2Id = pb2Id;
    insert cancellationOpp; //SOQL cumulative count: 63/100 (insert opp +12)

    //insert child quote - refactored into test method within Test.start/stop

    //SOQL cumulative count: 63/100
  }

  @isTest
  public static void itShouldSyncOpportunityStatusFromParentOppToChildOpp() {
    Test.startTest();

    //GIVEN
    Opportunity parentOpp = [
      SELECT Id, StageName, SBQQ__PrimaryQuote__c
      FROM Opportunity
      WHERE Name = :PARENT_OPP_NAME
      LIMIT 1
    ]; //SOQL cumulative count: 1/100 (query +1)

    Opportunity childOpp = [
      SELECT Id, AccountId, StageName, SBQQ__PrimaryQuote__c
      FROM Opportunity
      WHERE Id != :parentOpp.Id
      LIMIT 1
    ]; //SOQL cumulative count: 2/100 (query +1)

    //insert child quote - refactored into test method within Test.start/stop
    SBQQ__Quote__c cancellationQuote = createCancellationQuote(
      childOpp.AccountId,
      childOpp.Id,
      parentOpp.SBQQ__PrimaryQuote__c
    );
    insert cancellationQuote; //SOQL cumulative count: 29/100 (insert quote +27)

    childOpp.SBQQ__PrimaryQuote__c = cancellationQuote.Id;
    update childOpp; //SOQL cumulative count: 39/100 (update opp +10)
    //

    List<Opportunity> childOpps = [
      SELECT Id, StageName, SBQQ__PrimaryQuote__c
      FROM Opportunity
      WHERE SBQQ__PrimaryQuote__r.Replacement_Quote__r.SBQQ__Opportunity2__c = :parentOpp.Id
    ]; //SOQL cumulative count: 40/100 (query +1)
    System.assertEquals(1, childOpps.size(), 'There should be  1 child opp returned');
    Opportunity childOpp1 = childOpps.get(0);
    System.assertEquals(
      Constants_SL.OPPORTUNITY_STAGE_DISCOVERY,
      parentOpp.StageName,
      'Opp should be at the initial opp stage'
    );
    System.assertEquals(
      Constants_SL.OPPORTUNITY_STAGE_DISCOVERY,
      childOpp1.StageName,
      'Opp should be at the initial opp stage'
    );

    //

    //WHEN
    parentOpp.StageName = Constants_SL.OPPORTUNITY_STAGE_WON;
    update parentOpp; //SOQL cumulative count: 50/100 (update opp +10)

    //

    //THEN
    //Feature Toggle
    List<CPQ_RR_Sync_Feature__mdt> featureControls = new List<CPQ_RR_Sync_Feature__mdt>();
    try {
      featureControls = [
        SELECT Is_Active__c
        FROM CPQ_RR_Sync_Feature__mdt
        WHERE Sync_Target_Object__c = 'Opportunity' AND Is_Active__c = TRUE
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

    List<Opportunity> reQueryChildOpps = [
      SELECT Id, StageName, SBQQ__PrimaryQuote__c
      FROM Opportunity
      WHERE SBQQ__PrimaryQuote__r.Replacement_Quote__r.SBQQ__Opportunity2__c = :parentOpp.Id
    ]; //SOQL cumulative count: 51/100 (query +1)

    for (Opportunity opp : reQueryChildOpps) {
      System.assertEquals(
        Constants_SL.OPPORTUNITY_STAGE_WON,
        opp.StageName,
        'Child Opportunity\'s StageName should sync from the replacement Opportunity'
      );
    }
    Test.stopTest(); //SOQL cumulative count: 51/100
  }

  @isTest
  public static void itShouldNotsyncOpportunityStatusForNonScopeOpps() {
    //GIVEN
    //pre-test SOQL cumulative count: 63/100
    Opportunity parentOpp = [
      SELECT Id, AccountId, StageName, SBQQ__PrimaryQuote__c
      FROM Opportunity
      WHERE Name = :PARENT_OPP_NAME
      LIMIT 1
    ]; //SOQL cumulative count: 64/100 (query +1)

    Opportunity childOpp = [
      SELECT Id, AccountId, StageName, SBQQ__PrimaryQuote__c
      FROM Opportunity
      WHERE Id != :parentOpp.Id
      LIMIT 1
    ]; //SOQL cumulative count: 65/100 (query +1)

    //insert child quote - refactored into test method within Test.start/stop
    SBQQ__Quote__c cancellationQuote = createCancellationQuote(
      childOpp.AccountId,
      childOpp.Id,
      parentOpp.SBQQ__PrimaryQuote__c
    );
    insert cancellationQuote; //SOQL cumulative count: 92/100 (insert quote +27)

    //pre-test SOQL cumulative count: 92/100

    Test.startTest();

    childOpp.SBQQ__PrimaryQuote__c = cancellationQuote.Id;
    update childOpp; //SOQL cumulative count: 10/100 (update opp +10)

    Id pb2Id = Test.getStandardPricebookId();

    //non scope opp
    Opportunity nonScopeOpp = DataFactory_SL.createOpportunity(parentOpp.AccountId, false);
    nonScopeOpp.Pricebook2Id = pb2Id;
    insert nonScopeOpp; //SOQL cumulative count: 22/100 (insert opp +12)
    //

    //non scope quote
    SBQQ__Quote__c nonScopeQuote = DataFactory_SL.createCPQQuote(parentOpp.AccountId, nonScopeOpp.Id, false);
    nonScopeQuote.SBQQ__StartDate__c = System.today();
    nonScopeQuote.SBQQ__EndDate__c = System.today().addMonths(6).addDays(-1);
    nonScopeQuote.SBQQ__BillingFrequency__c = 'Annual';
    nonScopeQuote.SBQQ__Primary__c = true;
    insert nonScopeQuote; //SOQL cumulative count: 49/100 (insert quote +27)

    nonScopeOpp.SBQQ__PrimaryQuote__c = nonScopeQuote.Id;
    update nonScopeOpp; //SOQL cumulative count: 59/100 (update opp +10)
    //

    List<Opportunity> otherOpps = [
      SELECT Id, StageName
      FROM Opportunity
      WHERE Id != :parentOpp.Id AND Id != :childOpp.Id
    ]; //SOQL cumulative count: 60/100 (query +1)

    //validate starting conditions
    System.assertEquals(
      Constants_SL.OPPORTUNITY_STAGE_DISCOVERY,
      parentOpp.StageName,
      'Opp should be at the initial opp stage'
    );

    System.assertEquals(
      Constants_SL.OPPORTUNITY_STAGE_DISCOVERY,
      childOpp.StageName,
      'Opp should be at the initial opp stage'
    );

    for (Opportunity o : otherOpps) {
      System.assertEquals(
        Constants_SL.OPPORTUNITY_STAGE_DISCOVERY,
        o.StageName,
        'Opp should be at the initial opp stage'
      );
    }
    //

    //WHEN - update on scope opp
    parentOpp.StageName = Constants_SL.OPPORTUNITY_STAGE_WON;
    update parentOpp; //SOQL cumulative count: 70/100 (update opp +10)
    //

    //THEN - no impact on non-scope opps
    List<Opportunity> reQueryOtherOpps = [
      SELECT Id, StageName
      FROM Opportunity
      WHERE Id != :parentOpp.Id AND Id != :childOpp.Id
    ]; //SOQL cumulative count: 71/100 (query +1)

    System.assertEquals(1, reQueryOtherOpps.size(), 'Should be 1 opp returned');
    for (Opportunity o : reQueryOtherOpps) {
      System.assertEquals(
        Constants_SL.OPPORTUNITY_STAGE_DISCOVERY,
        o.StageName,
        'Opp should STILL be at the initial opp stage'
      );
    }
    Test.stopTest(); //SOQL cumulative count: 71/100
  }

  @isTest
  public static void itShouldCreateAsyncTasksForRrOppSyncs() {
    //GIVEN
    Test.startTest();
    Opportunity parentOpp = [
      SELECT Id, AccountId, StageName, SBQQ__PrimaryQuote__c
      FROM Opportunity
      WHERE Name = :PARENT_OPP_NAME
      LIMIT 1
    ]; //SOQL cumulative count: 1/100 (query +1)

    Opportunity childOpp = [
      SELECT Id, AccountId, StageName, SBQQ__PrimaryQuote__c
      FROM Opportunity
      WHERE Id != :parentOpp.Id
      LIMIT 1
    ]; //SOQL cumulative count: 2/100 (query +1)

    //insert child quote - refactored into test method within Test.start/stop
    SBQQ__Quote__c cancellationQuote = createCancellationQuote(
      childOpp.AccountId,
      childOpp.Id,
      parentOpp.SBQQ__PrimaryQuote__c
    );
    insert cancellationQuote; //SOQL cumulative count: 29/100 (insert quote +27)

    childOpp.SBQQ__PrimaryQuote__c = cancellationQuote.Id;
    update childOpp; //SOQL cumulative count: 39/100 (update opp +10)

    System.assertEquals(2, [SELECT Id FROM SBQQ__Quote__c].size(), 'There should be 2 quotes in the test db'); //SOQL cumulative count: 40/100 (query +1)

    Map<Id, Opportunity> childOpps = new Map<Id, Opportunity>(
      [
        SELECT Id, StageName, SBQQ__PrimaryQuote__c
        FROM Opportunity
        WHERE SBQQ__PrimaryQuote__r.Replacement_Quote__r.SBQQ__Opportunity2__c = :parentOpp.Id
      ]
    ); //SOQL cumulative count: 41/100 (query +1)
    //

    //WHEN - update a parent opp
    parentOpp.StageName = Constants_SL.OPPORTUNITY_STAGE_WON;
    update parentOpp; //SOQL cumulative count: 51/100 (update opp +10)
    //

    //THEN - Async tasks should be created for the child opp(s)

    //Feature Toggle
    List<CPQ_RR_Sync_Feature__mdt> featureControls = new List<CPQ_RR_Sync_Feature__mdt>();
    try {
      featureControls = [
        SELECT Is_Active__c
        FROM CPQ_RR_Sync_Feature__mdt
        WHERE Sync_Target_Object__c = 'Opportunity' AND Is_Active__c = TRUE
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
    List<AsyncTask__c> childOppAsyncTasks = [
      SELECT Id, Opportunity__c, Type__c, Status__c
      FROM AsyncTask__c
      WHERE Opportunity__c IN :childOpps.keySet()
    ]; //SOQL cumulative count: 52/100 (query +1)

    System.assertEquals(1, childOppAsyncTasks.size(), 'Should be 1 task returned');

    for (AsyncTask__c ast : childOppAsyncTasks) {
      //finalizer marks task as complete so in test context we can only assert the tasks have been created
      System.assertEquals(ASYNC_INPROGRESS_STATUS, ast.Status__c, 'Async tasks should be in an in progress state');
      System.assertEquals(
        OppRipReplaceSyncTask_SL.SYNC_TASK_TYPE,
        ast.Type__c,
        'Async tasks in this context should have the RR opp sync type'
      );
    }
    Test.stopTest();

    //SOQL cumulative count: 52/100
  }

  private static SBQQ__Quote__c createCancellationQuote(Id accountId, Id oppId, Id parentQuoteId) {
    SBQQ__Quote__c cancellationQuote = DataFactory_SL.createCPQQuote(accountId, oppId, false);
    cancellationQuote.SBQQ__StartDate__c = START_DATE_FOR_RR;
    cancellationQuote.SBQQ__EndDate__c = System.today().addMonths(6).addDays(-1);
    cancellationQuote.Replacement_Quote__c = parentQuoteId;
    cancellationQuote.SBQQ__BillingFrequency__c = 'Annual';
    cancellationQuote.SBQQ__Primary__c = true;

    return cancellationQuote;
  }
}