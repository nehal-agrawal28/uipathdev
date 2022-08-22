@IsTest(IsParallel=false)
public with sharing class CaseValidateRiskFunctionTest_SL {
  @TestSetup
  static void makeData() {
    Account account = DataFactory_CM.createAccount(Constants.ACCOUNT_RECORD_TYPE_1, true);
    Opportunity opportunity = DataFactory_SL.createOpportunity(account.Id, true);
    SBQQ__Quote__c quote = DataFactory_SL.createCPQQuote(account.Id, opportunity.Id, false);
    quote.Bill_To_Account__c = account.Id;
    quote.SBQQ__Primary__c = true;
    insert quote;
  }
  @IsTest
  static void onFinanceReview_checkForRiskCategory() {
    Id recordId = fflib_IDGenerator.generate(Case.getSObjectType());
    SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
    Case existingRecord = DataFactory_SL.createCase(CaseMetadata_SL.FinanceRequestRecordType, false);
    existingRecord.Id = recordId;

    Case record = DataFactory_SL.createCase(CaseMetadata_SL.FinanceRequestRecordType, false);
    record.Id = recordId;
    record.Status = CaseMetadata_SL.FINANCE_REVIEW;
    record.Primary_Quote__c = quote.Id;

    Test.startTest();
    fflib_SObjectDomain.Test.Database.onUpdate(
      new List<Case>{ record },
      new Map<Id, SObject>{ recordId => existingRecord }
    );
    fflib_SObjectDomain.triggerHandler(Cases_SL.class);

    System.assertNotEquals(null, record.getErrors(), 'No validation error thrown.');

    Test.stopTest();
  }
}