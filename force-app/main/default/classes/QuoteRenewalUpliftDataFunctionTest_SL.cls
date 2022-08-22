@IsTest
public with sharing class QuoteRenewalUpliftDataFunctionTest_SL {
  static List<CPQ_Renewal_Uplift__mdt> CMT_RECORDS {
    get {
      if (CMT_RECORDS == null) {
        CMT_RECORDS = generateUpliftRecords();
      }
      return CMT_RECORDS;
    }
    set {
    }
  }
  //INTEGRATION
  //I001
  @isTest
  public static void itShouldSetInsertedQuoteUpliftFields() {
    //GIVEN
    Account account = DataFactory_CM.createAccount(Constants.ACCOUNT_RECORD_TYPE_1, false);
    account.BillingCountry = 'Canada';
    account.Geo__c = 'AMER';
    insert account;
    Opportunity opportunity = DataFactory_SL.createOpportunity(account.Id, true);
    SBQQ__Quote__c quote = DataFactory_SL.createCPQQuote(account.Id, opportunity.Id, false);

    //WHEN
    quote.SBQQ__Type__c = Constants_SL.QUOTE_TYPE_RENEWAL;
    insert quote;

    //THEN
    quote = [SELECT Id, Geo_Area_Uplift_Rate__c, Geo_Area_Uplift_Threshold_USD__c FROM SBQQ__Quote__c LIMIT 1];
    System.assertNotEquals(null, quote.Geo_Area_Uplift_Rate__c, 'This field should have been set');
    System.assertNotEquals(null, quote.Geo_Area_Uplift_Threshold_USD__c, 'This field should have been set');
  }

  //I002
  @isTest
  public static void itShouldSetUpdatedQuoteUpliftFields() {
    //GIVEN
    Account account = DataFactory_CM.createAccount(Constants.ACCOUNT_RECORD_TYPE_1, false);
    account.BillingCountry = 'Canada';
    account.Geo__c = 'AMER';
    insert account;
    Opportunity opportunity = DataFactory_SL.createOpportunity(account.Id, true);
    SBQQ__Quote__c quote = DataFactory_SL.createCPQQuote(account.Id, opportunity.Id, false);
    quote.SBQQ__Type__c = Constants_SL.QUOTE_TYPE_NEW;
    insert quote;
    quote = [SELECT Id, Geo_Area_Uplift_Rate__c, Geo_Area_Uplift_Threshold_USD__c FROM SBQQ__Quote__c LIMIT 1];
    System.assertEquals(null, quote.Geo_Area_Uplift_Rate__c, 'This field should NOT have been set');
    System.assertEquals(null, quote.Geo_Area_Uplift_Threshold_USD__c, 'This field NOT should have been set');

    //WHEN
    quote.SBQQ__Type__c = Constants_SL.QUOTE_TYPE_RENEWAL;
    update quote;

    //THEN
    quote = [SELECT Id, Geo_Area_Uplift_Rate__c, Geo_Area_Uplift_Threshold_USD__c FROM SBQQ__Quote__c LIMIT 1];
    System.assertNotEquals(null, quote.Geo_Area_Uplift_Rate__c, 'This field should have been set');
    System.assertNotEquals(null, quote.Geo_Area_Uplift_Threshold_USD__c, 'This field should have been set');
  }

  //UNITS
  //U001
  @isTest
  public static void itShouldSetQuoteUpliftFields() {
    setCmtMock();
    //GIVEN
    Account account = DataFactory_CM.createAccount(Constants.ACCOUNT_RECORD_TYPE_1, false);
    Opportunity opportunity = DataFactory_SL.createOpportunity(account.Id, false);
    SBQQ__Quote__c quote = DataFactory_SL.createCPQQuote(account.Id, opportunity.Id, false);
    quote.SBQQ__Type__c = Constants_SL.QUOTE_TYPE_RENEWAL;
    quote = (SBQQ__Quote__c) setFormulafield(quote, 'Account_Geo__c', 'AMER');

    System.assertEquals(null, quote.Geo_Area_Uplift_Rate__c, 'This field should NOT have been set');
    System.assertEquals(null, quote.Geo_Area_Uplift_Threshold_USD__c, 'This field should NOT have been set');
    System.assertEquals(null, quote.Geo_Area_Uplift_Threshold_Local__c, 'This field should NOT have been set');

    //WHEN
    QuoteRenewalUpliftDataFunction_SL.setRenewalUpliftData(new List<SBQQ__Quote__c>{ quote });

    //THEN
    System.assertNotEquals(null, quote.Geo_Area_Uplift_Rate__c, 'This field should have been set');
    System.assertNotEquals(null, quote.Geo_Area_Uplift_Threshold_USD__c, 'This field should have been set');
    System.assertEquals(
      quote.Geo_Area_Uplift_Threshold_USD__c,
      quote.Geo_Area_Uplift_Threshold_Local__c,
      'This field should have been set to the USD value'
    );
  }

  //U002
  @isTest
  public static void itShouldSetSomeQuoteUpliftFields() {
    setCmtMock();
    //GIVEN
    Account account = DataFactory_CM.createAccount(Constants.ACCOUNT_RECORD_TYPE_1, false);
    Opportunity opportunity = DataFactory_SL.createOpportunity(account.Id, false);
    List<SBQQ__Quote__c> quotes = new List<SBQQ__Quote__c>();

    //Quote 1 - should be set
    SBQQ__Quote__c quote = DataFactory_SL.createCPQQuote(account.Id, opportunity.Id, false);
    quote.SBQQ__Type__c = Constants_SL.QUOTE_TYPE_RENEWAL;
    quote = (SBQQ__Quote__c) setFormulafield(quote, 'Account_Geo__c', 'AMER');
    System.assertEquals(null, quote.Geo_Area_Uplift_Rate__c, 'This field should NOT have been set');
    System.assertEquals(null, quote.Geo_Area_Uplift_Threshold_USD__c, 'This field should NOT have been set');
    System.assertEquals(null, quote.Geo_Area_Uplift_Threshold_Local__c, 'This field should NOT have been set');
    quotes.add(quote);

    //Quote 2 - should not be set
    SBQQ__Quote__c quote2 = DataFactory_SL.createCPQQuote(account.Id, opportunity.Id, false);
    quote2.SBQQ__Type__c = Constants_SL.QUOTE_TYPE_NEW;
    quote2 = (SBQQ__Quote__c) setFormulafield(quote2, 'Account_Geo__c', 'AMER');
    System.assertEquals(null, quote2.Geo_Area_Uplift_Rate__c, 'This field should NOT have been set');
    System.assertEquals(null, quote2.Geo_Area_Uplift_Threshold_USD__c, 'This field should NOT have been set');
    System.assertEquals(null, quote2.Geo_Area_Uplift_Threshold_Local__c, 'This field should NOT have been set');
    quotes.add(quote2);

    //Quote 3 - should not be set
    SBQQ__Quote__c quote3 = DataFactory_SL.createCPQQuote(account.Id, opportunity.Id, false);
    quote3.SBQQ__Type__c = Constants_SL.QUOTE_TYPE_AMENDMENT;
    quote3 = (SBQQ__Quote__c) setFormulafield(quote3, 'Account_Geo__c', 'AMER');
    System.assertEquals(null, quote3.Geo_Area_Uplift_Rate__c, 'This field should NOT have been set');
    System.assertEquals(null, quote3.Geo_Area_Uplift_Threshold_USD__c, 'This field should NOT have been set');
    System.assertEquals(null, quote3.Geo_Area_Uplift_Threshold_Local__c, 'This field should NOT have been set');

    quotes.add(quote3);

    //Quote 4 should be set
    SBQQ__Quote__c quote4 = DataFactory_SL.createCPQQuote(account.Id, opportunity.Id, false);
    quote4.SBQQ__Type__c = Constants_SL.QUOTE_TYPE_RENEWAL;
    quote4 = (SBQQ__Quote__c) setFormulafield(quote4, 'Account_Geo__c', 'AMER');
    System.assertEquals(null, quote4.Geo_Area_Uplift_Rate__c, 'This field should NOT have been set');
    System.assertEquals(null, quote4.Geo_Area_Uplift_Threshold_USD__c, 'This field should NOT have been set');
    System.assertEquals(null, quote4.Geo_Area_Uplift_Threshold_Local__c, 'This field should NOT have been set');

    quotes.add(quote4);

    //WHEN
    QuoteRenewalUpliftDataFunction_SL.setRenewalUpliftData(quotes);

    //THEN
    System.assertNotEquals(null, quote.Geo_Area_Uplift_Rate__c, 'This field should have been set');
    System.assertNotEquals(null, quote.Geo_Area_Uplift_Threshold_USD__c, 'This field should have been set');
    System.assertNotEquals(null, quote.Geo_Area_Uplift_Threshold_Local__c, 'This field should have been set');
    System.assertEquals(null, quote2.Geo_Area_Uplift_Rate__c, 'This field should NOT have been set');
    System.assertEquals(null, quote2.Geo_Area_Uplift_Threshold_USD__c, 'This field should NOT have been set');
    System.assertEquals(null, quote2.Geo_Area_Uplift_Threshold_Local__c, 'This field should NOT have been set');
    System.assertEquals(null, quote3.Geo_Area_Uplift_Rate__c, 'This field should have NOT been set');
    System.assertEquals(null, quote3.Geo_Area_Uplift_Threshold_USD__c, 'This field should NOT have been set');
    System.assertEquals(null, quote3.Geo_Area_Uplift_Threshold_Local__c, 'This field should NOT have been set');
    System.assertNotEquals(null, quote4.Geo_Area_Uplift_Rate__c, 'This field should have been set');
    System.assertNotEquals(null, quote4.Geo_Area_Uplift_Threshold_USD__c, 'This field should have been set');
    System.assertNotEquals(null, quote4.Geo_Area_Uplift_Threshold_Local__c, 'This field should have been set');
  }

  //U003
  @isTest
  public static void itShouldNotSetQuoteUpliftFields() {
    setCmtMock();
    //GIVEN
    Account account = DataFactory_CM.createAccount(Constants.ACCOUNT_RECORD_TYPE_1, false);
    Opportunity opportunity = DataFactory_SL.createOpportunity(account.Id, false);
    SBQQ__Quote__c quote = DataFactory_SL.createCPQQuote(account.Id, opportunity.Id, false);
    quote.SBQQ__Type__c = Constants_SL.QUOTE_TYPE_NEW;
    quote = (SBQQ__Quote__c) setFormulafield(quote, 'Account_Geo__c', 'AMER');

    System.assertEquals(null, quote.Geo_Area_Uplift_Rate__c, 'This field should NOT have been set');
    System.assertEquals(null, quote.Geo_Area_Uplift_Threshold_USD__c, 'This field should NOT have been set');
    System.assertEquals(null, quote.Geo_Area_Uplift_Threshold_Local__c, 'This field should NOT have been set');

    SBQQ__Quote__c quote2 = DataFactory_SL.createCPQQuote(account.Id, opportunity.Id, false);
    quote2.SBQQ__Type__c = Constants_SL.QUOTE_TYPE_AMENDMENT;
    quote2 = (SBQQ__Quote__c) setFormulafield(quote2, 'Account_Geo__c', 'AMER');

    System.assertEquals(null, quote2.Geo_Area_Uplift_Rate__c, 'This field should NOT have been set');
    System.assertEquals(null, quote2.Geo_Area_Uplift_Threshold_USD__c, 'This field should NOT have been set');
    System.assertEquals(null, quote2.Geo_Area_Uplift_Threshold_Local__c, 'This field should NOT have been set');

    //WHEN
    QuoteRenewalUpliftDataFunction_SL.setRenewalUpliftData(new List<SBQQ__Quote__c>{ quote, quote2 });

    //THEN
    System.assertEquals(null, quote.Geo_Area_Uplift_Rate__c, 'This field should NOT have been set');
    System.assertEquals(null, quote.Geo_Area_Uplift_Threshold_USD__c, 'This field should NOT have been set');
    System.assertEquals(null, quote.Geo_Area_Uplift_Threshold_Local__c, 'This field should NOT have been set');
    System.assertEquals(null, quote2.Geo_Area_Uplift_Rate__c, 'This field should NOT have been set');
    System.assertEquals(null, quote2.Geo_Area_Uplift_Threshold_USD__c, 'This field should NOT have been set');
    System.assertEquals(null, quote2.Geo_Area_Uplift_Threshold_Local__c, 'This field should NOT have been set');
  }

  //U004
  @isTest
  public static void itShouldHandleAnNullList() {
    setCmtMock();
    //GIVEN
    List<SBQQ__Quote__c> quotes;
    String exceptionMsg;

    //WHEN
    try {
      QuoteRenewalUpliftDataFunction_SL.setRenewalUpliftData(quotes);
    } catch (Exception e) {
      exceptionMsg = e.getMessage();
    }

    //THEN
    System.assertEquals(null, exceptionMsg, 'Null list should not have produced an exception');
  }

  //U005
  @isTest
  public static void itShouldHandleAnEmptyList() {
    //GIVEN
    List<SBQQ__Quote__c> quotes = new List<SBQQ__Quote__c>();
    String exceptionMsg;

    //WHEN
    try {
      QuoteRenewalUpliftDataFunction_SL.setRenewalUpliftData(quotes);
    } catch (Exception e) {
      exceptionMsg = e.getMessage();
    }

    //THEN
    System.assertEquals(null, exceptionMsg, 'Empty list should not have produced an exception');
  }

  //U006
  @isTest
  public static void itShouldReturnTheAMERGeoCmt() {
    setCmtMock();
    //GIVEN
    String geo = 'AMER';
    String area;

    //WHEN
    CPQ_Renewal_Uplift__mdt cmt = QuoteRenewalUpliftDataFunction_SL.getGeoAreaCmt(geo, area);

    //THEN
    System.assertNotEquals(null, cmt, 'A custom metadata record should have been returned');
    System.assertEquals('AMER', cmt.Geo__c, 'The custom metadata record should have a Geo of AMER');
  }

  //U007
  @isTest
  public static void itShouldReturnTheDefaultCmt_null() {
    setCmtMock();
    //GIVEN
    String geo;
    String area;

    //WHEN
    CPQ_Renewal_Uplift__mdt cmt = QuoteRenewalUpliftDataFunction_SL.getGeoAreaCmt(geo, area);

    //THEN
    System.assertNotEquals(null, cmt, 'A custom metadata record should have been returned');
    System.assertEquals(null, cmt.Geo__c, 'The custom metadata record should have a Geo of null');
  }

  //U008
  @isTest
  public static void itShouldReturnTheDefaultCmt_noRecord() {
    setCmtMock();
    //GIVEN
    String geo = 'ARRAKIS';
    String area;

    //WHEN
    CPQ_Renewal_Uplift__mdt cmt = QuoteRenewalUpliftDataFunction_SL.getGeoAreaCmt(geo, area);

    //THEN
    System.assertNotEquals(null, cmt, 'A custom metadata record should have been returned');
    System.assertEquals(null, cmt.Geo__c, 'The custom metadata record should have a blank Geo');
  }

  //U009
  @isTest
  public static void itShouldReturnTheDefaultConversionRate() {
    System.assertEquals(
      1.0,
      QuoteRenewalUpliftDataFunction_SL.getCurrencyConversionRate('USD'),
      'The USD currency conversion should be 1.0'
    );
  }

  //U010
  @isTest
  public static void itShouldReturnTheCorrectGeoAreaCmtRecordApjIndia() {
    setCmtMock();
    //GIVEN
    String geo = 'APJ';
    String area = 'India';
    Double uplift = 5.00;
    Double threshold = 15000.00;
    CPQ_Renewal_Uplift__mdt expectedCmt = new CPQ_Renewal_Uplift__mdt(
      Geo__c = geo,
      Area__c = area,
      UpliftRate__c = uplift,
      UpliftThreshold__c = threshold
    );

    //WHEN
    CPQ_Renewal_Uplift__mdt actualCmt = QuoteRenewalUpliftDataFunction_SL.getGeoAreaCmt(geo, area);

    //THEN
    System.assertEquals(expectedCmt.Geo__c, actualCmt.Geo__c, 'Expect vs actual Geo should match');
    System.assertEquals(expectedCmt.Area__c, actualCmt.Area__c, 'Expect vs actual Area should match');
    System.assertEquals(expectedCmt.UpliftRate__c, actualCmt.UpliftRate__c, 'Expect vs actual UpliftRate should match');
    System.assertEquals(
      expectedCmt.UpliftThreshold__c,
      actualCmt.UpliftThreshold__c,
      'Expect vs actual UpliftThreshold should match'
    );
  }

  //U011
  @isTest
  public static void itShouldReturnTheCorrectGeoAreaCmtRecordApjJapan() {
    setCmtMock();
    //GIVEN
    String geo = 'APJ';
    String area = 'Japan';
    Double uplift = 0.00;
    Double threshold = 15000.00;
    CPQ_Renewal_Uplift__mdt expectedCmt = new CPQ_Renewal_Uplift__mdt(
      Geo__c = geo,
      Area__c = area,
      UpliftRate__c = uplift,
      UpliftThreshold__c = threshold
    );

    //WHEN
    CPQ_Renewal_Uplift__mdt actualCmt = QuoteRenewalUpliftDataFunction_SL.getGeoAreaCmt(geo, area);

    //THEN
    System.assertEquals(expectedCmt.Geo__c, actualCmt.Geo__c, 'Expect vs actual Geo should match');
    System.assertEquals(expectedCmt.Area__c, actualCmt.Area__c, 'Expect vs actual Area should match');
    System.assertEquals(expectedCmt.UpliftRate__c, actualCmt.UpliftRate__c, 'Expect vs actual UpliftRate should match');
    System.assertEquals(
      expectedCmt.UpliftThreshold__c,
      actualCmt.UpliftThreshold__c,
      'Expect vs actual UpliftThreshold should match'
    );
  }

  //U012
  @isTest
  public static void itShouldReturnTheCorrectGeoAreaCmtRecordApjDefaultNoArea() {
    setCmtMock();
    //GIVEN
    String geo = 'APJ';
    String area = '';
    Double uplift = 4.00;
    Double threshold = 10000.00;
    CPQ_Renewal_Uplift__mdt expectedCmt = new CPQ_Renewal_Uplift__mdt(
      Geo__c = geo,
      Area__c = area,
      UpliftRate__c = uplift,
      UpliftThreshold__c = threshold
    );

    //WHEN
    CPQ_Renewal_Uplift__mdt actualCmt = QuoteRenewalUpliftDataFunction_SL.getGeoAreaCmt(geo, area);

    //THEN
    System.assertEquals(expectedCmt.Geo__c, actualCmt.Geo__c, 'Expect vs actual Geo should match');
    System.assertEquals(null, actualCmt.Area__c, 'Expect vs actual Area should match');
    System.assertEquals(expectedCmt.UpliftRate__c, actualCmt.UpliftRate__c, 'Expect vs actual UpliftRate should match');
    System.assertEquals(
      expectedCmt.UpliftThreshold__c,
      actualCmt.UpliftThreshold__c,
      'Expect vs actual UpliftThreshold should match'
    );
  }

  //U013
  @isTest
  public static void itShouldReturnTheCorrectGeoAreaCmtRecordApjAreaNotFound() {
    setCmtMock();
    //GIVEN
    String geo = 'APJ';
    String area = 'Vanuatu';
    Double uplift = 4.00;
    Double threshold = 10000.00;
    CPQ_Renewal_Uplift__mdt expectedCmt = new CPQ_Renewal_Uplift__mdt(
      Geo__c = geo,
      Area__c = area,
      UpliftRate__c = uplift,
      UpliftThreshold__c = threshold
    );
    Map<String, Map<String, CPQ_Renewal_Uplift__mdt>> recs = QuoteRenewalUpliftDataFunction_SL.UPLIFTS_BY_GEO_BY_AREA;
    for (String str : recs.keySet()) {
      System.debug(str);
      Map<String, CPQ_Renewal_Uplift__mdt> geoRecs = recs.get(str);
      for (String str2 : geoRecs.keySet()) {
        System.debug(str2 + ': ' + geoRecs.get(str2));
      }
      System.debug(' ');
    }

    //WHEN
    CPQ_Renewal_Uplift__mdt actualCmt = QuoteRenewalUpliftDataFunction_SL.getGeoAreaCmt(geo, area);

    //THEN
    System.assertEquals(expectedCmt.Geo__c, actualCmt.Geo__c, 'Expected vs actual Geo should match');
    System.assertEquals(null, actualCmt.Area__c, 'Expected vs actual Area should match');
    System.assertEquals(
      expectedCmt.UpliftRate__c,
      actualCmt.UpliftRate__c,
      'Expected vs actual UpliftRate should match'
    );
    System.assertEquals(
      expectedCmt.UpliftThreshold__c,
      actualCmt.UpliftThreshold__c,
      'Expect vs actual UpliftThreshold should match'
    );
  }

  //U014
  @isTest
  public static void itShouldReturnTheCorrectGeoAreaCmtRecordGlobalDefaultNoGeoNoArea() {
    setCmtMock();
    //GIVEN
    String geo = '';
    String area = '';
    Double uplift = 17.00;
    Double threshold = 15000.00;
    CPQ_Renewal_Uplift__mdt expectedCmt = new CPQ_Renewal_Uplift__mdt(
      Geo__c = geo,
      Area__c = area,
      UpliftRate__c = uplift,
      UpliftThreshold__c = threshold
    );

    //WHEN
    CPQ_Renewal_Uplift__mdt actualCmt = QuoteRenewalUpliftDataFunction_SL.getGeoAreaCmt(geo, area);

    //THEN
    System.assertEquals(null, actualCmt.Geo__c, 'Expect vs actual Geo should match');
    System.assertEquals(null, actualCmt.Area__c, 'Expect vs actual Area should match');
    System.assertEquals(expectedCmt.UpliftRate__c, actualCmt.UpliftRate__c, 'Expect vs actual UpliftRate should match');
    System.assertEquals(
      expectedCmt.UpliftThreshold__c,
      actualCmt.UpliftThreshold__c,
      'Expect vs actual UpliftThreshold should match'
    );
  }

  //U015
  @isTest
  public static void itShouldReturnTheCorrectGeoAreaCmtRecordGlobalDefaultGeoNotFound() {
    setCmtMock();
    //GIVEN
    String geo = 'UK';
    String area = '';
    Double uplift = 17.00;
    Double threshold = 15000.00;
    CPQ_Renewal_Uplift__mdt expectedCmt = new CPQ_Renewal_Uplift__mdt(
      Geo__c = geo,
      Area__c = area,
      UpliftRate__c = uplift,
      UpliftThreshold__c = threshold
    );

    //WHEN
    CPQ_Renewal_Uplift__mdt actualCmt = QuoteRenewalUpliftDataFunction_SL.getGeoAreaCmt(geo, area);

    //THEN
    System.assertEquals(null, actualCmt.Geo__c, 'Expect vs actual Geo should match');
    System.assertEquals(null, actualCmt.Area__c, 'Expect vs actual Area should match');
    System.assertEquals(expectedCmt.UpliftRate__c, actualCmt.UpliftRate__c, 'Expect vs actual UpliftRate should match');
    System.assertEquals(
      expectedCmt.UpliftThreshold__c,
      actualCmt.UpliftThreshold__c,
      'Expect vs actual UpliftThreshold should match'
    );
  }

  //U016
  @isTest
  public static void itShouldPopulateUpliftRecordsCorrectlyGlobalDefault() {
    //GIVEN
    List<CPQ_Renewal_Uplift__mdt> records = generateUpliftRecords();

    //WHEN
    Map<String, Map<String, CPQ_Renewal_Uplift__mdt>> recordMap = QuoteRenewalUpliftDataFunction_SL.populateUpliftRecords(
      records
    );

    //THEN
    System.assertEquals(true, recordMap.containsKey('Global'), 'The Global key should be present');
    Map<String, CPQ_Renewal_Uplift__mdt> geoAreas = recordMap.get('Global');
    System.assertEquals(1, geoAreas.keySet().size(), 'The Global key should have only one child record');
    System.assertEquals(true, geoAreas.containsKey('Default'), 'The Global key should return a default record');
    CPQ_Renewal_Uplift__mdt actual = geoAreas.get('Default');
    System.assertEquals(17, actual.UpliftRate__c, 'The Global Default record does not have the expected UpliftRate__c');
    System.assertEquals(
      15000,
      actual.UpliftThreshold__c,
      'The Global Default record does not have the expected UpliftThreshold__c'
    );
  }

  //U017
  @isTest
  public static void itShouldReturnUsdConversionRate() {
    //GIVEN
    String usdIsoCode = 'USD';

    //WHEN
    Double actual = QuoteRenewalUpliftDataFunction_SL.getCurrencyConversionRate(usdIsoCode);

    //THEN
    System.assertEquals(1.0, actual, 'The USD currency conversion should return 1.0');
  }

  /**
   * UTILS
   */

  /**
   * Util to set formula fields in memory
   *
   * @param quote the quote to manipulate
   * @param fieldName the field to set
   * @param value the value to set
   *
   * @return the manipulated record
   */
  private static SObject setFormulafield(SBQQ__Quote__c quote, String fieldName, String value) {
    String jsonString = JSON.serialize(quote);
    Map<String, Object> dataMap = (Map<String, Object>) JSON.deserializeUntyped(jsonString);
    dataMap.put(fieldName, value);
    jsonString = JSON.serialize(dataMap);
    return (SBQQ__Quote__c) JSON.deserialize(jsonString, SBQQ__Quote__c.class);
  }

  /**
   * Util to generate in memory CMT records
   *
   * @return the generated CMT records
   */
  private static List<CPQ_Renewal_Uplift__mdt> generateUpliftRecords() {
    List<CPQ_Renewal_Uplift__mdt> records = new List<CPQ_Renewal_Uplift__mdt>{
      new CPQ_Renewal_Uplift__mdt(Geo__c = 'APJ', Area__c = null, UpliftRate__c = 4, UpliftThreshold__c = 10000),
      new CPQ_Renewal_Uplift__mdt(Geo__c = 'APJ', Area__c = 'Japan', UpliftRate__c = 0, UpliftThreshold__c = 15000),
      new CPQ_Renewal_Uplift__mdt(Geo__c = 'APJ', Area__c = 'India', UpliftRate__c = 5.0, UpliftThreshold__c = 15000),
      new CPQ_Renewal_Uplift__mdt(Geo__c = 'EMEA', Area__c = null, UpliftRate__c = 5, UpliftThreshold__c = 15000),
      new CPQ_Renewal_Uplift__mdt(Geo__c = 'AMER', Area__c = null, UpliftRate__c = 9, UpliftThreshold__c = 1000),
      new CPQ_Renewal_Uplift__mdt(Geo__c = null, Area__c = null, UpliftRate__c = 17, UpliftThreshold__c = 15000)
    };
    return records;
  }

  /**
   * Util to set CMT record mocking
   */
  private static void setCmtMock() {
    fflib_ApexMocks mocks = new fflib_ApexMocks();
    CPQRenewalUpliftSelector_SL mockSelector = (CPQRenewalUpliftSelector_SL) mocks.mock(
      CPQRenewalUpliftSelector_SL.class
    );
    mocks.startStubbing();
    mocks.when(mockSelector.getSObjectType()).thenReturn(CPQ_Renewal_Uplift__mdt.SObjectType);
    mocks.when(mockSelector.sObjectType()).thenReturn(CPQ_Renewal_Uplift__mdt.SObjectType);
    mocks.when(mockSelector.getAll()).thenReturn(CMT_RECORDS);
    mocks.stopStubbing();
    Application_SL.Selector.setMock(mockSelector);
  }
}