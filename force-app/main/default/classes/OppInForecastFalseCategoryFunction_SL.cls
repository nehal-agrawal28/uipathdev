public inherited sharing class OppInForecastFalseCategoryFunction_SL implements SObjectToSObjectFunction {
  public SObject apply(Opportunity opp) {
    opp.In_Forecast__c = false;
    return opp;
  }

  public SObject apply(SObject record) {
    return apply((Opportunity) record);
  }

  /**
   *
   */
  public static void deriveCloseLostForecastOnUpdate(List<Opportunity> opps, Map<Id, SObject> existingOpps) {
    SObjectPredicate hasChanged = new HasRecordChanged(
      new Set<SObjectField>{ Opportunity.IsClosed, Opportunity.IsWon },
      opps,
      existingOpps
    );
    List<Opportunity> changedOpps = Collection.of(opps)
      .filter(hasChanged)
      .filter(
        Match.field(Opportunity.In_Forecast__c)
          .equals(true)
          .also(Opportunity.IsClosed)
          .equals(true)
          .also(Opportunity.IsWon)
          .equals(false)
      )
      .asList();
    if (!changedOpps.isEmpty()) {
      Collection.of(changedOpps).mapAll(new OppInForecastFalseCategoryFunction_SL());
    }
  }
}