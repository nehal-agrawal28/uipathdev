@IsTest
public with sharing class QuoteSubmitForApprovalControllerTest {
  @TestSetup
  static void makeData() {
    SBQQ.TriggerControl.disable();
    Account account = DataFactory_CM.createAccount('Customer', true);
    Opportunity opp = DataFactory_SL.createOpportunity(account.Id, true);
    SBQQ__Quote__c quote = DataFactory_SL.createCPQQuote(account.Id, opp.Id, false);
    quote.General_Comments__c = 'Test Comments';
    insert quote;
  }

  @IsTest
  static void validateQuoteTest() {
    SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
    Test.startTest();
    QuoteSubmitForApprovalController.QuoteSubmitForApprovalWrapper wrapper = QuoteSubmitForApprovalController.validateQuote(
      quote.Id
    );
    System.assertEquals(true, wrapper.warnings.size() > 0);
    Test.stopTest();
  }
}