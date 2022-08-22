public with sharing class ContractOrderFunction_SL implements SObjectToSObjectFunction {
  public SObject apply(Contract record) {
    if (record.Original_OrderID__c == null) {
      record.Original_OrderID__c = record.SBQQ__Order__c;
    }
    return record;
  }

  public SObject apply(SObject record) {
    return apply((Contract) record);
  }

  public static void setOriginalOrderId(List<SObject> records) {
    Collection.of(records)
      .mapSome(Match.field(Contract.SBQQ__Order__c).hasValue(), new ContractOrderFunction_SL())
      .asList();
  }
}