@isTest(isParallel=false)
public class OppRipReplaceNamingQueueableTest_SL {
  private static final List<Opportunity> SCOPE_OPP_RECORDS {
    get {
      if (SCOPE_OPP_RECORDS == null) {
        SCOPE_OPP_RECORDS = generateInMemoryOpps(true, SCOPE_OPP_IDS);
      }
      return SCOPE_OPP_RECORDS;
    }
    set;
  }

  private static final List<Opportunity> NON_SCOPE_OPP_RECORDS {
    get {
      if (NON_SCOPE_OPP_RECORDS == null) {
        NON_SCOPE_OPP_RECORDS = generateInMemoryOpps(false, NON_SCOPE_OPP_IDS);
      }
      return NON_SCOPE_OPP_RECORDS;
    }
    set;
  }

  private static final List<Id> SCOPE_OPP_IDS = new List<Id>{
    fflib_IDGenerator.generate(Opportunity.getSObjectType()),
    fflib_IDGenerator.generate(Opportunity.getSObjectType()),
    fflib_IDGenerator.generate(Opportunity.getSObjectType()),
    fflib_IDGenerator.generate(Opportunity.getSObjectType())
  };

  private static final List<Id> NON_SCOPE_OPP_IDS = new List<Id>{
    fflib_IDGenerator.generate(Opportunity.getSObjectType()),
    fflib_IDGenerator.generate(Opportunity.getSObjectType()),
    fflib_IDGenerator.generate(Opportunity.getSObjectType())
  };

  private static final List<Opportunity> EXPECTED_OPP_RECORDS {
    get {
      if (EXPECTED_OPP_RECORDS == null) {
        EXPECTED_OPP_RECORDS = new List<Opportunity>();
        for (Opportunity opp : SCOPE_OPP_RECORDS) {
          EXPECTED_OPP_RECORDS.add(
            new Opportunity(Id = opp.Id, Name = Constants_SL.OPPORTUNITY_NAME_RIP_REPLACE_PREFIX + opp.Name)
          );
        }
      }
      return EXPECTED_OPP_RECORDS;
    }
    set;
  }

  static void createBaseSetupData() {
    Id customerRT = AccountMetadata.getAccountRecordTypeId('Customer');
    Account testAccount = DataFactory_CM.createAccount(customerRT, false);
    testAccount.name = 'Customer Account Test';
    testAccount.BillingCountry = 'France';
    testAccount.SBQQ__RenewalModel__c = 'Contract Based';
    insert testAccount;
    Opportunity testOpp = DataFactory_SL.createOpportunity(testAccount.id, false);
    testOpp.name = 'TestOpportunity for testing';
    insert testOpp;
    Contract cont = DataFactory_SL.createContract(testAccount.id, false);
    cont.EndDate = Date.today().addDays(10);
    cont.SBQQ__Opportunity__c = testOpp.id;
    insert cont;
  }

  //UNIT\\

  @isTest
  public static void itShouldCallDependenciesInExpectedWayFromQueueableWork() {
    //GIVEN
    fflib_ApexMocks mocks = new fflib_ApexMocks();
    Set<Id> oppIds = new Set<Id>(SCOPE_OPP_IDS);
    oppIds.addAll(new Set<Id>(NON_SCOPE_OPP_IDS));
    OpportunitiesSelector_SL mockSelector = (OpportunitiesSelector_SL) setOppSelectorMock(mocks, oppIds);
    fflib_SObjectUnitOfWork mockUow = setUowMock(mocks);
    OppRipReplaceNamingQueueable_SL nameQueueable = new OppRipReplaceNamingQueueable_SL(oppIds);

    //WHEN
    OppRipReplaceNamingQueueable_SL queueable = new OppRipReplaceNamingQueueable_SL(oppIds);
    queueable.work();

    //THEN
    ((fflib_SObjectUnitOfWork) mocks.verify(mockUow, 1)).registerDirty(EXPECTED_OPP_RECORDS);
    ((fflib_SObjectUnitOfWork) mocks.verify(mockUow, 1)).commitWork();
    ((OpportunitiesSelector_SL) mocks.verify(mockSelector, 1)).getOppsWithPrimaryQuote(new Set<Id>(oppIds));
  }

