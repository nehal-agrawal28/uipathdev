public with sharing class OppDealRegistrationOwnerQueueable_SL extends AbstractQueueable {
  private final List<SObject> opps;

  public OppDealRegistrationOwnerQueueable_SL(List<SObject> opps) {
    super('OppDealRegistrationOwnerQueueable_SL');
    this.opps = opps;
    //to allow for logging against record. only used in non-bulk contexts
    if (opps != null && opps.size() == 1) {
      this.setPrimaryRecordId(opps.get(0).Id);
    }
  }

  public override void work() {
    this.updateTypeOnOpties(this.opps);
  }

  private void updateTypeOnOpties(List<SObject> opps) {
    List<Opportunity> recordsToUpdate = new List<Opportunity>();

    for (Opportunity opp : [
      SELECT Id, OwnerId, Account.OwnerId, BPO_MS_End_Customer__r.OwnerId, Opportunity.Do_We_Know_End_Customer__c
      FROM Opportunity
      WHERE Id IN :opps
    ]) {
      if (opp.Do_We_Know_End_Customer__c == 'Yes' || opp.OwnerId != opp.Account.OwnerId) {
        opp.OwnerId = (opp.Do_We_Know_End_Customer__c == 'Yes')
          ? opp.BPO_MS_End_Customer__r.OwnerId
          : opp.Account.OwnerId;
        recordsToUpdate.add(opp);
      }
    }
    fflib_SObjectDomain.getTriggerEvent(Opportunities_SL.class).disableAll();
    update recordsToUpdate;
    fflib_SObjectDomain.getTriggerEvent(Opportunities_SL.class).enableAll();
  }

  /**
   * Set Opportunity Owner on creation
   */
  public static void setOwner(List<Opportunity> records) {
    List<Opportunity> eligibleRecords = Collection.of(records)
      .filter(
        Match.field(Opportunity.RecordTypeId)
          .isIn(new Set<String>{ OpportunityMetadata_SL.DealRegistrationRecordType })
          .also(Opportunity.Deal_Reg_Status__c)
          .equals('Submitted')
      )
      .asList();

    if (!eligibleRecords.isEmpty()) {
      AbstractQueueable.enqueue(new OppDealRegistrationOwnerQueueable_SL(eligibleRecords));
    }
  }

  /**
   * Set Opportunity Owner on update
   */
  public static void setOwner(List<Opportunity> records, Map<Id, SObject> existingRecords) {
    SObjectPredicate hasChanged = new HasRecordChanged(
      new Set<SObjectField>{
        Opportunity.RecordTypeId,
        Opportunity.Deal_Reg_Status__c,
        Opportunity.Do_We_Know_End_Customer__c
      },
      records,
      existingRecords
    );
    List<Opportunity> eligibleRecords = Collection.of(records)
      .filter(hasChanged)
      .filter(
        Match.field(Opportunity.RecordTypeId)
          .isIn(new Set<String>{ OpportunityMetadata_SL.DealRegistrationRecordType })
          .also(Opportunity.Deal_Reg_Status__c)
          .equals('Submitted')
      )
      .asList();

    if (!eligibleRecords.isEmpty()) {
      AbstractQueueable.enqueue(new OppDealRegistrationOwnerQueueable_SL(eligibleRecords));
    }
  }
}