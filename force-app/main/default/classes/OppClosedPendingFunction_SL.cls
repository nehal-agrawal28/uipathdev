public with sharing class OppClosedPendingFunction_SL implements SObjectToSObjectFunction {
  public OppClosedPendingFunction_SL(List<Opportunity> records) {
  }

  public SObject apply(Opportunity opp) {
    opp.Closed_Pending_Checkbox__c = true;
    return opp;
  }

  public SObject apply(SObject record) {
    return apply((Opportunity) record);
  }

  /**
   */
  public static void deriveClosedPendingCheckbox(List<Opportunity> opps, Map<Id, SObject> existingOpps) {
    SObjectPredicate stageChanged = new HasRecordChanged(
      new Set<SObjectField>{ Opportunity.StageName },
      opps,
      existingOpps
    );
    List<Opportunity> changedOpps = Collection.of(opps)
      .filter(stageChanged)
      .filter(Match.field(Opportunity.StageName).equals(OpportunityMetadata_SL.CLOSED_WON_PENDING))
      .asList();

    if (!changedOpps.isEmpty()) {
      Collection.of(changedOpps).mapAll(new OppClosedPendingFunction_SL(changedOpps));
    }
  }
}