@isTest(isParallel=false)
private class OpportunityFinancialReqJPTest_SL {
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
      SELECT Id, StageName, CurrencyIsoCode, Included_in_Partner_Community__c, Pricing_Type__c
      FROM Opportunity
      LIMIT 1
    ];
    insertedOpp.StageName = 'Closed Won Pending';
    insertedOpp.CurrencyIsoCode = 'JPY';
    insertedOpp.Included_in_Partner_Community__c = true;
    insertedOpp.Pricing_Type__c = 'NPS';
    insertedOpp.JP_Campaign__c = 'Tassei';
    insertedOpp.Won_Reasons__c = 'Successful POC';
    update insertedOpp;

    Test.startTest();
    List<Case> cases = [SELECT Id FROM Case];
    System.assertEquals(1, cases.size(), 'Case not created');
    Test.stopTest();
  }

  @isTest
  private static void createCasesOnUpdateReplacementTransaction() {
    setup();
    Opportunity insertedOpp = [
      SELECT
        Id,
        StageName,
        CurrencyIsoCode,
        Included_in_Partner_Community__c,
        Pricing_Type__c,
        Replacement_Transaction__c,
        Cancellation_Transaction__c
      FROM Opportunity
      LIMIT 1
    ];
    SBQQ__Quote__c quote = [SELECT Id, SBQQ__ListAmount__c FROM SBQQ__Quote__c LIMIT 1];

    insertedOpp.StageName = 'Closed Won Pending';
    insertedOpp.CurrencyIsoCode = 'JPY';
    insertedOpp.Included_in_Partner_Community__c = true;
    insertedOpp.Pricing_Type__c = 'NPS';
    insertedOpp.JP_Campaign__c = 'Tassei';
    insertedOpp.Won_Reasons__c = 'Successful POC';
    insertedOpp.Replacement_Transaction__c = true;
    insertedOpp.SBQQ__PrimaryQuote__c = quote.Id;
    update insertedOpp;

    Test.startTest();
    List<Case> cases = [SELECT Id, Replacement_Transaction__c, Cancellation_Transaction__c FROM Case];
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
    Opportunity insertedOpp = [
      SELECT
        Id,
        AccountId,
        StageName,
        CurrencyIsoCode,
        Included_in_Partner_Community__c,
        Pricing_Type__c,
        Replacement_Transaction__c,
        Cancellation_Transaction__c
      FROM Opportunity
      LIMIT 1
    ];
    SBQQ__Quote__c quote = [SELECT Id, SBQQ__ListAmount__c FROM SBQQ__Quote__c LIMIT 1];

    //create replacement transaction
    Opportunity repJpyOpp = DataFactory_SL.createOpportunity(insertedOpp.AccountId, true);
    Product2 repJpyProduct = DataFactory_SL.createProduct(false);
    repJpyProduct.Name = repJpyProduct.Name + ' Test Prod 2';
    repJpyProduct.NS_Item_Name__c = repJpyProduct.NS_Item_Name__c + ' Test Prod 2';
    repJpyProduct.ProductCode = repJpyProduct.ProductCode + '2';
    repJpyProduct.NS_Item_Internal_ID__c = '1222';
    insert repJpyProduct;
    SBQQ__Quote__c repJpyQuote = DataFactory_SL.createCPQQuote(repJpyOpp.AccountId, repJpyOpp.Id, true);
    DataFactory_SL.createCPQQuoteLine(repJpyProduct.Id, repJpyQuote.Id, true);
    //

    quote.Replacement_Quote__c = repJpyQuote.Id;
    update quote;

    insertedOpp.StageName = 'Closed Won Pending';
    insertedOpp.CurrencyIsoCode = 'JPY';
    insertedOpp.Included_in_Partner_Community__c = true;
    insertedOpp.Pricing_Type__c = 'NPS';
    insertedOpp.JP_Campaign__c = 'Tassei';
    insertedOpp.Won_Reasons__c = 'Successful POC';
    insertedOpp.SBQQ__PrimaryQuote__c = quote.Id;

    update insertedOpp;

    Test.startTest();
    List<Case> cases = [SELECT Id, Replacement_Transaction__c, Cancellation_Transaction__c FROM Case];
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
  private static void itShouldCreateCaseOnlyOnce() {
    //GIVEN
    setup();
    Opportunity insertedOpp = [
      SELECT Id, StageName, CurrencyIsoCode, Included_in_Partner_Community__c, Pricing_Type__c
      FROM Opportunity
      LIMIT 1
    ];
    insertedOpp.StageName = 'Closed Won Pending';
    insertedOpp.CurrencyIsoCode = 'JPY';
    insertedOpp.Included_in_Partner_Community__c = true;
    insertedOpp.Pricing_Type__c = 'NPS';
    insertedOpp.JP_Campaign__c = 'Tassei';
    insertedOpp.Won_Reasons__c = 'Successful POC';
    fflib_SObjectDomain.getTriggerEvent(Opportunities_SL.class).disableAll();
    update insertedOpp;
    fflib_SObjectDomain.getTriggerEvent(Opportunities_SL.class).enableAll();

    //WHEN
    Test.startTest();
    OpportunityFinancialReqJPQueueable_SL queueable = new OpportunityFinancialReqJPQueueable_SL(
      new List<SObject>{ insertedOpp }
    );
    queueable.work();
    queueable.work();
    Test.stopTest();

    //THEN
    List<Case> cases = [SELECT Id FROM Case];
    System.assertEquals(1, cases.size(), 'Case not created');
  }

  //UNITS

  @isTest
  public static void itShouldDetermineNonRipReplaceContext() {
    //GIVEN
    Opportunity jpyOpp = DataFactory_SL.createOpportunity(fflib_IDGenerator.generate(Account.SObjectType), false);
    Case jpyFinancialCase = DataFactory_SL.createCase(CaseMetadata_SL.FinanceRequestRecordType, false);

    //WHEN
    OpportunityFinancialReqJPQueueable_SL.determineRipReplaceContext(jpyOpp, jpyFinancialCase);

    //THEN
    System.assertEquals(
      false,
      jpyFinancialCase.Cancellation_Transaction__c,
      'This case should NOT identify itself as in a RR context as a cancellation'
    );
    System.assertEquals(
      false,
      jpyFinancialCase.Replacement_Transaction__c,
      'This case should NOT identify itself as in a RR context as a replacement'
    );
  }

  @isTest
  public static void itShouldDetermineReplacementRipReplaceContext() {
    //GIVEN
    Opportunity jpyOpp = DataFactory_SL.createOpportunity(fflib_IDGenerator.generate(Account.SObjectType), false);
    Case jpyFinancialCase = DataFactory_SL.createCase(CaseMetadata_SL.FinanceRequestRecordType, false);
    jpyOpp = setFormulaField(jpyOpp, 'Replacement_Transaction__c', 'true');

    //WHEN
    OpportunityFinancialReqJPQueueable_SL.determineRipReplaceContext(jpyOpp, jpyFinancialCase);

    //THEN
    System.assertEquals(
      false,
      jpyFinancialCase.Cancellation_Transaction__c,
      'This case should NOT identify itself as in a RR context as a cancellation'
    );
    System.assertEquals(
      true,
      jpyFinancialCase.Replacement_Transaction__c,
      'This case should identify itself as in a RR context as a replacement'
    );
  }

  @isTest
  public static void itShouldDetermineCancellationRipReplaceContext() {
    //GIVEN
    Opportunity jpyOpp = DataFactory_SL.createOpportunity(fflib_IDGenerator.generate(Account.SObjectType), false);
    Case jpyFinancialCase = DataFactory_SL.createCase(CaseMetadata_SL.FinanceRequestRecordType, false);
    jpyOpp = setFormulaField(jpyOpp, 'Cancellation_Transaction__c', 'true');

    //WHEN
    OpportunityFinancialReqJPQueueable_SL.determineRipReplaceContext(jpyOpp, jpyFinancialCase);

    //THEN
    System.assertEquals(
      true,
      jpyFinancialCase.Cancellation_Transaction__c,
      'This case should identify itself as in a RR context as a cancellation'
    );
    System.assertEquals(
      false,
      jpyFinancialCase.Replacement_Transaction__c,
      'This case should NOT identify itself as in a RR context as a replacement'
    );
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
  private static Opportunity setFormulaField(Opportunity record, String fieldName, String value) {
    String jsonString = JSON.serialize(record);
    Map<String, Object> dataMap = (Map<String, Object>) JSON.deserializeUntyped(jsonString);
    dataMap.put(fieldName, value);
    jsonString = JSON.serialize(dataMap);
    return (Opportunity) JSON.deserialize(jsonString, Opportunity.class);
  }
}