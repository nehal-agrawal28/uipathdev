@IsTest(IsParallel=false)
public with sharing class QuoteDiscountReasonsQueueableTest_SL {
  @TestSetup
  static void makeData() {
    SBQQ.TriggerControl.disable();
    Account account = DataFactory_CM.createAccount('Customer', true);
    DataFactory_SL.createOpportunity(account.Id, true);
  }

  @IsTest
  static void testUpdateDiscountReasons() {
    Account account = [SELECT Id FROM Account LIMIT 1];
    Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
    SBQQ__Quote__c quote = DataFactory_SL.createCPQQuote(account.Id, opp.Id, true);
    sbaa__Approval__c approval = new sbaa__Approval__c();
    approval.sbaa__ApprovalStep__c = 0;
    approval.sbaa__RecordField__c = 'field test';
    approval.Quote__c = quote.Id;
    insert approval;

    SBQQ__Quote__c updatedQuote = DataFactory_SL.createCPQQuote(account.Id, opp.Id, false);
    updatedQuote.id = quote.Id;
    updatedQuote.Discount_Reasons__c = 'Discount reason updated.';
    update updatedQuote;

    Test.startTest();
    new QuoteDiscountReasonsQueueable_SL(new List<SBQQ__Quote__c>{ updatedQuote }).work();
    Test.stopTest();

    sbaa__Approval__c updatedApproval = [SELECT Id, Discount_Reasons__c FROM sbaa__Approval__c LIMIT 1];
    System.assertEquals(
      updatedQuote.Discount_Reasons__c,
      updatedApproval.Discount_Reasons__c,
      'Discount Reason was not updated!'
    );
  }
}