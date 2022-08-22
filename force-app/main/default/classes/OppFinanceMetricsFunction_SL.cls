public with sharing class OppFinanceMetricsFunction_SL implements SObjectToSObjectFunction {
  public OppFinanceMetricsFunction_SL() {
  }

  private SObject apply(Opportunity opp) {
    opp.Financial_Metrics_Dirty__c = true;
    return opp;
  }

  public SObject apply(SObject record) {
    return apply((Opportunity) record);
  }

  public static void deriveDirtyFlag(List<Opportunity> records) {
    Collection.of(records).mapAll(new OppFinanceMetricsFunction_SL());
  }

  public static void deriveDirtyFlag(List<Opportunity> records, Map<Id, SObject> existingRecords) {
    SObjectPredicate hasChanged = new HasRecordChanged(
      new Set<SObjectField>{ Opportunity.Amount, Opportunity.StageName, Opportunity.CloseDate },
      records,
      existingRecords
    );
    Collection.of(records).filter(hasChanged).mapAll(new OppFinanceMetricsFunction_SL());
  }
}