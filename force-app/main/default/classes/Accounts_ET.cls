/**
 * Responsibility: Account Domain Class
 * Mostly just delegates work to Mapped Functions or to Async Queueables
 */
public with sharing class Accounts_ET extends fflib_SObjectDomain implements IAccounts {
  public Accounts_ET(List<Account> sObjectList) {
    super(sObjectList);
    this.Configuration.disableTriggerCRUDSecurity();
  }

  public override void onBeforeInsert() {
    AccountsService_ET service = (AccountsService_ET) Application_ET.Service.newInstance(AccountsService_ET.class);
    service.populateTerritoryZipcodeMapping(Records, null, false, true);
  }

  public override void onAfterInsert() {
    AccountsService_ET service = (AccountsService_ET) Application_ET.Service.newInstance(AccountsService_ET.class);
    service.runTerritoryRules(Records, null);
  }

  public override void onBeforeUpdate(Map<Id, SObject> existingRecords) {
    AccountsService_ET service = (AccountsService_ET) Application_ET.Service.newInstance(AccountsService_ET.class);
    service.setRecalculateCompensationFlag(getRecords(), (Map<Id, Account>) existingRecords);
    List<Account> listOfAccounts = new List<Account>();
    Id technologyAllianceRTId = Schema.SobjectType.Account.getRecordTypeInfosByDeveloperName()
      .get('Technology_Alliance')
      .getRecordTypeId();
    Id learningAllianceRTId = Schema.SobjectType.Account.getRecordTypeInfosByDeveloperName()
      .get('Academic')
      .getRecordTypeId();
    List<Account> changedRecords = getChangedRecords(new Set<Schema.SObjectField>{ Account.Sync_Static_Fields__c });

    for (Account objAccount : changedRecords) {
      if (objAccount.RecordTypeId != technologyAllianceRTId && objAccount.RecordTypeId != learningAllianceRTId) {
        listOfAccounts.add(objAccount);
      }
    }
    if (!changedRecords.isEmpty() || AddressTriggerHandler.syncAddressFromObject == true) {
      service.populateTerritoryZipcodeMapping(Records, (Map<Id, Account>) existingRecords, false, false);
    }
    if (AddressTriggerHandler.syncAddressFromObject == true)
      AddressTriggerHandler.syncAddressFromObject = false;
  }

  public override void onAfterUpdate(Map<Id, SObject> existingRecords) {
    AccountsService_ET service = (AccountsService_ET) Application_ET.Service.newInstance(AccountsService_ET.class);
    service.runTerritoryRules(Records, (Map<Id, Account>) existingRecords);
    //To be uncommented for post MVP CSM changes
    /* List<Account> changedRecords = getChangedRecords(new Set<Schema.SObjectField>{ Account.CSM__c });
    if (changedRecords.isEmpty())
      return;
    	
      AbstractQueueable.enqueue(new AccountQueueable_ET(changedRecords,existingRecords));*/
  }
  public class Constructor implements fflib_SObjectDomain.IConstructable {
    public fflib_SObjectDomain construct(List<SObject> sObjectList) {
      return new Accounts_ET(sObjectList);
    }
  }
}