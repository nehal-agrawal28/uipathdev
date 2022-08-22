public with sharing class Ideas_ST extends fflib_SObjectDomain implements IIdeas_ST {
  public static IIdeas_ST newInstance(List<Sales_Technology_Idea__c> recordList) {
    return (IIdeas_ST) Application.Domain.newInstance(recordList);
  }

  public static IIdeas_ST newInstance(Set<Id> recordIdSet) {
    return (IIdeas_ST) Application.Domain.newInstance(recordIdSet);
  }

  public Ideas_ST(List<Sales_Technology_Idea__c> sObjectList) {
    super(sObjectList);
    this.Configuration.disableTriggerCRUDSecurity();
  }

  public override void onBeforeInsert() {
  }
  public override void onBeforeUpdate(Map<Id, SObject> existingRecords) {
  }

  public override void onAfterInsert() {
    IdeaIntegrationService.publishInsertsToJira(Records);
  }

  public override void onAfterUpdate(Map<Id, SObject> existingRecords) {
    IdeaIntegrationService.publishUpdatesToJira(Records, existingRecords);
  }

  public class Constructor implements fflib_SObjectDomain.IConstructable {
    public fflib_SObjectDomain construct(List<SObject> sObjectList) {
      return new Ideas_ST(sObjectList);
    }
  }
}