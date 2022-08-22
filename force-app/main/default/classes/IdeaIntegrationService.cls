public with sharing class IdeaIntegrationService {
  public static void publishInsertsToJira(List<SObject> records) {
    OrchestratorNotifierQueueable.beginSetup(Records, SltechConstants.IDEA_UIPATH_SF_CONNECTOR_TEMPLATE)
      .withFilterConditions(
        Match.field(Sales_Technology_Idea__c.Status__c)
          .equals(SltechConstants.IDEA_STATUS_ACCEPTED)
          .also(Sales_Technology_Idea__c.Send_to_JIRA__c)
          .equals(true)
      )
      .endSetup()
      .publishNewRecords();
  }

  public static void publishUpdatesToJira(List<SObject> records, Map<Id, SObject> oldRecords) {
    OrchestratorNotifierQueueable.beginSetup(records, SltechConstants.IDEA_UIPATH_SF_CONNECTOR_TEMPLATE)
      .withFilterConditions(
        Match.field(Sales_Technology_Idea__c.Status__c)
          .equals(SltechConstants.IDEA_STATUS_ACCEPTED)
          .also(Sales_Technology_Idea__c.Send_to_JIRA__c)
          .equals(true)
      )
      .withFieldsToCheckForChange(
        new Set<SObjectField>{ Sales_Technology_Idea__c.Status__c, Sales_Technology_Idea__c.Send_to_JIRA__c }
      )
      .withOldRecords(oldRecords)
      .endSetup()
      .publishUpdatedRecords();
  }
}