  @isTest
  public static void itShouldCallDependenciesInExpectedWayFromHandlerEntry() {
    //GIVEN
    fflib_ApexMocks mocks = new fflib_ApexMocks();
    Set<Id> oppIds = new Set<Id>(SCOPE_OPP_IDS);
    oppIds.addAll(new Set<Id>(NON_SCOPE_OPP_IDS));
    OpportunitiesSelector_SL mockSelector = (OpportunitiesSelector_SL) setOppSelectorMock(mocks, oppIds);
    fflib_SObjectUnitOfWork mockUow = setUowMock(mocks);
    OppRipReplaceNamingQueueable_SL nameQueueable = new OppRipReplaceNamingQueueable_SL(oppIds);

    //WHEN
    OppRipReplaceNamingQueueable_SL queueable = new OppRipReplaceNamingQueueable_SL(oppIds);
    queueable.work();

    //THEN
    ((fflib_SObjectUnitOfWork) mocks.verify(mockUow, 1)).registerDirty(EXPECTED_OPP_RECORDS);
    ((fflib_SObjectUnitOfWork) mocks.verify(mockUow, 1)).commitWork();
    ((OpportunitiesSelector_SL) mocks.verify(mockSelector, 1)).getOppsWithPrimaryQuote(new Set<Id>(oppIds));
  }

  @isTest
  public static void itShouldReturnTheCorrectEligibleRecordIds() {
    //GIVEN
    List<Opportunity> Records = new List<Opportunity>();
    Records.addAll(NON_SCOPE_OPP_RECORDS);
    Records.addAll(SCOPE_OPP_RECORDS);

    List<Opportunity> existingRecordsList = new List<Opportunity>();
    for (Opportunity opp : SCOPE_OPP_RECORDS) {
      Opportunity tempOpp = new Opportunity(Id = opp.Id, SBQQ__AmendedContract__c = opp.SBQQ__AmendedContract__c);
      existingRecordsList.add((Opportunity) setFormulafield(tempOpp, 'Cancellation_Transaction__c', 'false'));
    }
    for (Opportunity opp : NON_SCOPE_OPP_RECORDS) {
      existingRecordsList.add(
        new Opportunity(
          Id = opp.Id,
          SBQQ__AmendedContract__c = opp.SBQQ__AmendedContract__c,
          SBQQ__PrimaryQuote__c = opp.SBQQ__PrimaryQuote__c
        )
      );
    }
    Map<Id, Opportunity> existingRecords = new Map<Id, Opportunity>(existingRecordsList);

    //WHEN
    System.debug(Records);
    System.debug(existingRecords);
    Set<Id> eligibleOppIds = OppRipReplaceNamingQueueable_SL.determineRecordEligibility(Records, existingRecords);

    //THEN
    System.assertEquals(
      new Set<Id>(SCOPE_OPP_IDS),
      eligibleOppIds,
      'The incorrect eligible opp ids have been returned'
    );
  }

  @isTest
  public static void itShouldHandleNullArgs() {
    //GIVEN
    List<Opportunity> Records;
    Map<Id, Opportunity> existingRecords;

    //WHEN
    String exceptionMsg = '';
    try {
      Set<Id> eligibleOppIds = OppRipReplaceNamingQueueable_SL.determineRecordEligibility(Records, existingRecords);
    } catch (Exception e) {
      exceptionMsg = e.getMessage();
    }

    //THEN
    System.assertEquals('', exceptionMsg, 'An exception should not have been thrown');
  }

  @isTest
  public static void itShouldHandleEmptyArgs() {
    //GIVEN
    List<Opportunity> Records = new List<Opportunity>();
    Map<Id, Opportunity> existingRecords = new Map<Id, Opportunity>();

    //WHEN
    String exceptionMsg = '';
    Set<Id> eligibleOppIds;
    try {
      eligibleOppIds = OppRipReplaceNamingQueueable_SL.determineRecordEligibility(Records, existingRecords);
    } catch (Exception e) {
      exceptionMsg = e.getMessage();
    }

    //THEN
    System.assertEquals('', exceptionMsg, 'An exception should not have been thrown');
    System.assertEquals(true, eligibleOppIds.isEmpty(), 'The set should be initialised and empty');
  }

  //INTEGRATION\\

