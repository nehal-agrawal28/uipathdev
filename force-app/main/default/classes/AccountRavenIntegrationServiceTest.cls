@IsTest
public with sharing class AccountRavenIntegrationServiceTest {
  public static final String CONFIRMATION_MESSAGE = 'There should be a publish attempt in the logs';
  @IsTest
  public static void publishesInsertsToRaven() {
    Account acc = new Account(
      Name = 'Test1',
      BillingCountry = 'India',
      BillingCountryCode = 'IN',
      BillingStateCode = 'KA',
      Country__c = 'India',
      State__c = 'Karnataka',
      Region_Specific__c = 'India Business - Top Strategic Accounts',
      Industry = 'Apparel',
      RecordTypeId = AccountMetadata.partnerRecordType
    );

    //Set to force a sync publish - which normally happens via a queueable
    OrchestratorNotifierQueueable.forceSyncMode = true;
    insert acc;

    List<UiPath__UiPathLog__c> logList = new List<UiPath__UiPathLog__c>();

    for (UiPath__UiPathLog__c log : [
      SELECT Id, UiPath__Details__c
      FROM UiPath__UiPathLog__c
      WHERE CreatedDate = TODAY
    ]) {
      if (log.Uipath__Details__c.contains(Constants.ACC_UIPATH_CONNECTOR_RAVEN_TEMPLATE)) {
        logList.add(log);
      }
    }

    /* System.assertEquals(
                true,
                !logList.isEmpty(),
                CONFIRMATION_MESSAGE
        );*/
  }

  @IsTest
  public static void publishesUpdatesToRaven() {
    Account acc = new Account(
      Name = 'Test1',
      BillingCountry = 'India',
      BillingCountryCode = 'IN',
      BillingStateCode = 'KA',
      Country__c = 'India',
      Region_Specific__c = 'India Business - Top Strategic Accounts',
      State__c = 'Karnataka',
      Industry = 'Apparel',
      RecordTypeId = AccountMetadata.partnerRecordType
    );

    //Set to force a sync publish - which normally happens via a queueable
    insert acc;

    acc.Name = 'Test2';

    OrchestratorNotifierQueueable.forceSyncMode = true;
    update acc;

    List<UiPath__UiPathLog__c> logList = new List<UiPath__UiPathLog__c>();

    for (UiPath__UiPathLog__c log : [
      SELECT Id, UiPath__Details__c
      FROM UiPath__UiPathLog__c
      WHERE CreatedDate = TODAY
    ]) {
      if (log.Uipath__Details__c.contains(Constants.ACC_UIPATH_CONNECTOR_RAVEN_TEMPLATE)) {
        logList.add(log);
      }
    }

    /* System.assertEquals(
                true,
                !logList.isEmpty(),
                CONFIRMATION_MESSAGE
        );*/
  }

  @IsTest
  public static void publishesDeletesToRaven() {
    Account acc = new Account(
      Name = 'Test1',
      BillingCountry = 'India',
      BillingCountryCode = 'IN',
      BillingStateCode = 'KA',
      Country__c = 'India',
      State__c = 'Karnataka',
      Industry = 'Apparel',
      RecordTypeId = AccountMetadata.partnerRecordType
    );
    insert acc;

    //Set to force a sync publish - which normally happens via a queueable
    OrchestratorNotifierQueueable.forceSyncMode = true;
    delete acc;

    List<UiPath__UiPathLog__c> logList = new List<UiPath__UiPathLog__c>();

    for(UiPath__UiPathLog__c log : [SELECT Id, UiPath__Details__c FROM UiPath__UiPathLog__c
                                    WHERE CreatedDate = TODAY]) {
        if(log.Uipath__Details__c.contains(Constants.ACC_UIPATH_CONNECTOR_RAVEN_TEMPLATE)) {
            logList.add(log);
        }
    }

    /* System.assertEquals(
            true,
            !logList.isEmpty(),
            CONFIRMATION_MESSAGE
    );*/
  }
}