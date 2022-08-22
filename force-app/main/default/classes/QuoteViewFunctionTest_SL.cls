@isTest
public with sharing class QuoteViewFunctionTest_SL {
  public static final string RENEWAL_TYPE = Constants.QUOTE_RENEWAL_TYPE;

  //INTEGRATION
  @isTest
  public static void itShouldSetTheQuotesViewToRenewal_integration() {
    //GIVEN
    Account account = DataFactory_CM.createAccount(Constants.ACCOUNT_RECORD_TYPE_1, true);
    Opportunity opp = DataFactory_SL.createOpportunity(account.Id, true);
    SBQQ__Quote__c quote = DataFactory_SL.createCPQQuote(account.Id, opp.Id, false);

    //WHEN
    quote.SBQQ__Type__c = RENEWAL_TYPE;
    insert quote;

    //THEN
    SBQQ__Quote__c reQueryQuote = [SELECT Id, Line_Editor_View__c FROM SBQQ__Quote__c LIMIT 1];
    System.assertEquals(
      QuoteViewFunction_SL.QUOTE_TYPE_TO_VIEW.get(RENEWAL_TYPE),
      reQueryQuote.Line_Editor_View__c,
      'Quote View should be set correctly'
    );
  }

  @isTest
  public static void itShouldSetTheQuotesViewToRenewalOnUpdate_integration() {
    //GIVEN
    Account account = DataFactory_CM.createAccount(Constants.ACCOUNT_RECORD_TYPE_1, true);
    Opportunity opp = DataFactory_SL.createOpportunity(account.Id, true);
    SBQQ__Quote__c quote = DataFactory_SL.createCPQQuote(account.Id, opp.Id, false);
    quote.SBQQ__Type__c = 'Quote';
    insert quote;
    System.assertNotEquals(
      QuoteViewFunction_SL.QUOTE_TYPE_TO_VIEW.get(RENEWAL_TYPE),
      [SELECT Id, Line_Editor_View__c FROM SBQQ__Quote__c LIMIT 1]
      .Line_Editor_View__c,
      'Quote view should not be set to renewal view'
    );

    //WHEN
    quote.SBQQ__Type__c = RENEWAL_TYPE;
    update quote;

    //THEN
    SBQQ__Quote__c reQueryQuote = [SELECT Id, Line_Editor_View__c FROM SBQQ__Quote__c LIMIT 1];
    System.assertEquals(
      QuoteViewFunction_SL.QUOTE_TYPE_TO_VIEW.get(RENEWAL_TYPE),
      reQueryQuote.Line_Editor_View__c,
      'Quote View should be set correctly'
    );
  }

  //UNIT
  @isTest
  public static void itShouldSetTheQuotesViewToRenewal() {
    //GIVEN
    String type = RENEWAL_TYPE;
    SBQQ__Quote__c quote = new SBQQ__Quote__c(
      Id = fflib_IDGenerator.generate(SBQQ__Quote__c.SObjectType),
      SBQQ__Type__c = type
    );
    quote = (SBQQ__Quote__c) setFormulafield(quote, 'Deal_Type__c', 'Direct');
    quote = (SBQQ__Quote__c) setFormulafield(quote, 'Account_Geo__c', 'India');

    //WHEN
    QuoteViewFunction_SL.setQuoteView(new List<SBQQ__Quote__c>{ quote });

    //THEN
    System.assertEquals(
      QuoteViewFunction_SL.QUOTE_TYPE_TO_VIEW.get(type),
      quote.Line_Editor_View__c,
      'Quote View should be set correctly'
    );
  }

  @isTest
  public static void itShouldSetMultipleQuotesViewToRenewal() {
    //GIVEN
    String type = RENEWAL_TYPE;
    SBQQ__Quote__c quote = new SBQQ__Quote__c(
      Id = fflib_IDGenerator.generate(SBQQ__Quote__c.SObjectType),
      SBQQ__Type__c = type
    );
    quote = (SBQQ__Quote__c) setFormulafield(quote, 'Deal_Type__c', 'Direct');
    quote = (SBQQ__Quote__c) setFormulafield(quote, 'Account_Geo__c', 'India');

    SBQQ__Quote__c quote2 = new SBQQ__Quote__c(
      Id = fflib_IDGenerator.generate(SBQQ__Quote__c.SObjectType),
      SBQQ__Type__c = type
    );
    quote2 = (SBQQ__Quote__c) setFormulafield(quote2, 'Deal_Type__c', 'Direct');
    quote2 = (SBQQ__Quote__c) setFormulafield(quote2, 'Account_Geo__c', 'India');

    List<SBQQ__Quote__c> quotes = new List<SBQQ__Quote__c>{ quote, quote2 };

    //WHEN
    QuoteViewFunction_SL.setQuoteView(quotes);

    //THEN
    for (SBQQ__Quote__c q : quotes) {
      System.assertEquals(
        QuoteViewFunction_SL.QUOTE_TYPE_TO_VIEW.get(type),
        q.Line_Editor_View__c,
        'Quote View should be set correctly'
      );
    }
  }

  @isTest
  public static void itShouldSetOnlyOneQuotesViewToRenewal() {
    //GIVEN
    String type = RENEWAL_TYPE;
    SBQQ__Quote__c quote = new SBQQ__Quote__c(
      Id = fflib_IDGenerator.generate(SBQQ__Quote__c.SObjectType),
      SBQQ__Type__c = type
    );
    quote = (SBQQ__Quote__c) setFormulafield(quote, 'Deal_Type__c', 'Direct');
    quote = (SBQQ__Quote__c) setFormulafield(quote, 'Account_Geo__c', 'India');

    type = 'Non Renewal';
    SBQQ__Quote__c quote2 = new SBQQ__Quote__c(
      Id = fflib_IDGenerator.generate(SBQQ__Quote__c.SObjectType),
      SBQQ__Type__c = type
    );
    quote2 = (SBQQ__Quote__c) setFormulafield(quote2, 'Deal_Type__c', 'Direct');
    quote2 = (SBQQ__Quote__c) setFormulafield(quote2, 'Account_Geo__c', 'India');

    List<SBQQ__Quote__c> quotes = new List<SBQQ__Quote__c>{ quote, quote2 };

    //WHEN
    QuoteViewFunction_SL.setQuoteView(quotes);

    //THEN
    System.assertEquals(
      QuoteViewFunction_SL.QUOTE_TYPE_TO_VIEW.get(RENEWAL_TYPE),
      quote.Line_Editor_View__c,
      'Quote View should be set correctly'
    );
    System.assertEquals(null, quote2.Line_Editor_View__c, 'Quote View should NOT be set');
  }

  @isTest
  public static void itShouldNotSetTheQuotesView() {
    //GIVEN
    //Disabled Type
    String type = 'Non Renewal';
    SBQQ__Quote__c quote = new SBQQ__Quote__c(
      Id = fflib_IDGenerator.generate(SBQQ__Quote__c.SObjectType),
      SBQQ__Type__c = type
    );
    quote = (SBQQ__Quote__c) setFormulafield(quote, 'Deal_Type__c', 'Direct');
    quote = (SBQQ__Quote__c) setFormulafield(quote, 'Account_Geo__c', 'India');

    //Disabled Deal Type
    type = 'ELA';
    SBQQ__Quote__c quote2 = new SBQQ__Quote__c(
      Id = fflib_IDGenerator.generate(SBQQ__Quote__c.SObjectType),
      SBQQ__Type__c = type
    );
    quote2 = (SBQQ__Quote__c) setFormulafield(quote2, 'Deal_Type__c', 'Partner');
    quote2 = (SBQQ__Quote__c) setFormulafield(quote2, 'Account_Geo__c', 'India');

    //Disabled Account Geo
    SBQQ__Quote__c quote3 = new SBQQ__Quote__c(
      Id = fflib_IDGenerator.generate(SBQQ__Quote__c.SObjectType),
      SBQQ__Type__c = type
    );
    quote3 = (SBQQ__Quote__c) setFormulafield(quote3, 'Deal_Type__c', 'Direct');
    quote3 = (SBQQ__Quote__c) setFormulafield(quote3, 'Account_Geo__c', 'EMEA');

    //WHEN
    QuoteViewFunction_SL.setQuoteView(new List<SBQQ__Quote__c>{ quote, quote2, quote3 });

    //THEN
    System.assertEquals(null, quote.Line_Editor_View__c, 'Quote View should NOT be set');
    System.assertEquals(null, quote2.Line_Editor_View__c, 'Quote View should NOT be set');
    System.assertEquals(null, quote3.Line_Editor_View__c, 'Quote View should NOT be set');
  }

  private static SObject setFormulafield(SBQQ__Quote__c quote, String fieldName, String value) {
    String jsonString = JSON.serialize(quote);
    Map<String, Object> dataMap = (Map<String, Object>) JSON.deserializeUntyped(jsonString);
    dataMap.put(fieldName, value);
    jsonString = JSON.serialize(dataMap);
    return (SBQQ__Quote__c) JSON.deserialize(jsonString, SBQQ__Quote__c.class);
  }

  @isTest
  public static void itShouldSetTheQuotesViewToRenewalOnUpdate() {
    //GIVEN
    Id quoteId = fflib_IDGenerator.generate(SBQQ__Quote__c.SObjectType);
    String type = 'Quote';
    SBQQ__Quote__c quote = new SBQQ__Quote__c(Id = quoteid, SBQQ__Type__c = type);
    Map<Id, SBQQ__Quote__c> existingQuote = new Map<Id, SBQQ__Quote__c>();
    existingQuote.put(quoteId, quote);

    String updatedType = RENEWAL_TYPE;
    SBQQ__Quote__c updatedQuote = new SBQQ__Quote__c(Id = quoteid, SBQQ__Type__c = updatedType);

    //WHEN
    QuoteViewFunction_SL.setQuoteView(new List<SBQQ__Quote__c>{ updatedQuote }, existingQuote);

    //THEN
    System.assertEquals(
      QuoteViewFunction_SL.QUOTE_TYPE_TO_VIEW.get(updatedType),
      updatedQuote.Line_Editor_View__c,
      'Quote View should be set correctly'
    );
  }

  @isTest
  public static void itShouldNotSetTheQuotesViewToRenewalOnUpdate() {
    //GIVEN
    Id quoteId = fflib_IDGenerator.generate(SBQQ__Quote__c.SObjectType);
    String type = '';
    SBQQ__Quote__c quote = new SBQQ__Quote__c(Id = quoteid, SBQQ__Type__c = type);
    Map<Id, SBQQ__Quote__c> existingQuote = new Map<Id, SBQQ__Quote__c>();
    existingQuote.put(quoteId, quote);

    String updatedType = 'Quote';
    SBQQ__Quote__c updatedQuote = new SBQQ__Quote__c(Id = quoteid, SBQQ__Type__c = updatedType);

    //WHEN
    QuoteViewFunction_SL.setQuoteView(new List<SBQQ__Quote__c>{ updatedQuote }, existingQuote);

    //THEN
    System.assertEquals(null, updatedQuote.Line_Editor_View__c, 'Quote View should NOT be set');
  }
}