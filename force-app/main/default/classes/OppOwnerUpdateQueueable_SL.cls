public with sharing class OppOwnerUpdateQueueable_SL extends AbstractQueueable {
  private final List<SObject> opps;

  public OppOwnerUpdateQueueable_SL(List<SObject> records) {
    super('OppOwnerUpdateQueueable_SL');
    this.opps = records;
    //to allow for logging against record. only used in non-bulk contexts
    if (opps.size() == 1) {
      this.setPrimaryRecordId(opps.get(0).Id);
    }
  }

  public override void work() {
    this.updateTypeOnOpties(this.opps);
  }

  private void updateTypeOnOpties(List<SObject> records) {
    List<Opportunity> recordToUpdate = new List<Opportunity>();

    for (Opportunity opp : [SELECT Id, OwnerId, Account.OwnerId FROM Opportunity WHERE Id IN :records]) {
      if (opp.OwnerId != opp.Account.OwnerId) {
        opp.OwnerId = opp.Account.OwnerId;
        recordToUpdate.add(opp);
      }
    }
    fflib_SObjectDomain.getTriggerEvent(Opportunities_SL.class).disableAll();
    update recordToUpdate;
    fflib_SObjectDomain.getTriggerEvent(Opportunities_SL.class).enableAll();
  }

  /**
   * Set Opportunity Owner on creation
   */
  public static AbstractQueueable setOwner(List<Opportunity> records) {
    List<Opportunity> eligibleRecords = Collection.of(records)
      .filter(
        Match.field(Opportunity.Converted_from_Lead__c)
          .hasValue()
          .also(Opportunity.Converted_from_Lead__c)
          .equals(true)
          .also(Opportunity.RecordTypeId)
          .notEquals(OpportunityMetadata_SL.BDRRecordType)
      )
      .asList();

    if (!eligibleRecords.isEmpty()) {
      return new OppOwnerUpdateQueueable_SL(eligibleRecords);
    }
    return new NoOpSkipToNext();
  }
}