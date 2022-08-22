public inherited sharing class OppClosedWonForecastFunction_SL implements SObjectToSObjectFunction {
  public SObject apply(Opportunity opp) {
    opp.In_Forecast__c = true;
    opp.Closed_Pending_Checkbox__c = true;
    return opp;
  }

  public SObject apply(SObject record) {
    return apply((Opportunity) record);
  }

  /**
   * Sets both In_Forecast__c and Closed_Pending_Checkbox__c to true if StageName changed to Closed Won Pending
   */
  public static void deriveForecastOnUpdate(List<Opportunity> opps, Map<Id, SObject> existingOpps) {
    SObjectPredicate hasChanged = new HasRecordChanged(
      new Set<SObjectField>{ Opportunity.StageName },
      opps,
      existingOpps
    );
    List<Opportunity> changedOpps = Collection.of(opps)
      .filter(hasChanged)
      .filter(Match.field(Opportunity.StageName).equals('Closed Won Pending'))
      .asList();
    if (!changedOpps.isEmpty()) {
      Collection.of(changedOpps).mapAll(new OppClosedWonForecastFunction_SL());
    }
  }
}