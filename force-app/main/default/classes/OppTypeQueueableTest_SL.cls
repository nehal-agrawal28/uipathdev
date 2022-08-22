@isTest(isParallel=false)
private class OppTypeQueueableTest_SL {
  private static final String ASSERT_MSG_EXCEPTION = 'No exception should be thrown';
  private static final String ERROR_MSG = 'Opp Type is incorrect';
  private static final String OPP_TYPE_NEW_BUSINESS = 'New Business';
  private static final String SINGLE_OPP_SCOPE_MSG = 'Only a single opp should be considered in-scope';
  private static final String EXPECTED_OPP_SCOPE_MSG = 'The expected opp was not in-scope';
  private static final String NO_OPP_SCOPE_MSG = 'No opps should be considered in-scope';
  private static final String ASSERT_MSG_NON_SCOPE_OPP = 'Non-scope opportunity Id should NOT be returned in the actual opp map';

  static void setup() {
    List<Account> testAccounts = DataFactory_CM.createAccounts(
      AccountMetadata.getAccountRecordTypeId('Customer'),
      2,
      true
    );
    Opportunity opp1 = DataFactory_SL.createOpportunity(testAccounts.get(0).Id, false);
    Opportunity opp2 = DataFactory_SL.createOpportunity(testAccounts.get(0).Id, false);
    Opportunity opp3 = DataFactory_SL.createOpportunity(testAccounts.get(1).Id, false);
    Opportunity opp4 = DataFactory_SL.createOpportunity(testAccounts.get(1).Id, false);
    opp2.SBQQ__Renewal__c = true;
    opp4.Name = 'TestUpsellOnUpdate';
    insert new List<Opportunity>{ opp1, opp2, opp3, opp4 };
    opp3.StageName = 'Closed Won Booked';
    opp3.Contract_Start_Date__c = Date.today().addDays(1);
    opp3.Contract_End_Date__c = Date.today().addDays(10);
    update opp3;
  }

  @isTest
  private static void setOppTypeOnUpdate() {
    setup();
    Opportunity opp = [
      SELECT Id, Type, Account.won_opportunities__c
      FROM Opportunity
      WHERE Name = 'TestUpsellOnUpdate'
      LIMIT 1
    ];
    opp.StageName = 'Closed Won Pending';
    opp.Won_Reasons__c = 'Other';
    update opp;

    OppTypeOnUpdateQueueable_SL queueable = new OppTypeOnUpdateQueueable_SL(new List<Opportunity>{ opp });
    queueable.execute(null);

    Test.startTest();
    Opportunity updatedOpp = [SELECT Id, Type FROM Opportunity WHERE Name = 'TestUpsellOnUpdate' LIMIT 1];
    System.assertEquals('Upsell', updatedOpp.Type, ERROR_MSG);

    Test.stopTest();
  }

  @isTest
  private static void setOppTypeOnInsert() {
    setup();
    Opportunity opp = [
      SELECT Id, Type, Account.won_opportunities__c, AccountId
      FROM Opportunity
      WHERE Name = 'TestUpsellOnUpdate'
      LIMIT 1
    ];
    opp.StageName = 'Closed Won Pending';
    opp.Won_Reasons__c = 'Other';
    update opp;

    Test.startTest();
    Opportunity opp2 = DataFactory_SL.createOpportunity(opp.AccountId, true);
    Test.stopTest();

    Opportunity updatedOpp = [SELECT Id, Type FROM Opportunity WHERE Id = :opp2.Id];
    System.assertEquals('Upsell', updatedOpp.Type, ERROR_MSG);
  }

