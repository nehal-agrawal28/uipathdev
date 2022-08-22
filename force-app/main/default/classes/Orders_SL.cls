/**
 * Responsibility: Orders Domain class
 */
public with sharing class Orders_SL extends fflib_SObjectDomain implements IOrders_SL {
  public static IOrders_SL newInstance(List<Order> recordList) {
    return (IOrders_SL) Application.Domain.newInstance(recordList);
  }

  public static IOrders_SL newInstance(Set<Id> recordIdSet) {
    return (IOrders_SL) Application.Domain.newInstance(recordIdSet);
  }

  public Orders_SL(List<Order> sObjectList) {
    super(sObjectList);
    this.Configuration.disableTriggerCRUDSecurity();
  }

  public override void onBeforeInsert() {
    OrderPricebookFunction_SL.populatePricebookIdInScratchOrgs(records);
  }

  public override void onAfterInsert() {
    OrderRipReplaceAssocQueueable_SL.setParent(Records);
  }

  public override void onBeforeUpdate(Map<Id, SObject> existingRecords) {
  }

  public override void onAfterUpdate(Map<Id, SObject> existingRecords) {
    OrderRipReplaceSyncQueueableSerial_SL.syncCancelledRecordsWithReplacementRecord(records, existingRecords);
  }

  public class Constructor implements fflib_SObjectDomain.IConstructable {
    public fflib_SObjectDomain construct(List<SObject> sObjectList) {
      return new Orders_SL(sObjectList);
    }
  }
}