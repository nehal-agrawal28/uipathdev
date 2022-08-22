/**
 * Just a bunch of Static Utility methods - each publishing Accounts to the UiPath Orchestrator in specific circumstances
 * These methods have been separated into this class to keep the domains small and readable
 */
public with sharing class AccountRavenIntegrationService {
    /**
     * Sends new Accounts to Raven
     * @param records inserted items
     */
    public static void publishInsertsToRaven(List<SObject> records) {
        OrchestratorNotifierQueueable.beginSetup(records, Constants.ACC_UIPATH_CONNECTOR_RAVEN_TEMPLATE)
                .withFilterConditions(
                Match.field(Account.RecordTypeId)
                        .isIn(new Set<String>{ AccountMetadata.partnerProspectRecordType, AccountMetadata.partnerRecordType })
        )
                .endSetup()
                .publishNewRecords();
    }

    /**
     * Sends updated Accounts to Raven
     * @param records updated objects
     * @param oldRecords objects as previously saved in DB
     */
    public static void publishUpdatesToRaven(List<SObject> records, Map<Id, SObject> oldRecords) {
        OrchestratorNotifierQueueable.beginSetup(records, Constants.ACC_UIPATH_CONNECTOR_RAVEN_TEMPLATE)
                .withFilterConditions(
                Match.field(Account.RecordTypeId)
                        .isIn(new Set<String>{ AccountMetadata.partnerProspectRecordType, AccountMetadata.partnerRecordType })
        )
                .withFieldsToCheckForChange(
                new Set<SObjectField>{
                        Account.Partner_Reporting_Name__c,
                        Account.Name,
                        Account.RecordTypeId,
                        Account.OwnerId,
                        Account.BillingCountry,
                        Account.Geo__c,
                        Account.Region__c,
                        Account.Area__c,
                        Account.Ultimate_Parent_Id__c,
                        Account.Ultimate_Parent_name__c,
                        Account.Business_Partner_Status__c,
                        Account.Business_Partner_Level__c
                }
        )
                .withOldRecords(oldRecords)
                .endSetup()
                .publishUpdatedRecords();
    }

     /**
     * Sends deleted Accounts to Raven
     * @param records deleted items
     */
    public static void publishDeletesToRaven(List<SObject> records) {
        OrchestratorNotifierQueueable.beginSetup(records, Constants.ACC_UIPATH_CONNECTOR_RAVEN_TEMPLATE)
          .withFilterConditions(
            Match.field(Account.RecordTypeId)
              .isIn(new Set<String>{ AccountMetadata.partnerProspectRecordType, AccountMetadata.partnerRecordType })
          )
          .endSetup()
          .publishDeletedRecords();
      }
}