  @isTest
  public static void itShouldUpdateOppTypeOnAccountIdChangeFromNewBusinessToUpsellAtNonClosedWonPendingOppStage() {
    //GIVEN
    setup();
    Account accWithWonOpps = [SELECT Id, Name, won_opportunities__c FROM Account WHERE won_opportunities__c = 1];
    Opportunity opp = [
      SELECT Id, Type, StageName
      FROM Opportunity
      WHERE Account.won_opportunities__c = 0 AND Type = :OPP_TYPE_NEW_BUSINESS
      LIMIT 1
    ];

    //WHEN
    Test.startTest();
    opp.AccountId = accWithWonOpps.Id;
    update opp;

    OppTypeOnUpdateQueueable_SL queueable = new OppTypeOnUpdateQueueable_SL(new List<Opportunity>{ opp });
    queueable.execute(null);

    Test.stopTest();

    //THEN
    Opportunity requeryOpp = [SELECT Id, AccountId, Type FROM Opportunity WHERE Id = :opp.Id];
    System.assertEquals(
      accWithWonOpps.Id,
      requeryOpp.AccountId,
      'The The Opportunity\'s Account should have been updated '
    );
    System.assertEquals('Upsell', requeryOpp.Type, 'The Opportunity\'s Type should be set to \'Upsell\'');
  }

  /*
  Opp.AccountId change when Opp.Stage at discovery should be in scope
  */
  @isTest
  public static void itShouldBeInScopeForAccountIdChangeAtOppStageDiscovery() {
    //GIVEN
    List<Opportunity> opps = new List<Opportunity>();
    Map<Id, SObject> existingOpps = new Map<Id, SObject>();
    createOpportunityStructures(opps, existingOpps);
    Opportunity opp = opps.get(1);

    //WHEN
    Id newAccId = fflib_IDGenerator.generate(Account.SObjectType);
    opp.AccountId = newAccId;
    Set<Opportunity> changedOpps = new Set<Opportunity>(
      OppTypeOnUpdateQueueable_SL.determineOppScope(opps, existingOpps)
    );

    //THEN
    System.assert(changedOpps.size() == 1, SINGLE_OPP_SCOPE_MSG);
    System.assert(changedOpps.contains(opp), EXPECTED_OPP_SCOPE_MSG);
  }

  /*
  Opp.AccountId change when Opp.Stage at negotiation should be in scope
  */
  @isTest
  public static void itShouldBeInScopeForAccountIdChangeAtOppStageNegotiation() {
    //GIVEN
    List<Opportunity> opps = new List<Opportunity>();
    Map<Id, SObject> existingOpps = new Map<Id, SObject>();
    createOpportunityStructures(opps, existingOpps);
    Opportunity opp = opps.get(1);
    opp.StageName = OpportunityMetadata_SL.NEGOTIATION;
    Opportunity oldOpp = (Opportunity) existingOpps.get(opp.Id);
    oldOpp.StageName = OpportunityMetadata_SL.NEGOTIATION;

    //WHEN
    Id newAccId = fflib_IDGenerator.generate(Account.SObjectType);
    opp.AccountId = newAccId;
    Set<Opportunity> changedOpps = new Set<Opportunity>(
      OppTypeOnUpdateQueueable_SL.determineOppScope(opps, existingOpps)
    );

    //THEN
    System.assert(changedOpps.size() == 1, SINGLE_OPP_SCOPE_MSG);
    System.assert(changedOpps.contains(opp), EXPECTED_OPP_SCOPE_MSG);
  }

  /*
  Opp.AccountId change when Opp.Stage at CWP should be  in scope
  */
  @isTest
  public static void itShouldBeInScopeForAccountIdChangeAtOppStageCWP() {
    //GIVEN
    List<Opportunity> opps = new List<Opportunity>();
    Map<Id, SObject> existingOpps = new Map<Id, SObject>();
    createOpportunityStructures(opps, existingOpps);
    Opportunity opp = opps.get(1);
    opp.StageName = OpportunityMetadata_SL.CLOSED_WON_PENDING;
    Opportunity oldOpp = (Opportunity) existingOpps.get(opp.Id);
    oldOpp.StageName = OpportunityMetadata_SL.CLOSED_WON_PENDING;

    //WHEN
    Id newAccId = fflib_IDGenerator.generate(Account.SObjectType);
    opp.AccountId = newAccId;
    Set<Opportunity> changedOpps = new Set<Opportunity>(
      OppTypeOnUpdateQueueable_SL.determineOppScope(opps, existingOpps)
    );

    //THEN
    System.assert(changedOpps.size() == 1, SINGLE_OPP_SCOPE_MSG);
    System.assert(changedOpps.contains(opp), EXPECTED_OPP_SCOPE_MSG);
  }

