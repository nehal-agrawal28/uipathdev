@IsTest
public with sharing class OppRDCIntegrationServiceTest_SL {
  @TestSetup
  static void makeData() {
    DataFactory_CM.createAccounts(AccountMetadata.customerRecordType, 3, true);
  }

  @IsTest
  public static void onInsert_publishAccount() {
    List<Account> accounts = [SELECT Id, RecordTypeId FROM Account];

    OrchestratorNotifierQueueable.forceSyncMode = true;
    DataFactory_SL.createOpportunity(accounts[0].Id, true);
    List<UiPath__UiPathLog__c> logList = new List<UiPath__UiPathLog__c>();

    for (UiPath__UiPathLog__c log : [
      SELECT Id, UiPath__Details__c
      FROM UiPath__UiPathLog__c
      WHERE CreatedDate = TODAY
    ]) {
      if (log.Uipath__Details__c.contains(CommonsConstants.ACC_RDC_UIPATH_SF_CONNECTOR_TEMPLATE)) {
        logList.add(log);
      }
    }

    System.assertEquals(true, !logList.isEmpty(), 'There should be at least 1 publish attempt in the logs');
  }

  @IsTest
  public static void onUpdate_publishAccount() {
    List<Account> accounts = [SELECT Id, RecordTypeId FROM Account];

    OrchestratorNotifierQueueable.forceSyncMode = true;
    Opportunity opp = DataFactory_SL.createOpportunity(accounts[0].Id, true);
    opp.AccountId = accounts[1].Id;
    opp.BPO_MS_End_Customer__c = accounts[2].Id;
    update opp;

    List<UiPath__UiPathLog__c> logList = new List<UiPath__UiPathLog__c>();

    for (UiPath__UiPathLog__c log : [
      SELECT Id, UiPath__Details__c
      FROM UiPath__UiPathLog__c
      WHERE CreatedDate = TODAY
    ]) {
      if (log.Uipath__Details__c.contains(CommonsConstants.ACC_RDC_UIPATH_SF_CONNECTOR_TEMPLATE)) {
        logList.add(log);
      }
    }

    System.assertEquals(true, !logList.isEmpty(), 'There should be at least 1 publish attempt in the logs');
  }
}