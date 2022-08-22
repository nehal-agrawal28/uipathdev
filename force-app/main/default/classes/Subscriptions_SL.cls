public with sharing class Subscriptions_SL extends fflib_SObjectDomain implements ISubscriptions_SL {
  public static ISubscriptions_SL newInstance(List<SBQQ__Subscription__c> recordList) {
    return (ISubscriptions_SL) Application.Domain.newInstance(recordList);
  }

  public static ISubscriptions_SL newInstance(Set<Id> recordIdSet) {
    return (ISubscriptions_SL) Application.Domain.newInstance(recordIdSet);
  }

  public Subscriptions_SL(List<SBQQ__Subscription__c> sObjectList) {
    super(sObjectList);
    this.Configuration.disableTriggerCRUDSecurity();
  }

  public override void onBeforeInsert() {
    SubEndBeforeContractFunction_SL.earlyEndingSubsOnInsert(Records);
  }

  public override void onBeforeUpdate(Map<Id, SObject> existingRecords) {
    SubEndBeforeContractFunction_SL.earlyEndingSubsOnUpdate(Records, existingRecords);
  }

  public override void onAfterInsert() {
  }

  public override void onAfterUpdate(Map<Id, SObject> existingRecords) {
  }

  public override void onBeforeDelete() {
  }

  public override void onAfterDelete() {
  }

  public class Constructor implements fflib_SObjectDomain.IConstructable {
    public fflib_SObjectDomain construct(List<SObject> sObjectList) {
      return new Subscriptions_SL(sObjectList);
    }
  }
}