@isTest
public with sharing class OppSetClsDateCnvrtFrmLeadFunctionTest_SL {
  @testSetup
  static void createSetupData() {
    Id customerRT = AccountMetadata.getAccountRecordTypeId('Customer');
    Account testAccount = DataFactory_CM.createAccount(customerRT, true);
  }

  @isTest
  private static void setCloseDateTo6MonthsTest() {
    Account testAccount = [SELECT id FROM Account LIMIT 1];
    Id oppId = fflib_IDGenerator.generate(Opportunity.SObjectType);
    Opportunity opp = DataFactory_SL.createOpportunity(testAccount.id, false);
    opp.Id = oppId;
    opp.Converted_from_Lead__c = true;
    fflib_SObjectDomain.Test.Database.onInsert(new List<Opportunity>{ opp });
    fflib_SObjectDomain.triggerHandler(Opportunities_SL.class);

    System.assertEquals(Date.today().addDays(180), opp.CloseDate, 'Close date should be set to 6 months from today.');
  }

  @isTest
  private static void clloseDateNotTo6MonthsTest() {
    Account testAccount = [SELECT id FROM Account LIMIT 1];
    Id oppId = fflib_IDGenerator.generate(Opportunity.SObjectType);
    Opportunity opp = DataFactory_SL.createOpportunity(testAccount.id, false);
    opp.Id = oppId;
    opp.Converted_from_Lead__c = false;
    fflib_SObjectDomain.Test.Database.onInsert(new List<Opportunity>{ opp });
    fflib_SObjectDomain.triggerHandler(Opportunities_SL.class);

    System.assert(opp.CloseDate != Date.today().addDays(180));
  }
}