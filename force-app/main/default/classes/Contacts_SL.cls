/**
 * Responsibility: Contact Domain Class
 * Mostly just delegates work to Mapped Functions or to Async Queueables
 */
public with sharing class Contacts_SL extends fflib_SObjectDomain implements IContacts_SL {
  public static IContacts_SL newInstance(List<Contact> recordList) {
    return (IContacts_SL) Application.Domain.newInstance(recordList);
  }

  public static IContacts_SL newInstance(Set<Id> recordIdSet) {
    return (IContacts_SL) Application.Domain.newInstance(recordIdSet);
  }

  public Contacts_SL(List<Contact> sObjectList) {
    super(sObjectList);
    this.Configuration.disableTriggerCRUDSecurity();
  }

  public override void onBeforeInsert() {
  }

  public override void onBeforeUpdate(Map<Id, SObject> existingRecords) {
  }

  public override void onAfterInsert() {
    ContactAccountPayableQueueable_SL.setAccountPayablesOnInsert(Records);
  }
  public override void onAfterUpdate(Map<Id, SObject> existingRecords) {
    ContactAccountPayableQueueable_SL.setAccountPayablesOnUpdate(Records, existingRecords);
  }

  public class Constructor implements fflib_SObjectDomain.IConstructable {
    public fflib_SObjectDomain construct(List<SObject> sObjectList) {
      return new Contacts_SL(sObjectList);
    }
  }
}