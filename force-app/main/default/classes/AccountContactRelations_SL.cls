/**
 * Responsibility: AccountContactRelation Domain Class
 * Mostly just delegates work to Mapped Functions or to Async Queueables
 */
public with sharing class AccountContactRelations_SL extends fflib_SObjectDomain implements IAccountContactRelations_SL {
  public static IAccountContactRelations_SL newInstance(List<AccountContactRelation> recordList) {
    return (IAccountContactRelations_SL) Application.Domain.newInstance(recordList);
  }

  public static IAccountContactRelations_SL newInstance(Set<Id> recordIdSet) {
    return (IAccountContactRelations_SL) Application.Domain.newInstance(recordIdSet);
  }

  public AccountContactRelations_SL(List<AccountContactRelation> sObjectList) {
    super(sObjectList);
    this.Configuration.disableTriggerCRUDSecurity();
  }

  public override void onBeforeInsert() {
  }

  public override void onBeforeUpdate(Map<Id, SObject> existingRecords) {
  }

  public override void onAfterInsert() {
    ContactAccountPayableQueueable_SL.setAccountPayablesOnRelationInsert(Records);
  }
  public override void onAfterUpdate(Map<Id, SObject> existingRecords) {
  }
  public override void onAfterDelete() {
    ContactAccountPayableQueueable_SL.setAccountPayablesOnRelatinDelete(Records);
  }

  public class Constructor implements fflib_SObjectDomain.IConstructable {
    public fflib_SObjectDomain construct(List<SObject> sObjectList) {
      return new AccountContactRelations_SL(sObjectList);
    }
  }
}