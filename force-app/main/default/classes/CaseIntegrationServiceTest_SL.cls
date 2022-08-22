@IsTest(IsParallel=true)
public with sharing class CaseIntegrationServiceTest_SL {
  @IsTest
  public static void publishToUiPathConnector() {
    Id recordTypeId = CaseMetadata_SL.FinanceRequestRecordType;

    Case oldCase = DataFactory_SL.createCase(recordTypeId, true);

    Case updatedCase = DataFactory_SL.createCase(recordTypeId, false);
    updatedCase.Id = oldCase.Id;
    updatedCase.Status = CaseMetadata_SL.INVOICED_DELIVERED;
    updatedCase.Opportunity__c = fflib_IDGenerator.generate(Opportunity.SObjectType);

    Test.startTest();
    OrchestratorNotifierQueueable.forceSyncMode = true;
    fflib_SObjectDomain.Test.Database.onUpdate(
      new List<Case>{ updatedCase },
      new Map<Id, SObject>{ oldCase.Id => oldCase }
    );
    fflib_SObjectDomain.triggerHandler(Cases_SL.class);
    Test.stopTest();

    List<UiPath__UiPathLog__c> logList = new List<UiPath__UiPathLog__c>();

    for (UiPath__UiPathLog__c log : [
      SELECT Id, UiPath__Details__c
      FROM UiPath__UiPathLog__c
      WHERE CreatedDate = TODAY
    ]) {
      if (log.Uipath__Details__c.contains(CommonsConstants.KLARITY_SF_CONNECTOR_TEMPLATE)) {
        logList.add(log);
      }
    }

    //System.assertEquals(true, !logList.isEmpty(), 'There should be a publish attempt in the logs');
  }
}