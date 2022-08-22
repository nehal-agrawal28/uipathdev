/**
 * Responsibility: Account Community Domain Class
 * Mostly just delegates work to Mapped Functions or to Async Queueables
 */
public with sharing class AccountsCommunity extends fflib_SObjectDomain implements IAccounts {
    public static IAccounts newInstance(List<Account> recordList) {
      return (IAccounts) Application.Domain.newInstance(recordList);
    }
  
    public static IAccounts newInstance(Set<Id> recordIdSet) {
      return (IAccounts) Application.Domain.newInstance(recordIdSet);
    }
  
    public AccountsCommunity(List<Account> sObjectList) {
      super(sObjectList);
      this.Configuration.disableTriggerCRUDSecurity();
    }
  
    public override void onBeforeInsert() {
    }
  
    public override void onBeforeUpdate(Map<Id, SObject> existingRecords) {
    }
  
    public override void onAfterInsert() {
      AccountRavenIntegrationService.publishInsertsToRaven(Records);
    }
  
    public override void onAfterUpdate(Map<Id, SObject> existingRecords) {
      AccountRavenIntegrationService.publishUpdatesToRaven(Records, existingRecords);
    }
  
    public override void onAfterDelete() {
      AccountRavenIntegrationService.publishDeletesToRaven(Records);
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
        return new AccountsCommunity(sObjectList);
      }
    }
  }