  @isTest
  public static void itShouldNotSetTheRrOppNamePrefixForRrAmendmentOppsOnUpdate() {
    //GIVEN
    createBaseSetupData();
    Id conId = createAdditionalSetupData();

    //WHEN
    Test.startTest();
    Id oppId = createRrAmendmentOpp(conId);
    Opportunity amendmentOpp = [
      SELECT Id, Name, SBQQ__PrimaryQuote__c, SBQQ__AmendedContract__c
      FROM Opportunity
      WHERE Id = :oppId
    ];
    System.debug(LoggingLevel.ERROR, '!!!!: ' + amendmentOpp.SBQQ__AmendedContract__c);
    System.debug(LoggingLevel.ERROR, '!!!!: ' + amendmentOpp.SBQQ__PrimaryQuote__c);

    Id quoteId = amendmentOpp.SBQQ__PrimaryQuote__c;
    amendmentOpp.SBQQ__PrimaryQuote__c = null;
    amendmentOpp.Amount = null;
    update amendmentOpp;
    amendmentOpp.SBQQ__PrimaryQuote__c = quoteId;
    amendmentOpp.Amount = 1000;
    update amendmentOpp;
    Test.stopTest();

    amendmentOpp = [SELECT Id, Name, SBQQ__PrimaryQuote__c FROM Opportunity WHERE Id = :oppId];
    System.debug(LoggingLevel.ERROR, '!!!!: ' + amendmentOpp.SBQQ__PrimaryQuote__c);
    System.assertEquals(
      Constants_SL.OPPORTUNITY_NAME_RIP_REPLACE_PREFIX,
      amendmentOpp.Name.left(6),
      'The opportunity name should have the RR prefix'
    );
  }

  @isTest
  public static void itShoulNotdSetTheRrOppNamePrefixForRrAmendmentOppsOnInsert() {
    //GIVEN
    createBaseSetupData();
    Id conId = createAdditionalSetupData();

    //WHEN
    Test.startTest();
    Id oppId = createRrAmendmentOpp(conId);
    Test.stopTest();

    //THEN
    Opportunity amendmentOpp = [SELECT Id, Name, SBQQ__PrimaryQuote__c FROM Opportunity WHERE Id = :oppId];
    System.debug(LoggingLevel.ERROR, '!!!!: ' + amendmentOpp.SBQQ__PrimaryQuote__c);
    System.assertNotEquals(
      Constants_SL.OPPORTUNITY_NAME_RIP_REPLACE_PREFIX,
      amendmentOpp.Name.left(6),
      'The opportunity name should not have the RR prefix'
    );
  }

  @isTest
  public static void itShouldSetTheRrOppNamePrefix() {
    //GIVEN
    fflib_SObjectDomain.getTriggerEvent(Opportunities_SL.class).disableAll();
    createBaseSetupData();
    Id conId = createAdditionalSetupData();
    Test.startTest();
    fflib_SObjectDomain.getTriggerEvent(Opportunities_SL.class).disableAll();
    Id oppId = createRrAmendmentOpp(conId);
    fflib_SObjectDomain.getTriggerEvent(Opportunities_SL.class).enableAll();

    //WHEN
    OppRipReplaceNamingQueueable_SL queuable = new OppRipReplaceNamingQueueable_SL(new Set<Id>{ oppId });
    queuable.work();
    Test.stopTest();

    Opportunity amendmentOpp = [SELECT Id, Name, SBQQ__PrimaryQuote__c FROM Opportunity WHERE Id = :oppId];
    System.debug(LoggingLevel.ERROR, '!!!!: ' + amendmentOpp.SBQQ__PrimaryQuote__c);
    System.assertEquals(
      Constants_SL.OPPORTUNITY_NAME_RIP_REPLACE_PREFIX,
      amendmentOpp.Name.left(6),
      'The opportunity name should have the RR prefix'
    );
  }

  @isTest
  public static void itShouldNotSetTheRrOppNamePrefix() {
    //GIVEN
    fflib_SObjectDomain.getTriggerEvent(Opportunities_SL.class).disableAll();
    createBaseSetupData();
    Id conId = createAdditionalSetupData();
    Test.startTest();
    fflib_SObjectDomain.getTriggerEvent(Opportunities_SL.class).disableAll();
    Id oppId = createStandardAmendmentOpp(conId);
    fflib_SObjectDomain.getTriggerEvent(Opportunities_SL.class).enableAll();

    //WHEN

    OppRipReplaceNamingQueueable_SL queuable = new OppRipReplaceNamingQueueable_SL(new Set<Id>{ oppId });
    queuable.work();
    Test.stopTest();

    Opportunity amendmentOpp = [SELECT Id, Name, SBQQ__PrimaryQuote__c FROM Opportunity WHERE Id = :oppId];
    System.debug(LoggingLevel.ERROR, '!!!!: ' + amendmentOpp.SBQQ__PrimaryQuote__c);
    System.assertNotEquals(
      Constants_SL.OPPORTUNITY_NAME_RIP_REPLACE_PREFIX,
      amendmentOpp.Name.left(6),
      'The opportunity name should not have the RR prefix'
    );
  }

