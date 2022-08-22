@isTest(isParallel=false)
private class OppDealRegApprovedFunctionTest_SL {
  @isTest
  private static void setRTOnUpdate() {
    Id accountId = fflib_IDGenerator.generate(Account.SObjectType);
    Id oppId = fflib_IDGenerator.generate(Opportunity.SObjectType);
    Opportunity oldOpp = DataFactory_SL.createOpportunity(accountId, false);
    oldOpp.Id = oppId;
    Opportunity updatedOpp = DataFactory_SL.createOpportunity(accountId, false);
    updatedOpp.Id = oppId;
    updatedOpp.Deal_Reg_Status__c = 'Approved';

    fflib_SObjectDomain.Test.Database.onUpdate(
      new List<Opportunity>{ updatedOpp },
      new Map<Id, SObject>{ oldOpp.Id => oldOpp }
    );
    fflib_SObjectDomain.triggerHandler(Opportunities_SL.class);

    System.assertEquals(updatedOpp.Deal_Reg_Approved_Date__c, System.Today(), 'Approved Date is not correct!');
  }

  @isTest
  private static void setRTOnInsert() {
    Id accountId = fflib_IDGenerator.generate(Account.SObjectType);
    Opportunity opp = DataFactory_SL.createOpportunity(accountId, false);
    opp.Deal_Reg_Status__c = 'Approved';
    opp.RecordTypeId = OpportunityMetadata_SL.DealRegistrationRecordType;

    fflib_SObjectDomain.Test.Database.onInsert(new List<Opportunity>{ opp });
    fflib_SObjectDomain.triggerHandler(Opportunities_SL.class);

    System.assertEquals(opp.Converted_from_Deal_Reg__c, true, 'Opp Converted from Deal Reg is incorrect');
    System.assertEquals(opp.RecordTypeId, OpportunityMetadata_SL.CPQDefaultRecordType, 'Opp Record Type is incorrect');
    System.assertEquals(opp.StageName, 'Discovery', 'Opp StageName is incorrect');
  }
}