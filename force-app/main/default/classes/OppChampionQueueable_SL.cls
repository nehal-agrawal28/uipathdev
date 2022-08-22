public with sharing class OppChampionQueueable_SL extends AbstractQueueable {
  private final List<Opportunity> opps;
  public OppChampionQueueable_SL(List<Opportunity> records) {
    super('OppChampionQueueable_SL');
    this.opps = records;
  }

  public override void work() {
    this.saveContactRole(this.opps);
  }

  public void saveContactRole(List<Opportunity> opps) {
    List<OpportunityContactRole> rolesToDelete = [
      SELECT Id
      FROM OpportunityContactRole
      WHERE OpportunityId IN :opps AND Role = :OpportunityMetadata_SL.CHAMPION
    ];
    delete rolesToDelete;

    List<OpportunityContactRole> rolesToInsert = new List<OpportunityContactRole>();
    for (Opportunity opp : opps) {
      OpportunityContactRole role = new OpportunityContactRole();
      role.Role = OpportunityMetadata_SL.CHAMPION;
      role.OpportunityId = opp.Id;
      role.ContactId = opp.Champion_Actual__c;
      rolesToInsert.add(role);
    }
    insert rolesToInsert;
  }

  public static void createContactRole(List<Opportunity> Records) {
    List<Opportunity> eligibleRecords = Collection.of(records)
      .filter(Match.field(Opportunity.Champion_Actual__c).hasValue())
      .asList();
    if (!eligibleRecords.isEmpty()) {
      AbstractQueueable.enqueue(new OppChampionQueueable_SL(eligibleRecords));
    }
  }
  public static void createContactRole(List<Opportunity> Records, Map<Id, SObject> existingRecords) {
    SObjectPredicate hasChanged = new HasRecordChanged(
      new Set<SObjectField>{ Opportunity.Champion_Actual__c },
      Records,
      existingRecords
    );
    List<Opportunity> eligibleRecords = Collection.of(records)
      .filter(hasChanged)
      .filter(Match.field(Opportunity.Champion_Actual__c).hasValue())
      .asList();
    if (!eligibleRecords.isEmpty()) {
      AbstractQueueable.enqueue(new OppChampionQueueable_SL(eligibleRecords));
    }
  }
}