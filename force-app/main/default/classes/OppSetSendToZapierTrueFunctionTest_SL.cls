@isTest
public with sharing class OppSetSendToZapierTrueFunctionTest_SL {
  @TestSetup
  static void createSetupData() {
    Id customerRT = AccountMetadata.getAccountRecordTypeId('Customer');
    Account testAccount = DataFactory_CM.createAccount(customerRT, true);
  }

  @isTest
  private static void setSendToZapierToTrueTest() {
    Account testAccount = [SELECT id FROM Account LIMIT 1];
    Id oppId = fflib_IDGenerator.generate(Opportunity.SObjectType);

    Opportunity oldOpp = DataFactory_SL.createOpportunity(testAccount.id, false);
    oldOpp.id = oppId;

    Opportunity updatedOpp = DataFactory_SL.createOpportunity(testAccount.id, false);
    updatedOpp.id = oppId;
    updatedOpp.StageName = OpportunityMetadata_SL.CLOSED_WON_BOOKED;

    fflib_SObjectDomain.Test.Database.onUpdate(
      new List<Opportunity>{ updatedOpp },
      new Map<Id, SObject>{ oldOpp.Id => oldOpp }
    );

    fflib_SObjectDomain.triggerHandler(Opportunities_SL.class);
    System.assertEquals(true, updatedOpp.Send_to_Zapier__c, 'Send to zapier should be true.');
  }

  @isTest
  private static void sendToZapierIsNotSetToTrueTest() {
    Account testAccount = [SELECT id FROM Account LIMIT 1];
    Id oppId = fflib_IDGenerator.generate(Opportunity.SObjectType);

    Opportunity oldOpp = DataFactory_SL.createOpportunity(testAccount.id, false);
    oldOpp.id = oppId;

    Opportunity updatedOpp = DataFactory_SL.createOpportunity(testAccount.id, false);
    updatedOpp.id = oppId;

    fflib_SObjectDomain.Test.Database.onUpdate(
      new List<Opportunity>{ updatedOpp },
      new Map<Id, SObject>{ oldOpp.Id => oldOpp }
    );

    fflib_SObjectDomain.triggerHandler(Opportunities_SL.class);
    System.assertEquals(false, updatedOpp.Send_to_Zapier__c, 'Send to zapier should not be true.');
  }
}