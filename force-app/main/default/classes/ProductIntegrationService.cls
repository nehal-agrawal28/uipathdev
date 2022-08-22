public with sharing class ProductIntegrationService {
  public static void publishInsertsToNetsuite(List<SObject> records) {
    OrchestratorNotifierQueueable.beginSetup(Records, CommonsConstants.PRD_UIPATH_SF_CONNECTOR_TEMPLATE)
      .withFilterConditions(
        Match.field(Product2.Sync_Status__c).isIn(new Set<String>{ CommonsConstants.PRD_SYNC_STATUS_VALID })
      )
      .endSetup()
      .publishNewRecords();
  }

  public static void publishUpdatesToNetsuite(List<SObject> records, Map<Id, SObject> oldRecords) {
    OrchestratorNotifierQueueable.beginSetup(records, CommonsConstants.PRD_UIPATH_SF_CONNECTOR_TEMPLATE)
      .withFilterConditions(
        Match.field(Product2.Sync_Status__c).isIn(new Set<String>{ CommonsConstants.PRD_SYNC_STATUS_VALID })
      )
      .withFieldsToCheckForChange(new Set<SObjectField>{ Product2.Sync_Status__c })
      .withOldRecords(oldRecords)
      .endSetup()
      .publishUpdatedRecords();
  }
}