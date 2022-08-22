public with sharing class SubEndBeforeContractFunction_SL implements SObjectToSObjectFunction {
  private Map<Id, Contract> conMap = new Map<Id, Contract>();
  private Map<Id, SBQQ__QuoteLine__c> qliMap = new Map<Id, SBQQ__QuoteLine__c>();

  public SubEndBeforeContractFunction_SL(List<SObject> records) {
    List<Id> conIds = Collection.of(records).pluckIds(SBQQ__Subscription__c.SBQQ__Contract__c);
    List<Id> qliIds = Collection.of(records).pluckIds(SBQQ__Subscription__c.SBQQ__QuoteLine__c);

    this.conMap = new Map<Id, Contract>([SELECT Id, EndDate FROM Contract WHERE Id IN :conIds]);
    this.qliMap = new Map<Id, SBQQ__QuoteLine__c>(
      [SELECT Id, SBQQ__EndDate__c FROM SBQQ__QuoteLine__c WHERE Id IN :qliIds]
    );
  }

  public SObject apply(SBQQ__Subscription__c sub) {
    if (
      sub.SBQQ__Contract__c != null &&
      sub.SBQQ__QuoteLine__c != null &&
      this.conMap.get(sub.SBQQ__Contract__c).EndDate > this.qliMap.get(sub.SBQQ__QuoteLine__c).SBQQ__EndDate__c
    ) {
      sub.SBQQ__RenewalQuantity__c = 0;
    }
    return sub;
  }

  public SObject apply(SObject record) {
    return apply((SBQQ__Subscription__c) record);
  }

  /**
   * @description   Set SBQQ__RenewalQuantity__c to 0 if subscription ends earlier than contract
   * @param records list of new contracts
   */
  public static void earlyEndingSubsOnInsert(List<SObject> records) {
    Collection.of(records)
      .mapSome(
        Match.field(SBQQ__Subscription__c.SBQQ__QuoteLine__c).hasValue(),
        new SubEndBeforeContractFunction_SL(records)
      );
  }
  public static void earlyEndingSubsOnUpdate(List<SObject> records, Map<Id, SObject> existingRecords) {
    SObjectPredicate hasChanged = new HasRecordChanged(
      new Set<SObjectField>{ SBQQ__Subscription__c.SBQQ__QuoteLine__c },
      records,
      existingRecords
    );
    List<SBQQ__Subscription__c> changedSubs = Collection.of(records).filter(hasChanged).asList();

    if (!changedSubs.isEmpty()) {
      Collection.of(changedSubs)
        .mapSome(
          Match.field(SBQQ__Subscription__c.SBQQ__QuoteLine__c).hasValue(),
          new SubEndBeforeContractFunction_SL(changedSubs)
        );
    }
  }
}