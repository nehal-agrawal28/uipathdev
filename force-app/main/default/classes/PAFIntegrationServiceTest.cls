@IsTest(isParallel=true)
public with sharing class PAFIntegrationServiceTest {
  public static final String CONFIRMATION_MESSAGE = 'There should be a publish attempt in the logs';

  @IsTest
  public static void publishesInsertsToRDC() {
    Partner_Application_Form__c partnerApplicationForm = new Partner_Application_Form__c(Country__c = 'Albania');

    //Set to force a sync publish - which normally happens via a queueable
    OrchestratorNotifierQueueable.forceSyncMode = true;
    insert partnerApplicationForm;

    List<UiPath__UiPathLog__c> logList = new List<UiPath__UiPathLog__c>();

    // prettier-ignore
    for (UiPath__UiPathLog__c log : [SELECT Id, UiPath__Details__c FROM UiPath__UiPathLog__c WHERE CreatedDate = TODAY]) {
      if (log.Uipath__Details__c.contains(CommonsConstants.PAF_RDC_UIPATH_SF_CONNECTOR_TEMPLATE)) {
        logList.add(log);
      }
    }
    System.assertEquals(true, !logList.isEmpty(), CONFIRMATION_MESSAGE);
  }

  @IsTest
  public static void publishesUpdatesToRDC() {
    Partner_Application_Form__c partnerApplicationForm = new Partner_Application_Form__c(Country__c = 'Albania');
    insert partnerApplicationForm;

    partnerApplicationForm.Legal_Company_Name__c = 'Changed Legal Name';

    //Set to force a sync publish - which normally happens via a queueable
    OrchestratorNotifierQueueable.forceSyncMode = true;
    update partnerApplicationForm;

    List<UiPath__UiPathLog__c> logList = new List<UiPath__UiPathLog__c>();

    // prettier-ignore
    for (UiPath__UiPathLog__c log : [SELECT Id, UiPath__Details__c FROM UiPath__UiPathLog__c WHERE CreatedDate = TODAY]) {
      if (log.Uipath__Details__c.contains(CommonsConstants.PAF_RDC_UIPATH_SF_CONNECTOR_TEMPLATE)) {
        logList.add(log);
      }
    }
    System.assertEquals(true, !logList.isEmpty(), CONFIRMATION_MESSAGE);
  }
}