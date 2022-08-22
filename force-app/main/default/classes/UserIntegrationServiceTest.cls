@IsTest(isParallel=false)
public with sharing class UserIntegrationServiceTest {
  public static final String LOS_ANGELES_TIMEZONE = 'America/Los_Angeles';

  @IsTest
  public static void publishesInsertsToRaven() {
    User usr = new User(
      // TODO refactor : else test will fail if profile is not present
      ProfileId = [SELECT Id FROM Profile WHERE Name = :Constants.APEX_TESTING_ONLY_PROFILE]
      .Id,
      Username = 'testgamemailacc1@testgam.com',
      LastName = 'TestUser',
      Email = 'testgamemailacc1@testgam.com',
      Alias = 'tgame433',
      TimeZoneSidKey = LOS_ANGELES_TIMEZONE,
      LocaleSidKey = 'en_US',
      EmailEncodingKey = 'UTF-8',
      LanguageLocaleKey = 'en_US'
    );

    //Set to force a sync publish - which normally happens via a queueable
    OrchestratorNotifierQueueable.forceSyncMode = true;
    insert usr;

    List<UiPath__UiPathLog__c> logList = new List<UiPath__UiPathLog__c>();

    for(UiPath__UiPathLog__c log : [SELECT Id, UiPath__Details__c FROM UiPath__UiPathLog__c
                                    WHERE CreatedDate = TODAY]) {
        if(log.Uipath__Details__c.contains(Constants.USR_UIPATH_CONNECTOR_RAVEN_TEMPLATE)) {
            logList.add(log);
        }
    }

    System.assertEquals(
            true,
            !logList.isEmpty(),
            'There should be a publish attempt in the logs'
    );
  }

  @IsTest
  public static void publishesUpdatesToRaven() {
    User usr = new User(
      // TODO refactor : else test will fail if profile is not present
      ProfileId = [SELECT Id FROM Profile WHERE Name = :Constants.APEX_TESTING_ONLY_PROFILE]
      .Id,
      Username = 'testgamemailacc2@testgam.com',
      LastName = 'TestUser',
      Email = 'testgamemailacc2@testgam.com',
      Alias = 'tgame433',
      TimeZoneSidKey = LOS_ANGELES_TIMEZONE,
      LocaleSidKey = 'en_US',
      EmailEncodingKey = 'UTF-8',
      LanguageLocaleKey = 'en_US'
    );

    //Set to force a sync publish - which normally happens via a queueable
    insert usr;

    usr.Country = 'Uganda';

    OrchestratorNotifierQueueable.forceSyncMode = true;
    update usr;

    List<UiPath__UiPathLog__c> logList = new List<UiPath__UiPathLog__c>();

    for(UiPath__UiPathLog__c log : [SELECT Id, UiPath__Details__c FROM UiPath__UiPathLog__c
                                    WHERE CreatedDate = TODAY]) {
        if(log.Uipath__Details__c.contains(Constants.USR_UIPATH_CONNECTOR_RAVEN_TEMPLATE)) {
            logList.add(log);
        }
    }

    System.assertEquals(
            true,
            !logList.isEmpty(),
            'There should be a publish attempt in the logs'
    );
  }
}