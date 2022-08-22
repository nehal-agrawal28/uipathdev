public with sharing class QuoteFullUpfrontFrequencyQueueable_SL extends AbstractQueueable {
  private final List<SObject> records;
  public QuoteFullUpfrontFrequencyQueueable_SL(List<SObject> records) {
    super('QuoteFullUpfrontFrequencyQueueable_SL');
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
    if (OpportunityMetadata_SL.IsOrderIntegrationFeatureOn) {
      Map<Id, SBQQ__Quote__c> quotes = new Map<Id, SBQQ__Quote__c>(
        [
          SELECT Id, SBQQ__BillingFrequency__c, SBQQ__Opportunity2__r.Payment_Cycle__c
          FROM SBQQ__Quote__c
          WHERE Id IN :records
        ]
      );

      List<Opportunity> opps = new List<Opportunity>();

      for (SBQQ__Quote__c record : records) {
        Opportunity newOpportunity = new Opportunity();
        newOpportunity.Id = quotes.get(record.Id).SBQQ__Opportunity2__r.Id;
        newOpportunity.Payment_Cycle__c = quotes.get(record.Id).SBQQ__BillingFrequency__c;
        opps.add(newOpportunity);
      }
      update opps;
    }
  }

  public static void updateBillingCycle(List<SBQQ__Quote__c> records) {
    List<SBQQ__Quote__c> eligibleRecords = Collection.of(records)
      .filter(
        Match.field(SBQQ__Quote__c.SBQQ__Opportunity2__c)
          .hasValue()
          .field(SBQQ__Quote__c.SBQQ__BillingFrequency__c)
          .hasValue()
          .also(SBQQ__Quote__c.SBQQ__BillingFrequency__c)
          .isIn(new Set<String>{ 'Upfront', 'Annual' })
          .also(SBQQ__Quote__c.SBQQ__Primary__c)
          .hasValue()
          .also(SBQQ__Quote__c.SBQQ__Primary__c)
          .equals(true)
      )
      .asList();

    if (!eligibleRecords.isEmpty()) {
      AbstractQueueable.enqueue(new QuoteFullUpfrontFrequencyQueueable_SL(eligibleRecords));
    }
  }

  public static void updateBillingCycle(List<SBQQ__Quote__c> records, Map<Id, SObject> existingRecords) {
    SObjectPredicate hasChanged = new HasRecordChanged(
      new Set<SObjectField>{
        SBQQ__Quote__c.SBQQ__BillingFrequency__c,
        SBQQ__Quote__c.SBQQ__Primary__c,
        SBQQ__Quote__c.SBQQ__Opportunity2__c
      },
      records,
      existingRecords
    );

    List<SBQQ__Quote__c> eligibleRecords = Collection.of(records).filter(hasChanged).asList();

    if (!eligibleRecords.isEmpty()) {
      QuoteFullUpfrontFrequencyQueueable_SL.updateBillingCycle(eligibleRecords);
    }
  }
}