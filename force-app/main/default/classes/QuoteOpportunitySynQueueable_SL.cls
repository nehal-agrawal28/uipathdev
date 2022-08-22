public with sharing class QuoteOpportunitySynQueueable_SL extends AbstractQueueable {
  private final List<SObject> records;
  public QuoteOpportunitySynQueueable_SL(List<SObject> records) {
    super('QuoteOpportunitySynQueueable_SL');
    this.records = records;
    //to allow for logging against record. only used in non-bulk contexts
    if (records != null && records.size() == 1) {
      this.setPrimaryRecordId(records.get(0).Id);
    }
  }
  public override void work() {
    this.updateOpportunities(records);
  }

  private void updateOpportunities(List<SBQQ__Quote__c> records) {
    List<Opportunity> opps = new List<Opportunity>();
    for (SBQQ__Quote__c record : records) {
      Opportunity opp = new Opportunity();
      opp.Id = record.SBQQ__Opportunity2__c;
      opp.Contract_Start_Date__c = record.SBQQ__StartDate__c;
      opp.Contract_End_Date__c = record.SBQQ__EndDate__c;
      opp.CPQ_OpportunityACV__c = record.CPQ_QuoteACV_val__c;
      opp.CPQ_OpportunityTCV__c = record.CPQ_QuoteTCV_val__c;
      opps.add(opp);
    }
    List<Id> opportunityIds = Collection.of(records).pluckIds(SBQQ__Quote__c.SBQQ__Opportunity2__c);
    Map<Id, Opportunity> existingOpps = new Map<Id, Opportunity>(
      [
        SELECT Id, Contract_Start_Date__c, Contract_End_Date__c, CPQ_OpportunityACV__c, CPQ_OpportunityTCV__c
        FROM Opportunity
        WHERE Id IN :opportunityIds
      ]
    );

    SObjectPredicate hasChanged = new HasRecordChanged(
      new Set<SObjectField>{
        Opportunity.Contract_Start_Date__c,
        Opportunity.Contract_End_Date__c,
        Opportunity.CPQ_OpportunityACV__c,
        Opportunity.CPQ_OpportunityTCV__c
      },
      opps,
      existingOpps
    );

    List<Opportunity> recordsToBeUpdated = Collection.of(opps).filter(hasChanged).asList();
    update recordsToBeUpdated;
  }

  public static void syncOpportunities(List<SBQQ__Quote__c> records, Map<Id, SObject> existingRecords) {
    SObjectPredicate hasChanged = new HasRecordChanged(
      new Set<SObjectField>{
        SBQQ__Quote__c.SBQQ__Primary__c,
        SBQQ__Quote__c.SBQQ__StartDate__c,
        SBQQ__Quote__c.SBQQ__EndDate__c,
        SBQQ__Quote__c.CPQ_QuoteACV_val__c,
        SBQQ__Quote__c.CPQ_QuoteTCV_val__c
      },
      records,
      existingRecords
    );

    List<SBQQ__Quote__c> eligibleRecords = Collection.of(records).filter(hasChanged).asList();

    if (!eligibleRecords.isEmpty()) {
      syncOpportunities(eligibleRecords);
    }
  }

  public static void syncOpportunities(List<SBQQ__Quote__c> records) {
    List<SBQQ__Quote__c> eligibleRecords = Collection.of(records)
      .filter(
        Match.field(SBQQ__Quote__c.SBQQ__Primary__c)
          .hasValue()
          .also(SBQQ__Quote__c.SBQQ__Primary__c)
          .equals(true)
          .also(SBQQ__Quote__c.SBQQ__Opportunity2__c)
          .hasValue()
      )
      .asList();

    if (!eligibleRecords.isEmpty()) {
      AbstractQueueable.enqueue(new QuoteOpportunitySynQueueable_SL(eligibleRecords));
    }
  }
}