  /*
  Opp.AccountId change when Opp.Stage at discovery & Overwrite_Type__c = true should be out of scope
  */
  @isTest
  public static void itShouldBeOutScopeForAccountIdChangeAtOppStageDiscoveryOverwriteType() {
    //GIVEN
    List<Opportunity> opps = new List<Opportunity>();
    Map<Id, SObject> existingOpps = new Map<Id, SObject>();
    createOpportunityStructures(opps, existingOpps);
    Opportunity opp = opps.get(1);

    //WHEN
    Id newAccId = fflib_IDGenerator.generate(Account.SObjectType);
    opp.AccountId = newAccId;
    opp.Overwrite_Type__c = true;
    Set<Opportunity> changedOpps = new Set<Opportunity>(
      OppTypeOnUpdateQueueable_SL.determineOppScope(opps, existingOpps)
    );

    //THEN
    System.assert(changedOpps.size() == 0, NO_OPP_SCOPE_MSG);
  }

  /*
  Opp.AccountId change when Opp.Stage at negotiation & Overwrite_Type__c = true should be out of scope
  */
  @isTest
  public static void itShouldBeOutScopeForAccountIdChangeAtOppStageNegotiationOverwriteType() {
    //GIVEN
    List<Opportunity> opps = new List<Opportunity>();
    Map<Id, SObject> existingOpps = new Map<Id, SObject>();
    createOpportunityStructures(opps, existingOpps);
    Opportunity opp = opps.get(1);
    opp.StageName = OpportunityMetadata_SL.NEGOTIATION;
    Opportunity oldOpp = (Opportunity) existingOpps.get(opp.Id);
    oldOpp.StageName = OpportunityMetadata_SL.NEGOTIATION;

    //WHEN
    Id newAccId = fflib_IDGenerator.generate(Account.SObjectType);
    opp.AccountId = newAccId;
    opp.Overwrite_Type__c = true;

    Set<Opportunity> changedOpps = new Set<Opportunity>(
      OppTypeOnUpdateQueueable_SL.determineOppScope(opps, existingOpps)
    );

    //THEN
    System.assert(changedOpps.size() == 0, NO_OPP_SCOPE_MSG);
  }

  /*
  Opp.AccountId change when Opp.Stage at CWP & Overwrite_Type__c = true should be out of scope
  */
  @isTest
  public static void itShouldBeOutScopeForAccountIdChangeAtOppStageCWPOverwriteType() {
    //GIVEN
    List<Opportunity> opps = new List<Opportunity>();
    Map<Id, SObject> existingOpps = new Map<Id, SObject>();
    createOpportunityStructures(opps, existingOpps);
    Opportunity opp = opps.get(1);
    opp.StageName = OpportunityMetadata_SL.CLOSED_WON_PENDING;
    Opportunity oldOpp = (Opportunity) existingOpps.get(opp.Id);
    oldOpp.StageName = OpportunityMetadata_SL.CLOSED_WON_PENDING;

    //WHEN
    Id newAccId = fflib_IDGenerator.generate(Account.SObjectType);
    opp.AccountId = newAccId;
    opp.Overwrite_Type__c = true;
    Set<Opportunity> changedOpps = new Set<Opportunity>(
      OppTypeOnUpdateQueueable_SL.determineOppScope(opps, existingOpps)
    );

    //THEN
    System.assert(changedOpps.size() == 0, NO_OPP_SCOPE_MSG);
  }

  /*
  Opp.AccountId change when Opp.Stage at CWB should be out of scope
  */
  @isTest
  public static void itShouldNotBeInScopeForAccountIdChangeOnClosedWonBookedStage() {
    //GIVEN
    List<Opportunity> opps = new List<Opportunity>();
    Map<Id, SObject> existingOpps = new Map<Id, SObject>();
    createOpportunityStructures(opps, existingOpps);
    Opportunity opp = opps.get(1);
    opp.StageName = OpportunityMetadata_SL.CLOSED_WON_BOOKED;
    Opportunity oldOpp = (Opportunity) existingOpps.get(opp.Id);
    oldOpp.StageName = OpportunityMetadata_SL.CLOSED_WON_BOOKED;

    //WHEN
    Id newAccId = fflib_IDGenerator.generate(Account.SObjectType);
    opp.AccountId = newAccId;
    Set<Opportunity> changedOpps = new Set<Opportunity>(
      OppTypeOnUpdateQueueable_SL.determineOppScope(opps, existingOpps)
    );

    //THEN
    System.assert(changedOpps.size() == 0, NO_OPP_SCOPE_MSG);
  }

