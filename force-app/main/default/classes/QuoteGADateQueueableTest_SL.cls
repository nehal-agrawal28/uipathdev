@IsTest(isParallel=false)
public class QuoteGADateQueueableTest_SL {
  @testSetup
  private static void setup() {
    Account testAccount = DataFactory_CM.createAccount('Customer', true);
    Opportunity testOpportunity = DataFactory_SL.createOpportunity(testAccount.Id, true);
    SBQQ__Quote__c testQuote = DataFactory_SL.createCPQQuote(testAccount.Id, testOpportunity.Id, false);
    testQuote.SBQQ__StartDate__c = System.Date.today().addDays(7);
    testQuote.Max_GA_Date__c = System.Date.today();
    insert testQuote;
  }

  @IsTest
  private static void testGADateUpdate() {
    SBQQ__Quote__c quote = [SELECT Id, SBQQ__Opportunity2__c, Max_GA_Date__c FROM SBQQ__Quote__c LIMIT 1];
    quote.Max_GA_Date__c = System.Date.today().addDays(1);
    update quote;

    Test.startTest();
    new QuoteGADateQueueable_SL(new List<SBQQ__Quote__c>{ quote }).work();
    Test.stopTest();

    Opportunity opp = [SELECT Id, Max_GA_Date__c, SBQQ__PrimaryQuote__r.Max_GA_Date__c FROM Opportunity LIMIT 1];
    System.assertEquals(opp.Max_GA_Date__c, opp.SBQQ__PrimaryQuote__r.Max_GA_Date__c, 'Max GA Date is not correct');
  }
}