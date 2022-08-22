@isTest
public with sharing class OppBDRRecordTypeFunctionTest_SL {
  private static String recordTypeIdBDR = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
    .get('BDR')
    .getRecordTypeId();

  @isTest
  private static void deriveAcceptedBRDRecordTypeTest() {
    Id accountId = fflib_IDGenerator.generate(Account.SObjectType);
    Id oppId = fflib_IDGenerator.generate(Opportunity.SObjectType);
    Opportunity oldOpp = DataFactory_SL.createOpportunity(accountId, false);
    oldOpp.Id = oppId;
    oldOpp.RecordTypeId = recordTypeIdBDR;
    Opportunity updatedOpp = DataFactory_SL.createOpportunity(accountId, false);
    updatedOpp.Id = oppId;
    updatedOpp.RecordTypeId = recordTypeIdBDR;
    updatedOpp.Amount = 10000;
    updatedOpp.StageName = OppBDRRecordTypeFunction_SL.BDR_ACCEPTED_STAGE;

    fflib_SObjectDomain.Test.Database.onUpdate(
      new List<Opportunity>{ updatedOpp },
      new Map<Id, SObject>{ oldOpp.Id => oldOpp }
    );
    fflib_SObjectDomain.triggerHandler(Opportunities_SL.class);

    System.assertEquals(
      updatedOpp.RecordTypeId,
      OpportunityMetadata_SL.CPQDefaultRecordType,
      'BDR Opp Record Type is not changed to CPQ Default'
    );
  }

  @isTest
  private static void deriveBRDRecordTypeTest() {
    User u = DataFactory_CM.createUser('TestBDR', 'User', 'System Administrator', false);
    u.BDR__c = true;
    insert u;

    System.runAs(u) {
      Id accountId = fflib_IDGenerator.generate(Account.SObjectType);
      Opportunity opp = DataFactory_SL.createOpportunity(accountId, false);

      fflib_SObjectDomain.Test.Database.onInsert(new List<Opportunity>{ opp });
      fflib_SObjectDomain.triggerHandler(Opportunities_SL.class);

      System.assertEquals(opp.RecordTypeId, recordTypeIdBDR, 'Opp is not of type BDR');
    }
  }
}