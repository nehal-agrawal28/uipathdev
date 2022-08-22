public with sharing class AccountQuoteKAMQueueable_SL extends AbstractQueueable {
  private final List<SObject> records;
  public AccountQuoteKAMQueueable_SL(List<SObject> records) {
    super('AccountQuoteKAMQueueable_SL');
    this.records = records;
    // to allow for logging against record. only used in non-bulk contexts
    if (records != null && records.size() == 1) {
      this.setPrimaryRecordId(records.get(0).Id);
    }
  }
  public override void work() {
    this.updateKAMFields(records);
  }

  private void updateKAMFields(List<Account> records) {
    List<SBQQ__Quote__c> quotes = new List<SBQQ__Quote__c>(
      [
        SELECT
          Id,
          KAM__c,
          SBQQ__Account__c,
          SBQQ__Account__r.KAM_Id__c,
          SBQQ__Account__r.KAM_GSI__c,
          SBQQ__Account__r.Classification__c
        FROM SBQQ__Quote__c
        WHERE SBQQ__Account__r.Id IN :records AND SBQQ__Status__c = :'Draft'
      ]
    );

    for (SBQQ__Quote__c quote : quotes) {
      if (quote.SBQQ__Account__r.Classification__c == 'KAP') {
        quote.KAM__c = quote.SBQQ__Account__r.KAM_Id__c;
      } else if (quote.SBQQ__Account__r.Classification__c == 'KAP-GSI') {
        quote.KAM__c = quote.SBQQ__Account__r.KAM_GSI__c;
      }
    }
    update quotes;
  }

  public static void updateQuoteKAMField(List<Account> records, Map<Id, SObject> existingRecords) {
    SObjectPredicate hasChanged = new HasRecordChanged(
      new Set<SObjectField>{ Account.Classification__c },
      records,
      existingRecords
    );

    List<Account> eligibleRecords = Collection.of(records)
      .filter(hasChanged)
      .filter(Match.field(Account.Classification__c).isIn(new Set<String>{ 'KAP', 'KAP-GSI' }))
      .asList();

    if (!eligibleRecords.isEmpty()) {
      AbstractQueueable.enqueue(new AccountQuoteKAMQueueable_SL(eligibleRecords));
    }
  }
}