public with sharing class Products_SL extends fflib_SObjectDomain implements IProducts_SL {
  public static IProducts_SL newInstance(List<Product2> recordList) {
    return (IProducts_SL) Application.Domain.newInstance(recordList);
  }

  public static IProducts_SL newInstance(Set<Id> recordIdSet) {
    return (IProducts_SL) Application.Domain.newInstance(recordIdSet);
  }

  public Products_SL(List<Product2> sObjectList) {
    super(sObjectList);
    this.Configuration.disableTriggerCRUDSecurity();
  }

  public override void onBeforeInsert() {
  }
  public override void onBeforeUpdate(Map<Id, SObject> existingRecords) {
  }

  public override void onAfterInsert() {
    ProductIntegrationService.publishInsertsToNetsuite(Records);
  }

  public override void onAfterUpdate(Map<Id, SObject> existingRecords) {
    ProductIntegrationService.publishUpdatesToNetsuite(Records, existingRecords);
  }

  public class Constructor implements fflib_SObjectDomain.IConstructable {
    public fflib_SObjectDomain construct(List<SObject> sObjectList) {
      return new Products_SL(sObjectList);
    }
  }
}