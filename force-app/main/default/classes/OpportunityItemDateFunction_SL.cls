public with sharing class OpportunityItemDateFunction_SL implements SObjectToSObjectFunction {
  List<OpportunityLineItem> records { get; set; }
  Map<Id, OpportunityLineItem> existingRecords { get; set; }
  public OpportunityItemDateFunction_SL(List<OpportunityLineItem> records, Map<Id, SObject> existingRecords) {
    this.records = records;
    this.existingRecords = (Map<Id, OpportunityLineItem>) existingRecords;
  }

  private SObject apply(OpportunityLineItem record) {
    if (
      record.Effective_Start_Date__c != null &&
      (record.ServiceDate == null ||
      record.ServiceDate == existingRecords.get(record.Id).ServiceDate)
    ) {
      record.ServiceDate = record.Effective_Start_Date__c;
    }
    return record;
  }

  public SObject apply(SObject record) {
    return apply((OpportunityLineItem) record);
  }

  public static void setServiceDate(List<OpportunityLineItem> records, Map<Id, SObject> existingRecords) {
    Collection.of(records).mapAll(new OpportunityItemDateFunction_SL(records, existingRecords));
  }
}