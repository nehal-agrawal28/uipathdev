/**
 * Just a bunch of Static Utility methods - each publishing Contacts to the UiPath Orchestrator in specific circumstances
 * These methods have been separated into this class to keep the domains small and readable
 */
public with sharing class ContactRavenIntegrationService {
  /**
   * Sends updated Contacts to Raven
   * @param records updated objects
   * @param oldRecords objects as previously saved in DB
   */
  public static void publishUpdatesToRaven(List<SObject> records, Map<Id, SObject> oldRecords) {
    OrchestratorNotifierQueueable.beginSetup(records, Constants_MK.CNT_UIPATH_CONNECTOR_RAVEN_TEMPLATE)
      .withFieldsToCheckForChange(new Set<SObjectField>{ Contact.AccountId })
      .withOldRecords(oldRecords)
      .endSetup()
      .publishUpdatedRecords();
  }
}