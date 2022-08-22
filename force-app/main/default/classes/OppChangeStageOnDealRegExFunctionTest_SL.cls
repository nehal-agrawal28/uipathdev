@isTest
public with sharing class OppChangeStageOnDealRegExFunctionTest_SL {
  @testSetup
  static void createSetupData() {
    Id customerRT = AccountMetadata.getAccountRecordTypeId('Customer');
    Account testAccount = DataFactory_CM.createAccount(customerRT, true);
  }

  @isTest
  private static void changeStageOnDealRegExiprationOnUpdateTest() {
    Account testAccount = [SELECT id FROM Account LIMIT 1];
    Id oppId = fflib_IDGenerator.generate(Opportunity.SObjectType);

    Opportunity oldOpp = DataFactory_SL.createOpportunity(testAccount.id, false);
    oldOpp.Id = oppId;
    Opportunity updatedOpp = DataFactory_SL.createOpportunity(testAccount.id, false);
    updatedOpp.Deal_Reg_Status__c = OpportunityMetadata_SL.EXPIRED_DEAL_REG_STATUS;
    updatedOpp.StageName = OpportunityMetadata_SL.DEAL_REGISTRATION_STAGE;
    updatedOpp.Id = oppId;

    fflib_SObjectDomain.Test.Database.onUpdate(
      new List<Opportunity>{ updatedOpp },
      new Map<Id, SObject>{ oldOpp.Id => oldOpp }
    );
    fflib_SObjectDomain.triggerHandler(Opportunities_SL.class);

    System.assertEquals(OpportunityMetadata_SL.CLOSED_LOST, updatedOpp.StageName, 'Stage should be Closed Lost');
  }

  @isTest
  private static void changeStageOnDealRegExiprationOnInsertTest() {
    Account testAccount = [SELECT id FROM Account LIMIT 1];
    Id oppId = fflib_IDGenerator.generate(Opportunity.SObjectType);
    Opportunity testOpp = DataFactory_SL.createOpportunity(testAccount.id, false);
    testOpp.Id = oppId;
    testOpp.Converted_from_Lead__c = false;
    testOpp.Deal_Reg_Status__c = OpportunityMetadata_SL.EXPIRED_DEAL_REG_STATUS;
    testOpp.StageName = OpportunityMetadata_SL.DEAL_REGISTRATION_STAGE;
    fflib_SObjectDomain.Test.Database.onInsert(new List<Opportunity>{ testOpp });
    fflib_SObjectDomain.triggerHandler(Opportunities_SL.class);

    System.assertEquals(OpportunityMetadata_SL.CLOSED_LOST, testOpp.StageName, 'Stage should be Closed Lost');
  }

  @isTest
  private static void stageOnOpportunityNotChangedTest() {
    Account testAccount = [SELECT id FROM Account LIMIT 1];
    Id oppId = fflib_IDGenerator.generate(Opportunity.SObjectType);

    Opportunity oldOpp = DataFactory_SL.createOpportunity(testAccount.id, false);
    oldOpp.Id = oppId;
    Opportunity updatedOpp = DataFactory_SL.createOpportunity(testAccount.id, false);
    //updatedOpp.Deal_Reg_Status__c = OpportunityMetadata_SL.DECLINED_DEAL_REG_STATUS;
    updatedOpp.StageName = OpportunityMetadata_SL.DEAL_REGISTRATION_STAGE;
    updatedOpp.Id = oppId;

    fflib_SObjectDomain.Test.Database.onUpdate(
      new List<Opportunity>{ updatedOpp },
      new Map<Id, SObject>{ oldOpp.Id => oldOpp }
    );
    fflib_SObjectDomain.triggerHandler(Opportunities_SL.class);

    System.assertEquals(
      OpportunityMetadata_SL.DEAL_REGISTRATION_STAGE,
      updatedOpp.StageName,
      'Stage should be Deal Registration'
    );
  }
}