  /*
  Opp.AccountId change when Opp moving to CWB should be out of scope
  */
  @isTest
  public static void itShouldNotBeInScopeForAccountIdChangeOnMovingToClosedWonBookedStage() {
    //GIVEN
    List<Opportunity> opps = new List<Opportunity>();
    Map<Id, SObject> existingOpps = new Map<Id, SObject>();
    createOpportunityStructures(opps, existingOpps);
    Opportunity opp = opps.get(1);

    //WHEN
    opp.StageName = OpportunityMetadata_SL.CLOSED_WON_BOOKED;
    Id newAccId = fflib_IDGenerator.generate(Account.SObjectType);
    opp.AccountId = newAccId;
    Set<Opportunity> changedOpps = new Set<Opportunity>(
      OppTypeOnUpdateQueueable_SL.determineOppScope(opps, existingOpps)
    );

    //THEN
    System.assert(changedOpps.size() == 0, NO_OPP_SCOPE_MSG);
  }

  /*
  Opp.Overwrite_Type__c change when Opp at CWP should be out of scope
  */
  @isTest
  public static void itShouldNotBeInScopeForUpdateOppTypeOnOverwriteTypeChange() {
    //GIVEN
    List<Opportunity> opps = new List<Opportunity>();
    Map<Id, SObject> existingOpps = new Map<Id, SObject>();
    createOpportunityStructures(opps, existingOpps);
    Opportunity opp = opps.get(1);
    opp.StageName = OpportunityMetadata_SL.CLOSED_WON_PENDING;
    Opportunity oldOpp = (Opportunity) existingOpps.get(opp.Id);
    oldOpp.StageName = OpportunityMetadata_SL.CLOSED_WON_PENDING;

    //WHEN
    opp.Type = 'Test Value';
    opp.Overwrite_Type__c = true;
    Set<Opportunity> changedOpps = new Set<Opportunity>(
      OppTypeOnUpdateQueueable_SL.determineOppScope(opps, existingOpps)
    );

    //THEN
    System.assert(changedOpps.size() == 0, NO_OPP_SCOPE_MSG);
  }

  /*
  Opp.RecordTypeId change when Opp NOT at CWP should be out of scope
  */
  @isTest
  public static void itShouldNotBeInScopeForUpdateOppTypeRecordTypeChangeNonCwp() {
    //GIVEN
    List<Opportunity> opps = new List<Opportunity>();
    Map<Id, SObject> existingOpps = new Map<Id, SObject>();
    createOpportunityStructures(opps, existingOpps);
    Opportunity opp = opps.get(1);
    opp.StageName = OpportunityMetadata_SL.NEGOTIATION;
    Opportunity oldOpp = (Opportunity) existingOpps.get(opp.Id);
    oldOpp.StageName = OpportunityMetadata_SL.NEGOTIATION;

    //WHEN
    Id cpqLockedRtId = OpportunityMetadata_SL.CPQLockedRecordType;
    opp.RecordTypeId = cpqLockedRtId;
    Set<Opportunity> changedOpps = new Set<Opportunity>(
      OppTypeOnUpdateQueueable_SL.determineOppScope(opps, existingOpps)
    );

    //THEN
    System.assert(changedOpps.size() == 0, NO_OPP_SCOPE_MSG);
  }

