@isTest(isParallel=false)
private class OppUpdateCloseDateFunctionTest_SL {
  @isTest
  private static void setCloseDateOnOpp() {
    Id accountId = fflib_IDGenerator.generate(Account.SObjectType);
    Id oppId = fflib_IDGenerator.generate(Opportunity.SObjectType);
    Opportunity oldOpp = DataFactory_SL.createOpportunity(accountId, false);
    oldOpp.Id = oppId;
    Opportunity updatedOpp = DataFactory_SL.createOpportunity(accountId, false);
    updatedOpp.Id = oppId;
    updatedOpp.StageName = OpportunityMetadata_SL.CLOSED_WON_PENDING;
    updatedOpp.Won_Reasons__c = 'Other';

    fflib_SObjectDomain.Test.Database.onUpdate(
      new List<Opportunity>{ updatedOpp },
      new Map<Id, SObject>{ oldOpp.Id => oldOpp }
    );
    fflib_SObjectDomain.triggerHandler(Opportunities_SL.class);

    System.assertEquals(updatedOpp.CloseDate, Date.Today(), 'Opp Close Date is incorrect');
  }
}