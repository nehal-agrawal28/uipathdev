public with sharing class QuoteGADateQueueable_SL extends AbstractQueueable {
  private final List<SObject> records;
  public QuoteGADateQueueable_SL(List<SObject> records) {
    super('QuoteGADateQueueable_SL');
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
    List<Id> opportunityIds = Collection.of(records).pluckIds(SBQQ__Quote__c.SBQQ__Opportunity2__c);
    List<Opportunity> existingOpps = new List<Opportunity>(
      [SELECT Id, Max_GA_Date__c, SBQQ__PrimaryQuote__r.Max_GA_Date__c FROM Opportunity WHERE Id IN :opportunityIds]
    );

    for (Opportunity opp : existingOpps) {
      opp.Max_GA_Date__c = opp.SBQQ__PrimaryQuote__r.Max_GA_Date__c;
    }
    update existingOpps;
  }

  public static void syncOpportunities(List<SBQQ__Quote__c> records, Map<Id, SObject> existingRecords) {
    SObjectPredicate hasChanged = new HasRecordChanged(
      new Set<SObjectField>{ SBQQ__Quote__c.Max_GA_Date__c },
      records,
      existingRecords
    );

    List<SBQQ__Quote__c> eligibleRecords = Collection.of(records)
      .filter(hasChanged)
      .filter(Match.field(SBQQ__Quote__c.Max_GA_Date__c).hasValue())
      .asList();

    if (!eligibleRecords.isEmpty()) {
      AbstractQueueable.enqueue(new QuoteGADateQueueable_SL(eligibleRecords));
    }
  }
}