  /*
  Opp.RecordTypeId change when Opp at CWP should be in scope
  */
  @isTest
  public static void itShouldBeInScopeForUpdateOppTypeRecordTypeChangeAtCwp() {
    //GIVEN
    List<Opportunity> opps = new List<Opportunity>();
    Map<Id, SObject> existingOpps = new Map<Id, SObject>();
    createOpportunityStructures(opps, existingOpps);
    Opportunity opp = opps.get(1);
    opp.StageName = OpportunityMetadata_SL.CLOSED_WON_PENDING;
    Opportunity oldOpp = (Opportunity) existingOpps.get(opp.Id);
    oldOpp.StageName = OpportunityMetadata_SL.CLOSED_WON_PENDING;

    //WHEN
    Id cpqLockedRtId = OpportunityMetadata_SL.CPQLockedRecordType;
    opp.RecordTypeId = cpqLockedRtId;
    Set<Opportunity> changedOpps = new Set<Opportunity>(
      OppTypeOnUpdateQueueable_SL.determineOppScope(opps, existingOpps)
    );

    //THEN
    System.assert(changedOpps.size() == 1, SINGLE_OPP_SCOPE_MSG);
    System.assert(changedOpps.contains(opp), EXPECTED_OPP_SCOPE_MSG);
  }

  @isTest
  public static void itShouldHandleNullArgumentForExistingOpps() {
    //GIVEN
    List<Opportunity> opps = new List<Opportunity>();
    Map<Id, SObject> existingOpps = new Map<Id, SObject>();
    createOpportunityStructures(opps, existingOpps);

    //WHEN
    String exc;
    existingOpps = null;
    Set<Opportunity> changedOpps;
    try {
      changedOpps = new Set<Opportunity>(OppTypeOnUpdateQueueable_SL.determineOppScope(opps, existingOpps));
    } catch (Exception e) {
      exc = e.getMessage();
    }

    //THEN
    System.assert(String.isEmpty(exc), ASSERT_MSG_EXCEPTION);
    System.assert(changedOpps.size() == 0, NO_OPP_SCOPE_MSG);
  }

  @isTest
  public static void itShouldHandleMissingRecordFromExistingOpps() {
    //GIVEN
    List<Opportunity> opps = new List<Opportunity>();
    Map<Id, SObject> existingOpps = new Map<Id, SObject>();
    createOpportunityStructures(opps, existingOpps);
    Opportunity opp = opps.get(1);

    //WHEN
    String exc;
    existingOpps.remove(opp.Id);
    Set<Opportunity> changedOpps;
    try {
      changedOpps = new Set<Opportunity>(OppTypeOnUpdateQueueable_SL.determineOppScope(opps, existingOpps));
    } catch (Exception e) {
      exc = e.getMessage();
    }

    //THEN
    System.assert(String.isEmpty(exc), ASSERT_MSG_EXCEPTION);
    System.assert(changedOpps.size() == 0, NO_OPP_SCOPE_MSG);
  }

  @isTest
  private static void itShouldCorrectlyDetermineOppScopeForReplacementOpp() {
    //GIVEN
    Id accountId4 = fflib_IDGenerator.generate(Account.getSObjectType());
    Id scopeOppId4 = fflib_IDGenerator.generate(Opportunity.getSObjectType());
    Opportunity currentScopeOpp4 = new Opportunity(
      Id = scopeOppId4,
      AccountId = accountId4,
      Replacement_Transaction__c = true,
      StageName = OpportunityMetadata_SL.NEGOTIATION,
      Type = Constants_SL.OPPORTUNITY_TYPE_NEW_BUSINESS,
      Overwrite_Type__c = false
    );
    Opportunity oldScopeOpp4 = currentScopeOpp4.clone(true, true, false, false);
    oldScopeOpp4.Replacement_Transaction__c = false;

    Id nonScopeOppId4 = fflib_IDGenerator.generate(Opportunity.getSObjectType());
    Opportunity currentNonScopeOpp4 = new Opportunity(
      Id = nonScopeOppId4,
      AccountId = accountId4,
      Replacement_Transaction__c = false,
      StageName = OpportunityMetadata_SL.NEGOTIATION,
      Type = Constants_SL.OPPORTUNITY_TYPE_NEW_BUSINESS,
      Overwrite_Type__c = false
    );
    Opportunity oldNonScopeOpp4 = currentNonScopeOpp4.clone(true, true, false, false);

    List<Opportunity> opps = new List<Opportunity>{ currentNonScopeOpp4, currentScopeOpp4 };
    Map<Id, SObject> existingOpps = new Map<Id, SObject>{
      nonScopeOppId4 => oldNonScopeOpp4,
      scopeOppId4 => oldScopeOpp4
    };

    //WHEN
    Map<Id, Opportunity> actualOppMap = new Map<Id, Opportunity>(
      OppTypeOnUpdateQueueable_SL.determineOppScope(opps, existingOpps)
    );

    //THEN
    System.assertEquals(true, actualOppMap.containsKey(scopeOppId4), EXPECTED_OPP_SCOPE_MSG);
    System.assertEquals(false, actualOppMap.containsKey(nonScopeOppId4), ASSERT_MSG_NON_SCOPE_OPP);
  }

