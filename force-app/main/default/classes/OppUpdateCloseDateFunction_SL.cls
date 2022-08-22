public inherited sharing class OppUpdateCloseDateFunction_SL implements SObjectToSObjectFunction {
  public SObject apply(Opportunity opp) {
    if (opp.StageName == OpportunityMetadata_SL.CLOSED_WON_PENDING) {
      opp.Close_Won_Pending_Date__c = Date.Today();
    }
    if (
      opp.StageName == OpportunityMetadata_SL.CLOSED_WON_PENDING ||
      opp.StageName == OpportunityMetadata_SL.CLOSED_WON_BOOKED ||
      opp.StageName == OpportunityMetadata_SL.CLOSED_LOST
    ) {
      opp.CloseDate = Date.Today();
    }
    return opp;
  }

  public SObject apply(SObject record) {
    return apply((Opportunity) record);
  }

  /**
   * Set opportunity Close_Won_Pending_Date__c or CloseDate
   */
  public static void deriveCloseDate(List<Opportunity> records, Map<Id, SObject> existingRecords) {
    SObjectPredicate hasOppStageChanged = new HasRecordChanged(
      new Set<SObjectField>{ Opportunity.StageName },
      records,
      existingRecords
    );
    List<Opportunity> eligibleRecords = Collection.of(records)
      .filter(hasOppStageChanged)
      .filter(
        Match.field(Opportunity.StageName)
          .isIn(
            new Set<String>{
              OpportunityMetadata_SL.CLOSED_WON_PENDING,
              OpportunityMetadata_SL.CLOSED_WON_BOOKED,
              OpportunityMetadata_SL.CLOSED_LOST
            }
          )
      )
      .asList();
    if (!eligibleRecords.isEmpty()) {
      Collection.of(eligibleRecords).mapAll(new OppUpdateCloseDateFunction_SL());
    }
  }
}