public without sharing class PIOpportunityQueueable_SL extends AbstractQueueable {
  private List<Opportunity> records;
  public PIOpportunityQueueable_SL(List<Opportunity> records) {
    super('PIOpportunityQueueable_SL');
    this.records = records;
    //to allow for logging against record. only used in non-bulk contexts
    if (records.size() == 1) {
      this.setPrimaryRecordId(records.get(0).Id);
    }
  }

  public override void work() {
    this.updateOpportunities(this.records);
  }

  private void updateOpportunities(List<Opportunity> records) {
    List<Opportunity> existing = records.deepClone(true);
    Collection existingRecords = Collection.of(existing);
    Collection modifiedOpportunities = Collection.of(records).mapAll(new PIOppWPartnersFunction_SL(records));

    List<Opportunity> recordsToUpdate = modifiedOpportunities
      .difference(
        existingRecords,
        new Set<Schema.SObjectField>{
          Opportunity.Sold_to_Partner__c,
          Opportunity.Tier_2_Partner__c,
          Opportunity.Tier_3_Partner__c,
          Opportunity.Implementation_Partner__c,
          Opportunity.Primary_Influence_Partner__c,
          Opportunity.Influencers__c,
          Opportunity.Is_Partner_Sourced__c
        }
      )
      .asList();

    update recordsToUpdate;
  }

  public static AbstractQueueable modifyOpportunities(
    List<Partner_Involvement__c> records,
    Map<Id, SObject> existingRecords
  ) {
    SObjectPredicate hasChanged = new HasRecordChanged(
      new Set<SObjectField>{
        Partner_Involvement__c.Primary_Influence__c,
        Partner_Involvement__c.Partner_Sales_Role__c,
        Partner_Involvement__c.Partner_Delivery_Role__c,
        Partner_Involvement__c.Influence_Approval_Status__c,
        Partner_Involvement__c.Opportunity_Sourced__c,
        Partner_Involvement__c.Partner_Account_Name__c
      },
      records,
      existingRecords
    );

    List<Partner_Involvement__c> eligibleRecords = Collection.of(records).filter(hasChanged).asList();

    return modifyOpportunities(eligibleRecords);
  }

  public static AbstractQueueable modifyOpportunities(List<Partner_Involvement__c> records) {
    List<Partner_Involvement__c> eligibleRecords = Collection.of(records).asList();

    Set<Id> opportunityIds = new Set<Id>(
      Collection.of(eligibleRecords).pluckIds(Partner_Involvement__c.PartnerOpp_Name__c)
    );

    List<Opportunity> opportunities = getOpportunities(opportunityIds);

    if (!opportunities.isEmpty()) {
      return new PIOpportunityQueueable_SL(opportunities);
    }
    return new NoOpSkipToNext();
  }

  @TestVisible
  private static List<Opportunity> getOpportunities(Set<Id> opportunityIds) {
    return [
      SELECT
        Id,
        Sold_to_Partner__c,
        Tier_2_Partner__c,
        Tier_3_Partner__c,
        Implementation_Partner__c,
        Primary_Influence_Partner__c,
        Influencers__c,
        Influence__c,
        Is_Partner_Sourced__c,
        (
          SELECT
            Id,
            PartnerOpp_Name__c,
            Primary_Influence__c,
            Partner_Sales_Role__c,
            Partner_Delivery_Role__c,
            Partner_Account_Name__c,
            Influence_Approval_Status__c,
            Opportunity_Sourced__c
          FROM Opportunity_Partners__r
        )
      FROM Opportunity
      WHERE Id IN :opportunityIds
    ];
  }
}