  @isTest
  private static void itShouldCorrectlyDetermineOppScopeForReplacementOppIgnoringOppsInCwb() {
    //GIVEN
    Id accountId3 = fflib_IDGenerator.generate(Account.getSObjectType());
    Id scopeOppId3 = fflib_IDGenerator.generate(Opportunity.getSObjectType());
    Opportunity currentScopeOpp3 = new Opportunity(
      Id = scopeOppId3,
      AccountId = accountId3,
      Replacement_Transaction__c = true,
      StageName = OpportunityMetadata_SL.NEGOTIATION,
      Type = Constants_SL.OPPORTUNITY_TYPE_NEW_BUSINESS,
      Overwrite_Type__c = false
    );
    Opportunity oldScopeOpp3 = currentScopeOpp3.clone(true, true, false, false);
    oldScopeOpp3.Replacement_Transaction__c = false;

    Id nonScopeOppId3 = fflib_IDGenerator.generate(Opportunity.getSObjectType());
    Opportunity currentNonScopeOpp3 = new Opportunity(
      Id = nonScopeOppId3,
      AccountId = accountId3,
      Replacement_Transaction__c = true,
      StageName = OpportunityMetadata_SL.CLOSED_WON_BOOKED,
      Type = Constants_SL.OPPORTUNITY_TYPE_NEW_BUSINESS,
      Overwrite_Type__c = false
    );
    Opportunity oldNonScopeOpp3 = currentNonScopeOpp3.clone(true, true, false, false);
    oldNonScopeOpp3.Replacement_Transaction__c = false;

    List<Opportunity> opps = new List<Opportunity>{ currentNonScopeOpp3, currentScopeOpp3 };
    Map<Id, SObject> existingOpps = new Map<Id, SObject>{
      nonScopeOppId3 => oldNonScopeOpp3,
      scopeOppId3 => oldScopeOpp3
    };

    //WHEN
    Map<Id, Opportunity> actualOppMap = new Map<Id, Opportunity>(
      OppTypeOnUpdateQueueable_SL.determineOppScope(opps, existingOpps)
    );

    //THEN
    System.assertEquals(true, actualOppMap.containsKey(scopeOppId3), EXPECTED_OPP_SCOPE_MSG);
    System.assertEquals(false, actualOppMap.containsKey(nonScopeOppId3), ASSERT_MSG_NON_SCOPE_OPP);
  }

  @isTest
  private static void itShouldCorrectlyDetermineOppScopeForReplacementOppIgnoringRenewals() {
    //GIVEN
    Id accountId2 = fflib_IDGenerator.generate(Account.getSObjectType());
    Id scopeOppId2 = fflib_IDGenerator.generate(Opportunity.getSObjectType());
    Opportunity currentScopeOpp2 = new Opportunity(
      Id = scopeOppId2,
      AccountId = accountId2,
      Replacement_Transaction__c = true,
      StageName = OpportunityMetadata_SL.NEGOTIATION,
      Type = Constants_SL.OPPORTUNITY_TYPE_NEW_BUSINESS,
      Overwrite_Type__c = false
    );
    Opportunity oldScopeOpp2 = currentScopeOpp2.clone(true, true, false, false);
    oldScopeOpp2.Replacement_Transaction__c = false;

    Id nonScopeOppId2 = fflib_IDGenerator.generate(Opportunity.getSObjectType());
    Opportunity currentNonScopeOpp2 = new Opportunity(
      Id = nonScopeOppId2,
      AccountId = accountId2,
      Replacement_Transaction__c = true,
      StageName = OpportunityMetadata_SL.NEGOTIATION,
      Type = Constants_SL.OPPORTUNITY_TYPE_RENEWAL,
      Overwrite_Type__c = false
    );
    Opportunity oldNonScopeOpp2 = currentNonScopeOpp2.clone(true, true, false, false);
    oldNonScopeOpp2.Replacement_Transaction__c = false;

    List<Opportunity> opps = new List<Opportunity>{ currentNonScopeOpp2, currentScopeOpp2 };
    Map<Id, SObject> existingOpps = new Map<Id, SObject>{
      nonScopeOppId2 => oldNonScopeOpp2,
      scopeOppId2 => oldScopeOpp2
    };

    //WHEN
    Map<Id, Opportunity> actualOppMap = new Map<Id, Opportunity>(
      OppTypeOnUpdateQueueable_SL.determineOppScope(opps, existingOpps)
    );

    //THEN
    System.assertEquals(true, actualOppMap.containsKey(scopeOppId2), EXPECTED_OPP_SCOPE_MSG);
    System.assertEquals(false, actualOppMap.containsKey(nonScopeOppId2), ASSERT_MSG_NON_SCOPE_OPP);
  }

