@IsTest(isParallel=true)
public with sharing class OpportunitiesTest_SL {
  private static final String ACV_ERROR_MESSAGE = 'CPQ Opportunity ACV is not populated';
  private static final String TCV_ERROR_MESSAGE = 'CPQ Opportunity TCV is not populated';
  private static final String ARR_ERROR_MESSAGE = 'CPQ Opportunity ARR is not populated';
  private static final String METRICS_ERROR_MESSAGE = 'Financial Metrics Dirty is not populated';

  @IsTest
  static void populateAmounts_onInsert() {
    Id accountId = fflib_IDGenerator.generate(Account.SObjectType);
    Opportunity newOpp = DataFactory_SL.createOpportunity(accountId, false);
    newOpp.Amount = 10000;

    fflib_SObjectDomain.Test.Database.onInsert(new List<Opportunity>{ newOpp });
    fflib_SObjectDomain.triggerHandler(Opportunities_SL.class);

    System.assertEquals(newOpp.Amount, newOpp.CPQ_OpportunityACV__c, ACV_ERROR_MESSAGE);
    System.assertEquals(newOpp.Amount, newOpp.CPQ_OpportunityTCV__c, TCV_ERROR_MESSAGE);
    System.assertEquals(newOpp.Amount, newOpp.CPQ_OpportunityARR__c, ARR_ERROR_MESSAGE);
  }

  @IsTest
  static void populateDirtyFlag_onInsert() {
    Id accountId = fflib_IDGenerator.generate(Account.SObjectType);
    Opportunity newOpp = DataFactory_SL.createOpportunity(accountId, false);

    fflib_SObjectDomain.Test.Database.onInsert(new List<Opportunity>{ newOpp });
    fflib_SObjectDomain.triggerHandler(Opportunities_SL.class);

    System.assertEquals(true, newOpp.Financial_Metrics_Dirty__c, METRICS_ERROR_MESSAGE);
  }
  @IsTest
  static void populateAmounts_onUpdate() {
    Id accountId = fflib_IDGenerator.generate(Account.SObjectType);
    Id oppId = fflib_IDGenerator.generate(Opportunity.SObjectType);
    Opportunity oldOpp = DataFactory_SL.createOpportunity(accountId, false);
    oldOpp.Id = oppId;
    oldOpp.Amount = 10000;
    Opportunity updatedOpp = DataFactory_SL.createOpportunity(accountId, false);
    updatedOpp.Id = oppId;
    updatedOpp.Amount = 20000;

    fflib_SObjectDomain.Test.Database.onUpdate(
      new List<Opportunity>{ updatedOpp },
      new Map<Id, SObject>{ oldOpp.Id => oldOpp }
    );
    fflib_SObjectDomain.triggerHandler(Opportunities_SL.class);

    System.assertEquals(null, updatedOpp.SBQQ__PrimaryQuote__c, 'Value is not null');
    System.assertEquals(null, updatedOpp.Number_of_Products__c, 'Value is not null');
    System.assertEquals(updatedOpp.Amount, updatedOpp.CPQ_OpportunityACV__c, ACV_ERROR_MESSAGE);
    System.assertEquals(updatedOpp.Amount, updatedOpp.CPQ_OpportunityTCV__c, TCV_ERROR_MESSAGE);
    System.assertEquals(updatedOpp.Amount, updatedOpp.CPQ_OpportunityARR__c, ARR_ERROR_MESSAGE);
    System.assertEquals(true, updatedOpp.Financial_Metrics_Dirty__c, METRICS_ERROR_MESSAGE);
  }

  @IsTest
  static void populateDirtyFlag_onUpdate() {
    Id accountId = fflib_IDGenerator.generate(Account.SObjectType);
    Id oppId = fflib_IDGenerator.generate(Opportunity.SObjectType);
    Opportunity oldOpp = DataFactory_SL.createOpportunity(accountId, false);
    oldOpp.Id = oppId;
    Opportunity updatedOpp = DataFactory_SL.createOpportunity(accountId, false);
    updatedOpp.Id = oppId;
    updatedOpp.StageName = Constants_SL.OPPORTUNITY_STAGE_WON;

    fflib_SObjectDomain.Test.Database.onUpdate(
      new List<Opportunity>{ updatedOpp },
      new Map<Id, SObject>{ oldOpp.Id => oldOpp }
    );
    fflib_SObjectDomain.triggerHandler(Opportunities_SL.class);

    System.assertEquals(true, updatedOpp.Financial_Metrics_Dirty__c, METRICS_ERROR_MESSAGE);
  }

  @IsTest
  static void dontPopulateAmounts_onInsert() {
    Id accountId = fflib_IDGenerator.generate(Account.SObjectType);
    Opportunity newOpp = DataFactory_SL.createOpportunity(accountId, false);
    newOpp.Amount = null;
    newOpp.CPQ_OpportunityACV__c = 1000;
    newOpp.CPQ_OpportunityTCV__c = 2000;
    newOpp.CPQ_OpportunityARR__c = 3000;

    fflib_SObjectDomain.Test.Database.onInsert(new List<Opportunity>{ newOpp });
    fflib_SObjectDomain.triggerHandler(Opportunities_SL.class);

    System.assertNotEquals(null, newOpp.CPQ_OpportunityACV__c, ACV_ERROR_MESSAGE);
    System.assertNotEquals(null, newOpp.CPQ_OpportunityTCV__c, TCV_ERROR_MESSAGE);
    System.assertNotEquals(null, newOpp.CPQ_OpportunityARR__c, ARR_ERROR_MESSAGE);
  }
}