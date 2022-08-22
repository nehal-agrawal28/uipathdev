@isTest
public with sharing class CaseNonStandardTrialQueueableTest_SL {
  @TestSetup
  static void setup() {
    Account testAccount = DataFactory_CM.createAccount('Customer', true);
    DataFactory_SL.createOpportunity(testAccount.Id, true);
  }

  @IsTest
  private static void approvalNonStandardTrialTest() {
    Account acc = [SELECT Id FROM Account LIMIT 1];
    Id caseId = fflib_IDGenerator.generate(Case.SObjectType);
    Id recordTypeId = CaseMetadata_SL.DealHubRequestRecordType;

    Case newCase = DataFactory_SL.createCase(recordTypeId, false);
    newCase.Id = caseId;
    newCase.Status = CaseMetadata_SL.IN_PROGRESS;
    newCase.Request_Type__c = CaseNonStandardTrialQueueable_SL.TRIAL_REQUEST_TYPE;
    newCase.AccountId = acc.Id;

    fflib_SObjectDomain.Test.Database.onInsert(new List<Case>{ newCase });
    fflib_SObjectDomain.triggerHandler(Cases_SL.class);

    CaseNonStandardTrialQueueable_SL queueable = new CaseNonStandardTrialQueueable_SL(new List<Case>{ newCase });
    queueable.execute(null);
  }
}