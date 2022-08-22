public inherited sharing class QuoteAssignCPQDefaultRTFunction_SL implements SObjectToSObjectFunction {
  public SObject apply(SBQQ__Quote__c quote) {
    quote.RecordTypeId = QuoteMetadata_SL.CPQDefaultRecordType;
    return quote;
  }

  public SObject apply(SObject record) {
    return apply((SBQQ__Quote__c) record);
  }

  /**
   * Set Quote RT
   */
  public static void deriveRT(List<SObject> records, Map<Id, SObject> existingRecords) {
    SObjectPredicate hasStatusChanged = new HasRecordChanged(
      new Set<SObjectField>{ SBQQ__Quote__c.SBQQ__Status__c },
      records,
      existingRecords
    );
    List<Opportunity> eligibleRecords = Collection.of(records)
      .filter(hasStatusChanged)
      .filter(Match.field(SBQQ__Quote__c.SBQQ__Status__c).equals('Draft'))
      .asList();
    if (!eligibleRecords.isEmpty()) {
      Collection.of(eligibleRecords).mapAll(new QuoteAssignCPQDefaultRTFunction_SL());
    }
  }

  /**
   * Set Quote RT
   */
  public static void deriveRT(List<SObject> records) {
    Collection.of(records)
      .filter(Match.field(SBQQ__Quote__c.SBQQ__Status__c).equals('Draft'))
      .mapAll(new QuoteAssignCPQDefaultRTFunction_SL());
  }
}