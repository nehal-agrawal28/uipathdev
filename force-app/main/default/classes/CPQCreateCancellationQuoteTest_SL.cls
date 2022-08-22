@isTest(isParallel=false)
public with sharing class CPQCreateCancellationQuoteTest_SL {
  public static void makeData() {
    //create account
    fflib_SObjectDomain.getTriggerEvent(Accounts.class).disableAll();
    Account account = DataFactory_CM.createAccount('Customer', false);
    fflib_SObjectDomain.getTriggerEvent(Accounts.class).enableAll();
    insert account;
    fflib_SObjectDomain.getTriggerEvent(Accounts.class).enableAll();
    //

    //create product
    Product2 prod = new Product2(
      Name = 'FixedPriceProduct',
      IsActive = true,
      SBQQ__SubscriptionPricing__c = 'Fixed Price',
      SBQQ__SubscriptionTerm__c = 12,
      SBQQ__SubscriptionType__c = 'Renewable'
    );
    insert prod;
    //

    Id standardPricebookId = Test.getStandardPricebookId();

    PricebookEntry pbe = new PricebookEntry(
      Pricebook2Id = standardPricebookId,
      Product2Id = prod.Id,
      UnitPrice = 1000.00,
      IsActive = true
    );
    insert new List<PricebookEntry>{ pbe };

    //create contract
    Contract contract = new Contract(
      AccountId = account.Id,
      SBQQ__PreserveBundleStructureUponRenewals__c = true,
      StartDate = Date.today()
    );
    insert contract;
    //

    //add sub
    Integer fPQty = 6;
    Date endDate = Date.today().addYears(1);
    Integer netPrice = 2000;
    SBQQ__Subscription__c subscriptionFP = new SBQQ__Subscription__c(
      SBQQ__Contract__c = contract.Id,
      SBQQ__Product__c = prod.Id,
      SBQQ__Quantity__c = fPQty,
      SBQQ__SubscriptionEndDate__c = endDate
    );
    insert subscriptionFP;
    //
  }

  @isTest
  static void createCancellationQuoteTest() {
    //GIVEN
    makeData();
    System.debug(LoggingLevel.INFO, 'S1. SOQL: ' + Limits.getQueries() + '/' + Limits.getLimitQueries());

    Id accountId = [SELECT Id FROM Account LIMIT 1].Id;
    Id contractId = [SELECT Id FROM Contract LIMIT 1].Id;

    System.debug(LoggingLevel.INFO, 'S2. SOQL: ' + Limits.getQueries() + '/' + Limits.getLimitQueries());
    //create replacement opp
    Date replaceStartDate = Date.today().addDays(14);
    Opportunity opp = DataFactory_SL.createOpportunity(accountId, false);
    opp.Name = 'RR Opp';
    opp.CloseDate = replaceStartDate;
    opp.StageName = Constants_SL.OPPORTUNITY_STAGE_DISCOVERY;
    opp.Pricebook2Id = Test.getStandardPricebookId();
    fflib_SObjectDomain.getTriggerEvent(Opportunities_SL.class).disableAll();
    insert opp;
    fflib_SObjectDomain.getTriggerEvent(Opportunities_SL.class).enableAll();
    System.debug(LoggingLevel.INFO, 'S3. SOQL: ' + Limits.getQueries() + '/' + Limits.getLimitQueries());
    //create replacement quote
    Integer replaceLengthMonths = 12;
    SBQQ__Quote__c quote = DataFactory_SL.createCPQQuote(accountId, opp.Id, false);
    quote.SBQQ__StartDate__c = replaceStartDate;
    quote.SBQQ__EndDate__c = replaceStartDate.addMonths(replaceLengthMonths).addDays(-1);
    quote.SBQQ__Account__c = null;
    fflib_SObjectDomain.getTriggerEvent(Quotes_SL.class).disableAll();
    insert quote;
    fflib_SObjectDomain.getTriggerEvent(Quotes_SL.class).enableAll();
    System.debug(LoggingLevel.INFO, 'S4. SOQL: ' + Limits.getQueries() + '/' + Limits.getLimitQueries());
    //

    CPQCreateCancellationQuote_SL cpqCCQ = new CPQCreateCancellationQuote_SL(
      String.valueOf(contractId),
      String.valueOf(replaceStartDate),
      String.valueOf(quote.Id)
    );

    System.debug(LoggingLevel.INFO, 'S5. SOQL: ' + Limits.getQueries() + '/' + Limits.getLimitQueries());

    try {
      //WHEN
      Test.startTest();
      TriggerHandler.bypass('CPQQuoteTriggerHandler');
      cpqCCQ.execute('Abc123');
      TriggerHandler.clearBypass('CPQQuoteTriggerHandler');
      System.debug(LoggingLevel.INFO, 'T1. SOQL: ' + Limits.getQueries() + '/' + Limits.getLimitQueries());
      Test.stopTest();
      System.debug(LoggingLevel.INFO, 'S6. SOQL: ' + Limits.getQueries() + '/' + Limits.getLimitQueries());

      //THEN
      List<SBQQ__Quote__c> cancelQuotes = [
        SELECT Id, Replacement_Quote__c, SBQQ__Opportunity2__c, SBQQ__NetAmount__c
        FROM SBQQ__Quote__c
        WHERE Replacement_Quote__c != NULL
      ];
      System.assertEquals(1, cancelQuotes.size());
      SBQQ__Quote__c cancelQuote = cancelQuotes[0];
      List<Opportunity> cancelQuoteOpps = [
        SELECT Id, Amount
        FROM Opportunity
        WHERE Id = :cancelQuote.SBQQ__Opportunity2__c
      ];
      System.assertEquals(1, cancelQuoteOpps.size());
      Opportunity cancelOpp = cancelQuoteOpps[0];
      System.assertNotEquals(null, cancelOpp.Amount);
      //
    } catch (Exception e) {
      System.debug('Exception' + e.getMessage() + ': ' + e.getStackTraceString());
    }
    System.debug(LoggingLevel.INFO, 'S7. SOQL: ' + Limits.getQueries() + '/' + Limits.getLimitQueries());
  }
}