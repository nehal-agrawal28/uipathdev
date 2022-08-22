public with sharing class OppCPQAmountFunction_SL implements SObjectToSObjectFunction {
  public OppCPQAmountFunction_SL() {
  }

  private SObject apply(Opportunity opp) {
    opp.CPQ_OpportunityACV__c = opp.Amount;
    opp.CPQ_OpportunityTCV__c = opp.Amount;
    if (opp.Number_of_Products__c == null || opp.Number_of_Products__c == 0) {
      opp.CPQ_OpportunityARR__c = opp.Amount;
    }
    return opp;
  }

  public SObject apply(SObject record) {
    return apply((Opportunity) record);
  }

  public static void populateAmounts(List<Opportunity> records) {
    Collection.of(records)
      .filter(Match.field(Opportunity.SBQQ__PrimaryQuote__c).equals(null).also(Opportunity.Amount).hasValue())
      .mapAll(new OppCPQAmountFunction_SL());
  }

  public static void populateAmounts(List<Opportunity> records, Map<Id, SObject> existingRecords) {
    SObjectPredicate hasChanged = new HasRecordChanged(
      new Set<SObjectField>{ Opportunity.Amount },
      records,
      existingRecords
    );
    Collection.of(records)
      .filter(hasChanged)
      .filter(Match.field(Opportunity.SBQQ__PrimaryQuote__c).equals(null).also(Opportunity.Amount).hasValue())
      .mapAll(new OppCPQAmountFunction_SL());
  }
}