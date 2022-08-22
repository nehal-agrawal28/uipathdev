@isTest
public with sharing class IdeaIntegrationServiceTest {
  public static final String CONFIRMATION_MESSAGE = 'There should be a publish attempt in the logs';

  @TestSetup
  static void createSetupData() {
    User u2 = DataFactory_ST.createUser('', 'OtherTest', 'System Administrator', true);
    u2.Rev_Tech_Team__c = true;
  }

  @IsTest
  public static void publishesInsertsToJira() {
    Sales_Technology_Idea__c idea = DataFactory_ST.createIdea('Leads', false);
    idea.Status__c = SltechConstants.IDEA_STATUS_ACCEPTED;
    idea.Send_to_JIRA__c = true;
    //Set to force a sync publish - which normally happens via a queueable
    OrchestratorNotifierQueueable.forceSyncMode = true;
    insert idea;

    System.assertEquals(
      true,
      [SELECT Id, UiPath__Details__c FROM UiPath__UiPathLog__c LIMIT 1]
        .UiPath__Details__c.contains(SltechConstants.IDEA_UIPATH_SF_CONNECTOR_TEMPLATE),
      CONFIRMATION_MESSAGE
    );
  }

  @IsTest
  public static void publishesUpdatesToJira() {
    User u2 = [SELECT id, Profile.name FROM User WHERE lastName = 'OtherTest' LIMIT 1];
    Sales_Technology_Idea__c idea = DataFactory_ST.createIdea('Leads', true);
    System.assertEquals(u2.profile.name, 'System Administrator');
    idea.Status__c = SltechConstants.IDEA_STATUS_ACCEPTED;
    idea.Jira_Assignee__c = u2.id;
    idea.Prioritization_Date__c = System.today();
    idea.Prioritization_Comments__c = 'We are definitely prioritising this';
    idea.Sales_Tech_Owner__c = u2.id;
    idea.Send_to_JIRA__c = true;

    OrchestratorNotifierQueueable.forceSyncMode = true;
    update idea;

    System.assertEquals(
      true,
      [SELECT Id, UiPath__Details__c FROM UiPath__UiPathLog__c LIMIT 1]
        .UiPath__Details__c.contains(SltechConstants.IDEA_UIPATH_SF_CONNECTOR_TEMPLATE),
      CONFIRMATION_MESSAGE
    );
  }
}