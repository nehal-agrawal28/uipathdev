public with sharing class OpportunityPopulateGADateFunction_SL implements SObjectToSObjectFunction {
  private Map<Id, SBQQ__Quote__c> quotes;
  public OpportunityPopulateGADateFunction_SL(List<Opportunity> records) {
    List<Id> quoteIds = Collection.of(records).pluckIds(Opportunity.SBQQ__PrimaryQuote__c);
    quotes = new Map<Id, SBQQ__Quote__c>(
      [SELECT Id, Max_GA_Date__c, SBQQ__Opportunity2__c FROM SBQQ__Quote__c WHERE Id IN :quoteIds]
    );
  }

  public SObject apply(Opportunity opp) {
    if (quotes.get(opp.SBQQ__PrimaryQuote__c).Max_GA_Date__c != null) {
      opp.Max_GA_Date__c = quotes.get(opp.SBQQ__PrimaryQuote__c).Max_GA_Date__c;
    }
    return opp;
  }

  public SObject apply(SObject record) {
    return apply((Opportunity) record);
  }

  /**
   */
  public static void deriveGADate(List<Opportunity> opps, Map<Id, SObject> existingOpps) {
    SObjectPredicate quoteChanged = new HasRecordChanged(
      new Set<SObjectField>{ Opportunity.SBQQ__PrimaryQuote__c },
      opps,
      existingOpps
    );
    List<Opportunity> changedOpps = Collection.of(opps)
      .filter(quoteChanged)
      .filter(Match.field(Opportunity.SBQQ__PrimaryQuote__c).hasValue())
      .asList();

    if (!changedOpps.isEmpty()) {
      Collection.of(changedOpps).mapAll(new OpportunityPopulateGADateFunction_SL(changedOpps));
    }
  }
}