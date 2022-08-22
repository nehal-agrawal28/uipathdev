@isTest
private class QuoteExtControllerTests {
  // TODO add proper tests
  testMethod static void testSubmit() {
    SBQQ__Quote__c quote = new SBQQ__Quote__c();
    insert quote;

    Test.startTest();
    QuoteExtController con = new QuoteExtController(new ApexPages.StandardController(quote));

    try {
      con.onSubmit();
      quote = [SELECT ApprovalStatus__c FROM SBQQ__Quote__c WHERE Id = :quote.Id LIMIT 1];
    } catch (Exception e) {
    }
    Test.stopTest();
  }

  testMethod static void testRecall() {
    SBQQ__Quote__c quote = new SBQQ__Quote__c();
    insert quote;

    Test.startTest();
    try {
      QuoteExtController con = new QuoteExtController(new ApexPages.StandardController(quote));
      con.onRecall();
      con.onCancel();
      SBQQ__Quote__c quote1 = con.quote;
      quote = [SELECT ApprovalStatus__c FROM SBQQ__Quote__c WHERE Id = :quote.Id LIMIT 1];
    } catch (Exception e) {
    }
    Test.stopTest();
  }
}