@IsTest(isParallel=false)
public class QuoteBudgetQuoteFunctionTest_SL {
  @testSetup
  private static void setup() {
    Account testAccount = DataFactory_CM.createAccount('Customer', true);
    Opportunity testOpportunity = DataFactory_SL.createOpportunity(testAccount.Id, true);
    SBQQ__Quote__c testQuote = DataFactory_SL.createCPQQuote(testAccount.Id, testOpportunity.Id, false);
    testQuote.Forecast_Quote__c = true;
    testQuote.SBQQ__TargetCustomerAmount__c = 10000;
    insert testQuote;
  }

  @IsTest
  private static void removeTargetCustomerAmountTest() {
    Test.startTest();
    SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c WHERE Forecast_Quote__c = TRUE LIMIT 1];
    quote.SBQQ__LastCalculatedOn__c = System.Now();
    update quote;

    quote = [SELECT Id, SBQQ__TargetCustomerAmount__c FROM SBQQ__Quote__c WHERE Id = :quote.Id];
    System.assertEquals(null, quote.SBQQ__TargetCustomerAmount__c, 'Target Customer Amount was not cleared');
    Test.stopTest();
  }

  @IsTest
  private static void prefixDocumentRefTest() {
    Test.startTest();
    SBQQ__Quote__c quote = [SELECT Id, Document_Ref__c FROM SBQQ__Quote__c WHERE Forecast_Quote__c = TRUE LIMIT 1];
    quote.Document_Ref__c = 'Q-10000';
    update quote;

    quote = [SELECT Id, Document_Ref__c FROM SBQQ__Quote__c WHERE Id = :quote.Id];
    System.assertEquals(
      QuoteBudgetQuoteFunction_SL.PREFIX_FORECAST_QUOTE + 'Q-10000',
      quote.Document_Ref__c,
      'Document Ref is not correct : ' + quote.Document_Ref__c
    );
    Test.stopTest();
  }
}