  //UTILS\\

  /**
   * Creates a mock Opportunity Selector implementation
   * @param mocks mock instance
   * @param oppIds the opportunity Ids that will be passed to the selector
   * @return the mock selector implementation
   */
  private static OpportunitiesSelector_SL setOppSelectorMock(fflib_ApexMocks mocks, Set<Id> oppIds) {
    OpportunitiesSelector_SL mockSelector = (OpportunitiesSelector_SL) mocks.mock(OpportunitiesSelector_SL.class);
    mocks.startStubbing();
    mocks.when(mockSelector.getSObjectType()).thenReturn(Opportunity.SObjectType);
    mocks.when(mockSelector.sObjectType()).thenReturn(Opportunity.SObjectType);
    mocks.when(mockSelector.getOppsWithPrimaryQuote(oppIds)).thenReturn(SCOPE_OPP_RECORDS);
    mocks.stopStubbing();
    Application_SL.Selector.setMock(mockSelector);
    return mockSelector;
  }

  /**
   * Creates a mock unit of work implementation
   * @param mocks mock instance
   * @return the mock uow implementation
   */
  private static fflib_SObjectUnitOfWork setUowMock(fflib_ApexMocks mocks) {
    fflib_SObjectUnitOfWork mockUow = (fflib_SObjectUnitOfWork) mocks.mock(fflib_SObjectUnitOfWork.class);
    Application_SL.UnitOfWork.setMock(mockUow);

    return mockUow;
  }

  /**
   * Generates in-memory opportunities
   * @param isRrOpp whether the opportunities should be rip and replace amendment opps
   * @param oppIds the opportunity ids to create opportunities from
   * @return the created in-memory opportunities
   */
  private static List<Opportunity> generateInMemoryOpps(Boolean isRrOpp, List<Id> oppIds) {
    List<Opportunity> opps = new List<Opportunity>();

    for (Id oppId : oppIds) {
      Opportunity opp = new Opportunity(Id = oppId, Name = 'Test ' + String.valueOf(oppId).right(5));
      if (isRrOpp) {
        SBQQ__Quote__c quote = new SBQQ__Quote__c(
          Id = fflib_IDGenerator.generate(SBQQ__Quote__c.getSObjectType()),
          Replacement_Quote__c = fflib_IDGenerator.generate(SBQQ__Quote__c.getSObjectType())
        );
        opp.SBQQ__PrimaryQuote__r = quote;
        opp.SBQQ__PrimaryQuote__c = quote.Id;
        opp.Amount = 1000;
        opp = (Opportunity) setFormulafield(opp, 'Cancellation_Transaction__c', 'true');
      }
      opp.SBQQ__AmendedContract__c = fflib_IDGenerator.generate(Contract.getSObjectType());

      opps.add(opp);
    }
    return opps;
  }

