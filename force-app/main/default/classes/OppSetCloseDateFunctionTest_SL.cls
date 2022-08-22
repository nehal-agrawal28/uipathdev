@isTest
public with sharing class OppSetCloseDateFunctionTest_SL {
  @testSetup
  static void createSetupData() {
    Id customerRT = AccountMetadata.getAccountRecordTypeId('Customer');
    Account testAccount = DataFactory_CM.createAccount(customerRT, true);
  }

  @isTest
  private static void setCloseDateOnInsertTest() {
    Account testAccount = [SELECT id FROM Account LIMIT 1];
    Id oppId = fflib_IDGenerator.generate(Opportunity.SObjectType);
    Opportunity testOpp = DataFactory_SL.createOpportunity(testAccount.id, false);
    testOpp.Id = oppId;
    testOpp.Converted_from_Lead__c = false;
    testOpp.StageName = OpportunityMetadata_SL.CLOSED_WON_PENDING;
    testOpp.CloseDate = Date.today().addDays(10);
    fflib_SObjectDomain.Test.Database.onInsert(new List<Opportunity>{ testOpp });
    fflib_SObjectDomain.triggerHandler(Opportunities_SL.class);

    System.assertEquals(Date.today(), testOpp.CloseDate, 'Close date should be set to today.');
  }

  @isTest
  private static void setCloseDateOnUpdateTest() {
    Account testAccount = [SELECT id FROM Account LIMIT 1];
    Id oppId = fflib_IDGenerator.generate(Opportunity.SObjectType);

    Opportunity oldOpp = DataFactory_SL.createOpportunity(testAccount.id, false);
    oldOpp.Id = oppId;
    Opportunity updatedOpp = DataFactory_SL.createOpportunity(testAccount.id, false);

    updatedOpp.StageName = OpportunityMetadata_SL.CLOSED_WON_PENDING;
    updatedOpp.CloseDate = Date.today().addDays(10);
    updatedOpp.Id = oppId;

    fflib_SObjectDomain.Test.Database.onUpdate(
      new List<Opportunity>{ updatedOpp },
      new Map<Id, SObject>{ oldOpp.Id => oldOpp }
    );
    fflib_SObjectDomain.triggerHandler(Opportunities_SL.class);

    System.assertEquals(Date.today(), updatedOpp.CloseDate, 'Close date should be set to today.');
  }
}