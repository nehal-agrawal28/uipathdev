@isTest
public with sharing class CaseRipReplaceFinReqSyncQueueableTest_SL {
  ///ASSERT MSGS

  private static final String ASSERT_MSG_INITIAL_STATE_REP_TRAN = 'Replacement Transaction case status should be in its initial state';
  private static final String ASSERT_MSG_INITIAL_STATE_REP_TRAN_DEAL_HUB_OWNER = 'Replacement Transaction case deal hub owner should be in its initial state';
  private static final String ASSERT_MSG_INITIAL_STATE_CAN_TRAN = 'Cancellation transaction case status should be in its initial state';
  private static final String ASSERT_MSG_INITIAL_STATE_REP_CAN_DEAL_HUB_OWNER_NULL = 'Cancellation transaction case deal hub owner should be in its initial null state';
  private static final String ASSERT_MSG_INITIAL_STATE_CAN_TRAN_MATCH_STATUS = 'Cancellation Transaction case status should match the Replacement Transaction case status';
  private static final String ASSERT_MSG_INITIAL_STATE_REP_CAN_DEAL_HUB_OWNER = 'Cancellation Transaction case deal hub owner should match the Replacement Transaction case deal hub owner';
  private static final String ASSERT_MSG_EXP_ACT_ID_MATCH = 'The expected and actual Id sets should be equal';
  private static final String ASSERT_MSG_ACTUAL_RECS_NULL = 'The actual records returned should not be null';
  private static final String ASSERT_MSG_ACTUAL_RECS_EMPTY = 'The actual records returned should be empty';
  private static final String ASSERT_MSG_HANDLER_NO_EXC = 'Handler logic should execute without generating an exception';
  private static final String ASSERT_MSG_NO_EXC = 'Logic should execute without generating an exception';
  private static final String ASSERT_MSG_ACTUAL_MAP_EXP_KEY = 'The actual map should contain the expected key(s)';
  private static final String ASSERT_MSG_ACTUAL_MAP_EXP_REC = 'The actual map should contain the expected record(s)';
  private static final String ASSERT_MSG_ACTUAL_COLLECTION_EMPTY = 'Returned record collection should be empty';
  private static final String ASSERT_MSG_SYNC_ENABLED = 'Sync feature enablement for Case should be true';
  private static final String ASSERT_MSG_SYNC_DISABLED = 'Sync feature enablement for Case should be false';
  private static final String ASSERT_MSG_ACTUAL_EXP_REC_EQUALITY = 'Each expected record should be equal to its equivalent actual record';
  private static final String ASSERT_MSG_MAP_KEY_NOT = 'The actual map should NOT contain this key';
  private static final String ASSERT_MSG_MAP_KEY_LIST_SIZE = 'The actual map should contain the expected key returning the expected list size';

  ///IN-MEMORY TESTING DATA STRUCTURES

  private static final Id CASE_FINANCE_REQUEST_RT_ID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
    .get(Constants.CASE_RECORD_TYPE_2)
    .getRecordTypeId();
  private static final List<Id> SCOPE_PARENT_IDS = new List<Id>{
    fflib_IDGenerator.generate(Case.getSObjectType()),
    fflib_IDGenerator.generate(Case.getSObjectType()),
    fflib_IDGenerator.generate(Case.getSObjectType())
  };
  private static final List<Id> NON_SCOPE_PARENT_IDS = new List<Id>{
    fflib_IDGenerator.generate(Case.getSObjectType()),
    fflib_IDGenerator.generate(Case.getSObjectType()),
    fflib_IDGenerator.generate(Case.getSObjectType())
  };
  private static final List<Id> ALL_PARENT_IDS {
    get {
      if (ALL_PARENT_IDS == null) {
        ALL_PARENT_IDS = new List<Id>{};
        ALL_PARENT_IDS.addAll(SCOPE_PARENT_IDS);
        ALL_PARENT_IDS.addAll(NON_SCOPE_PARENT_IDS);
      }
      return ALL_PARENT_IDS;
    }
    set;
  }
  private static final List<Id> SCOPE_CHILD_IDS = new List<Id>{
    fflib_IDGenerator.generate(Case.getSObjectType()),
    fflib_IDGenerator.generate(Case.getSObjectType()),
    fflib_IDGenerator.generate(Case.getSObjectType()),
    fflib_IDGenerator.generate(Case.getSObjectType()),
    fflib_IDGenerator.generate(Case.getSObjectType()),
    fflib_IDGenerator.generate(Case.getSObjectType())
  };
  private static final List<Id> NON_SCOPE_CHILD_IDS = new List<Id>{
    fflib_IDGenerator.generate(Case.getSObjectType()),
    fflib_IDGenerator.generate(Case.getSObjectType()),
    fflib_IDGenerator.generate(Case.getSObjectType()),
    fflib_IDGenerator.generate(Case.getSObjectType()),
    fflib_IDGenerator.generate(Case.getSObjectType()),
    fflib_IDGenerator.generate(Case.getSObjectType())
  };
  private static final List<Id> ALL_CHILD_IDS {
    get {
      if (ALL_CHILD_IDS == null) {
        ALL_CHILD_IDS = new List<Id>();
        ALL_CHILD_IDS.addAll(SCOPE_CHILD_IDS);
        ALL_CHILD_IDS.addAll(NON_SCOPE_CHILD_IDS);
      }
      return ALL_CHILD_IDS;
    }
    set;
  }
  private static final List<Id> ALL_IDS {
    get {
      if (ALL_IDS == null) {
        ALL_IDS = new List<Id>();
        ALL_IDS.addAll(ALL_PARENT_IDS);
        ALL_IDS.addAll(ALL_CHILD_IDS);
      }
      return ALL_IDS;
    }
    set;
  }
  private static final Set<Id> SCOPE_REP_QUOTE_IDS {
    get {
      if (SCOPE_REP_QUOTE_IDS == null) {
        SCOPE_REP_QUOTE_IDS = new Set<Id>();
        for (Id id : SCOPE_PARENT_IDS) {
          SCOPE_REP_QUOTE_IDS.add(CASE_PARENT_ID_TO_QUOTE_ID.get(id));
        }
      }
      return SCOPE_REP_QUOTE_IDS;
    }
    set;
  }
  private static final Map<Id, List<Id>> PARENT_ID_TO_CHILD_IDS {
    get {
      if (PARENT_ID_TO_CHILD_IDS == null) {
        PARENT_ID_TO_CHILD_IDS = new Map<Id, List<Id>>{
          SCOPE_PARENT_IDS[0] => new List<Id>{ SCOPE_CHILD_IDS[0], SCOPE_CHILD_IDS[1] },
          SCOPE_PARENT_IDS[1] => new List<Id>{ SCOPE_CHILD_IDS[2], SCOPE_CHILD_IDS[3] },
          SCOPE_PARENT_IDS[2] => new List<Id>{ SCOPE_CHILD_IDS[4], SCOPE_CHILD_IDS[5] },
          NON_SCOPE_PARENT_IDS[0] => new List<Id>{ NON_SCOPE_CHILD_IDS[0], NON_SCOPE_CHILD_IDS[1] },
          NON_SCOPE_PARENT_IDS[1] => new List<Id>{ NON_SCOPE_CHILD_IDS[2], NON_SCOPE_CHILD_IDS[3] },
          NON_SCOPE_PARENT_IDS[2] => new List<Id>{ NON_SCOPE_CHILD_IDS[4], NON_SCOPE_CHILD_IDS[5] }
        };
      }
      return PARENT_ID_TO_CHILD_IDS;
    }
    set;
  }
  private static final Map<Id, Id> CHILD_ID_TO_PARENT_ID {
    get {
      if (CHILD_ID_TO_PARENT_ID == null) {
        CHILD_ID_TO_PARENT_ID = new Map<Id, Id>();
        for (Id id : PARENT_ID_TO_CHILD_IDS.keySet()) {
          List<Id> childIds = PARENT_ID_TO_CHILD_IDS.get(id);
          for (Id cId : childIds) {
            CHILD_ID_TO_PARENT_ID.put(cId, id);
          }
        }
      }
      return CHILD_ID_TO_PARENT_ID;
    }
    set;
  }
  private static final List<Case> SCOPE_PARENT_RECORDS {
    get {
      if (SCOPE_PARENT_RECORDS == null) {
        SCOPE_PARENT_RECORDS = createInMemoryCases(SCOPE_PARENT_IDS, true, false);
      }
      return SCOPE_PARENT_RECORDS;
    }
    set;
  }
  private static final List<Case> NON_SCOPE_PARENT_RECORDS {
    get {
      if (NON_SCOPE_PARENT_RECORDS == null) {
        NON_SCOPE_PARENT_RECORDS = createInMemoryCases(NON_SCOPE_PARENT_IDS, true, false);
        for (Case c : NON_SCOPE_PARENT_RECORDS) {
          c.Replacement_Transaction__c = false;
        }
      }
      return NON_SCOPE_PARENT_RECORDS;
    }
    set;
  }
  private static final List<Case> ALL_PARENT_RECORDS {
    get {
      if (ALL_PARENT_RECORDS == null) {
        ALL_PARENT_RECORDS = new List<Case>();
        ALL_PARENT_RECORDS.addAll(SCOPE_PARENT_RECORDS);
        ALL_PARENT_RECORDS.addAll(NON_SCOPE_PARENT_RECORDS);
      }
      return ALL_PARENT_RECORDS;
    }
    set;
  }
  private static final Map<Id, Case> ALL_PARENT_ID_TO_PARENT_RECORDS = new Map<Id, Case>(ALL_PARENT_RECORDS);
  private static final List<CPQ_RR_Sync_Feature__mdt> CMT_RECORDS_CASE_SYNC_OFF = new List<CPQ_RR_Sync_Feature__mdt>{
    new CPQ_RR_Sync_Feature__mdt(
      DeveloperName = String.valueOf(Case.getSObjectType()),
      Sync_Target_Object__c = String.valueOf(Case.getSObjectType()),
      Is_Active__c = false
    ),
    new CPQ_RR_Sync_Feature__mdt(
      DeveloperName = String.valueOf(Opportunity.getSObjectType()),
      Sync_Target_Object__c = String.valueOf(Opportunity.getSObjectType()),
      Is_Active__c = true
    ),
    new CPQ_RR_Sync_Feature__mdt(
      DeveloperName = String.valueOf(Order.getSObjectType()),
      Sync_Target_Object__c = String.valueOf(Order.getSObjectType()),
      Is_Active__c = true
    ),
    new CPQ_RR_Sync_Feature__mdt(
      DeveloperName = String.valueOf(SBQQ__Quote__c.getSObjectType()),
      Sync_Target_Object__c = String.valueOf(SBQQ__Quote__c.getSObjectType()),
      Is_Active__c = true
    )
  };
  private static final List<CPQ_RR_Sync_Feature__mdt> CMT_RECORDS_CASE_SYNC_ON = new List<CPQ_RR_Sync_Feature__mdt>{
    new CPQ_RR_Sync_Feature__mdt(
      DeveloperName = String.valueOf(Case.getSObjectType()),
      Sync_Target_Object__c = String.valueOf(Case.getSObjectType()),
      Is_Active__c = true
    ),
    new CPQ_RR_Sync_Feature__mdt(
      DeveloperName = String.valueOf(Opportunity.getSObjectType()),
      Sync_Target_Object__c = String.valueOf(Opportunity.getSObjectType()),
      Is_Active__c = false
    ),
    new CPQ_RR_Sync_Feature__mdt(
      DeveloperName = String.valueOf(Order.getSObjectType()),
      Sync_Target_Object__c = String.valueOf(Order.getSObjectType()),
      Is_Active__c = false
    ),
    new CPQ_RR_Sync_Feature__mdt(
      DeveloperName = String.valueOf(SBQQ__Quote__c.getSObjectType()),
      Sync_Target_Object__c = String.valueOf(SBQQ__Quote__c.getSObjectType()),
      Is_Active__c = false
    )
  };
  private static final Map<Id, Id> CASE_PARENT_ID_TO_OPP_ID {
    get {
      if (CASE_PARENT_ID_TO_OPP_ID == null) {
        CASE_PARENT_ID_TO_OPP_ID = new Map<Id, Id>();
        for (Id id : ALL_PARENT_IDS) {
          CASE_PARENT_ID_TO_OPP_ID.put(id, fflib_IDGenerator.generate(Opportunity.getSObjectType()));
        }
      }
      return CASE_PARENT_ID_TO_OPP_ID;
    }
    set;
  }
  private static final Map<Id, Id> CASE_PARENT_ID_TO_QUOTE_ID {
    get {
      if (CASE_PARENT_ID_TO_QUOTE_ID == null) {
        CASE_PARENT_ID_TO_QUOTE_ID = new Map<Id, Id>();
        for (Id id : ALL_PARENT_IDS) {
          CASE_PARENT_ID_TO_QUOTE_ID.put(id, fflib_IDGenerator.generate(SBQQ__Quote__c.getSObjectType()));
        }
      }
      return CASE_PARENT_ID_TO_QUOTE_ID;
    }
    set;
  }
  private static final Map<Id, Opportunity> PARENT_CASE_ID_TO_PARENT_OPPS {
    get {
      if (PARENT_CASE_ID_TO_PARENT_OPPS == null) {
        PARENT_CASE_ID_TO_PARENT_OPPS = new Map<Id, Opportunity>();
        for (Id id : CASE_PARENT_ID_TO_OPP_ID.keySet()) {
          SBQQ__Quote__c parentQuote = PARENT_CASE_ID_TO_PARENT_QUOTES.get(id);
          PARENT_CASE_ID_TO_PARENT_OPPS.put(
            id,
            new Opportunity(Id = CASE_PARENT_ID_TO_OPP_ID.get(id), Replacement_Transaction__c = true)
          );
        }
      }
      return PARENT_CASE_ID_TO_PARENT_OPPS;
    }
    set;
  }
  private static final Map<Id, Id> CASE_ID_TO_DEAL_HUB_OWNER_ID {
    get {
      if (CASE_ID_TO_DEAL_HUB_OWNER_ID == null) {
        CASE_ID_TO_DEAL_HUB_OWNER_ID = new Map<Id, Id>();
        for (Id id : ALL_IDS) {
          CASE_ID_TO_DEAL_HUB_OWNER_ID.put(id, fflib_IDGenerator.generate(User.getSObjectType()));
        }
      }
      return CASE_ID_TO_DEAL_HUB_OWNER_ID;
    }
    set;
  }
  private static final Map<Id, SBQQ__Quote__c> PARENT_CASE_ID_TO_PARENT_QUOTES {
    get {
      if (PARENT_CASE_ID_TO_PARENT_QUOTES == null) {
        PARENT_CASE_ID_TO_PARENT_QUOTES = new Map<Id, SBQQ__Quote__c>();
        for (Id id : CASE_PARENT_ID_TO_QUOTE_ID.keySet()) {
          Opportunity parentOpp = PARENT_CASE_ID_TO_PARENT_OPPS.get(id);
          PARENT_CASE_ID_TO_PARENT_QUOTES.put(
            id,
            new SBQQ__Quote__c(
              Id = CASE_PARENT_ID_TO_QUOTE_ID.get(id),
              Replacement_Transaction__c = true,
              SBQQ__Opportunity2__c = parentOpp.Id,
              SBQQ__Opportunity2__r = parentOpp
            )
          );
        }
      }
      return PARENT_CASE_ID_TO_PARENT_QUOTES;
    }
    set;
  }
  private static Map<Id, Opportunity> ALL_CASE_ID_TO_OPPS {
    get {
      if (ALL_CASE_ID_TO_OPPS == null) {
        ALL_CASE_ID_TO_OPPS = new Map<Id, Opportunity>();
        ALL_CASE_ID_TO_OPPS.putAll(PARENT_CASE_ID_TO_PARENT_OPPS);
      }
      return ALL_CASE_ID_TO_OPPS;
    }
    set;
  }
  private static Map<Id, SBQQ__Quote__c> ALL_CASE_ID_TO_QUOTES {
    get {
      if (ALL_CASE_ID_TO_QUOTES == null) {
        ALL_CASE_ID_TO_QUOTES = new Map<Id, SBQQ__Quote__c>();
        ALL_CASE_ID_TO_QUOTES.putAll(PARENT_CASE_ID_TO_PARENT_QUOTES);
      }
      return ALL_CASE_ID_TO_QUOTES;
    }
    set;
  }
  private static final List<Case> SCOPE_CHILD_RECORDS {
    get {
      if (SCOPE_CHILD_RECORDS == null) {
        SCOPE_CHILD_RECORDS = new List<Case>();
        SCOPE_CHILD_RECORDS = createInMemoryCases(SCOPE_CHILD_IDS, false, true);
      }
      return SCOPE_CHILD_RECORDS;
    }
    set;
  }
  private static final List<Case> NON_SCOPE_CHILD_RECORDS {
    get {
      if (NON_SCOPE_CHILD_RECORDS == null) {
        NON_SCOPE_CHILD_RECORDS = new List<Case>();
        NON_SCOPE_CHILD_RECORDS = createInMemoryCases(NON_SCOPE_CHILD_IDS, false, false);
      }
      return NON_SCOPE_CHILD_RECORDS;
    }
    set;
  }
  private static final List<Case> ALL_CHILD_RECORDS {
    get {
      if (ALL_CHILD_RECORDS == null) {
        ALL_CHILD_RECORDS = new List<Case>();
        ALL_CHILD_RECORDS.addAll(SCOPE_CHILD_RECORDS);
        ALL_CHILD_RECORDS.addAll(NON_SCOPE_CHILD_RECORDS);
      }
      return ALL_CHILD_RECORDS;
    }
    set;
  }
  private static final Map<Id, Case> EXPECTED_SCOPE_CHILD_RECORDS {
    get {
      if (EXPECTED_SCOPE_CHILD_RECORDS == null) {
        EXPECTED_SCOPE_CHILD_RECORDS = new Map<Id, Case>();
        for (Id id : SCOPE_CHILD_IDS) {
          EXPECTED_SCOPE_CHILD_RECORDS.put(
            id,
            new Case(
              Id = id,
              Status = Constants_SL.CASE_STATUS_PENDING_LEGAL_REVIEW,
              Deal_Hub_Owner__c = CASE_ID_TO_DEAL_HUB_OWNER_ID.get(CHILD_ID_TO_PARENT_ID.get(id))
            )
          );
        }
      }
      return EXPECTED_SCOPE_CHILD_RECORDS;
    }
    set;
  }

  ///SETUP
  /**
   * @description creates records and data structures in the test database
   */
  public static void setup() {
    Account account = DataFactory_SL.createAccount(Constants.ACCOUNT_RECORD_TYPE_1, true);
    User dealHubUser = DataFactory_SL.createUser('Deal', 'HubMcDealHub', Constants.STANDARD_USER_PROFILE, true);

    //replacement records
    Opportunity repOpp = DataFactory_SL.createOpportunity(account.Id, true);
    SBQQ__Quote__c repQuote = DataFactory_SL.createCPQQuote(account.Id, repOpp.Id, false);
    repQuote.Replacement_Transaction__c = true;
    insert repQuote;
    repOpp.Replacement_Transaction__c = true;
    repOpp.SBQQ__PrimaryQuote__c = repQuote.Id;
    update repOpp;
    Case repCase = DataFactory_SL.createCase(CASE_FINANCE_REQUEST_RT_ID, false);
    repCase.Opportunity__c = repOpp.Id;
    repCase.Replacement_Transaction__c = true;
    repCase.Deal_Hub_Owner__c = dealHubUser.Id;
    repCase.Status = Constants_SL.CASE_STATUS_DEAL_HUB_REVIEW;
    insert repCase;

    //cancellation records
    Opportunity canOpp = DataFactory_SL.createOpportunity(account.Id, true);
    SBQQ__Quote__c canQuote = DataFactory_SL.createCPQQuote(account.Id, canOpp.Id, false);
    canQuote.Replacement_Quote__c = repQuote.Id;
    insert canQuote;
    canOpp.SBQQ__PrimaryQuote__c = canQuote.Id;
    update canOpp;
    Case canCase = DataFactory_SL.createCase(CASE_FINANCE_REQUEST_RT_ID, false);
    canCase.Opportunity__c = canOpp.Id;
    canCase.Cancellation_Transaction__c = true;
    canCase.Status = Constants.CASE_STATUS_3;
    insert canCase;
  }

  ///INTEGRATIONS

  @isTest
  public static void itShouldCorrectlySyncStatusAndDealHubUserFromReplacementCaseToCancellationCase() {
    //GIVEN
    setup();
    Case repCase = [SELECT Id, Status, Deal_Hub_Owner__c FROM Case WHERE Replacement_Transaction__c = TRUE LIMIT 1];
    System.assertEquals(Constants_SL.CASE_STATUS_DEAL_HUB_REVIEW, repCase.Status, ASSERT_MSG_INITIAL_STATE_REP_TRAN);
    System.assertNotEquals(null, repCase.Deal_Hub_Owner__c, ASSERT_MSG_INITIAL_STATE_REP_TRAN_DEAL_HUB_OWNER);
    Case canCase = [SELECT Id, Status, Deal_Hub_Owner__c FROM Case WHERE Cancellation_Transaction__c = TRUE LIMIT 1];
    System.assertEquals(Constants.CASE_STATUS_3, canCase.Status, ASSERT_MSG_INITIAL_STATE_CAN_TRAN);
    System.assertEquals(null, canCase.Deal_Hub_Owner__c, ASSERT_MSG_INITIAL_STATE_REP_CAN_DEAL_HUB_OWNER_NULL);

    //WHEN
    Test.startTest();
    repCase.Status = Constants_SL.CASE_STATUS_PENDING_LEGAL_REVIEW;
    update repCase;
    CaseRipReplaceFinReqSyncQueueable_SL queueable = new CaseRipReplaceFinReqSyncQueueable_SL(
      new Set<Id>{ repCase.Id }
    );
    queueable.work();
    Test.stopTest();

    //THEN
    Case reQueryCanCase = [SELECT Id, Status, Deal_Hub_Owner__c FROM Case WHERE Id = :canCase.Id];
    System.assertEquals(repCase.Status, reQueryCanCase.Status, ASSERT_MSG_INITIAL_STATE_CAN_TRAN_MATCH_STATUS);
    System.assertEquals(
      repCase.Deal_Hub_Owner__c,
      reQueryCanCase.Deal_Hub_Owner__c,
      ASSERT_MSG_INITIAL_STATE_REP_CAN_DEAL_HUB_OWNER
    );
    //*/
  }

  ///UNITS

  @isTest
  public static void itShouldCorrectlyDetermineRecordEligibility() {
    //GIVEN
    //1. Case.Record Type == Finance_Request
    //2. Case.Replacement_Transaction__c == true
    //3. Case.Status hasChanged
    //4. Case.Status prior value == 'Deal Hub Review'
    List<Case> Records = ALL_PARENT_RECORDS;
    List<Case> exisitingRecordsList = new List<Case>();
    for (Case c : Records) {
      Case clonedCase = c.clone(true, true, true, true);
      clonedCase.Status = Constants_SL.CASE_STATUS_DEAL_HUB_REVIEW;
      exisitingRecordsList.add(clonedCase);
    }
    Map<Id, SObject> ExistingRecords = new Map<Id, SObject>(exisitingRecordsList);

    //WHEN
    Set<Id> actualIds = CaseRipReplaceFinReqSyncQueueable_SL.determineRecordEligibility(Records, ExistingRecords);

    //THEN
    System.assertEquals(new Set<Id>(SCOPE_PARENT_IDS), actualIds, ASSERT_MSG_EXP_ACT_ID_MATCH);
  }

  @isTest
  public static void itShouldCorrectlyDetermineRecordEligibility_EmptyArgs() {
    //GIVEN
    List<Case> Records = new List<Case>();
    Map<Id, SObject> ExistingRecords = new Map<Id, SObject>();

    //WHEN
    Set<Id> actualIds = CaseRipReplaceFinReqSyncQueueable_SL.determineRecordEligibility(Records, ExistingRecords);

    //THEN
    System.assertNotEquals(null, actualIds, ASSERT_MSG_ACTUAL_RECS_NULL);
    System.assertEquals(0, actualIds.size(), ASSERT_MSG_ACTUAL_RECS_EMPTY);
  }

  @isTest
  public static void itShouldCorrectlyDetermineRecordEligibility_NullArgs() {
    //GIVEN
    List<Case> Records;
    Map<Id, SObject> ExistingRecords;

    //WHEN
    Set<Id> actualIds = CaseRipReplaceFinReqSyncQueueable_SL.determineRecordEligibility(Records, ExistingRecords);

    //THEN
    System.assertNotEquals(null, actualIds, ASSERT_MSG_ACTUAL_RECS_NULL);
    System.assertEquals(0, actualIds.size(), ASSERT_MSG_ACTUAL_RECS_EMPTY);
  }

  @IsTest
  private static void itShouldExecuteHandlerLogic() {
    //GIVEN
    fflib_SObjectDomain.Test.Database.onUpdate(ALL_PARENT_RECORDS, new Map<Id, SObject>(ALL_PARENT_RECORDS));
    String exceptionMsg = '';

    //WHEN
    try {
      fflib_SObjectDomain.triggerHandler(Cases_SL.class);
    } catch (Exception e) {
      exceptionMsg = e.getMessage();
    }

    //THEN
    System.assert(String.isBlank(exceptionMsg), ASSERT_MSG_HANDLER_NO_EXC);
  }

  @IsTest
  private static void itShouldExecuteHandlerLogic_disabledSyncFeature() {
    //GIVEN
    fflib_ApexMocks mocks = new fflib_ApexMocks();
    setCmtMock(mocks, CMT_RECORDS_CASE_SYNC_OFF);
    fflib_SObjectDomain.Test.Database.onUpdate(ALL_PARENT_RECORDS, new Map<Id, SObject>(ALL_PARENT_RECORDS));
    String exceptionMsg = '';

    //WHEN
    try {
      fflib_SObjectDomain.triggerHandler(Cases_SL.class);
    } catch (Exception e) {
      exceptionMsg = e.getMessage();
    }

    //THEN
    System.assert(String.isBlank(exceptionMsg), ASSERT_MSG_HANDLER_NO_EXC);
  }

  @isTest
  public static void itShouldHandleInvalidSObjectFieldPairs() {
    //GIVEN
    Schema.SObjectType sobjectType = SBQQ__Quote__c.getSObjectType();
    Schema.SObjectField field = Case.Status;
    String fieldPriorValue = 'Xyz';
    List<SObject> records = new List<SObject>();
    Map<Id, SObject> existingRecords = new Map<Id, SObject>();

    //WHEN
    String excMsg;
    try {
      SObjectPredicate pred = new CaseRipReplaceFinReqSyncQueueable_SL.HasPriorFieldStringValue(
        sobjectType,
        field,
        fieldPriorValue,
        records,
        existingRecords
      );
    } catch (Exception e) {
      excMsg = e.getMessage();
    }

    //THEN
    System.assertEquals(null, excMsg, ASSERT_MSG_NO_EXC);
  }

  @isTest
  public static void itShouldHandleSObjectWithMissingField() {
    //GIVEN
    Schema.SObjectType sobjectType = Case.getSObjectType();
    Schema.SObjectField field = Case.Status;
    String fieldPriorValue = 'In-Progress';
    Case caseObj = new Case(Id = fflib_IDGenerator.generate(Case.getSObjectType()));
    List<SObject> records = new List<SObject>{ caseObj };
    Map<Id, SObject> existingRecords = new Map<Id, SObject>(records);

    //WHEN
    String excMsg;
    try {
      SObjectPredicate pred = new CaseRipReplaceFinReqSyncQueueable_SL.HasPriorFieldStringValue(
        sobjectType,
        field,
        fieldPriorValue,
        records,
        existingRecords
      );
    } catch (Exception e) {
      excMsg = e.getMessage();
    }

    //THEN
    System.assertEquals(null, excMsg, ASSERT_MSG_NO_EXC);
  }

  @isTest
  public static void itShouldCorrectlyGetParentIdToParentMap() {
    //GIVEN
    SBQQ__Quote__c parentCaseQuote = new SBQQ__Quote__c(
      Id = fflib_IDGenerator.generate(SBQQ__Quote__c.getSObjectType())
    );
    Opportunity parentCaseOpp = new Opportunity(
      Id = fflib_IDGenerator.generate(Opportunity.getSObjectType()),
      SBQQ__PrimaryQuote__c = parentCaseQuote.Id,
      SBQQ__PrimaryQuote__r = parentCaseQuote
    );
    Case parentCase = new Case(
      Id = fflib_IDGenerator.generate(Case.getSObjectType()),
      Opportunity__c = parentCaseOpp.Id,
      Opportunity__r = parentCaseOpp
    );

    Opportunity parentCaseWithNoQuoteOpp = new Opportunity(
      Id = fflib_IDGenerator.generate(Opportunity.getSObjectType())
    );
    Case parentCaseWithNoQuote = new Case(
      Id = fflib_IDGenerator.generate(Case.getSObjectType()),
      Opportunity__c = parentCaseWithNoQuoteOpp.Id,
      Opportunity__r = parentCaseWithNoQuoteOpp
    );
    Case parentCaseWithNoOpp = new Case(Id = fflib_IDGenerator.generate(Case.getSObjectType()));

    List<Case> cases = new List<Case>{ parentCase, parentCaseWithNoQuote, parentCaseWithNoOpp };

    //WHEN
    Map<Id, Case> actualParentIdToParentMap = CaseRipReplaceFinReqSyncQueueable_SL.getParentIdToParentMap(cases);

    //THEN
    System.assertEquals(1, actualParentIdToParentMap.size(), ASSERT_MSG_ACTUAL_MAP_EXP_KEY);
    System.assertEquals(true, actualParentIdToParentMap.containsKey(parentCase.Id), ASSERT_MSG_ACTUAL_MAP_EXP_KEY);
    System.assertEquals(parentCase, actualParentIdToParentMap.get(parentCase.Id), ASSERT_MSG_ACTUAL_MAP_EXP_REC);
  }

  @isTest
  public static void itShouldCorrectlyGetParentIdToParentMap_EmptyArg() {
    //GIVEN
    List<Case> emptyCases = new List<Case>();
    String excMsg;

    //WHEN
    Map<Id, Case> actualParentIdToParentMap;
    try {
      actualParentIdToParentMap = CaseRipReplaceFinReqSyncQueueable_SL.getParentIdToParentMap(emptyCases);
    } catch (Exception e) {
      excMsg = e.getMessage();
    }

    //THEN
    System.assertEquals(null, excMsg, ASSERT_MSG_NO_EXC);
    System.assertEquals(0, actualParentIdToParentMap.size(), ASSERT_MSG_ACTUAL_COLLECTION_EMPTY);
  }

  @isTest
  public static void itShouldCorrectlyGetParentIdToParentMap_NullArg() {
    //GIVEN
    List<Case> nullCases;
    String excMsg;

    //WHEN
    Map<Id, Case> actualParentIdToParentMap;
    try {
      actualParentIdToParentMap = CaseRipReplaceFinReqSyncQueueable_SL.getParentIdToParentMap(nullCases);
    } catch (Exception e) {
      excMsg = e.getMessage();
    }

    //THEN
    System.assertEquals(null, excMsg, ASSERT_MSG_NO_EXC + ': ' + excMsg);
    System.assertEquals(0, actualParentIdToParentMap.size(), ASSERT_MSG_ACTUAL_RECS_EMPTY);
  }

  @isTest
  public static void itShouldCorrectlyGetReplacementQuoteIdToParentCaseId() {
    //GIVEN
    ///1
    SBQQ__Quote__c parentCaseQuote = new SBQQ__Quote__c(
      Id = fflib_IDGenerator.generate(SBQQ__Quote__c.getSObjectType())
    );
    Opportunity parentCaseOpp = new Opportunity(
      Id = fflib_IDGenerator.generate(Opportunity.getSObjectType()),
      SBQQ__PrimaryQuote__c = parentCaseQuote.Id,
      SBQQ__PrimaryQuote__r = parentCaseQuote
    );
    Case parentCase = new Case(
      Id = fflib_IDGenerator.generate(Case.getSObjectType()),
      Opportunity__c = parentCaseOpp.Id,
      Opportunity__r = parentCaseOpp
    );
    ///2
    Opportunity parentCaseWithNoQuoteOpp = new Opportunity(
      Id = fflib_IDGenerator.generate(Opportunity.getSObjectType())
    );
    Case parentCaseWithNoQuote = new Case(
      Id = fflib_IDGenerator.generate(Case.getSObjectType()),
      Opportunity__c = parentCaseWithNoQuoteOpp.Id,
      Opportunity__r = parentCaseWithNoQuoteOpp
    );
    ///3
    Case parentCaseWithNoOpp = new Case(Id = fflib_IDGenerator.generate(Case.getSObjectType()));

    ///4
    SBQQ__Quote__c parentCase2Quote = new SBQQ__Quote__c(
      Id = fflib_IDGenerator.generate(SBQQ__Quote__c.getSObjectType())
    );
    Opportunity parentCase2Opp = new Opportunity(
      Id = fflib_IDGenerator.generate(Opportunity.getSObjectType()),
      SBQQ__PrimaryQuote__c = parentCase2Quote.Id,
      SBQQ__PrimaryQuote__r = parentCase2Quote
    );
    Case parentCase2 = new Case(
      Id = fflib_IDGenerator.generate(Case.getSObjectType()),
      Opportunity__c = parentCase2Opp.Id,
      Opportunity__r = parentCase2Opp
    );

    List<Case> cases = new List<Case>{ parentCase, parentCaseWithNoQuote, parentCaseWithNoOpp, parentCase2 };

    //WHEN
    Map<Id, Case> actualReplacementQuoteIdToParentCase = CaseRipReplaceFinReqSyncQueueable_SL.getReplacementQuoteIdToParentCaseId(
      cases
    );

    //THEN
    System.assertEquals(2, actualReplacementQuoteIdToParentCase.size(), ASSERT_MSG_ACTUAL_MAP_EXP_KEY);
    System.assertEquals(
      true,
      actualReplacementQuoteIdToParentCase.containsKey(parentCaseQuote.Id),
      ASSERT_MSG_ACTUAL_MAP_EXP_KEY
    );
    System.assertEquals(
      parentCase,
      actualReplacementQuoteIdToParentCase.get(parentCaseQuote.Id),
      ASSERT_MSG_ACTUAL_MAP_EXP_REC
    );
    System.assertEquals(
      true,
      actualReplacementQuoteIdToParentCase.containsKey(parentCase2Quote.Id),
      ASSERT_MSG_ACTUAL_MAP_EXP_KEY
    );
    System.assertEquals(
      parentCase2,
      actualReplacementQuoteIdToParentCase.get(parentCase2Quote.Id),
      ASSERT_MSG_ACTUAL_MAP_EXP_REC
    );
  }

  @isTest
  public static void itShouldCorrectlyGetReplacementQuoteIdToParentCaseId_EmptyArg() {
    //GIVEN
    List<Case> emptyCases = new List<Case>();
    String excMsg;

    //WHEN
    Map<Id, Case> actualParentIdToParentMap;
    try {
      actualParentIdToParentMap = CaseRipReplaceFinReqSyncQueueable_SL.getReplacementQuoteIdToParentCaseId(emptyCases);
    } catch (Exception e) {
      excMsg = e.getMessage();
    }

    //THEN
    System.assertEquals(null, excMsg, ASSERT_MSG_NO_EXC + ': ' + excMsg);
    System.assertEquals(0, actualParentIdToParentMap.size(), ASSERT_MSG_ACTUAL_COLLECTION_EMPTY);
  }

  @isTest
  public static void itShouldCorrectlyGetReplacementQuoteIdToParentCaseId_NullArg() {
    //GIVEN
    List<Case> nullCases;
    String excMsg;

    //WHEN
    Map<Id, Case> actualParentIdToParentMap;
    try {
      actualParentIdToParentMap = CaseRipReplaceFinReqSyncQueueable_SL.getReplacementQuoteIdToParentCaseId(nullCases);
    } catch (Exception e) {
      excMsg = e.getMessage();
    }

    //THEN
    System.assertEquals(null, excMsg, ASSERT_MSG_NO_EXC + ': ' + excMsg);
    System.assertEquals(0, actualParentIdToParentMap.size(), ASSERT_MSG_ACTUAL_COLLECTION_EMPTY);
  }

  @isTest
  public static void itShouldCorrectlyGetParentIdToChildCases() {
    //GIVEN
    ///1
    ////1 - parent case
    SBQQ__Quote__c parentCaseQuote1 = new SBQQ__Quote__c(
      Id = fflib_IDGenerator.generate(SBQQ__Quote__c.getSObjectType())
    );
    Opportunity parentCaseOpp1 = new Opportunity(
      Id = fflib_IDGenerator.generate(Opportunity.getSObjectType()),
      SBQQ__PrimaryQuote__c = parentCaseQuote1.Id,
      SBQQ__PrimaryQuote__r = parentCaseQuote1
    );
    Case parentCase1 = new Case(
      Id = fflib_IDGenerator.generate(Case.getSObjectType()),
      Opportunity__c = parentCaseOpp1.Id,
      Opportunity__r = parentCaseOpp1
    );

    ////1a - child case
    SBQQ__Quote__c childCaseQuote1a = new SBQQ__Quote__c(
      Id = fflib_IDGenerator.generate(SBQQ__Quote__c.getSObjectType()),
      Replacement_Quote__c = parentCaseQuote1.Id,
      Replacement_Quote__r = parentCaseQuote1
    );
    Opportunity parentCaseOpp1a = new Opportunity(
      Id = fflib_IDGenerator.generate(Opportunity.getSObjectType()),
      SBQQ__PrimaryQuote__c = childCaseQuote1a.Id,
      SBQQ__PrimaryQuote__r = childCaseQuote1a
    );
    Case childCase1a = new Case(
      Id = fflib_IDGenerator.generate(Case.getSObjectType()),
      Opportunity__c = parentCaseOpp1a.Id,
      Opportunity__r = parentCaseOpp1a
    );

    ////1b - child case
    SBQQ__Quote__c childCaseQuote1b = new SBQQ__Quote__c(
      Id = fflib_IDGenerator.generate(SBQQ__Quote__c.getSObjectType()),
      Replacement_Quote__c = parentCaseQuote1.Id,
      Replacement_Quote__r = parentCaseQuote1
    );
    Opportunity childCaseOpp1b = new Opportunity(
      Id = fflib_IDGenerator.generate(Opportunity.getSObjectType()),
      SBQQ__PrimaryQuote__c = childCaseQuote1b.Id,
      SBQQ__PrimaryQuote__r = childCaseQuote1b
    );
    Case childCase1b = new Case(
      Id = fflib_IDGenerator.generate(Case.getSObjectType()),
      Opportunity__c = childCaseOpp1b.Id,
      Opportunity__r = childCaseOpp1b
    );
    ///2
    ////2 - parent case
    SBQQ__Quote__c parentCaseQuote2 = new SBQQ__Quote__c(
      Id = fflib_IDGenerator.generate(SBQQ__Quote__c.getSObjectType())
    );
    Opportunity parentCaseOpp2 = new Opportunity(
      Id = fflib_IDGenerator.generate(Opportunity.getSObjectType()),
      SBQQ__PrimaryQuote__c = parentCaseQuote2.Id,
      SBQQ__PrimaryQuote__r = parentCaseQuote2
    );
    Case parentCase2 = new Case(
      Id = fflib_IDGenerator.generate(Case.getSObjectType()),
      Opportunity__c = parentCaseOpp2.Id,
      Opportunity__r = parentCaseOpp2
    );

    ////2a - child case
    SBQQ__Quote__c childCaseQuote2a = new SBQQ__Quote__c(
      Id = fflib_IDGenerator.generate(SBQQ__Quote__c.getSObjectType()),
      Replacement_Quote__c = parentCaseQuote2.Id,
      Replacement_Quote__r = parentCaseQuote2
    );
    Opportunity parentCaseOpp2a = new Opportunity(
      Id = fflib_IDGenerator.generate(Opportunity.getSObjectType()),
      SBQQ__PrimaryQuote__c = childCaseQuote2a.Id,
      SBQQ__PrimaryQuote__r = childCaseQuote2a
    );
    Case childCase2a = new Case(
      Id = fflib_IDGenerator.generate(Case.getSObjectType()),
      Opportunity__c = parentCaseOpp2a.Id,
      Opportunity__r = parentCaseOpp2a
    );

    ///3
    ////3 - parent case with no child cases
    SBQQ__Quote__c parentCaseQuote3 = new SBQQ__Quote__c(
      Id = fflib_IDGenerator.generate(SBQQ__Quote__c.getSObjectType())
    );
    Opportunity parentCaseOpp3 = new Opportunity(
      Id = fflib_IDGenerator.generate(Opportunity.getSObjectType()),
      SBQQ__PrimaryQuote__c = parentCaseQuote3.Id,
      SBQQ__PrimaryQuote__r = parentCaseQuote3
    );
    Case parentCase3 = new Case(
      Id = fflib_IDGenerator.generate(Case.getSObjectType()),
      Opportunity__c = parentCaseOpp3.Id,
      Opportunity__r = parentCaseOpp3
    );

    ////4 - child case with no parent
    SBQQ__Quote__c childCaseQuote4 = new SBQQ__Quote__c(
      Id = fflib_IDGenerator.generate(SBQQ__Quote__c.getSObjectType())
    );
    Opportunity parentCaseOpp4 = new Opportunity(
      Id = fflib_IDGenerator.generate(Opportunity.getSObjectType()),
      SBQQ__PrimaryQuote__c = childCaseQuote4.Id,
      SBQQ__PrimaryQuote__r = childCaseQuote4
    );
    Case childCase4 = new Case(
      Id = fflib_IDGenerator.generate(Case.getSObjectType()),
      Opportunity__c = parentCaseOpp4.Id,
      Opportunity__r = parentCaseOpp4
    );

    Map<Id, Case> replacementQuoteIdToParentCase = new Map<Id, Case>{
      parentCaseQuote1.Id => parentCase1,
      parentCaseQuote2.Id => parentCase2,
      parentCaseQuote3.Id => parentCase3
    };
    List<Case> childCases = new List<Case>{ childCase1a, childCase1b, childCase2a, childCase4 };

    //WHEN
    Map<Id, List<Case>> actualParentIdToChildCases = CaseRipReplaceFinReqSyncQueueable_SL.getParentIdToChildCases(
      replacementQuoteIdToParentCase,
      childCases
    );

    //THEN
    System.assertEquals(2, actualParentIdToChildCases.size(), ASSERT_MSG_ACTUAL_MAP_EXP_KEY);
    System.assertEquals(true, actualParentIdToChildCases.containsKey(parentCase1.Id), ASSERT_MSG_ACTUAL_MAP_EXP_KEY);
    System.assertEquals(2, actualParentIdToChildCases.get(parentCase1.Id).size(), ASSERT_MSG_MAP_KEY_LIST_SIZE);
    System.assertEquals(true, actualParentIdToChildCases.containsKey(parentCase2.Id), ASSERT_MSG_ACTUAL_MAP_EXP_KEY);
    System.assertEquals(1, actualParentIdToChildCases.get(parentCase2.Id).size(), ASSERT_MSG_MAP_KEY_LIST_SIZE);
    System.assertNotEquals(true, actualParentIdToChildCases.containsKey(parentCase3.Id), ASSERT_MSG_MAP_KEY_NOT);
  }

  @isTest
  public static void itShouldCorrectlyGetParentIdToChildCases_EmptyArg() {
    //GIVEN
    Map<Id, Case> replacementQuoteIdToParentCase = new Map<Id, Case>();
    List<Case> childCases = new List<Case>();
    String excMsg;

    //WHEN
    Map<Id, List<Case>> actualParentIdToChildCases;
    try {
      actualParentIdToChildCases = CaseRipReplaceFinReqSyncQueueable_SL.getParentIdToChildCases(
        replacementQuoteIdToParentCase,
        childCases
      );
    } catch (Exception e) {
      excMsg = e.getMessage();
    }

    //THEN
    System.assertEquals(null, excMsg, ASSERT_MSG_NO_EXC + ': ' + excMsg);
    System.assertEquals(0, actualParentIdToChildCases.size(), ASSERT_MSG_ACTUAL_COLLECTION_EMPTY);
  }

  @isTest
  public static void itShouldCorrectlyGetParentIdToChildCases_NullArg() {
    //GIVEN
    Map<Id, Case> replacementQuoteIdToParentCase;
    List<Case> childCases;
    String excMsg;

    //WHEN
    Map<Id, List<Case>> actualParentIdToChildCases;
    try {
      actualParentIdToChildCases = CaseRipReplaceFinReqSyncQueueable_SL.getParentIdToChildCases(
        replacementQuoteIdToParentCase,
        childCases
      );
    } catch (Exception e) {
      excMsg = e.getMessage();
    }

    //THEN
    System.assertEquals(null, excMsg, ASSERT_MSG_NO_EXC + ': ' + excMsg);
    System.assertEquals(0, actualParentIdToChildCases.size(), ASSERT_MSG_ACTUAL_COLLECTION_EMPTY);
  }

  @isTest
  public static void itShouldCorretlyUpdateCancellationTransactionCaseRecords() {
    //GIVEN
    Id parentCaseId = fflib_IDGenerator.generate(Case.getSObjectType());
    Id parentDealHubUserId = fflib_IDGenerator.generate(User.getSObjectType());
    Case parentCase = new Case(
      Id = parentCaseId,
      Deal_Hub_Owner__c = parentDealHubUserId,
      Status = Constants_SL.CASE_STATUS_PENDING_LEGAL_REVIEW
    );
    Id childCaseId1a = fflib_IDGenerator.generate(Case.getSObjectType());
    Case childCase1a = new Case(Id = childCaseId1a, Status = Constants_SL.CASE_STATUS_DEAL_HUB_REVIEW);
    Id childCaseId1b = fflib_IDGenerator.generate(Case.getSObjectType());
    Case childCase1b = new Case(Id = childCaseId1b, Status = Constants_SL.CASE_STATUS_DEAL_HUB_REVIEW);
    Case orphanedChildCase = new Case(Id = fflib_IDGenerator.generate(Case.getSObjectType()));
    Map<Id, List<Case>> parentIdToChildCases = new Map<Id, List<Case>>{
      parentCaseId => new List<Case>{ childCase1a, childCase1b }
    };
    Map<Id, Case> parentIdToParent = new Map<Id, Case>{
      parentCaseId => parentCase,
      fflib_IDGenerator.generate(Case.getSObjectType()) => new Case(),
      null => null,
      fflib_IDGenerator.generate(Case.getSObjectType()) => null
    };
    Map<Id, Case> expectedRecords = new Map<Id, Case>(
      new List<Case>{
        new Case(
          Id = childCaseId1a,
          Deal_Hub_Owner__c = parentDealHubUserId,
          Status = Constants_SL.CASE_STATUS_PENDING_LEGAL_REVIEW
        ),
        new Case(
          Id = childCaseId1b,
          Deal_Hub_Owner__c = parentDealHubUserId,
          Status = Constants_SL.CASE_STATUS_PENDING_LEGAL_REVIEW
        )
      }
    );

    //WHEN
    Map<Id, Case> actualRecords = new Map<Id, Case>(
      CaseRipReplaceFinReqSyncQueueable_SL.updateCancellationTransactionCaseRecords(
        parentIdToChildCases,
        parentIdToParent
      )
    );

    //THEN
    System.assertEquals(expectedRecords.size(), actualRecords.size(), ASSERT_MSG_ACTUAL_MAP_EXP_KEY);
    for (Id id : expectedRecords.keySet()) {
      System.assertEquals(true, actualRecords.containsKey(id), ASSERT_MSG_ACTUAL_MAP_EXP_REC);
      System.assertEquals(expectedRecords.get(Id), actualRecords.get(Id), ASSERT_MSG_ACTUAL_EXP_REC_EQUALITY);
    }
  }

  @isTest
  public static void itShouldCorretlyUpdateCancellationTransactionCaseRecords_emptyArgs() {
    //GIVEN
    Map<Id, List<Case>> parentIdToChildCases = new Map<Id, List<Case>>();
    Map<Id, Case> parentIdToParent = new Map<Id, Case>{};
    String excMsg;

    //WHEN
    Map<Id, Case> actualRecords;
    try {
      actualRecords = new Map<Id, Case>(
        CaseRipReplaceFinReqSyncQueueable_SL.updateCancellationTransactionCaseRecords(
          parentIdToChildCases,
          parentIdToParent
        )
      );
    } catch (Exception e) {
      excMsg = e.getMessage();
    }

    //THEN
    System.assertEquals(null, excMsg, ASSERT_MSG_NO_EXC + ': ' + excMsg);
    System.assertEquals(0, actualRecords.size(), ASSERT_MSG_ACTUAL_COLLECTION_EMPTY);
  }

  @isTest
  public static void itShouldCorretlyUpdateCancellationTransactionCaseRecords_nullArgs() {
    //GIVEN
    Map<Id, List<Case>> parentIdToChildCases;
    Map<Id, Case> parentIdToParent;
    String excMsg;

    //WHEN
    Map<Id, Case> actualRecords;
    try {
      actualRecords = new Map<Id, Case>(
        CaseRipReplaceFinReqSyncQueueable_SL.updateCancellationTransactionCaseRecords(
          parentIdToChildCases,
          parentIdToParent
        )
      );
    } catch (Exception e) {
      excMsg = e.getMessage();
    }

    //THEN
    System.assertEquals(null, excMsg, ASSERT_MSG_NO_EXC + ': ' + excMsg);
    System.assertEquals(0, actualRecords.size(), ASSERT_MSG_ACTUAL_COLLECTION_EMPTY);
  }

  @isTest
  public static void itShoulCorrectlyReturnIsSyncFeatureEnabled_disabled() {
    //GIVEN
    fflib_ApexMocks mocks = new fflib_ApexMocks();
    CPQRipReplaceSyncFeaturesSelector_SL mockSelector = setCmtMock(mocks, CMT_RECORDS_CASE_SYNC_OFF);

    //WHEN
    Boolean isCaseSyncEnabled = CaseRipReplaceFinReqSyncQueueable_SL.isSyncFeatureEnabled(Case.getSObjectType());

    //THEN
    System.assertEquals(false, isCaseSyncEnabled, ASSERT_MSG_SYNC_DISABLED);
  }

  @isTest
  public static void itShoulCorrectlyReturnIsSyncFeatureEnabled_nullArg() {
    //GIVEN
    fflib_ApexMocks mocks = new fflib_ApexMocks();
    CPQRipReplaceSyncFeaturesSelector_SL mockSelector = setCmtMock(mocks, CMT_RECORDS_CASE_SYNC_OFF);
    String excMsg;

    //WHEN
    Boolean isCaseSyncEnabled;
    try {
      isCaseSyncEnabled = CaseRipReplaceFinReqSyncQueueable_SL.isSyncFeatureEnabled(null);
    } catch (Exception e) {
      excMsg = e.getMessage();
    }

    //THEN
    System.assertEquals(null, excMsg, ASSERT_MSG_NO_EXC + ': ' + excMsg);
    System.assertEquals(false, isCaseSyncEnabled, ASSERT_MSG_SYNC_DISABLED);
  }

  @isTest
  public static void itShoulCorrectlyReturnIsSyncFeatureEnabled_otherSobject() {
    //GIVEN
    fflib_ApexMocks mocks = new fflib_ApexMocks();
    CPQRipReplaceSyncFeaturesSelector_SL mockSelector = setCmtMock(mocks, CMT_RECORDS_CASE_SYNC_OFF);
    String excMsg;

    //WHEN
    Boolean isCaseSyncEnabled;
    try {
      isCaseSyncEnabled = CaseRipReplaceFinReqSyncQueueable_SL.isSyncFeatureEnabled(Account.getSObjectType());
    } catch (Exception e) {
      excMsg = e.getMessage();
    }

    //THEN
    System.assertEquals(null, excMsg, ASSERT_MSG_NO_EXC + ': ' + excMsg);
    System.assertEquals(false, isCaseSyncEnabled, ASSERT_MSG_SYNC_DISABLED);
  }

  @isTest
  public static void itShoulCorrectlyReturnIsSyncFeatureEnabled_enabled() {
    //GIVEN
    fflib_ApexMocks mocks = new fflib_ApexMocks();
    CPQRipReplaceSyncFeaturesSelector_SL mockSelector = setCmtMock(mocks, CMT_RECORDS_CASE_SYNC_ON);

    //WHEN
    Boolean isCaseSyncEnabled = CaseRipReplaceFinReqSyncQueueable_SL.isSyncFeatureEnabled(Case.getSObjectType());

    //THEN
    System.assertEquals(true, isCaseSyncEnabled, ASSERT_MSG_SYNC_ENABLED);
  }

  @isTest
  public static void itShouldCorrectlyCallMethods() {
    //GIVEN
    fflib_ApexMocks mocks = new fflib_ApexMocks();
    setCmtMock(mocks, CMT_RECORDS_CASE_SYNC_ON);
    CasesSelector_SL mockSelector = setCaseSelectorMockParentCase(
      mocks,
      new Set<Id>(SCOPE_PARENT_IDS),
      SCOPE_PARENT_RECORDS
    );
    setCaseSelectorMockChildCase(mocks, mockSelector, new Set<Id>(SCOPE_REP_QUOTE_IDS), SCOPE_CHILD_RECORDS);
    fflib_SObjectUnitOfWork mockUow = setUowMock(mocks);

    //WHEN
    CaseRipReplaceFinReqSyncQueueable_SL queueable = new CaseRipReplaceFinReqSyncQueueable_SL(
      new Set<Id>(SCOPE_PARENT_IDS)
    );
    queueable.work();

    //THEN
    ((CasesSelector_SL) mocks.verify(mockSelector, 1))
      .selectReplacementTransactionQuoteIdsByCaseId(new Set<Id>(SCOPE_PARENT_IDS), false);
    ((CasesSelector_SL) mocks.verify(mockSelector, 1))
      .selectCancellationTransactionCasesByReplacementQuoteIds(new Set<Id>(SCOPE_REP_QUOTE_IDS), false);
    ((fflib_SObjectUnitOfWork) mocks.verify(mockUow, 1)).registerDirty(EXPECTED_SCOPE_CHILD_RECORDS.values());
    ((fflib_SObjectUnitOfWork) mocks.verify(mockUow, 1)).commitWork();
  }

  @isTest
  public static void itShouldUpdateCancellationTransactionCaseRecords_missingKey() {
    //GIVEN
    Id missingKey = fflib_IDGenerator.generate(Case.getSObjectType());
    Case childCaseForMissingKey = new Case(Id = fflib_IDGenerator.generate(Case.getSObjectType()));
    Id presentKey = fflib_IDGenerator.generate(Case.getSObjectType());
    Case parentCaseForPresentKey = new Case(Id = presentKey);
    Case childCaseForPresentKey = new Case(Id = fflib_IDGenerator.generate(Case.getSObjectType()));
    Map<Id, List<Case>> parentIdToChildCases = new Map<Id, List<Case>>{
      missingKey => new List<Case>{ childCaseForMissingKey },
      presentKey => new List<Case>{ childCaseForPresentKey }
    };
    Map<Id, Case> parentIdToParent = new Map<Id, Case>{ presentKey => parentCaseForPresentKey };

    //WHEN
    String excMsg;
    List<Case> actualRecords;
    try {
      actualRecords = CaseRipReplaceFinReqSyncQueueable_SL.updateCancellationTransactionCaseRecords(
        parentIdToChildCases,
        parentIdToParent
      );
    } catch (Exception e) {
      excMsg = e.getMessage();
    }

    //THEN
    System.assertEquals(null, excMsg, ASSERT_MSG_NO_EXC + ': ' + excMsg);
    System.assertEquals(0, actualRecords.size(), ASSERT_MSG_ACTUAL_COLLECTION_EMPTY);
  }

  @isTest
  public static void itShouldUpdateCancellationTransactionCaseRecords_nullEmptyChildLists() {
    //GIVEN
    Id key1 = fflib_IDGenerator.generate(Case.getSObjectType());
    Case parentCase1 = new Case(Id = key1);
    Id key2 = fflib_IDGenerator.generate(Case.getSObjectType());
    Case parentCase2 = new Case(Id = key2);
    Map<Id, List<Case>> parentIdToChildCases = new Map<Id, List<Case>>{ key1 => null, key2 => new List<Case>() };
    Map<Id, Case> parentIdToParent = new Map<Id, Case>{ key1 => parentCase1, key2 => parentCase2 };

    //WHEN
    String excMsg;
    List<Case> actualRecords;
    try {
      actualRecords = CaseRipReplaceFinReqSyncQueueable_SL.updateCancellationTransactionCaseRecords(
        parentIdToChildCases,
        parentIdToParent
      );
    } catch (Exception e) {
      excMsg = e.getMessage();
    }

    //THEN
    System.assertEquals(null, excMsg, ASSERT_MSG_NO_EXC + ': ' + excMsg);
    System.assertEquals(0, actualRecords.size(), ASSERT_MSG_ACTUAL_COLLECTION_EMPTY);
  }

  ///UTILS

  /**
   * @description creates in-memory records including relationships to parent records,
   * dependent on other static data structures
   * @param recordIds case record ids to iterate through, creating a case for each
   * @param isParent indicates the cases, and associated records, are part of 'Replacement
   * Transactions' in an R&R context
   * @param isChild indicates the cases, and associated records, are part of 'Cancellation
   * Transactions' in an R&R context
   * @return the in-memory only case records with opportunity and quote relations
   */
  private static List<Case> createInMemoryCases(List<Id> recordIds, Boolean isParent, Boolean isChild) {
    if ((isParent && isChild) || recordIds == null || recordIds.isEmpty()) {
      return new List<Case>();
    }
    List<Case> records = new List<Case>();

    for (Id id : recordIds) {
      SBQQ__Quote__c quote;
      Opportunity opp;
      if (isParent) {
        quote = ALL_CASE_ID_TO_QUOTES.get(id);
        opp = ALL_CASE_ID_TO_OPPS.get(id);
      } else {
        Case parentCase = ALL_PARENT_ID_TO_PARENT_RECORDS.get(CHILD_ID_TO_PARENT_ID.get(id));
        opp = new Opportunity(Id = fflib_IDGenerator.generate(Opportunity.getSObjectType()));
        quote = new SBQQ__Quote__c(
          Id = fflib_IDGenerator.generate(SBQQ__Quote__c.getSObjectType()),
          SBQQ__Opportunity2__c = opp.Id,
          SBQQ__Opportunity2__r = opp
        );
        quote.Replacement_Quote__c = parentCase.Opportunity__r.SBQQ__PrimaryQuote__c;
        quote.Replacement_Quote__r = parentCase.Opportunity__r.SBQQ__PrimaryQuote__r;
      }
      opp.SBQQ__PrimaryQuote__c = quote.Id;
      opp.SBQQ__PrimaryQuote__r = quote;

      String status = isParent
        ? Constants_SL.CASE_STATUS_PENDING_LEGAL_REVIEW
        : Constants_SL.CASE_STATUS_DEAL_HUB_REVIEW;
      Case c = new Case(
        Id = id,
        Cancellation_Transaction__c = isChild,
        Deal_Hub_Owner__c = CASE_ID_TO_DEAL_HUB_OWNER_ID.get(id),
        Opportunity__c = opp.Id,
        Opportunity__r = opp,
        RecordTypeId = CASE_FINANCE_REQUEST_RT_ID,
        Replacement_Transaction__c = isParent,
        Status = status
      );
      records.add(c);
    }

    return records;
  }

  /**
   * @description creates mock selector and sets CMT record mocking and stubbing
   * @param mocks mock instance for the running methods test context
   * @param cmtRecords the records to returned when calling the stub method(s)
   * @return the instantiated mock selector
   */
  private static CPQRipReplaceSyncFeaturesSelector_SL setCmtMock(
    fflib_ApexMocks mocks,
    List<CPQ_RR_Sync_Feature__mdt> cmtRecords
  ) {
    CPQRipReplaceSyncFeaturesSelector_SL mockSelector = (CPQRipReplaceSyncFeaturesSelector_SL) mocks.mock(
      CPQRipReplaceSyncFeaturesSelector_SL.class
    );
    mocks.startStubbing();
    mocks.when(mockSelector.getSObjectType()).thenReturn(CPQ_RR_Sync_Feature__mdt.SObjectType);
    mocks.when(mockSelector.sObjectType()).thenReturn(CPQ_RR_Sync_Feature__mdt.SObjectType);
    mocks.when(mockSelector.getAll()).thenReturn(cmtRecords);
    mocks.stopStubbing();
    Application_SL.Selector.setMock(mockSelector);

    return mockSelector;
  }

  /**
   * @description creates mock selector and sets record mocking and stubbing for a
   * specific selector method, overload
   * @param mocks mock instance for the running methods test context
   * @param scopeIds the ids the mock selector expects the stubbed method to be called with
   * @param caseRecordsToReturn the records to returned when calling the stub method(s)
   * @return the instantiated mock selector
   */
  private static CasesSelector_SL setCaseSelectorMockParentCase(
    fflib_ApexMocks mocks,
    Set<Id> scopeIds,
    List<Case> caseRecordsToReturn
  ) {
    CasesSelector_SL mockSelector = (CasesSelector_SL) mocks.mock(CasesSelector_SL.class);
    return setCaseSelectorMockParentCase(mocks, mockSelector, scopeIds, caseRecordsToReturn);
  }

  /**
   * @description creates mock selector and sets record mocking and stubbing for a
   * specific selector method
   * @param mocks mock instance for the running methods test context
   * @param mockSelector instantiated mock selecor
   * @param scopeIds the ids the mock selector expects the stubbed method to be called with
   * @param caseRecordsToReturn the records to returned when calling the stub method(s)
   * @return the instantiated mock selector
   */
  private static CasesSelector_SL setCaseSelectorMockParentCase(
    fflib_ApexMocks mocks,
    CasesSelector_SL mockSelector,
    Set<Id> scopeIds,
    List<Case> caseRecordsToReturn
  ) {
    mocks.startStubbing();
    mocks.when(mockSelector.getSObjectType()).thenReturn(Case.SObjectType);
    mocks.when(mockSelector.sObjectType()).thenReturn(Case.SObjectType);
    mocks.when(mockSelector.selectReplacementTransactionQuoteIdsByCaseId(scopeIds, false))
      .thenReturn(caseRecordsToReturn);
    mocks.stopStubbing();
    Application_SL.Selector.setMock(mockSelector);

    return mockSelector;
  }

  /**
   * @description creates mock selector and sets record mocking and stubbing for a
   * specific selector method, overload
   * @param mocks mock instance for the running methods test context
   * @param scopeIds the ids the mock selector expects the stubbed method to be called with
   * @param caseRecordsToReturn the records to returned when calling the stub method(s)
   * @return the instantiated mock selector
   */
  private static CasesSelector_SL setCaseSelectorMockChildCase(
    fflib_ApexMocks mocks,
    Set<Id> scopeIds,
    List<Case> caseRecordsToReturn
  ) {
    CasesSelector_SL mockSelector = (CasesSelector_SL) mocks.mock(CasesSelector_SL.class);
    return setCaseSelectorMockChildCase(mocks, mockSelector, scopeIds, caseRecordsToReturn);
  }

  /**
   * @description creates mock selector and sets record mocking and stubbing for a
   * specific selector method
   * @param mocks mock instance for the running methods test context
   * @param mockSelector instantiated mock selecor
   * @param scopeIds the ids the mock selector expects the stubbed method to be called with
   * @param caseRecordsToReturn the records to returned when calling the stub method(s)
   * @return the instantiated mock selector
   */
  private static CasesSelector_SL setCaseSelectorMockChildCase(
    fflib_ApexMocks mocks,
    CasesSelector_SL mockSelector,
    Set<Id> scopeIds,
    List<Case> caseRecordsToReturn
  ) {
    mocks.startStubbing();
    mocks.when(mockSelector.getSObjectType()).thenReturn(Case.SObjectType);
    mocks.when(mockSelector.sObjectType()).thenReturn(Case.SObjectType);
    mocks.when(mockSelector.selectCancellationTransactionCasesByReplacementQuoteIds(scopeIds, false))
      .thenReturn(caseRecordsToReturn);
    mocks.stopStubbing();
    Application_SL.Selector.setMock(mockSelector);

    return mockSelector;
  }

  /**
   * Creates a mock unit of work implementation
   * @param mocks mock instance
   * @return the mock uow instance
   */
  private static fflib_SObjectUnitOfWork setUowMock(fflib_ApexMocks mocks) {
    fflib_SObjectUnitOfWork mockUow = (fflib_SObjectUnitOfWork) mocks.mock(fflib_SObjectUnitOfWork.class);
    Application_SL.UnitOfWork.setMock(mockUow);

    return mockUow;
  }
}