public inherited sharing class QuoteApprovalStatusCloneFunction_SL implements SObjectToSObjectFunction {
  public SObject apply(SBQQ__Quote__c quote) {
    quote.ApprovalStatus__c = null;
    return quote;
  }

  public SObject apply(SObject record) {
    return apply((SBQQ__Quote__c) record);
  }

  /**
   * Set Quote Approval Status
   */
  public static void deriveApprovalStatus(List<SBQQ__Quote__c> records) {
    Collection.of(records).mapAll(new QuoteApprovalStatusCloneFunction_SL());
  }
}