/**
 * Responsibility: Contract Domain class
 */
public with sharing class Contracts_SL extends fflib_SObjectDomain implements IContracts_SL {
  public static IContracts_SL newInstance(List<Contract> recordList) {
    return (IContracts_SL) Application.Domain.newInstance(recordList);
  }

  public static IContracts_SL newInstance(Set<Id> recordIdSet) {
    return (IContracts_SL) Application.Domain.newInstance(recordIdSet);
  }

  public Contracts_SL(List<Contract> sObjectList) {
    super(sObjectList);
    this.Configuration.disableTriggerCRUDSecurity();
  }

  public override void onBeforeInsert() {
    ContractRenewalAmendmentFunction_SL.setDefaultsForRenewalAmendments(Records);
  }

  public override void onAfterInsert() {
  }

  public override void onBeforeUpdate(Map<Id, SObject> existingRecords) {
    ContractActivationFunction_SL.setStatusToActivated(Records); // SF does not allow activated status on before insert
    ContractOrderFunction_SL.setOriginalOrderId(Records);
  }

  public override void onAfterUpdate(Map<Id, SObject> existingRecords) {
    ContractOptyDirtyFlagQueueable.setDirtyFlagOnRenewalOpties(Records, existingRecords);
    ContractRenewalQueueable_SL.renewalsForecast(Records, existingRecords); //Causes failure in data import Contract activation upsert - queueable depth exception
    ContractSetSupportFlagOnAccQueueable_SL.setClearForSuppOnUpdate(Records, existingRecords);
  }

  public class Constructor implements fflib_SObjectDomain.IConstructable {
    public fflib_SObjectDomain construct(List<SObject> sObjectList) {
      return new Contracts_SL(sObjectList);
    }
  }
}