  /**
   * Creates required data for testing Rip & Replace (RR) Opp naming
   * @return id of contract ready for RR amendmendment
   */
  public static Id createAdditionalSetupData() {
    //1. Create a RR replacment opp/quote
    Opportunity replacementOpp = [SELECT Id, AccountId FROM Opportunity LIMIT 1];
    SBQQ__Quote__c replacementQuote = DataFactory_SL.createCPQQuote(replacementOpp.AccountId, replacementOpp.Id, true);
    replacementOpp.SBQQ__PrimaryQuote__c = replacementQuote.Id;
    update replacementOpp;

    Id pricebookId = Test.getStandardPricebookId();

    Product2 prod = new Product2(
      Name = 'Product Uipath 2' + String.valueOf((Math.random() * 100) + 1),
      ProductCode = 'PROD' + String.valueOf((Math.random() * 100) + 1),
      isActive = true,
      SBQQ__SubscriptionPricing__c = 'Fixed Price'
    );
    insert new List<Product2>{ prod };

    PricebookEntry pbe = new PricebookEntry(
      Pricebook2Id = pricebookId,
      Product2Id = prod.Id,
      UnitPrice = 1000.00,
      IsActive = true
    );
    insert new List<PricebookEntry>{ pbe };

    //2. Create contract inputs for RR cancellation
    Opportunity contractOpp = DataFactory_SL.createOpportunity(replacementOpp.AccountId, false);
    contractOpp.Pricebook2Id = Test.getStandardPricebookId();
    insert contractOpp;

    SBQQ__Quote__c contractQuote = DataFactory_SL.createCPQQuote(replacementOpp.AccountId, replacementOpp.Id, false);
    contractQuote.SBQQ__PricebookId__c = Test.getStandardPricebookId();
    contractQuote.SBQQ__SubscriptionTerm__c = 12;
    insert contractQuote;

    SBQQ__QuoteLine__c qli = new SBQQ__QuoteLine__c(
      SBQQ__Quote__c = contractQuote.Id,
      SBQQ__Product__c = prod.Id,
      SBQQ__PricebookEntryId__c = pbe.Id,
      SBQQ__Number__c = 1, // Number
      SBQQ__Quantity__c = 30.00, // Quantity
      SBQQ__Renewal__c = false, // Renewal
      Unit_of_measure__c = 'Each/User per year', // Unit of measure
      SBQQ__CostEditable__c = false, // Cost Editable
      SBQQ__PriceEditable__c = false, // Price Editable
      SBQQ__PricingMethod__c = 'List', // Pricing Method
      Business_Type__c = 'Renewal', // Business Type
      SBQQ__PricingMethodEditable__c = false, // Pricing Method Editable
      SBQQ__Hidden__c = false, // Hidden
      Line_Product_Family__c = 'UiPath', // Line Product Family
      Product_Version__c = '2019.10', // Product Version
      License_Model__c = 'Named User', // License Model
      Orchestrator_Disaster_Recovery_Option__c = false, // Orchestrator Disaster Recovery Option
      SBQQ__Description__c = 'With the named user licensing only one named user can access the Studio.UiPath Studio is our Process and Workflow Designer tool. It runs only on Windows like the robot which mimicks the user keystrokes of the target Desktop environment. It enables users to automate with highly intuitive tools (not code): process recorders, drag and drop widgets, re-use best practices templates or refer to other workflow libraries.\n', // Description
      SBQQ__ListPrice__c = 3000.00, // List Unit Price
      SBQQ__CustomerPrice__c = 3820.40, // Customer Unit Price
      SBQQ__NetPrice__c = 3820.40, // Net Unit Price
      SBQQ__SpecialPrice__c = 2292.25, // Special Price                // Contracted Price
      SBQQ__RegularPrice__c = 3820.41, // Regular Unit Price
      SBQQ__ProratedListPrice__c = 5000.01, // Prorated List Price
      SBQQ__SubscriptionPricing__c = 'Fixed Price', // Subscription Pricing
      SBQQ__SubscriptionScope__c = 'Quote', // Percent of Total Scope
      SBQQ__SubscriptionBase__c = 'List', // Percent of Total Base
      SBQQ__DefaultSubscriptionTerm__c = 12, // Default Subscription Term
      SBQQ__NonDiscountable__c = false, // Non Discountable
      SBQQ__NonPartnerDiscountable__c = false
    );
    insert qli;

    OpportunityLineItem oli = new OpportunityLineItem(
      Product2Id = prod.Id,
      OpportunityId = contractOpp.Id,
      PricebookEntryId = pbe.Id,
      TotalPrice = 1000 * 30,
      Quantity = 30,
      SBQQ__QuoteLine__c = qli.Id
    );
    insert oli;

    fflib_SObjectDomain.getTriggerEvent(Contracts_SL.class).disableAll();
    //SBQQ.TriggerControl.enable();

    //3. Create contract and Sub for RR cancellation
    Contract con = (Contract) Contract.sObjectType.newSObject(null, false);
    con.AccountId = replacementOpp.AccountId;
    String ref = 'Test ' + String.valueOf(Math.random() + ' : ' + String.valueOf(System.now()));
    con.contract_ref__c = ref.left(25);
    con.StartDate = System.today();
    con.EndDate = System.today().addYears(1).addDays(-1);
    con.SBQQ__Quote__c = contractQuote.Id;
    con.SBQQ__Opportunity__c = contractOpp.Id;
    con.ContractTerm = 12;
    con.SBQQ__RenewalPricebookId__c = Test.getStandardPricebookId();
    con.SBQQ__AmendmentPricebookId__c = Test.getStandardPricebookId();
    insert con;
    fflib_SObjectDomain.getTriggerEvent(Contracts_SL.class).enableAll();

    con.Status = 'Activated';
    update con;

    SBQQ__Subscription__c sub = new SBQQ__Subscription__c(
      SBQQ__Account__c = replacementOpp.AccountId,
      SBQQ__Contract__c = con.Id,
      SBQQ__Product__c = prod.Id,
      SBQQ__Quantity__c = 30,
      SBQQ__QuoteLine__c = qli.Id,
      SBQQ__OriginalQuoteLine__c = qli.Id
    );
    insert sub;

    return con.Id;
  }

