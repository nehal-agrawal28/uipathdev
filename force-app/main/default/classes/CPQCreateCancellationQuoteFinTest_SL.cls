@isTest
public with sharing class CPQCreateCancellationQuoteFinTest_SL {
  public static void makeData() {
    //create acc
    fflib_SObjectDomain.getTriggerEvent(Accounts.class).disableAll();
    Account acc = DataFactory_CM.createAccount('Customer', false);
    insert acc;
    fflib_SObjectDomain.getTriggerEvent(Accounts.class).enableAll();

    //create product1
    Product2 product1 = new Product2(
      Name = 'FixedPriceProduct',
      IsActive = true,
      SBQQ__SubscriptionPricing__c = 'Fixed Price',
      SBQQ__SubscriptionTerm__c = 12,
      SBQQ__SubscriptionType__c = 'Renewable'
    );
    insert product1;
    //

    Id stdPbId = Test.getStandardPricebookId();

    PricebookEntry pbe = new PricebookEntry(
      Pricebook2Id = stdPbId,
      Product2Id = product1.Id,
      UnitPrice = 1000.00,
      IsActive = true
    );
    insert new List<PricebookEntry>{ pbe };

    //create contract
    Contract contract = new Contract(
      AccountId = acc.Id,
      SBQQ__PreserveBundleStructureUponRenewals__c = true,
      StartDate = Date.today()
    );
    insert contract;
    //

    //add subscription
    Integer qty = 4;
    Date endDate = Date.today().addYears(1);
    Integer netPri = 1000;
    SBQQ__Subscription__c sub = new SBQQ__Subscription__c(
      SBQQ__Contract__c = contract.Id,
      SBQQ__Product__c = product1.Id,
      SBQQ__Quantity__c = qty,
      SBQQ__SubscriptionEndDate__c = endDate
    );
    insert sub;
    //
  }

  @isTest
  public static void itShouldSetTheReplacementTransactionFlagToTrueForUserCreatedReplacementQuotes() {
    //GIVEN
    makeData();
    Test.startTest();

    Id accId = [SELECT Id FROM Account LIMIT 1].Id;
    //create replacement opp
    Date repStartDate = Date.today().addDays(14);
    Opportunity repOpp = DataFactory_SL.createOpportunity(accId, false);
    repOpp.Name = 'RR Replacement Opportunity';
    repOpp.CloseDate = repStartDate;
    repOpp.StageName = Constants_SL.OPPORTUNITY_STAGE_DISCOVERY;
    repOpp.Pricebook2Id = Test.getStandardPricebookId();
    fflib_SObjectDomain.getTriggerEvent(Opportunities_SL.class).disableAll();
    insert repOpp;
    fflib_SObjectDomain.getTriggerEvent(Opportunities_SL.class).enableAll();

    //create replacement quote
    Integer repLenMonths = 12;
    SBQQ__Quote__c repQuote = DataFactory_SL.createCPQQuote(accId, repOpp.Id, false);
    repQuote.SBQQ__StartDate__c = repStartDate;
    repQuote.SBQQ__EndDate__c = repStartDate.addMonths(repLenMonths).addDays(-1);
    repQuote.SBQQ__Account__c = null;
    repQuote.Replacement_Transaction__c = false;
    fflib_SObjectDomain.getTriggerEvent(Quotes_SL.class).disableAll();
    insert repQuote;
    fflib_SObjectDomain.getTriggerEvent(Quotes_SL.class).enableAll();

    CPQCreateCancellationQuoteFinalizer_SL cccqf = new CPQCreateCancellationQuoteFinalizer_SL(
      '',
      System.today(),
      repQuote.Id,
      new List<String>(),
      new List<String>()
    );

    //WHEN
    cccqf.nextJob();

    //THEN
    SBQQ__Quote__c quote = [SELECT Id, Replacement_Transaction__c FROM SBQQ__Quote__c WHERE Id = :repQuote.Id];
    System.assertEquals(
      true,
      quote.Replacement_Transaction__c,
      'The replacement transaction flag should be set to true'
    );
    Test.stopTest();
  }
}