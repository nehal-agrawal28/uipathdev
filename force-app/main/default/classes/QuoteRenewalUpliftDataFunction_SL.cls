public with sharing class QuoteRenewalUpliftDataFunction_SL implements SObjectToSObjectFunction {
  private static final Set<Object> ENABLED_QUOTE_TYPES = new Set<Object>{ Constants_SL.QUOTE_TYPE_RENEWAL }; //SBQQ__Quote__c.SBQQ__Type__c
  private static final List<CPQ_Renewal_Uplift__mdt> GEO_UPLIFTS {
    get {
      if (GEO_UPLIFTS == null) {
        GEO_UPLIFTS = selector.getAll();
      }
      return GEO_UPLIFTS;
    }
    set {
    }
  }

  @TestVisible
  private static final Map<String, Map<String, CPQ_Renewal_Uplift__mdt>> UPLIFTS_BY_GEO_BY_AREA {
    get {
      if (UPLIFTS_BY_GEO_BY_AREA == null) {
        UPLIFTS_BY_GEO_BY_AREA = populateUpliftRecords(GEO_UPLIFTS);
      }
      return UPLIFTS_BY_GEO_BY_AREA;
    }
    set {
    }
  }

  private static final List<CurrencyType> CURRENCY_CONVERSION_RATES {
    get {
      if (CURRENCY_CONVERSION_RATES == null) {
        CURRENCY_CONVERSION_RATES = [
          SELECT Id, IsoCode, ConversionRate, DecimalPlaces, IsActive, IsCorporate
          FROM CurrencyType
          WHERE IsActive = TRUE
        ];
      }
      return CURRENCY_CONVERSION_RATES;
    }
    set {
    }
  }

  @TestVisible
  private static final Map<String, CurrencyType> CURRENCYTYPE_BY_CODE {
    get {
      if (CURRENCYTYPE_BY_CODE == null) {
        CURRENCYTYPE_BY_CODE = new Map<String, CurrencyType>();
        for (CurrencyType ct : CURRENCY_CONVERSION_RATES) {
          CURRENCYTYPE_BY_CODE.put(ct.IsoCode, ct);
        }
      }
      return CURRENCYTYPE_BY_CODE;
    }
    set {
    }
  }

  @TestVisible
  private static final CPQRenewalUpliftSelector_SL selector {
    get {
      if (selector == null) {
        selector = (CPQRenewalUpliftSelector_SL) Application_SL.Selector.newInstance(
          CPQ_Renewal_Uplift__mdt.SObjectType
        );
      }
      return selector;
    }
    set {
    }
  }

  public SObject apply(SObject record) {
    return apply((SBQQ__Quote__c) record);
  }

  public SObject apply(SBQQ__Quote__c quote) {
    CPQ_Renewal_Uplift__mdt cmt = getGeoAreaCmt(quote.Account_Geo__c, quote.Account_Area__c);

    if (cmt != null) {
      quote.Geo_Area_Uplift_Rate__c = cmt.UpliftRate__c;
      quote.Geo_Area_Uplift_Threshold_USD__c = cmt.UpliftThreshold__c;
      quote.Geo_Area_Uplift_Threshold_local__c =
        quote.Geo_Area_Uplift_Threshold_USD__c * getCurrencyConversionRate(quote.CurrencyIsoCode);
    }

    return quote;
  }

  public static void setRenewalUpliftData(List<SObject> quotes) {
    if (quotes != null && quotes.size() > 0) {
      SObjectPredicate enabledQuoteType = new FieldValueIsInSet(
        SBQQ__Quote__c.SBQQ__Type__c,
        quotes,
        ENABLED_QUOTE_TYPES
      );

      Collection.of(quotes).filter(enabledQuoteType).mapAll(new QuoteRenewalUpliftDataFunction_SL());
    }
  }

  public static void setRenewalUpliftData(List<SObject> quotes, Map<Id, SObject> existingQuotes) {
    if (quotes != null && quotes.size() > 0) {
      SObjectPredicate enabledQuoteType = new FieldValueIsInSet(
        SBQQ__Quote__c.SBQQ__Type__c,
        quotes,
        ENABLED_QUOTE_TYPES
      );
      SObjectPredicate hasChanged = new HasRecordChanged(
        new Set<SObjectField>{ SBQQ__Quote__c.SBQQ__Type__c },
        quotes,
        existingQuotes
      );

      Collection.of(quotes).filter(hasChanged).filter(enabledQuoteType).mapAll(new QuoteRenewalUpliftDataFunction_SL());
    }
  }

  @TestVisible
  private static CPQ_Renewal_Uplift__mdt getGeoAreaCmt(String geo, String area) {
    CPQ_Renewal_Uplift__mdt cmt;

    if (UPLIFTS_BY_GEO_BY_AREA.containsKey(geo) && UPLIFTS_BY_GEO_BY_AREA.get(geo).containsKey(area)) {
      //geo-area match
      System.debug('geo-area match');
      cmt = UPLIFTS_BY_GEO_BY_AREA.get(geo).get(area);
    } else if (UPLIFTS_BY_GEO_BY_AREA.containsKey(geo) && UPLIFTS_BY_GEO_BY_AREA.get(geo).containsKey('Default')) {
      //geo-default match
      System.debug('geo-default match');
      cmt = UPLIFTS_BY_GEO_BY_AREA.get(geo).get('Default');
    } else if (
      UPLIFTS_BY_GEO_BY_AREA.containsKey('Global') && UPLIFTS_BY_GEO_BY_AREA.get('Global').containsKey('Default')
    ) {
      //global default match
      System.debug('global default match');
      cmt = UPLIFTS_BY_GEO_BY_AREA.get('Global').get('Default');
    }

    return cmt;
  }

  @TestVisible
  private static Double getCurrencyConversionRate(String currencyCode) {
    Double currencyConversion = 1.0; //default to USD rate

    if (CURRENCYTYPE_BY_CODE.containsKey(currencyCode)) {
      currencyConversion = CURRENCYTYPE_BY_CODE.get(currencyCode).ConversionRate;
    }

    return currencyConversion;
  }

  @TestVisible
  private static Map<String, Map<String, CPQ_Renewal_Uplift__mdt>> populateUpliftRecords(
    List<CPQ_Renewal_Uplift__mdt> records
  ) {
    /* EXAMPLE
      | Geo       | Area     | Record                  | Note
      | 'APJ'     | 'Japan'  | CPQ_Renewal_Uplift__mdt | Geo + Area
      | 'APJ'     | 'India'  | CPQ_Renewal_Uplift__mdt | Geo + Area
      | 'APJ'     | 'Default'| CPQ_Renewal_Uplift__mdt | Geo default
      | 'EMEA'    | 'Default'| CPQ_Renewal_Uplift__mdt | Geo default
      | 'AMER'    | 'Default'| CPQ_Renewal_Uplift__mdt | Geo default
      | 'Global'  | 'Default'| CPQ_Renewal_Uplift__mdt | Global default
    */

    Map<String, Map<String, CPQ_Renewal_Uplift__mdt>> upliftByGeoByArea = new Map<String, Map<String, CPQ_Renewal_Uplift__mdt>>();

    for (CPQ_Renewal_Uplift__mdt cmt : records) {
      Map<String, CPQ_Renewal_Uplift__mdt> geoAreas = new Map<String, CPQ_Renewal_Uplift__mdt>();

      if (String.isEmpty(cmt.Geo__c)) {
        //'Global Default'
        geoAreas.put('Default', cmt);
        upliftByGeoByArea.put('Global', geoAreas);
        continue;
      }

      if (upliftByGeoByArea.containsKey(cmt.Geo__c)) {
        //get existing CMT for Geo
        geoAreas = upliftByGeoByArea.get(cmt.Geo__c);
      } else {
        //add geoAreas for Geo
        upliftByGeoByArea.put(cmt.Geo__c, geoAreas);
      }

      if (String.isEmpty(cmt.Area__c)) {
        //blank area = Geo default
        geoAreas.put('Default', cmt);
        continue;
      }

      if (!geoAreas.containsKey(cmt.Area__c)) {
        geoAreas.put(cmt.Area__c, cmt); //Geo + area
      } else {
        //duplicate Geo + area CMT
      }
    }
    return upliftByGeoByArea;
  }
}