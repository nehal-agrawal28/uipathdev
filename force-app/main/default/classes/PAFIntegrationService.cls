public with sharing class PAFIntegrationService {
  /**
   * Sends new Partner Application form to RDC for processing
   * @param records inserted objects
   */

  public static void publishInsertsToRDC(List<SObject> records) {
    OrchestratorNotifierQueueable.beginSetup(records, CommonsConstants.PAF_RDC_UIPATH_SF_CONNECTOR_TEMPLATE)
      .endSetup()
      .publishNewRecords();
  }

  /**
   * Sends updated Partner Application form to RDC
   * @param records updated objects
   * @param oldRecords objects as previously saved in DB
   */
  public static void publishUpdatesToRDC(List<SObject> records, Map<Id, SObject> oldRecords) {
    OrchestratorNotifierQueueable.beginSetup(records, CommonsConstants.PAF_RDC_UIPATH_SF_CONNECTOR_TEMPLATE)
      .withFieldsToCheckForChange(
        new Set<SObjectField>{
          Partner_Application_Form__c.Country__c,
          Partner_Application_Form__c.Legal_Company_Address__c,
          Partner_Application_Form__c.Legal_Company_Name__c
        }
      )
      .withOldRecords(oldRecords)
      .endSetup()
      .publishUpdatedRecords();
  }
}