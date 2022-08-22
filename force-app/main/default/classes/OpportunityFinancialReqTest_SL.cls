@isTest(isParallel=false)
private class OpportunityFinancialReqTest_SL {
  //SETUP
  static void setup() {
    Account testAccount = DataFactory_CM.createAccount('Customer', true);

    Opportunity opp = DataFactory_SL.createOpportunity(testAccount.Id, true);

    Product2 product = DataFactory_SL.createProduct(true);
    SBQQ__Quote__c quote = DataFactory_SL.createCPQQuote(opp.AccountId, opp.Id, true);
    DataFactory_SL.createCPQQuoteLine(product.Id, quote.Id, true);

    User user = DataFactory_SL.createUser('Test', 'Testman', 'System Administrator', true);
    Financial_Request_Owners__c froSetting = new Financial_Request_Owners__c();
    froSetting.Case_Owner__c = user.Id;
    insert froSetting;
  }

  //INTEGRATIONS

  @isTest
  private static void createCasesOnUpdate() {
    setup();
    Opportunity insertedOpp = [
      SELECT
        Id,
        StageName,
        CurrencyIsoCode,
        Deal_Type__c,
        Won_Reasons__c,
        Included_in_Partner_Community__c,
        AccountId,
        SBQQ__PrimaryQuote__c,
        SBQQ__PrimaryQuote__r.SBQQ__ListAmount__c
      FROM Opportunity
      LIMIT 1
    ];

    SBQQ__Quote__c quote = [SELECT Id, SBQQ__ListAmount__c FROM SBQQ__Quote__c LIMIT 1];

    insertedOpp.StageName = 'Closed Won Pending';
    insertedOpp.CurrencyIsoCode = 'USD';
    insertedOpp.Deal_Type__c = 'Direct';
    insertedOpp.Won_Reasons__c = 'Successful POC';
    insertedOpp.SBQQ__PrimaryQuote__c = quote.Id;
    update insertedOpp;

    Test.startTest();
    List<Case> cases = [SELECT Id FROM Case WHERE RecordTypeId = :CaseMetadata_SL.FinanceRequestRecordType];
    System.assertEquals(1, cases.size(), 'Case not created');
    Test.stopTest();
  }

  @isTest
  private static void createCasesOnUpdateReplacementTransaction() {
    setup();
    Opportunity opp = [
      SELECT
        Id,
        StageName,
        CurrencyIsoCode,
        Deal_Type__c,
        Won_Reasons__c,
        Included_in_Partner_Community__c,
        AccountId,
        SBQQ__PrimaryQuote__c,
        SBQQ__PrimaryQuote__r.SBQQ__ListAmount__c,
        Replacement_Transaction__c,
        Cancellation_Transaction__c
      FROM Opportunity
      LIMIT 1
    ];

    SBQQ__Quote__c quote = [SELECT Id, SBQQ__ListAmount__c FROM SBQQ__Quote__c LIMIT 1];

    opp.Replacement_Transaction__c = true;
    opp.StageName = 'Closed Won Pending';
    opp.CurrencyIsoCode = 'USD';
    opp.Deal_Type__c = 'Direct';
    opp.Won_Reasons__c = 'Successful POC';
    opp.SBQQ__PrimaryQuote__c = quote.Id;
    update opp;

    Test.startTest();
    List<Case> cases = [
      SELECT Id, Replacement_Transaction__c, Cancellation_Transaction__c
      FROM Case
      WHERE RecordTypeId = :CaseMetadata_SL.FinanceRequestRecordType
    ];
    System.assertEquals(1, cases.size(), 'Case not created');
    System.assertEquals(
      true,
      cases[0].Replacement_Transaction__c,
      'The case should identify itself as being related to a RR replacement opportunity'
    );
    System.assertEquals(
      false,
      cases[0].Cancellation_Transaction__c,
      'The case should NOT identify itself as being related to a RR cancellation opportunity'
    );
    Test.stopTest();
  }

