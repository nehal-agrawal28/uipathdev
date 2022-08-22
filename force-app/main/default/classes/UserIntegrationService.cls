/**
 * Just a bunch of Static Utility methods - each publishing Users to the UiPath Orchestrator in specific circumstances
 * These methods have been separated into this class to keep the domains small and readable
 */
public with sharing class UserIntegrationService {
  /**
   * Sends new Users to Raven
   * @param records inserted items
   */
  public static void publishInsertsToRaven(List<SObject> records) {
    OrchestratorNotifierQueueable.beginSetup(records, Constants.USR_UIPATH_CONNECTOR_RAVEN_TEMPLATE)
      .withFilterConditions(Match.field(User.ProfileId).isIn(UserMetadata.PortalProfileIds))
      .endSetup()
      .publishNewRecords();
  }

  /**
   * Sends updated Users to Raven
   * @param records updated objects
   * @param oldRecords objects as previously saved in DB
   */
  public static void publishUpdatesToRaven(List<SObject> records, Map<Id, SObject> oldRecords) {
    OrchestratorNotifierQueueable.beginSetup(records, Constants.USR_UIPATH_CONNECTOR_RAVEN_TEMPLATE)
      .withFilterConditions(Match.field(User.ProfileId).isIn(UserMetadata.PortalProfileIds))
      .withFieldsToCheckForChange(
        new Set<SObjectField>{
          User.Email,
          User.Username,
          User.FirstName,
          User.LastName,
          User.Country,
          User.LanguageLocaleKey,
          User.IsActive
        }
      )
      .withOldRecords(oldRecords)
      .endSetup()
      .publishUpdatedRecords();
  }
}