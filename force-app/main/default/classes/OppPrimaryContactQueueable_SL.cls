public with sharing class OppPrimaryContactQueueable_SL extends AbstractQueueable {
  private final List<Opportunity> opps;
  public OppPrimaryContactQueueable_SL(List<Opportunity> records) {
    super('OppPrimaryContactQueueable_SL');
    this.opps = records;
  }

  public override void work() {
    this.saveContactRole(this.opps);
  }

  public void saveContactRole(List<Opportunity> opps) {
    List<OpportunityContactRole> rolesToDelete = [
      SELECT Id, ContactId, OpportunityId, IsPrimary
      FROM OpportunityContactRole
      WHERE OpportunityId IN :opps AND Role = :OpportunityMetadata_SL.PRIMARY_CONTACT
    ];
    delete rolesToDelete;

    List<OpportunityContactRole> rolesToInsert = new List<OpportunityContactRole>();
    for (Opportunity opp : opps) {
      OpportunityContactRole role = new OpportunityContactRole();
      role.Role = OpportunityMetadata_SL.PRIMARY_CONTACT;
      role.OpportunityId = opp.Id;
      role.ContactId = opp.Customer_Primary_Contact__c;
      role.IsPrimary = true;
      rolesToInsert.add(role);
    }
    insert rolesToInsert;
  }

  public static void createContactRole(List<Opportunity> Records) {
    List<Opportunity> eligibleRecords = Collection.of(records)
      .filter(
        Match.field(Opportunity.Customer_Primary_Contact__c)
          .hasValue()
          .also(Opportunity.Converted_from_Lead__c)
          .equals(false)
          .also(Opportunity.SBQQ__AmendedContract__c)
          .equals(null)
          .also(Opportunity.SBQQ__RenewedContract__c)
          .equals(null)
      )
      .asList();
    if (!eligibleRecords.isEmpty()) {
      AbstractQueueable.enqueue(new OppPrimaryContactQueueable_SL(eligibleRecords));
    }
  }

  public static void createContactRole(List<Opportunity> Records, Map<Id, SObject> existingRecords) {
    SObjectPredicate hasChanged = new HasRecordChanged(
      new Set<SObjectField>{ Opportunity.Customer_Primary_Contact__c },
      Records,
      existingRecords
    );
    List<Opportunity> eligibleRecords = Collection.of(records)
      .filter(hasChanged)
      .filter(Match.field(Opportunity.Customer_Primary_Contact__c).hasValue())
      .asList();
    if (!eligibleRecords.isEmpty()) {
      AbstractQueueable.enqueue(new OppPrimaryContactQueueable_SL(eligibleRecords));
    }
  }
}