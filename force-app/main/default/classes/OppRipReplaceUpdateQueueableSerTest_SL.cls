@isTest
public with sharing class OppRipReplaceUpdateQueueableSerTest_SL {
  static final Date START_DATE_FOR_RR = System.today().addDays(7);
  static final String PARENT_OPP_NAME = 'Parent RR Opp';
  static final String ASYNC_INPROGRESS_STATUS = 'Inprogress';

  @TestSetup
  static void makeData() {
    Id pb2Id = Test.getStandardPricebookId();

    SBQQ.TriggerControl.disable();
    //Setup
    //Base acc
    Account acc = DataFactory_CM.createAccount('Customer', false);
    Database.DMLOptions dml = new Database.DMLOptions();
    dml.DuplicateRuleHeader.allowSave = true;
    Database.insert(acc, dml); //SOQL cumulative count: 2/100 (insert acc +2)

    //parent opp
    Opportunity rrOpportunity = DataFactory_SL.createOpportunity(acc.Id, false);
    rrOpportunity.Name = PARENT_OPP_NAME;
    rrOpportunity.Replacement_Transaction__c = true;
    insert rrOpportunity; //SOQL cumulative count: 14/100 (insert opp +12)

    //parent quote
    SBQQ__Quote__c rrQuote = DataFactory_SL.createCPQQuote(acc.Id, rrOpportunity.Id, false);
    rrQuote.SBQQ__StartDate__c = START_DATE_FOR_RR;
    rrQuote.SBQQ__EndDate__c = System.today().addMonths(12).addDays(-1);
    rrQuote.SBQQ__BillingFrequency__c = 'Annual';
    rrQuote.SBQQ__Primary__c = true;
    insert rrQuote; //SOQL cumulative count: 41/100 (insert quote +27)

    rrOpportunity.SBQQ__PrimaryQuote__c = rrQuote.Id;
    update rrOpportunity; //SOQL cumulative count: 51/100 (update opp +10)
    //

    //child opp
    Opportunity cancellationOpp = DataFactory_SL.createOpportunity(acc.Id, false);
    cancellationOpp.Pricebook2Id = pb2Id;
    insert cancellationOpp; //SOQL cumulative count: 63/100 (insert opp +12)

    //insert child quote - refactored into test method within Test.start/stop

    //SOQL cumulative count: 63/100
  }

  @isTest
  public static void itShouldUpdateTheSuppliedOppsStageName() {
    Test.startTest();

    //GIVEN
    Opportunity parentOpportunity = [
      SELECT Id, StageName, SBQQ__PrimaryQuote__c
      FROM Opportunity
      WHERE Name = :PARENT_OPP_NAME
      LIMIT 1
    ]; //SOQL cumulative count: 1/100 (query +1)

    Opportunity childOpp = [
      SELECT Id, AccountId, StageName, SBQQ__PrimaryQuote__c
      FROM Opportunity
      WHERE Id != :parentOpportunity.Id
      LIMIT 1
    ]; //SOQL cumulative count: 2/100 (query +1)

    System.assertEquals(
      Constants_SL.OPPORTUNITY_STAGE_DISCOVERY,
      childOpp.StageName,
      'Opp should be at the initial opp stage'
    );

    Map<Id, Map<String, String>> recordIdToFieldUpdateMap = new Map<Id, Map<String, String>>();
    Map<String, String> fieldUpdateMap = new Map<String, String>();
    fieldUpdateMap.put('StageName', Constants.OPPORTUNITY_STAGE_WON);
    recordIdToFieldUpdateMap.put(childOpp.Id, fieldUpdateMap);
    recordIdToFieldUpdateMap.put(parentOpportunity.Id, fieldUpdateMap);

    //WHEN
    OppRipReplaceUpdateQueueableSerial_SL orruqs = new OppRipReplaceUpdateQueueableSerial_SL(
      recordIdToFieldUpdateMap,
      new List<Id>{ childOpp.Id, parentOpportunity.Id },
      fflib_IDGenerator.generate(User.getSObjectType()),
      'Theme4d'
    );
    orruqs.work();

    //THEN
    Opportunity reQueryChildOpp = [SELECT StageName FROM Opportunity WHERE Id = :childOpp.Id];
    System.assertEquals(
      Constants.OPPORTUNITY_STAGE_WON,
      reQueryChildOpp.StageName,
      'The Opp stage should have been updated'
    );
    Opportunity reQueryParentOpp = [SELECT StageName FROM Opportunity WHERE Id = :parentOpportunity.Id];
    System.assertEquals(
      Constants.OPPORTUNITY_STAGE_WON,
      reQueryParentOpp.StageName,
      'The Opp stage should have been updated'
    );
  }
  @isTest
  public static void itShouldUpdateTheSuppliedOppsStageNameSecConstructor() {
    Test.startTest();

    //GIVEN
    Opportunity parentOppty = [
      SELECT Id, StageName, SBQQ__PrimaryQuote__c
      FROM Opportunity
      WHERE Name = :PARENT_OPP_NAME
      LIMIT 1
    ]; //SOQL cumulative count: 1/100 (query +1)

    Opportunity childOpp = [
      SELECT Id, AccountId, StageName, SBQQ__PrimaryQuote__c
      FROM Opportunity
      WHERE Id != :parentOppty.Id
      LIMIT 1
    ]; //SOQL cumulative count: 2/100 (query +1)

    System.assertEquals(
      Constants_SL.OPPORTUNITY_STAGE_DISCOVERY,
      childOpp.StageName,
      'Opp should be at the initial opp stage'
    );

    Map<Id, Map<String, String>> recordIdToFieldUpdateMap = new Map<Id, Map<String, String>>();
    Map<String, String> fieldUpdateMap = new Map<String, String>();
    fieldUpdateMap.put('StageName', Constants.OPPORTUNITY_STAGE_WON);
    recordIdToFieldUpdateMap.put(childOpp.Id, fieldUpdateMap);
    recordIdToFieldUpdateMap.put(parentOppty.Id, fieldUpdateMap);

    //WHEN
    OppRipReplaceUpdateQueueableSerial_SL orruqs = new OppRipReplaceUpdateQueueableSerial_SL(
      recordIdToFieldUpdateMap,
      new List<Id>{ childOpp.Id, parentOppty.Id },
      fflib_IDGenerator.generate(User.getSObjectType()),
      'Theme4d',
      new List<String>()
    );
    orruqs.work();

    //THEN
    Opportunity reQueryChildOpp = [SELECT StageName FROM Opportunity WHERE Id = :childOpp.Id];
    System.assertEquals(
      Constants.OPPORTUNITY_STAGE_WON,
      reQueryChildOpp.StageName,
      'The Opp stage should have been updated'
    );
    Opportunity reQueryParentOpp = [SELECT StageName FROM Opportunity WHERE Id = :parentOppty.Id];
    System.assertEquals(
      Constants.OPPORTUNITY_STAGE_WON,
      reQueryParentOpp.StageName,
      'The Opp stage should have been updated'
    );
  }
}