public with sharing class QuoteBudgetQuoteFunction_SL implements SObjectToSObjectFunction {
  public static final String PREFIX_FORECAST_QUOTE = 'FORECAST-';
  private static final String TYPE_UPDATE_TARGET_AMOUNT = 'Update Target Amount';
  private static final String TYPE_UPDATE_DOC_REF = 'Update Document Ref';
  private String functionType;

  /**
   * @description - Constructor
   */
  public QuoteBudgetQuoteFunction_SL(String functionType) {
    this.functionType = functionType;
  }

  private SObject updateTargetCustomerAmount(SBQQ__Quote__c record) {
    record.SBQQ__TargetCustomerAmount__c = null;
    return record;
  }
  private SObject updateQuoteDocumentRef(SBQQ__Quote__c record) {
    if (record.Document_Ref__c != null && !record.Document_Ref__c.startsWith(PREFIX_FORECAST_QUOTE)) {
      record.Document_Ref__c = PREFIX_FORECAST_QUOTE + record.Document_Ref__c;
    }
    return record;
  }

  /**
   * @description - process record based on functionType value
   */
  public SObject apply(SObject record) {
    if (functionType == TYPE_UPDATE_TARGET_AMOUNT) {
      return updateTargetCustomerAmount((SBQQ__Quote__c) record);
    } else if (functionType == TYPE_UPDATE_DOC_REF) {
      return updateQuoteDocumentRef((SBQQ__Quote__c) record);
    }
    return record;
  }

  /**
   * @description - remove Target Customer Amount from budget/quick Quotes
   */
  public static void removeTargetCustomerAmount(List<SBQQ__Quote__c> records, Map<Id, SObject> existingQuotes) {
    List<SBQQ__Quote__c> eligibleRecords = Collection.of(records)
      .filter(
        Match.field(SBQQ__Quote__c.SBQQ__LastCalculatedOn__c)
          .hasValue()
          .also(SBQQ__Quote__c.SBQQ__TargetCustomerAmount__c)
          .hasValue()
          .also(SBQQ__Quote__c.Forecast_Quote__c)
          .equals(true)
      )
      .asList();

    if (!eligibleRecords.isEmpty()) {
      Collection.of(eligibleRecords).mapAll(new QuoteBudgetQuoteFunction_SL(TYPE_UPDATE_TARGET_AMOUNT));
    }
  }

  /**
   * @description - add forecast prefix to document ref for budget/quick Quotes
   */
  public static void prefixDocumentRef(List<SBQQ__Quote__c> records, Map<Id, SObject> existingQuotes) {
    SObjectPredicate hasChanged = new HasRecordChanged(
      new Set<SObjectField>{ SBQQ__Quote__c.Document_Ref__c, SBQQ__Quote__c.Forecast_Quote__c },
      records,
      existingQuotes
    );
    List<SBQQ__Quote__c> eligibleRecords = Collection.of(records)
      .filter(hasChanged)
      .filter(Match.field(SBQQ__Quote__c.Forecast_Quote__c).equals(true))
      .asList();

    if (!eligibleRecords.isEmpty()) {
      Collection.of(eligibleRecords).mapAll(new QuoteBudgetQuoteFunction_SL(TYPE_UPDATE_DOC_REF));
    }
  }
}