  @isTest
  private static void itShouldCorrectlyDetermineOppScopeForReplacementNullArgs() {
    //GIVEN
    Id accId = fflib_IDGenerator.generate(Account.getSObjectType());
    Id scopeOppId1 = fflib_IDGenerator.generate(Opportunity.getSObjectType());
    Opportunity currentScopeOpp1 = new Opportunity(
      Id = scopeOppId1,
      AccountId = accId,
      Replacement_Transaction__c = true,
      StageName = OpportunityMetadata_SL.NEGOTIATION,
      Type = Constants_SL.OPPORTUNITY_TYPE_NEW_BUSINESS,
      Overwrite_Type__c = false
    );
    Opportunity oldScopeOpp1 = currentScopeOpp1.clone(true, true, false, false);
    oldScopeOpp1.Replacement_Transaction__c = false;

    Id nonScopeOppId1 = fflib_IDGenerator.generate(Opportunity.getSObjectType());
    Opportunity currentNonScopeOpp1 = new Opportunity(
      Id = nonScopeOppId1,
      AccountId = accId,
      StageName = OpportunityMetadata_SL.NEGOTIATION,
      Type = Constants_SL.OPPORTUNITY_TYPE_RENEWAL,
      Overwrite_Type__c = false
    );
    Opportunity oldNonScopeOpp1 = currentNonScopeOpp1.clone(true, true, false, false);

    List<Opportunity> opps = new List<Opportunity>{ currentNonScopeOpp1, currentScopeOpp1 };
    Map<Id, SObject> existingOpps = new Map<Id, SObject>{
      nonScopeOppId1 => oldNonScopeOpp1,
      scopeOppId1 => oldScopeOpp1
    };
    String excMsg;
    Map<Id, Opportunity> actualOppMap;

    //WHEN
    try {
      actualOppMap = new Map<Id, Opportunity>(OppTypeOnUpdateQueueable_SL.determineOppScope(opps, existingOpps));
    } catch (Exception e) {
      excMsg = e.getMessage();
    }

    //THEN
    System.assertEquals(null, excMsg, ASSERT_MSG_EXCEPTION);
    System.assertEquals(true, actualOppMap.containsKey(scopeOppId1), EXPECTED_OPP_SCOPE_MSG);
    System.assertEquals(false, actualOppMap.containsKey(nonScopeOppId1), ASSERT_MSG_NON_SCOPE_OPP);
  }

  private static void createOpportunityStructures(List<Opportunity> opps, Map<Id, SObject> existingOpps) {
    for (Integer i = 0; i < 5; i++) {
      Id accId = fflib_IDGenerator.generate(Account.SObjectType);
      Id oppId = fflib_IDGenerator.generate(Opportunity.SObjectType);

      Opportunity opp = new Opportunity(
        Id = oppId,
        StageName = Constants.OPPORTUNITY_STAGE_DISCOVERY,
        AccountId = accId,
        RecordTypeId = OpportunityMetadata_SL.CpqRecordType,
        Type = 'New Business',
        Overwrite_Type__c = false
      );

      opps.add(opp);
      existingOpps.put(oppId, opp.clone(true, true, false, false));
    }
  }
}