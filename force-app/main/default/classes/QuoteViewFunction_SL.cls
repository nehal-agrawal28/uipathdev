public with sharing class QuoteViewFunction_SL implements SObjectToSObjectFunction {
  private static final Set<Object> ENABLED_QUOTE_TYPES = new Set<Object>{ 'Renewal' }; //SBQQ__Quote__c.SBQQ__Type__c
  //private static final Set<Object> ENABLED_QUOTE_DEAL_TYPES = new Set<Object>{ 'Direct' }; //SBQQ__Quote__c.Deal_Type__c
  //private static final Set<Object> ENABLED_ACCOUNT_GEOS = new Set<Object>{ 'India' }; //SBQQ__Quote__c.Account_Geo__c
  public static final Map<String, String> QUOTE_TYPE_TO_VIEW = new Map<String, String>{ 'Renewal' => 'Renewal' }; //SBQQ__Quote__c.SBQQ__Type__c => SBQQ__Quote__c.Line_Editor_View__c
  public static final Set<String> ACTIVE_QUOTE_VIEWS {
    get {
      if (ACTIVE_QUOTE_VIEWS == null) {
        ACTIVE_QUOTE_VIEWS = getQuoteViewPickListValuesIntoSet();
      }
      return ACTIVE_QUOTE_VIEWS;
    }
    set {
      ACTIVE_QUOTE_VIEWS = value;
    }
  }

  public SObject apply(SBQQ__Quote__c quote) {
    if (
      QUOTE_TYPE_TO_VIEW.containsKey(quote.SBQQ__Type__c) &&
      ACTIVE_QUOTE_VIEWS.contains(QUOTE_TYPE_TO_VIEW.get(quote.SBQQ__Type__c))
    ) {
      quote.Line_Editor_View__c = QUOTE_TYPE_TO_VIEW.get(quote.SBQQ__Type__c);
    }
    return quote;
  }

  public SObject apply(SObject record) {
    return apply((SBQQ__Quote__c) record);
  }

  public static void setQuoteView(List<SObject> records) {
    SObjectPredicate enabledQuoteType = new FieldValueIsInSet(
      SBQQ__Quote__c.SBQQ__Type__c,
      records,
      ENABLED_QUOTE_TYPES
    );
    /*
    SObjectPredicate enabledQuoteDealType = new FieldValueIsInSet(
      SBQQ__Quote__c.Deal_Type__c,
      quotes,
      ENABLED_QUOTE_DEAL_TYPES
    );
    SObjectPredicate enabledQuoteAccountGeo = new FieldValueIsInSet(
      SBQQ__Quote__c.Account_Geo__c,
      quotes,
      ENABLED_ACCOUNT_GEOS
    );
    */

    Collection.of(records).filter(enabledQuoteType).mapAll(new QuoteViewFunction_SL());
  }

  public static void setQuoteView(List<SObject> records, Map<Id, SObject> existingRecords) {
    SObjectPredicate hasChanged = new HasRecordChanged(
      new Set<SObjectField>{ SBQQ__Quote__c.SBQQ__Type__c },
      records,
      existingRecords
    );
    SObjectPredicate enabledQuoteType = new FieldValueIsInSet(
      SBQQ__Quote__c.SBQQ__Type__c,
      records,
      ENABLED_QUOTE_TYPES
    );

    Collection.of(records).filter(hasChanged).filter(enabledQuoteType).mapAll(new QuoteViewFunction_SL());
  }

  private static Set<String> getQuoteViewPickListValuesIntoSet() {
    Set<String> pickListValues = new Set<String>();
    Schema.DescribeFieldResult fieldResult = SBQQ__Quote__c.Line_Editor_View__c.getDescribe();
    List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
    for (Schema.PicklistEntry pickListVal : ple) {
      pickListValues.add(pickListVal.getValue());
    }
    return pickListValues;
  }
}