public with sharing class OppRPAPrimaryContactQueueable_SL extends AbstractQueueable {
  private final List<SObject> opps;

  public OppRPAPrimaryContactQueueable_SL(List<SObject> opps) {
    super('OppRPAPrimaryContactQueueable_SL');
    this.opps = opps;
    //to allow for logging against record. only used in non-bulk contexts
    if (opps != null && opps.size() == 1) {
      this.setPrimaryRecordId(opps.get(0).Id);
    }
  }

  public override void work() {
    this.updateRoleOnContact(this.opps);
  }

  private void updateRoleOnContact(List<SObject> opps) {
    Set<Id> contactIds = new Set<Id>(Collection.of(opps).pluckIds(Opportunity.RPA_Primary_Contact__c));
    List<Contact> contactToUpdate = new List<Contact>();

    for (Contact contact : [SELECT Id, Role__c, Account.RecordType.Name FROM Contact WHERE Id IN :contactIds]) {
      if (contact.Account.RecordType.Name == 'Customer' || contact.Account.RecordType.Name == 'Customer Prospect') {
        contact.Role__c = 'RPA Primary Contact';
        contactToUpdate.add(contact);
      }
    }

    update contactToUpdate;
  }

  /**
   * Update Contact Role__c on Update
   */
  public static void setRoleOnContact(List<Opportunity> records, Map<Id, SObject> existingRecords) {
    SObjectPredicate hasChanged = new HasRecordChanged(
      new Set<SObjectField>{ Opportunity.RPA_Primary_Contact__c, Opportunity.StageName },
      records,
      existingRecords
    );
    List<Opportunity> eligibleRecords = Collection.of(records)
      .filter(hasChanged)
      .filter(
        Match.field(Opportunity.RPA_Primary_Contact__c)
          .notEquals(null)
          .also(Opportunity.StageName)
          .equals(OpportunityMetadata_SL.CLOSED_WON_PENDING)
      )
      .asList();

    if (!eligibleRecords.isEmpty()) {
      AbstractQueueable.enqueue(new OppRPAPrimaryContactQueueable_SL(eligibleRecords));
    }
  }
}