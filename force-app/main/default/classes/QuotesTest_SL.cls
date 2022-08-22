@IsTest(isParallel=false)
private class QuotesTest_SL {
  @isTest
  private static void testDeleteChildSegments() {
    Account testAccount = DataFactory_CM.createAccount('Customer', true);
    Opportunity testOpportunity = DataFactory_SL.createOpportunity(testAccount.Id, true);
    SBQQ__Quote__c testQuote = DataFactory_SL.createCPQQuote(testAccount.Id, testOpportunity.Id, true);
    Billing_Segment__c testBillingSeg = DataFactory_SL.createBillingSegment(testQuote.id, 1, 20, true);

    Test.startTest();
    delete testQuote;
    Test.stopTest();

    System.Assert([SELECT id FROM Billing_Segment__c].isEmpty());
  }
}