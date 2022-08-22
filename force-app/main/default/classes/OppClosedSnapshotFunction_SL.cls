public without sharing class OppClosedSnapshotFunction_SL implements SObjectToSObjectFunction {
  private Map<Id, User> users;
  public OppClosedSnapshotFunction_SL(List<Opportunity> records) {
    List<Id> ownerIds = Collection.of(records).pluckIds(Opportunity.OwnerId);
    users = new Map<Id, User>([SELECT Id, UserRole.Name FROM User WHERE Id IN :ownerIds]);
  }

  private SObject apply(Opportunity record) {
    record.Owner_Role_Snapshot__c = this.users.get(record.OwnerId).UserRole.Name;
    return record;
  }

  public SObject apply(SObject record) {
    return apply((Opportunity) record);
  }

  public static void deriveOwnerRole(List<Opportunity> records, Map<Id, SObject> existingRecords) {
    SObjectPredicate hasChanged = new HasRecordChanged(
      new Set<SObjectField>{ Opportunity.StageName, Opportunity.OwnerId },
      records,
      existingRecords
    );

    List<Opportunity> eligibleRecords = Collection.of(records)
      .filter(hasChanged)
      .filter(
        Match.field(Opportunity.StageName)
          .isIn(new Set<String>{ OpportunityMetadata_SL.CLOSED_WON_BOOKED, OpportunityMetadata_SL.CLOSED_LOST })
          .also(Opportunity.OwnerId)
          .hasValue()
      )
      .asList();
    if (!eligibleRecords.isEmpty()) {
      Collection.of(eligibleRecords).mapAll(new OppClosedSnapshotFunction_SL(eligibleRecords));
    }
  }
}