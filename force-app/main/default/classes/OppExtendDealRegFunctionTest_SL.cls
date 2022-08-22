@isTest(isParallel=false)
private class OppExtendDealRegFunctionTest_SL {
  @isTest
  private static void extendExpireDateOnUpdate() {
    Id accountId = fflib_IDGenerator.generate(Account.SObjectType);
    Id oppId = fflib_IDGenerator.generate(Opportunity.SObjectType);
    Opportunity oldOpp = DataFactory_SL.createOpportunity(accountId, false);
    oldOpp.Id = oppId;
    Opportunity updatedOpp = DataFactory_SL.createOpportunity(accountId, false);
    updatedOpp.Id = oppId;
    updatedOpp.Converted_from_Deal_Reg__c = true;
    updatedOpp.Extend_Deal_Reg_Expire_Date__c = true;
    updatedOpp.Deal_Reg_Expire_Date_new__c = System.Today();

    fflib_SObjectDomain.Test.Database.onUpdate(
      new List<Opportunity>{ updatedOpp },
      new Map<Id, SObject>{ oldOpp.Id => oldOpp }
    );
    fflib_SObjectDomain.triggerHandler(Opportunities_SL.class);

    System.assertEquals(updatedOpp.Deal_Reg_Expire_Date_new__c, System.Today().addDays(90), 'Expire Date is incorrect');
  }

  @isTest
  private static void extendExpireDateOnInsert() {
    Id accountId = fflib_IDGenerator.generate(Account.SObjectType);
    Opportunity opp = DataFactory_SL.createOpportunity(accountId, false);
    opp.Converted_from_Deal_Reg__c = true;
    opp.Extend_Deal_Reg_Expire_Date__c = true;
    opp.Deal_Reg_Expire_Date_new__c = System.Today();

    fflib_SObjectDomain.Test.Database.onInsert(new List<Opportunity>{ opp });
    fflib_SObjectDomain.triggerHandler(Opportunities_SL.class);

    System.assertEquals(opp.Deal_Reg_Expire_Date_new__c, System.Today().addDays(90), 'Expire Date is incorrect');
  }
}