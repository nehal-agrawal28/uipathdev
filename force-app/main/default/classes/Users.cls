/**
 * Responsibility: User Domain Class
 * Mostly just delegates work to Mapped Functions or to Async Queueables
 */
public with sharing class Users extends fflib_SObjectDomain implements IUsers {
  public static IUsers newInstance(List<User> recordList) {
    return (IUsers) Application.Domain.newInstance(recordList);
  }

  public static IUsers newInstance(Set<Id> recordIdSet) {
    return (IUsers) Application.Domain.newInstance(recordIdSet);
  }

  public Users(List<User> sObjectList) {
    super(sObjectList);
    this.Configuration.disableTriggerCRUDSecurity();
  }

  public override void onBeforeInsert() {
  }

  public override void onBeforeUpdate(Map<Id, SObject> existingRecords) {
  }

  public override void onAfterInsert() {
    UserIntegrationService.publishInsertsToRaven(Records);
  }

  public override void onAfterUpdate(Map<Id, SObject> existingRecords) {
    UserIntegrationService.publishUpdatesToRaven(Records, existingRecords);
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
      return new Users(sObjectList);
    }
  }
}