  @isTest
  private static void createCasesOnUpdateCancellationTransaction() {
    setup();
    Opportunity opp = [
      SELECT
        Id,
        StageName,
        CurrencyIsoCode,
        Deal_Type__c,
        Won_Reasons__c,
        Included_in_Partner_Community__c,
        AccountId,
        SBQQ__PrimaryQuote__c,
        SBQQ__PrimaryQuote__r.SBQQ__ListAmount__c,
        Replacement_Transaction__c,
        Cancellation_Transaction__c
      FROM Opportunity
      LIMIT 1
    ];
    SBQQ__Quote__c quote = [SELECT Id, SBQQ__ListAmount__c FROM SBQQ__Quote__c LIMIT 1];

    //create replacement transaction
    Opportunity repOpp = DataFactory_SL.createOpportunity(opp.AccountId, true);
    Product2 repProduct = DataFactory_SL.createProduct(false);
    repProduct.Name = repProduct.Name + ' Test Prod 2';
    repProduct.NS_Item_Name__c = repProduct.NS_Item_Name__c + ' Test Prod 2';
    repProduct.ProductCode = repProduct.ProductCode + '2';
    repProduct.NS_Item_Internal_ID__c = '1222';
    insert repProduct;
    SBQQ__Quote__c repQuote = DataFactory_SL.createCPQQuote(repOpp.AccountId, repOpp.Id, true);
    DataFactory_SL.createCPQQuoteLine(repProduct.Id, repQuote.Id, true);
    //

    quote.Replacement_Quote__c = repQuote.Id;
    update quote;

    opp.StageName = 'Closed Won Pending';
    opp.CurrencyIsoCode = 'USD';
    opp.Deal_Type__c = 'Direct';
    opp.Won_Reasons__c = 'Successful POC';
    opp.SBQQ__PrimaryQuote__c = quote.Id;
    update opp;

    Test.startTest();
    List<Case> cases = [
      SELECT Id, Replacement_Transaction__c, Cancellation_Transaction__c
      FROM Case
      WHERE RecordTypeId = :CaseMetadata_SL.FinanceRequestRecordType
    ];
    System.assertEquals(1, cases.size(), 'Case not created');
    System.assertEquals(
      false,
      cases[0].Replacement_Transaction__c,
      'The case should NOT identify itself as being related to a RR replacment opportunity'
    );
    System.assertEquals(
      true,
      cases[0].Cancellation_Transaction__c,
      'The case should identify itself as being related to a RR cancellation opportunity'
    );
    Test.stopTest();
  }

  @isTest
  private static void itShouldCreateCasesOnlyOnce() {
    //GIVEN
    setup();
    Opportunity insertedOpp = [
      SELECT
        Id,
        StageName,
        CurrencyIsoCode,
        Deal_Type__c,
        Won_Reasons__c,
        Included_in_Partner_Community__c,
        AccountId,
        SBQQ__PrimaryQuote__c,
        SBQQ__PrimaryQuote__r.SBQQ__ListAmount__c
      FROM Opportunity
      LIMIT 1
    ];

    SBQQ__Quote__c quote = [SELECT Id, SBQQ__ListAmount__c FROM SBQQ__Quote__c LIMIT 1];

    insertedOpp.StageName = 'Closed Won Pending';
    insertedOpp.CurrencyIsoCode = 'USD';
    insertedOpp.Deal_Type__c = 'Direct';
    insertedOpp.Won_Reasons__c = 'Successful POC';
    insertedOpp.SBQQ__PrimaryQuote__c = quote.Id;
    fflib_SObjectDomain.getTriggerEvent(Opportunities_SL.class).disableAll();
    update insertedOpp;
    fflib_SObjectDomain.getTriggerEvent(Opportunities_SL.class).enableAll();

    //WHEN
    Test.startTest();
    OpportunityFinancialReqQueueable_SL queuable = new OpportunityFinancialReqQueueable_SL(
      new List<SObject>{ insertedOpp }
    );
    queuable.work();
    queuable.work();
    Test.stopTest();

    //THEN
    List<Case> cases = [SELECT Id FROM Case WHERE RecordTypeId = :CaseMetadata_SL.FinanceRequestRecordType];
    System.assertEquals(1, cases.size(), 'Case not created');
  }

