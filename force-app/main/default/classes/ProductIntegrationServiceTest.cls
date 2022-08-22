@isTest(isParallel=true)
public with sharing class ProductIntegrationServiceTest {
  public static final String CONFIRMATION_MESSAGE = 'There should be a publish attempt in the logs';

  @IsTest
  public static void publishesInsertsToNetsuite() {
    Product2 prod = DataFactory_SL.createProduct(false);
    prod.Sync_Status__c = CommonsConstants.PRD_SYNC_STATUS_VALID;

    //Set to force a sync publish - which normally happens via a queueable
    OrchestratorNotifierQueueable.forceSyncMode = true;
    insert prod;

    System.assertEquals(
      true,
      [SELECT Id, UiPath__Details__c FROM UiPath__UiPathLog__c LIMIT 1]
        .UiPath__Details__c.contains(CommonsConstants.PRD_UIPATH_SF_CONNECTOR_TEMPLATE),
      CONFIRMATION_MESSAGE
    );
  }

  @IsTest
  public static void publishesUpdatesToNetsuite() {
    Product2 prod = DataFactory_SL.createProduct(true);

    prod.Sync_Status__c = CommonsConstants.PRD_SYNC_STATUS_VALID;

    OrchestratorNotifierQueueable.forceSyncMode = true;
    update prod;

    System.assertEquals(
      true,
      [SELECT Id, UiPath__Details__c FROM UiPath__UiPathLog__c LIMIT 1]
        .UiPath__Details__c.contains(CommonsConstants.PRD_UIPATH_SF_CONNECTOR_TEMPLATE),
      CONFIRMATION_MESSAGE
    );
  }
}