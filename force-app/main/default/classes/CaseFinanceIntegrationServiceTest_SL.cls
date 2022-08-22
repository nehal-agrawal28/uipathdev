@IsTest
public with sharing class CaseFinanceIntegrationServiceTest_SL {
  @TestSetup
  static void makeData() {
    Account testAccount = DataFactory_CM.createAccount('Customer', true);
    Opportunity opp = DataFactory_SL.createOpportunity(testAccount.Id, true);

    Product2 product = DataFactory_SL.createProduct(true);
    SBQQ__Quote__c quote = DataFactory_SL.createCPQQuote(opp.AccountId, opp.Id, false);
    quote.SBQQ__Primary__c = true;
    insert quote;
    DataFactory_SL.createCPQQuoteLine(product.Id, quote.Id, true);
  }

  @IsTest
  static void onInsert_publishToUiPathConnector() {
    SBQQ__Quote__c quote = [SELECT Id, SBQQ__Opportunity2__c FROM SBQQ__Quote__c LIMIT 1];

    Case record = DataFactory_SL.createCase(CaseMetadata_SL.FinanceRequestRecordType, false);
    record.Id = fflib_IDGenerator.generate(Case.SObjectType);
    record.Status = CaseMetadata_SL.DEAL_HUB_REVIEW;
    record.Subject = CaseMetadata_SL.PLEASE_INVOICE;
    record.Opportunity__c = quote.SBQQ__Opportunity2__c;

    Test.startTest();
    OrchestratorNotifierQueueable.forceSyncMode = true;
    fflib_SObjectDomain.Test.Database.onInsert(new List<Case>{ record });
    fflib_SObjectDomain.triggerHandler(Cases_SL.class);

    Test.stopTest();
    List<UiPath__UiPathLog__c> logList = new List<UiPath__UiPathLog__c>();

    for (UiPath__UiPathLog__c log : [
      SELECT Id, UiPath__Details__c
      FROM UiPath__UiPathLog__c
      WHERE CreatedDate = TODAY
    ]) {
      if (log.Uipath__Details__c.contains(Constants_SL.FINANCE_CASE_TEMPLATE)) {
        logList.add(log);
      }
    }

    System.assertEquals(true, !logList.isEmpty(), 'There should be at least 1 publish attempt in the logs');
  }
}