  //UNITS

  @isTest
  public static void itShouldDetermineNonRipReplaceContext() {
    //GIVEN
    Opportunity opp = DataFactory_SL.createOpportunity(fflib_IDGenerator.generate(Account.SObjectType), false);
    Case financialCase = DataFactory_SL.createCase(CaseMetadata_SL.FinanceRequestRecordType, false);

    //WHEN
    OpportunityFinancialReqQueueable_SL.determineRipReplaceContext(opp, financialCase);

    //THEN
    System.assertEquals(
      false,
      financialCase.Cancellation_Transaction__c,
      'This case should NOT identify itself as in a RR context as a cancellation'
    );
    System.assertEquals(
      false,
      financialCase.Replacement_Transaction__c,
      'This case should NOT identify itself as in a RR context as a replacement'
    );
  }

  @isTest
  public static void itShouldDetermineReplacementRipReplaceContext() {
    //GIVEN
    Opportunity opp = DataFactory_SL.createOpportunity(fflib_IDGenerator.generate(Account.SObjectType), false);
    Case financialCase = DataFactory_SL.createCase(CaseMetadata_SL.FinanceRequestRecordType, false);
    opp = setFormulafield(opp, 'Replacement_Transaction__c', 'true');

    //WHEN
    OpportunityFinancialReqQueueable_SL.determineRipReplaceContext(opp, financialCase);

    //THEN
    System.assertEquals(
      false,
      financialCase.Cancellation_Transaction__c,
      'This case should NOT identify itself as in a RR context as a cancellation'
    );
    System.assertEquals(
      true,
      financialCase.Replacement_Transaction__c,
      'This case should identify itself as in a RR context as a replacement'
    );
  }

  @isTest
  public static void itShouldDetermineCancellationRipReplaceContext() {
    //GIVEN
    Opportunity opp = DataFactory_SL.createOpportunity(fflib_IDGenerator.generate(Account.SObjectType), false);
    Case financialCase = DataFactory_SL.createCase(CaseMetadata_SL.FinanceRequestRecordType, false);
    opp = setFormulafield(opp, 'Cancellation_Transaction__c', 'true');

    //WHEN
    OpportunityFinancialReqQueueable_SL.determineRipReplaceContext(opp, financialCase);

    //THEN
    System.assertEquals(
      true,
      financialCase.Cancellation_Transaction__c,
      'This case should identify itself as in a RR context as a cancellation'
    );
    System.assertEquals(
      false,
      financialCase.Replacement_Transaction__c,
      'This case should NOT identify itself as in a RR context as a replacement'
    );
  }

  @isTest
  public static void itShouldRespectHasRunBoolean() {
    //GIVEN
    Opportunity opp = new Opportunity(Id = fflib_IDGenerator.generate(Opportunity.getSObjectType()));
    String excMsg;

    //WHEN
    OpportunityFinancialReqQueueable_SL queueable = new OpportunityFinancialReqQueueable_SL(
      new List<Opportunity>{ opp }
    );
    queueable.hasRun = true;
    try {
      queueable.work();
    } catch (Exception e) {
      excMsg = e.getMessage();
    }

    //THEN
    System.assertEquals(null, excMsg, 'No exception was expected');
  }

  //UTILS

  /**
   *
   * @description util to set formula fields in memory
   * @param record the record to manipulate
   * @param fieldName the field to set
   * @param value the value to set
   *
   * @return the manipulated record
   */
  private static Opportunity setFormulafield(Opportunity record, String fieldName, String value) {
    String jsonString = JSON.serialize(record);
    Map<String, Object> dataMap = (Map<String, Object>) JSON.deserializeUntyped(jsonString);
    dataMap.put(fieldName, value);
    jsonString = JSON.serialize(dataMap);
    return (Opportunity) JSON.deserialize(jsonString, Opportunity.class);
  }
}