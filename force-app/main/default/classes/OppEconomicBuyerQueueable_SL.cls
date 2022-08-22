public with sharing class OppEconomicBuyerQueueable_SL extends AbstractQueueable {
  private final List<Opportunity> opps;
  public OppEconomicBuyerQueueable_SL(List<Opportunity> records) {
    super('OppEconomicBuyerQueueable_SL');
    this.opps = records;
  }

  public override void work() {
    this.saveContactRole(this.opps);
  }

  public void saveContactRole(List<Opportunity> opps) {
    List<OpportunityContactRole> rolesToDelete = [
      SELECT Id
      FROM OpportunityContactRole
      WHERE OpportunityId IN :opps AND Role = :OpportunityMetadata_SL.ECONOMIC_BUYER
    ];
    delete rolesToDelete;

    List<OpportunityContactRole> rolesToInsert = new List<OpportunityContactRole>();
    for (Opportunity opp : opps) {
      OpportunityContactRole role = new OpportunityContactRole();
      role.Role = OpportunityMetadata_SL.ECONOMIC_BUYER;
      role.OpportunityId = opp.Id;
      role.ContactId = opp.Economic_Buyer__c;
      rolesToInsert.add(role);
    }
    insert rolesToInsert;
  }

  public static void createContactRole(List<Opportunity> Records) {
    List<Opportunity> eligibleRecords = Collection.of(records)
      .filter(Match.field(Opportunity.Economic_Buyer__c).hasValue())
      .asList();
    if (!eligibleRecords.isEmpty()) {
      AbstractQueueable.enqueue(new OppEconomicBuyerQueueable_SL(eligibleRecords));
    }
  }

  public static void createContactRole(List<Opportunity> Records, Map<Id, SObject> existingRecords) {
    SObjectPredicate hasChanged = new HasRecordChanged(
      new Set<SObjectField>{ Opportunity.Economic_Buyer__c },
      Records,
      existingRecords
    );
    List<Opportunity> eligibleRecords = Collection.of(records)
      .filter(hasChanged)
      .filter(Match.field(Opportunity.Economic_Buyer__c).hasValue())
      .asList();
    if (!eligibleRecords.isEmpty()) {
      AbstractQueueable.enqueue(new OppEconomicBuyerQueueable_SL(eligibleRecords));
    }
  }
}