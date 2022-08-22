@IsTest
private class CPQConsolidateRenewalsCleanupTest {
  private static Contract masterContract { get; set; }
  private static Contract otherContract { get; set; }

  private static void createData() {
    Account testAccount = DataFactory_CM.createAccount('Customer', true);
    Opportunity testOpportunity = DataFactory_SL.createOpportunity(testAccount.Id, true);
    Opportunity testOpportunity2 = DataFactory_SL.createOpportunity(testAccount.Id, true);

    Contract contract = new Contract(
      StartDate = Date.today() - 300,
      ContractTerm = 12,
      Status = 'Draft',
      AccountId = testAccount.Id,
      SBQQ__RenewalOpportunity__c = testOpportunity.Id
    );
    insert contract;
    masterContract = contract;

    Contract contract2 = new Contract(
      StartDate = Date.today() - 300,
      ContractTerm = 12,
      Status = 'Draft',
      AccountId = testAccount.Id,
      SBQQ__RenewalOpportunity__c = testOpportunity2.Id
    );
    insert contract2;
    otherContract = contract2;
  }

  @IsTest
  private static void cleanupExtraRenewalTest() {
    createData();

    Test.startTest();
    RestRequest req = new RestRequest();
    RestResponse res = new RestResponse();
    req.requestURI = '/services/apexrest/consolidate/renewals/cleanup';
    req.httpMethod = 'GET';
    req.addParameter('masterid', masterContract.Id);
    req.addParameter('conids', masterContract.Id + ',' + otherContract.Id);
    RestContext.request = req;
    RestContext.response = res;

    CPQConsolidateRenewalsCleanup.cleanupExtraRenewals();
    Test.stopTest();

    List<Opportunity> oppList = [SELECT Id FROM Opportunity WHERE Id = :otherContract.SBQQ__RenewalOpportunity__c];
    System.assertEquals(oppList.size(), 0, 'Extra opportunity was not deleted');
  }
}