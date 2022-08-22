public inherited sharing class QuoteAdvanceApprovalFunction_SL implements SObjectToSObjectFunction {
  public SObject apply(SBQQ__Quote__c quote) {
    if (
      quote.SBQQ__Status__c == null ||
      quote.SBQQ__Status__c == QuoteMetadata_SL.DRAFT ||
      quote.SBQQ__Status__c == QuoteMetadata_SL.IN_REVIEW ||
      quote.SBQQ__Status__c == QuoteMetadata_SL.REJECTED ||
      quote.SBQQ__Status__c == QuoteMetadata_SL.RECALLED ||
      quote.SBQQ__Status__c == QuoteMetadata_SL.APPROVED
    ) {
      if (quote.ApprovalStatus__c == QuoteMetadata_SL.PENDING) {
        quote.SBQQ__Status__c = QuoteMetadata_SL.IN_REVIEW;
      } else if (quote.ApprovalStatus__c == QuoteMetadata_SL.APPROVED) {
        quote.SBQQ__Status__c = QuoteMetadata_SL.APPROVED;
      } else if (quote.ApprovalStatus__c == QuoteMetadata_SL.REJECTED) {
        quote.SBQQ__Status__c = QuoteMetadata_SL.REJECTED;
      } else if (quote.ApprovalStatus__c == QuoteMetadata_SL.RECALLED) {
        quote.SBQQ__Status__c = QuoteMetadata_SL.DRAFT;
      }
    }

    if (quote.ApprovalStatus__c == QuoteMetadata_SL.APPROVED || quote.SBQQ__Status__c == QuoteMetadata_SL.APPROVED) {
      quote.RecordTypeId = QuoteMetadata_SL.CPQApprovedRecordType;
      quote.Approved_Discount__c = quote.Quote_Total_Discount__c;
    }
    return quote;
  }

  public SObject apply(SObject record) {
    return apply((SBQQ__Quote__c) record);
  }

  /**
   * Set Quote Status
   */
  public static void deriveStatus(List<SObject> records, Map<Id, SObject> existingRecords) {
    SObjectPredicate hasApprovalStatusQuoteChanged = new HasRecordChanged(
      new Set<SObjectField>{
        SBQQ__Quote__c.ApprovalStatus__c,
        SBQQ__Quote__c.SBQQ__Status__c,
        SBQQ__Quote__c.SBQQ__LastCalculatedOn__c
      },
      records,
      existingRecords
    );
    List<Opportunity> eligibleRecords = Collection.of(records).filter(hasApprovalStatusQuoteChanged).asList();
    if (!eligibleRecords.isEmpty()) {
      Collection.of(eligibleRecords).mapAll(new QuoteAdvanceApprovalFunction_SL());
    }
  }
}