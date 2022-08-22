@IsTest(isParallel=false)
public with sharing class SubEndBeforeContractFunctionTest_SL {
  @testSetup
  static void setup() {
    SBQQ.TriggerControl.disable();

    // Create Account
    Account testAccount = DataFactory_CM.createAccount('Customer', true);
    // Create  Opportunity
    Opportunity testOpportunity = DataFactory_SL.createOpportunity(testAccount.Id, true);

    // Create the order int feature toggle custom setting
    insert new CPQ_Order_Integration_Features__c(SetupOwnerId = UserInfo.getOrganizationId(), Active__c = true);

    Product2 testProduct = DataFactory_SL.createProduct(true);

    // Create Amendment Quote
    SBQQ__Quote__c testQuote = DataFactory_SL.createCPQQuote(testAccount.Id, testOpportunity.Id, false);
    testQuote.SBQQ__Primary__c = true;
    testQuote.SBQQ__StartDate__c = System.today();
    testQuote.SBQQ__EndDate__c = System.today().addYears(1);
    insert testQuote;

    // Create Amendment Quoteline
    SBQQ__QuoteLine__c testQuoteLine = DataFactory_SL.createCPQQuoteLine(testProduct.Id, testQuote.Id, false);
    testQuoteLine.SBQQ__ProrateMultiplier__c = 1;
    testQuoteLine.SBQQ__EndDate__c = System.today().addYears(1);
    insert testQuoteLine;

    Contract testContract = DataFactory_SL.createContract(testAccount.Id, false);
    testContract.StartDate = System.today().addYears(1);
    testContract.EndDate = System.today().addYears(2);
    insert testContract;
  }

  @IsTest
  private static void earlyEndingSubsTest() {
    Contract testContract = [SELECT Id FROM Contract LIMIT 1];
    testContract.EndDate = System.today().addYears(2);
    update testContract;

    SBQQ__QuoteLine__c testQuoteLine = [SELECT Id FROM SBQQ__QuoteLine__c LIMIT 1];
    Product2 testProduct = [SELECT Id FROM Product2 LIMIT 1];

    Test.startTest();
    SBQQ__Subscription__c testSubscription = new SBQQ__Subscription__c();
    testSubscription.SBQQ__Contract__c = testContract.Id;
    testSubscription.SBQQ__QuoteLine__c = testQuoteLine.Id;
    testSubscription.SBQQ__Product__c = testProduct.Id;
    testSubscription.SBQQ__Quantity__c = 1;
    insert testSubscription;

    SBQQ__Subscription__c subToTest = [
      SELECT Id, SBQQ__RenewalQuantity__c
      FROM SBQQ__Subscription__c
      WHERE Id = :testSubscription.Id
    ];
    System.assertEquals(0, subToTest.SBQQ__RenewalQuantity__c, 'Subscription renewal quantity should be 0');

    testSubscription.SBQQ__QuoteLine__c = null;
    update testSubscription;

    Test.stopTest();
  }
}