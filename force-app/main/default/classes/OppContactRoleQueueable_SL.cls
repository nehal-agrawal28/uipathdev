public with sharing class OppContactRoleQueueable_SL extends AbstractQueueable {
  private final List<SObject> records;
  public OppContactRoleQueueable_SL(List<SObject> records) {
    super('OppContactRoleQueueable_SL');
    this.records = records;
    if (records != null && records.size() == 1) {
      this.setPrimaryRecordId(records.get(0).Id);
    }
  }

  public override void work() {
    this.updateOpportunities(this.records);
  }

  private void updateOpportunities(List<OpportunityContactRole> eligibleRecords) {
    List<Id> oppIds = Collection.of(eligibleRecords).pluckIds(OpportunityContactRole.OpportunityId);
    Map<Id, Opportunity> opportunitiesById = new Map<Id, Opportunity>(
      [SELECT Id, Customer_Primary_Contact__c FROM Opportunity WHERE Id IN :oppIds]
    );

    List<Opportunity> recordsToUpdate = new List<Opportunity>();
    for (OpportunityContactRole record : eligibleRecords) {
      Opportunity opp = new Opportunity();
      opp.Id = record.OpportunityId;
      opp.Customer_Primary_Contact__c = (record.IsPrimary && !Trigger.IsDelete) ? record.ContactId : null;
      if (opp.Customer_Primary_Contact__c != opportunitiesById.get(opp.Id).Customer_Primary_Contact__c) {
        recordsToUpdate.add(opp);
      }
    }
    fflib_SObjectDomain.getTriggerEvent(Opportunities_SL.class).disableAll();
    update recordsToUpdate;
    fflib_SObjectDomain.getTriggerEvent(Opportunities_SL.class).enableAll();
  }

  public static void setPrimaryContactOnOpportunities(List<OpportunityContactRole> records) {
    List<OpportunityContactRole> eligibleRecords = Collection.of(records)
      .filter(
        Match.field(OpportunityContactRole.IsPrimary).hasValue().also(OpportunityContactRole.IsPrimary).equals(true)
      )
      .asList();

    if (!eligibleRecords.isEmpty()) {
      AbstractQueueable.enqueue(new OppContactRoleQueueable_SL(eligibleRecords));
    }
  }

  public static void setPrimaryContactOnOpportunities(
    List<OpportunityContactRole> records,
    Map<Id, SObject> existingRecords
  ) {
    SObjectPredicate hasChanged = new HasRecordChanged(
      new Set<SObjectField>{ OpportunityContactRole.IsPrimary, OpportunityContactRole.Role },
      records,
      existingRecords
    );

    List<OpportunityContactRole> eligibleRecords = Collection.of(records).filter(hasChanged).asList();

    if (!eligibleRecords.isEmpty()) {
      AbstractQueueable.enqueue(new OppContactRoleQueueable_SL(eligibleRecords));
    }
  }

  public static void deriveRole(List<OpportunityContactRole> records) {
    for (OpportunityContactRole record : records) {
      if (record.IsPrimary) {
        record.Role = OpportunityMetadata_SL.PRIMARY_CONTACT;
      }
    }
  }
}