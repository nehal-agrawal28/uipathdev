@isTest(isParallel=false)
private class OppClosedPendingFunctionTest_SL {
  @isTest
  private static void setClosedPendingCheckboxOnOpty() {
    Id accountId = fflib_IDGenerator.generate(Account.SObjectType);
    Id oppId = fflib_IDGenerator.generate(Opportunity.SObjectType);
    Opportunity oldOpp = DataFactory_SL.createOpportunity(accountId, false);
    oldOpp.Id = oppId;
    Opportunity updatedOpp = DataFactory_SL.createOpportunity(accountId, false);
    updatedOpp.Id = oppId;
    updatedOpp.StageName = OpportunityMetadata_SL.CLOSED_WON_PENDING;
    updatedOpp.Won_Reasons__c = 'Successful POC';

    fflib_SObjectDomain.Test.Database.onUpdate(
      new List<Opportunity>{ updatedOpp },
      new Map<Id, SObject>{ oldOpp.Id => oldOpp }
    );
    fflib_SObjectDomain.triggerHandler(Opportunities_SL.class);

    System.assertEquals(updatedOpp.Closed_Pending_Checkbox__c, true, 'Opp Closed_Pending_Checkbox__c is incorrect');
  }
}