@IsTest
private class ApprovalQuoteDetailsControllerTest {
  @TestSetup
  private static void makeData() {
    Account testAccount = DataFactory_CM.createAccount('Customer', true);
    Opportunity testOpportunity = DataFactory_SL.createOpportunity(testAccount.Id, true);
    SBQQ__Quote__c testQuote = DataFactory_SL.createCPQQuote(testAccount.Id, testOpportunity.Id, true);
    Product2 testProduct = DataFactory_SL.createProduct(true);
    DataFactory_SL.createCPQQuoteLine(testProduct.Id, testQuote.Id, true);
  }

  @IsTest
  private static void approvalQuoteDetailsTest() {
    SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];

    Test.startTest();
    ApprovalQuoteDetailsController ctrl = new ApprovalQuoteDetailsController();
    ctrl.qId = quote.Id;
    System.assertEquals(true, ctrl.products.size() > 0, 'Product wrapper was empty');
    Test.stopTest();
  }
}