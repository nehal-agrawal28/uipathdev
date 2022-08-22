public without sharing class OpportunityProductQueueable_SL extends AbstractQueueable {
  private final List<SObject> records;

  public OpportunityProductQueueable_SL(List<Opportunity> records) {
    super('OpportunityProductQueueable_SL');
    this.records = records;
    //to allow for logging against record. only used in non-bulk contexts
    if (records != null && records.size() == 1) {
      this.setPrimaryRecordId(records.get(0).Id);
    }
  }

  public override void work() {
    this.updateLineItems(this.records);
  }

  private void updateLineItems(List<Opportunity> records) {
    Map<Id, Opportunity> opportunityMap = new Map<Id, Opportunity>(records);
    List<OpportunityLineItem> recordsToUpdate = new List<OpportunityLineItem>();

    for (OpportunityLineItem eachLineItem : [
      SELECT OpportunityId, Business_Type__c
      FROM OpportunityLineItem
      WHERE OpportunityId IN :opportunityMap.keySet() AND Business_Type__c != 'Renewal'
    ]) {
      if (
        opportunityMap.containsKey(eachLineItem.OpportunityId) &&
        eachLineItem.Business_Type__c != opportunityMap.get(eachLineItem.OpportunityId).Type
      ) {
        eachLineItem.Business_Type__c = opportunityMap.get(eachLineItem.OpportunityId).Type;
        recordsToUpdate.add(eachLineItem);
      }
    }
    fflib_SObjectDomain.getTriggerEvent(Opportunities_SL.class).disableAll();
    update recordsToUpdate;
    fflib_SObjectDomain.getTriggerEvent(Opportunities_SL.class).enableAll();
  }

  public static void updateBusinessType(List<Opportunity> records, Map<Id, SObject> existingRecords) {
    SObjectPredicate hasChanged = new HasRecordChanged(
      new Set<SObjectField>{ Opportunity.Type },
      records,
      existingRecords
    );

    List<Opportunity> eligibleRecords = Collection.of(records)
      .filter(hasChanged)
      .filter(Match.field(Opportunity.Type).isIn(new Set<String>{ 'New Business', 'Upsell' }))
      .asList();

    if (!eligibleRecords.isEmpty()) {
      AbstractQueueable.enqueue(new OpportunityProductQueueable_SL(eligibleRecords));
    }
  }
}