public with sharing class QuoteDiscountReasonsQueueable_SL extends AbstractQueueable {
  private final List<SObject> records;
  public QuoteDiscountReasonsQueueable_SL(List<SObject> records) {
    super('QuoteDiscountReasonsQueueable_SL');
    this.records = records;
    //to allow for logging against record. only used in non-bulk contexts
    if (records != null && records.size() == 1) {
      this.setPrimaryRecordId(records.get(0).Id);
    }
  }
  public override void work() {
    this.updateApprovals(records);
  }

  private void updateApprovals(List<SBQQ__Quote__c> records) {
    List<sbaa__Approval__c> approvals = new List<sbaa__Approval__c>(
      [
        SELECT Id, Discount_Reasons__c, Quote__r.Discount_Reasons__c
        FROM sbaa__Approval__c
        WHERE Quote__r.Id IN :records
      ]
    );

    for (sbaa__Approval__c approval : approvals) {
      approval.Discount_Reasons__c = approval.Quote__r.Discount_Reasons__c;
    }
    update approvals;
  }

  public static void updateDiscountReasons(List<SBQQ__Quote__c> records, Map<Id, SObject> existingRecords) {
    SObjectPredicate hasChanged = new HasRecordChanged(
      new Set<SObjectField>{ SBQQ__Quote__c.Discount_Reasons__c },
      records,
      existingRecords
    );

    List<SBQQ__Quote__c> eligibleRecords = Collection.of(records).filter(hasChanged).asList();

    if (!eligibleRecords.isEmpty()) {
      AbstractQueueable.enqueue(new QuoteDiscountReasonsQueueable_SL(eligibleRecords));
    }
  }
}