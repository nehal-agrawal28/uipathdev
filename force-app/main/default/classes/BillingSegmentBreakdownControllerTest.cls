/**
 * @author Gen Estrada @ Slalom
 * @date 20/10/2020
 * @description Test Class for BillingSegmentBreakdownController
 */
@isTest
private with sharing class BillingSegmentBreakdownControllerTest {
  @testSetup
  static void setup() {
    // Create Account
    Account testAccount = DataFactory_CM.createAccount('Customer', true);
    // Create  Opportunity
    Opportunity testOpportunity = DataFactory_SL.createOpportunity(testAccount.Id, true);

    // Create the order int feature toggle custom setting
    insert new CPQ_Order_Integration_Features__c(SetupOwnerId = UserInfo.getOrganizationId(), Active__c = true);
  }

  @isTest
  static void testSingleMYDQuote() {
    // Query Account
    List<Account> testAccount = [SELECT Id FROM Account LIMIT 1];
    // Query Opportunity
    List<Opportunity> testOpportunity = [SELECT Id FROM Opportunity LIMIT 1];
    // Create Product
    Product2 testProduct = DataFactory_SL.createProduct(true);

    Test.startTest();
    // Create Quote
    SBQQ__Quote__c testQuote = DataFactory_SL.createCPQQuote(testAccount.get(0).Id, testOpportunity.get(0).Id, false);
    testQuote.SBQQ__Primary__c = true;
    testQuote.SBQQ__StartDate__c = System.today();
    testQuote.SBQQ__EndDate__c = System.today().addYears(3);
    testQuote.SBQQ__BillingFrequency__c = Constants.QUOTE_BILLING_FREQ_ANNUAL;
    testQuote.SBQQ__Type__c = Constants.QUOTE_TYPE_NEW;
    insert testQuote;

    // Create Quoteline
    SBQQ__QuoteLine__c testQuoteLine = DataFactory_SL.createCPQQuoteLine(testProduct.Id, testQuote.Id, true);
    // Create controller
    BillingSegmentWrapper returnedWrapper = BillingSegmentBreakdownController.getSegmentationData(testQuote.Id);
    Test.stopTest();

    System.assertNotEquals(null, returnedWrapper, 'Wrapper is null.');
    System.assertEquals(null, returnedWrapper.errorMessage, 'Error message is being returned to LWC.');
    System.assertEquals(3, returnedWrapper.billingSegments.size(), 'Billing Segment size is incorrect.');
    System.assertEquals(1, returnedWrapper.qlSegmentsList.size(), 'Quoteline Billing Segments size is incorrect.');
  }

  @isTest
  static void testNonAnnualQuote() {
    // Query Account
    List<Account> testAccount = [SELECT Id FROM Account LIMIT 1];
    // Query Opportunity
    List<Opportunity> testOpportunity = [SELECT Id FROM Opportunity LIMIT 1];
    // Create Product
    Product2 testProduct = DataFactory_SL.createProduct(true);

    Test.startTest();
    // Create Quote
    SBQQ__Quote__c testQuote = DataFactory_SL.createCPQQuote(testAccount.get(0).Id, testOpportunity.get(0).Id, false);
    testQuote.SBQQ__Primary__c = true;
    testQuote.SBQQ__StartDate__c = System.today();
    testQuote.SBQQ__EndDate__c = System.today().addYears(3);
    testQuote.SBQQ__BillingFrequency__c = Constants.QUOTE_BILLING_FREQ_UPFRONT;
    testQuote.SBQQ__Type__c = Constants.QUOTE_TYPE_NEW;
    insert testQuote;

    // Create Quoteline
    SBQQ__QuoteLine__c testQuoteLine = DataFactory_SL.createCPQQuoteLine(testProduct.Id, testQuote.Id, true);
    // Create controller
    BillingSegmentWrapper returnedWrapper = BillingSegmentBreakdownController.getSegmentationData(testQuote.Id);
    Test.stopTest();

    System.assertNotEquals(null, returnedWrapper, 'Wrapper is null.');
    System.assertEquals(
      Label.NonAnnualQuoteErrorMessage,
      returnedWrapper.errorMessage,
      'Incorrect error message is not returned to LWC.'
    );
    System.assertEquals(0, returnedWrapper.billingSegments.size(), 'Billing Segment size is incorrect.');
    System.assertEquals(0, returnedWrapper.qlSegmentsList.size(), 'Quoteline Billing Segments size is incorrect.');
  }

  @isTest
  static void testAmendmentQuote() {
    // Query Account
    List<Account> testAccount = [SELECT Id FROM Account LIMIT 1];
    // Query Opportunity
    List<Opportunity> testOpportunity = [SELECT Id FROM Opportunity LIMIT 1];
    // Create Product
    Product2 testProduct = DataFactory_SL.createProduct(true);

    // Create Original Quote
    SBQQ__Quote__c testQuote = DataFactory_SL.createCPQQuote(testAccount.get(0).Id, testOpportunity.get(0).Id, false);
    testQuote.SBQQ__Primary__c = true;
    testQuote.SBQQ__StartDate__c = System.today();
    testQuote.SBQQ__EndDate__c = System.today().addYears(2);
    testQuote.SBQQ__BillingFrequency__c = Constants.QUOTE_BILLING_FREQ_ANNUAL;
    testQuote.SBQQ__Type__c = Constants.QUOTE_TYPE_NEW;
    insert testQuote;

    // Create Quoteline
    SBQQ__QuoteLine__c testQuoteLine = DataFactory_SL.createCPQQuoteLine(testProduct.Id, testQuote.Id, false);
    testQuoteLine.SBQQ__ProrateMultiplier__c = 2;
    insert testQuoteLine;

    // Update Quote to Approved
    testQuote.SBQQ__EndDate__c = System.today().addYears(3);
    update testQuote;
    testQuote.SBQQ__Status__c = Constants.QUOTE_STATUS_3;
    update testQuote;

    // Re-query Quote to get First_Anniversary_Date__c
    testQuote = [
      SELECT Id, First_Anniversary_Date__c, SBQQ__StartDate__c, SBQQ__EndDate__c
      FROM SBQQ__Quote__c
      WHERE Id = :testQuote.Id
      LIMIT 1
    ];

    // Create Contract
    Contract testContract = DataFactory_SL.createContract(testAccount.get(0).Id, false);
    testContract.StartDate = System.today().addYears(1);
    testContract.EndDate = System.today().addYears(2);
    testContract.First_Anniversary_Date__c = testQuote.First_Anniversary_Date__c;
    insert testContract;

    Test.startTest();
    // Create Amendment Opportunity
    Opportunity testAmendmentOpportunity = DataFactory_SL.createOpportunity(testAccount.get(0).Id, false);
    testAmendmentOpportunity.SBQQ__AmendedContract__c = testContract.Id;
    insert testAmendmentOpportunity;

    // Create Amendment Quote
    SBQQ__Quote__c testAmendmentQuote = DataFactory_SL.createCPQQuote(
      testAccount.get(0).Id,
      testAmendmentOpportunity.Id,
      false
    );
    testAmendmentQuote.SBQQ__Primary__c = true;
    testAmendmentQuote.SBQQ__StartDate__c = System.today();
    testAmendmentQuote.SBQQ__EndDate__c = System.today().addYears(3);
    testAmendmentQuote.SBQQ__BillingFrequency__c = Constants.QUOTE_BILLING_FREQ_ANNUAL;
    testAmendmentQuote.SBQQ__Type__c = Constants.QUOTE_TYPE_AMENDMENT;
    testAmendmentQuote.SBQQ__MasterContract__c = testContract.Id;
    testAmendmentQuote.SBQQ__OriginalQuote__c = testQuote.Id;
    testAmendmentQuote.First_Anniversary_Date__c = testQuote.First_Anniversary_Date__c;
    insert testAmendmentQuote;

    // Create Amendment Quoteline
    SBQQ__QuoteLine__c testAmendmentQuoteLine = DataFactory_SL.createCPQQuoteLine(
      testProduct.Id,
      testAmendmentQuote.Id,
      false
    );
    testAmendmentQuoteLine.SBQQ__ProrateMultiplier__c = 1;
    insert testAmendmentQuoteLine;

    SBQQ__Subscription__c testSubscription = new SBQQ__Subscription__c();
    testSubscription.SBQQ__Contract__c = testContract.Id;
    testSubscription.SBQQ__Product__c = testProduct.Id;
    testSubscription.SBQQ__Quantity__c = 1;
    testSubscription.SBQQ__SubscriptionEndDate__c = System.today().addYears(3);
    insert testSubscription;

    // Create controller
    BillingSegmentWrapper returnedWrapper = BillingSegmentBreakdownController.getSegmentationData(
      testAmendmentQuote.Id
    );
    Test.stopTest();

    System.assertNotEquals(null, returnedWrapper, 'Wrapper is null.');
    System.assertEquals(null, returnedWrapper.errorMessage, 'Error message is being returned to LWC.');
    System.assertEquals(2, returnedWrapper.billingSegments.size(), 'Billing Segment size is incorrect.');
    System.assertEquals(1, returnedWrapper.qlSegmentsList.size(), 'Quoteline Billing Segments size is incorrect.');
  }

  @isTest
  static void testMYDQuoteLinesBulk() {
    // Query Account
    List<Account> testAccount = [SELECT Id FROM Account LIMIT 1];
    // Query Opportunity
    List<Opportunity> testOpportunity = [SELECT Id FROM Opportunity LIMIT 1];
    // Create Product
    Product2 testProduct = DataFactory_SL.createProduct(true);

    Test.startTest();
    // Create Quote
    SBQQ__Quote__c testQuote = DataFactory_SL.createCPQQuote(testAccount.get(0).Id, testOpportunity.get(0).Id, false);
    testQuote.SBQQ__Primary__c = true;
    testQuote.SBQQ__StartDate__c = System.today();
    testQuote.SBQQ__EndDate__c = System.today().addYears(10);
    testQuote.SBQQ__BillingFrequency__c = Constants.QUOTE_BILLING_FREQ_ANNUAL;
    testQuote.SBQQ__Type__c = Constants.QUOTE_TYPE_NEW;
    insert testQuote;

    List<SBQQ__QuoteLine__c> quoteLines = new List<SBQQ__QuoteLine__c>();

    // for(Integer i = 0; i < 10; i++){
    quoteLines.add(DataFactory_SL.createCPQQuoteLine(testProduct.Id, testQuote.Id, false));
    //}

    insert quoteLines;
    // Create controller
    BillingSegmentWrapper returnedWrapper = BillingSegmentBreakdownController.getSegmentationData(testQuote.Id);
    Test.stopTest();

    System.assertNotEquals(null, returnedWrapper, 'Wrapper is null.');
    System.assertEquals(null, returnedWrapper.errorMessage, 'Error message is being returned to LWC.');
    //System.assertEquals(10, returnedWrapper.billingSegments.size(), 'Billing Segment size is incorrect.');
    //System.assertEquals(10, returnedWrapper.qlSegmentsList.size(), 'Quoteline Billing Segments size is incorrect.');
  }

  @isTest
  static void testNoLineItems() {
    // Query Account
    List<Account> testAccount = [SELECT Id FROM Account LIMIT 1];
    // Query Opportunity
    List<Opportunity> testOpportunity = [SELECT Id FROM Opportunity LIMIT 1];
    // Create Product
    Product2 testProduct = DataFactory_SL.createProduct(true);

    Test.startTest();
    // Create Quote
    SBQQ__Quote__c testQuote = DataFactory_SL.createCPQQuote(testAccount.get(0).Id, testOpportunity.get(0).Id, false);
    testQuote.SBQQ__Primary__c = true;
    testQuote.SBQQ__StartDate__c = System.today();
    testQuote.SBQQ__EndDate__c = System.today().addYears(3);
    testQuote.SBQQ__BillingFrequency__c = Constants.QUOTE_BILLING_FREQ_ANNUAL;
    testQuote.SBQQ__Type__c = Constants.QUOTE_TYPE_NEW;
    insert testQuote;

    // Create controller
    BillingSegmentWrapper returnedWrapper = BillingSegmentBreakdownController.getSegmentationData(testQuote.Id);
    Test.stopTest();

    System.assertNotEquals(null, returnedWrapper, 'Wrapper is null.');
    System.assertNotEquals(null, returnedWrapper.errorMessage, 'Error message is being returned to LWC.');
    System.assertEquals(0, returnedWrapper.billingSegments.size(), 'Billing Segment size is incorrect.');
    System.assertEquals(0, returnedWrapper.qlSegmentsList.size(), 'Quoteline Billing Segments size is incorrect.');
  }
}