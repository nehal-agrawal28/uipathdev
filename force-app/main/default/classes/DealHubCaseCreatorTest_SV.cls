@IsTest
public with sharing class DealHubCaseCreatorTest_SV {
  @IsTest
  static void testSubmitCase() {
    Account account = DataFactory_CM.createAccount('Customer', true);
    Case caseData = DataFactory_SV.createIncidentCase(false);
    caseData.AccountId = account.Id;
    caseData.SuppliedName = 'James Twight';
    Id caseId = DealHubCaseCreator_SV.submitCase(caseData);
    System.assertNotEquals(null, caseId, 'Case not created');
  }
}