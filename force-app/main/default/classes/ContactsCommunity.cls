/**
 * Responsibility: Community Contact Domain Class
 * Mostly just delegates work to Mapped Functions or to Async Queueables
 */
public with sharing class ContactsCommunity extends fflib_SObjectDomain implements IContacts {
    public static IContacts newInstance(List<Contact> recordList) {
      return (IContacts) Application.Domain.newInstance(recordList);
    }
  
    public static IContacts newInstance(Set<Id> recordIdSet) {
      return (IContacts) Application.Domain.newInstance(recordIdSet);
    }
  
    public ContactsCommunity(List<Contact> sObjectList) {
      super(sObjectList);
      this.Configuration.disableTriggerCRUDSecurity();
    }
  
    public override void onBeforeInsert() {
    }
  
    public override void onBeforeUpdate(Map<Id, SObject> existingRecords) {
    }
  
    public override void onAfterInsert() {
    }
  
    public override void onAfterUpdate(Map<Id, SObject> existingRecords) {
        ContactRavenIntegrationService.publishUpdatesToRaven(Records, existingRecords);
    }
  
    public override void onAfterDelete() {
    }
  
    /**
     * Validates accounts inserted or Updated
     */
    public override void onValidate() {
    }
  
    /**
     * Validates accounts that are updated
     * @param existingRecords updated Records
     */
    public override void onValidate(Map<Id, SObject> existingRecords) {
    }
  
    public class Constructor implements fflib_SObjectDomain.IConstructable {
      public fflib_SObjectDomain construct(List<SObject> sObjectList) {
        return new ContactsCommunity(sObjectList);
      }
    }
  }