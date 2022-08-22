public with sharing class OppSetCloseDateFunction_SL implements SObjectToSObjectFunction {
  public OppSetCloseDateFunction_SL() {
  }

  public SObject apply(Opportunity opp) {
    opp.CloseDate = Date.today();
    return opp;
  }

  public SObject apply(SObject record) {
    return apply((Opportunity) record);
  }

  public static void populateCloseDateOnOppOnInsert(List<Opportunity> opps) {
    List<Opportunity> elegibleOpps = Collection.of(opps)
      .filter(
        Match.field(Opportunity.StageName)
          .isIn(new Set<String>{ OpportunityMetadata_SL.CLOSED_WON_PENDING, OpportunityMetadata_SL.CLOSED_LOST })
          .also(Opportunity.CloseDate)
          .notEquals(Date.today())
      )
      .asList();

    if (!elegibleOpps.isEmpty()) {
      Collection.of(elegibleOpps).mapAll(new OppSetCloseDateFunction_SL());
    }
  }

  public static void populateCloseDateOnOppOnUpdate(List<Opportunity> opps, Map<Id, SObject> existingOpportunities) {
    SObjectPredicate hasChanged = new HasRecordChanged(
      new Set<SObjectField>{ Opportunity.StageName },
      opps,
      existingOpportunities
    );

    List<Opportunity> elegibleOpps = Collection.of(opps)
      .filter(hasChanged)
      .filter(
        Match.field(Opportunity.StageName)
          .isIn(new Set<String>{ OpportunityMetadata_SL.CLOSED_WON_PENDING, OpportunityMetadata_SL.CLOSED_LOST })
          .also(Opportunity.CloseDate)
          .notEquals(Date.today())
      )
      .asList();

    if (!elegibleOpps.isEmpty()) {
      Collection.of(elegibleOpps).mapAll(new OppSetCloseDateFunction_SL());
    }
  }
}