/**
* @author Gen Estrada @ Slalom
* @date 02/1/2020
* @description Test Class for BillingSegmentationCalculation
*/
@isTest
private with sharing class BillingSegmentationCalculationTest {
    @testSetup static void setup() {
        // Create Account
        Account testAccount = DataFactory_CM.createAccount('Customer', true);
        // Create  Opportunity
        Opportunity testOpportunity = DataFactory_SL.createOpportunity(testAccount.Id, true);
        
        // Create the order int feature toggle custom setting
        insert new CPQ_Order_Integration_Features__c(SetupOwnerId = UserInfo.getOrganizationId(), Active__c = true);
    }
    
    @isTest static void testCalculateSegments() {
        // Query Account
        List<Account> testAccount = [SELECT Id FROM Account LIMIT 1];
        // Query Opportunity
        List<Opportunity> testOpportunity = [SELECT Id FROM Opportunity LIMIT 1];
        // Create Product
        Product2 testProduct = DataFactory_SL.createProduct(true);

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
        
        Test.startTest();
        	// Re-query Quote
        	List<SBQQ__Quote__c> testQuoteRequeried = [SELECT Id, Name, SBQQ__BillingFrequency__c, First_Anniversary_Date__c, SBQQ__StartDate__c, SBQQ__EndDate__c, 
                        Quote_Duration__c, SBQQ__NetAmount__c, SBQQ__Type__c, SBQQ__MasterContract__c, CurrencyIsoCode, Quote_Duration_YMD__c,
                        (SELECT Id, SBQQ__Product__r.Name, SBQQ__EffectiveStartDate__c, SBQQ__EffectiveEndDate__c, SBQQ__NetTotal__c, SBQQ__Number__c, SBQQ__Dimension__c,SBQQ__ProrateMultiplier__c, SBQQ__SubscriptionPricing__c
                        FROM SBQQ__LineItems__r ORDER BY SBQQ__Number__c ASC)
                        FROM SBQQ__Quote__c  
                        WHERE Id = :testQuote.Id];
        	
            // Create Utility class
            BillingSegmentationCalculation util = new BillingSegmentationCalculation();
        	util.calculateSegments(testQuoteRequeried.get(0), testQuoteRequeried[0].SBQQ__LineItems__r);
        Test.stopTest();
                
        System.assertNotEquals(null, util.wrapper, 'Wrapper is null.');
        System.assertEquals(null, util.wrapper.errorMessage, 'Error message is being returned to LWC.');
        System.assertEquals(3, util.wrapper.billingSegments.size(), 'Billing Segment size is incorrect.');
        System.assertEquals(1, util.wrapper.qlSegmentsList.size(), 'Quoteline Billing Segments size is incorrect.');
    }

    @isTest static void testQualifyQuotePositive() {
        // Query Account
        List<Account> testAccount = [SELECT Id FROM Account LIMIT 1];
        // Query Opportunity
        List<Opportunity> testOpportunity = [SELECT Id FROM Opportunity LIMIT 1];
        
        // Create Quote
        SBQQ__Quote__c testQuote = DataFactory_SL.createCPQQuote(testAccount.get(0).Id, testOpportunity.get(0).Id, false);
        testQuote.SBQQ__Primary__c = true;
        testQuote.SBQQ__StartDate__c = System.today();
        testQuote.SBQQ__EndDate__c = System.today().addYears(3);
        testQuote.SBQQ__BillingFrequency__c = Constants.QUOTE_BILLING_FREQ_ANNUAL;
        testQuote.SBQQ__Type__c = Constants.QUOTE_TYPE_NEW;
        insert testQuote;

        // Create Utility class
        BillingSegmentationCalculation util = new BillingSegmentationCalculation();
        
        Test.startTest();
        	Boolean qualifiedQuote = util.qualifyQuote(testQuote);
        Test.stopTest();
        
        System.assertEquals(true, qualifiedQuote, 'Quote was not qualified correctly.');
    }
    
    @isTest static void testQualifyQuoteNegative() {
        // Query Account
        List<Account> testAccount = [SELECT Id FROM Account LIMIT 1];
        // Query Opportunity
        List<Opportunity> testOpportunity = [SELECT Id FROM Opportunity LIMIT 1];
        
        // Create Quote
        SBQQ__Quote__c testQuote = DataFactory_SL.createCPQQuote(testAccount.get(0).Id, testOpportunity.get(0).Id, false);
        testQuote.SBQQ__Primary__c = true;
        testQuote.SBQQ__StartDate__c = System.today();
        testQuote.SBQQ__EndDate__c = System.today().addYears(3);
        testQuote.SBQQ__BillingFrequency__c = Constants.QUOTE_BILLING_FREQ_UPFRONT;
        testQuote.SBQQ__Type__c = Constants.QUOTE_TYPE_NEW;
        insert testQuote;

        // Create Utility class
        BillingSegmentationCalculation util = new BillingSegmentationCalculation();
        
        Test.startTest();
        	Boolean qualifiedQuote = util.qualifyQuote(testQuote);
        Test.stopTest();
        
        System.assertEquals(false, qualifiedQuote, 'Quote was qualified incorrectly.');
    }
    
    @isTest static void testQualifyQuotelinesPositive() {
        // Query Account
        List<Account> testAccount = [SELECT Id FROM Account LIMIT 1];
        // Query Opportunity
        List<Opportunity> testOpportunity = [SELECT Id FROM Opportunity LIMIT 1];
        // Create Product
        Product2 testProduct = DataFactory_SL.createProduct(true);
        
        // Create Quote
        SBQQ__Quote__c testQuote = DataFactory_SL.createCPQQuote(testAccount.get(0).Id, testOpportunity.get(0).Id, false);testQuote.SBQQ__Primary__c = true;
        testQuote.SBQQ__StartDate__c = System.today();
        testQuote.SBQQ__EndDate__c = System.today().addYears(3);
        testQuote.SBQQ__BillingFrequency__c = Constants.QUOTE_BILLING_FREQ_ANNUAL;
        testQuote.SBQQ__Type__c = Constants.QUOTE_TYPE_NEW;
        insert testQuote;
        
        // Create Quoteline
        List<SBQQ__QuoteLine__c> quoteLines = new List<SBQQ__QuoteLine__c>();
		for(Integer i = 0; i < 2; i++){
            quoteLines.add(DataFactory_SL.createCPQQuoteLine(testProduct.Id, testQuote.Id, false));
        }
        insert quoteLines;

        // Create Utility class
        BillingSegmentationCalculation util = new BillingSegmentationCalculation();
        
        Test.startTest();
        	Boolean qualifiedQuotelines = util.qualifyQuotelines(quoteLines);
        Test.stopTest();
        
        System.assertEquals(true, qualifiedQuotelines, 'Quote was not qualified correctly.');
    }
    
    // TODO
    @isTest static void testQualifyQuotelinesNegative() {
        // Create Utility class
        BillingSegmentationCalculation util = new BillingSegmentationCalculation();
        
        Test.startTest();
        	Boolean qualifiedQuotelines = util.qualifyQuotelines(null);
        Test.stopTest();
        
        System.assertEquals(false, qualifiedQuotelines, 'Quotelines was not qualified correctly.');
    }
    
    @isTest static void testEstablishDatesNewQuote() {
        // Query Account
        List<Account> testAccount = [SELECT Id FROM Account LIMIT 1];
        // Query Opportunity
        List<Opportunity> testOpportunity = [SELECT Id FROM Opportunity LIMIT 1];
        // Create Product
        Product2 testProduct = DataFactory_SL.createProduct(true);
        
        // Create Utility class
        BillingSegmentationCalculation util = new BillingSegmentationCalculation();
        
        Test.startTest();
            // Create Original Quote
            SBQQ__Quote__c testQuote = DataFactory_SL.createCPQQuote(testAccount.get(0).Id, testOpportunity.get(0).Id, false);
            testQuote.SBQQ__Primary__c = true;
            testQuote.SBQQ__StartDate__c = System.today();
            testQuote.SBQQ__EndDate__c = System.today().addYears(3);
            testQuote.SBQQ__BillingFrequency__c = Constants.QUOTE_BILLING_FREQ_ANNUAL;
            testQuote.SBQQ__Type__c = Constants.QUOTE_TYPE_NEW;
            insert testQuote;
            
            // Create Quoteline
            SBQQ__QuoteLine__c testQuoteLine = DataFactory_SL.createCPQQuoteLine(testProduct.Id, testQuote.Id, true);
            
        	util.establishDates(testQuote);
        Test.stopTest();
        
        System.assertEquals(testQuote.SBQQ__StartDate__c, util.startDate, 'Contract start date was used.');
        System.assertEquals(testQuote.SBQQ__EndDate__c, util.endDate, 'Contract end date was used.');
    }
    
    @isTest static void testEstablishDatesAmendmentQuote() {
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
        SBQQ__QuoteLine__c testQuoteLine = DataFactory_SL.createCPQQuoteLine(testProduct.Id, testQuote.Id, true);
        
        // Update Quote End Date
        testQuote.SBQQ__EndDate__c = System.today().addYears(3);
        update testQuote;
        
        // Re-query Quote to get First_Anniversary_Date__c
        testQuote = [SELECT Id, First_Anniversary_Date__c FROM SBQQ__Quote__c WHERE Id = :testQuote.Id LIMIT 1];
        System.debug('testQuote.First_Anniversary_Date__c ' + testQuote.First_Anniversary_Date__c);
        
        // Create Contract
        Contract testContract = DataFactory_SL.createContract(testAccount.get(0).Id, false);
        testContract.StartDate = System.today().addYears(1);
        testContract.EndDate = System.today().addYears(2);
        testContract.First_Anniversary_Date__c = testQuote.First_Anniversary_Date__c;
        insert testContract;
        
        // Create Utility class
        BillingSegmentationCalculation util = new BillingSegmentationCalculation();
        
        Test.startTest();
            // Create Amendment Opportunity
            Opportunity testAmendmentOpportunity = DataFactory_SL.createOpportunity(testAccount.get(0).Id, false);
        	testAmendmentOpportunity.SBQQ__AmendedContract__c = testContract.Id;
        	insert testAmendmentOpportunity;
            
        	// Create Amendment Quote
            SBQQ__Quote__c testAmendmentQuote = DataFactory_SL.createCPQQuote(testAccount.get(0).Id, testAmendmentOpportunity.Id, false);
            testAmendmentQuote.SBQQ__Primary__c = true;
            testAmendmentQuote.SBQQ__StartDate__c = System.today().addYears(1);
            testAmendmentQuote.SBQQ__EndDate__c = System.today().addYears(2);
            testAmendmentQuote.SBQQ__BillingFrequency__c = Constants.QUOTE_BILLING_FREQ_ANNUAL;
            testAmendmentQuote.SBQQ__Type__c = Constants.QUOTE_TYPE_AMENDMENT;
            testAmendmentQuote.SBQQ__MasterContract__c = testContract.Id;
        	testAmendmentQuote.SBQQ__OriginalQuote__c = testQuote.Id;
            insert testAmendmentQuote;
        
        	util.establishDates(testAmendmentQuote);
        Test.stopTest();
        
        System.assertEquals(testContract.StartDate, util.startDate, 'Contract start date was not used.');
        System.assertEquals(testContract.EndDate, util.endDate, 'Contract end date was not used.');
    }
    
    @isTest static void testBuildSegment() {
        // Query Account
        List<Account> testAccount = [SELECT Id FROM Account LIMIT 1];
        // Query Opportunity
        List<Opportunity> testOpportunity = [SELECT Id FROM Opportunity LIMIT 1];
        // Create Product
        Product2 testProduct = DataFactory_SL.createProduct(true);
        
        // Create Quote
        SBQQ__Quote__c testQuote = DataFactory_SL.createCPQQuote(testAccount.get(0).Id, testOpportunity.get(0).Id, false);
        testQuote.SBQQ__Primary__c = true;
        testQuote.SBQQ__StartDate__c = System.today();
        testQuote.SBQQ__EndDate__c = System.today().addYears(3);
        testQuote.SBQQ__BillingFrequency__c = Constants.QUOTE_BILLING_FREQ_ANNUAL;
        testQuote.SBQQ__Type__c = Constants.QUOTE_TYPE_NEW;
        insert testQuote;

        // Create Utility class
        BillingSegmentationCalculation util = new BillingSegmentationCalculation();
        
        Test.startTest();
        	Billing_Segment__c returnedSegment = util.buildSegment(testQuote.Id, 0, testQuote.SBQQ__StartDate__c, testQuote.SBQQ__EndDate__c);
        Test.stopTest();
        
        System.assertEquals(testQuote.Id, returnedSegment.Quote__c, 'Quote was not linked to Billing Segment.');
        System.assertEquals(0, returnedSegment.Segment_No__c, 'Billing Segment index incorrect.');
        System.assertEquals(testQuote.SBQQ__StartDate__c, returnedSegment.Start_Date__c, 'Billing Segment start date incorrect.');
        System.assertEquals(testQuote.SBQQ__EndDate__c, returnedSegment.End_Date__c, 'Billing Segment end date incorrect.');
    }
    
    @isTest static void testCalculateMYD() {
        BillingSegmentationCalculation util = new BillingSegmentationCalculation();
        
        Test.startTest();
        	String returnedYMD = util.calculateYMD(System.today(), System.today().addYears(3).addDays(1));
        Test.stopTest();
        
        List<String> returnedYMDSplit = returnedYMD.split(' '); 
        
        System.assertNotEquals(null, returnedYMDSplit, 'YMD is incorrect.');
    }
}