  /**
   * Creates a RR amendment opportunity
   * @param conId the contract to perform a RR amend on
   * @return the id of the created amendment opp
   */
  private static Id createRrAmendmentOpp(Id conId) {
    Opportunity replacementOpp = [SELECT Id, AccountId FROM Opportunity LIMIT 1];
    SBQQ__Quote__c replacementQuote = DataFactory_SL.createCPQQuote(replacementOpp.AccountId, replacementOpp.Id, true);
    replacementOpp.SBQQ__PrimaryQuote__c = replacementQuote.Id;
    update replacementOpp;

    //Create a RR amendment
    CPQServiceRouter_SL productManager = new CPQServiceRouter_SL();
    CPQModel_Quote_SL model = productManager.loadContract(conId);
    CPQQuoteCalculator_SL calculator = new CPQQuoteCalculator_SL();
    model = calculator.read(model.record.Id);
    model.record.Replacement_Quote__c = replacementQuote.Id;
    model.record.SBQQ__StartDate__c = System.today().addDays(364);
    calculator.calculate(model, 'QuoteService_SL');

    Opportunity amendmentOpp = [
      SELECT Id, Name, SBQQ__PrimaryQuote__c, SBQQ__PrimaryQuote__r.Replacement_Quote__c
      FROM Opportunity
      WHERE SBQQ__PrimaryQuote__r.Replacement_Quote__c != NULL
      LIMIT 1
    ];

    return amendmentOpp.Id;
  }

  /**
   * Creates a standard amendment opportunity
   * @param conId the contract to perform an amendment on
   * @return the id of the created amendment opp
   */
  private static Id createStandardAmendmentOpp(Id conId) {
    Opportunity replacementOpp = [SELECT Id, AccountId FROM Opportunity LIMIT 1];
    SBQQ__Quote__c replacementQuote = DataFactory_SL.createCPQQuote(replacementOpp.AccountId, replacementOpp.Id, true);
    replacementOpp.SBQQ__PrimaryQuote__c = replacementQuote.Id;
    update replacementOpp;

    //Create a RR amendment
    CPQServiceRouter_SL productManager = new CPQServiceRouter_SL();
    CPQModel_Quote_SL model = productManager.loadContract(conId);
    CPQQuoteCalculator_SL calculator = new CPQQuoteCalculator_SL();
    model = calculator.read(model.record.Id);
    model.record.SBQQ__StartDate__c = System.today().addDays(364);
    calculator.calculate(model, 'QuoteService_SL');

    Opportunity amendmentOpp = [
      SELECT Id, Name, SBQQ__PrimaryQuote__c, SBQQ__PrimaryQuote__r.Replacement_Quote__c
      FROM Opportunity
      WHERE SBQQ__PrimaryQuote__c = :model.record.Id
      LIMIT 1
    ];

    return amendmentOpp.Id;
  }

  /**
   * Util to set formula fields in memory
   *
   * @param quote the quote to manipulate
   * @param fieldName the field to set
   * @param value the value to set
   *
   * @return the manipulated record
   */
  private static SObject setFormulafield(Opportunity opp, String fieldName, String value) {
    String jsonString = JSON.serialize(opp);
    Map<String, Object> dataMap = (Map<String, Object>) JSON.deserializeUntyped(jsonString);
    dataMap.put(fieldName, value);
    jsonString = JSON.serialize(dataMap);
    return (Opportunity) JSON.deserialize(jsonString, Opportunity.class);
  }
}