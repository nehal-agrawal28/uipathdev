/**
 * --
 * @date 18/03/2019
 * @description Event listeners for Opty Trigger. This class should ideally delegate work to Domain/Service classes
 * @Modification Log
 *       06/08/2020 - Slalom - New method to test setDatesOnOpportunity to run date logic if Primary is ticked
 *       02/11/2020 - Slalom - New method to test createBillingSegments, deleteBillingSegments
 *       11/11/2020 -  Slalom - Added testCreateBillingSegmentsUpdate method to test if billing segments are createdfor Approved Quotes if updated
 */
@isTest
private class CPQQuoteTriggerHandlerTest {
  @testSetup
  public static void testSetup() {
    Account testAccount = DataFactory_CM.createAccount(Constants.ACCOUNT_RECORD_TYPE_1, true);
    Contact testContact = DataFactory_CM.createContact(testAccount.Id, true);
    Opportunity testOpportunity = DataFactory_SL.createOpportunity(testAccount.Id, true);

    SBQQ__Quote__c quote = DataFactory_SL.createCPQQuote(testAccount.Id, testOpportunity.Id, true);

    //create the order int feature toggle custom setting
    insert new CPQ_Order_Integration_Features__c(SetupOwnerId = UserInfo.getOrganizationId(), Active__c = true);
  }

  @isTest
  static void canCreateCPQQuote() {
    Account account = getAccount();
    insert account;
    Opportunity opportunity = getOpportunity(account);

    insert opportunity;

    SBQQ__Quote__c quote = getQuote(opportunity, account);

    Test.startTest();
    Database.SaveResult insertResult = Database.insert(quote, true);
    Database.DeleteResult deleteResult = Database.delete(quote, true);
    Test.stopTest();

    System.assert(insertResult.isSuccess());
    System.assert(deleteResult.isSuccess());
  }

  @isTest
  static void canDeleteCPQQuote() {
    Account account = getAccount();
    insert account;
    Opportunity opportunity = getOpportunity(account);
    insert opportunity;

    SBQQ__Quote__c quote = getQuote(opportunity, account);
    insert quote;

    Test.startTest();
    Database.DeleteResult deleteResult = Database.delete(quote, true);
    Test.stopTest();

    System.assert(deleteResult.isSuccess());
  }

  @isTest
  static void quoteTypeIsSetToRenewal() {
    Account account = getAccount();
    insert account;

    Contract newContract = new Contract();
    newContract.AccountId = account.id;
    insert newContract;

    Opportunity opportunity = getOpportunity(account);
    opportunity.SBQQ__RenewedContract__c = newContract.id;
    opportunity.SBQQ__Renewal__c = true;
    insert opportunity;

    SBQQ__Quote__c quote = getQuote(opportunity, account);

    Test.startTest();
    insert quote;
    Test.stopTest();

    quote = [SELECT Id, SBQQ__Type__c FROM SBQQ__Quote__c WHERE id = :quote.id];

    System.assertEquals(
            Constants.QUOTE_RENEWAL_TYPE,
            quote.SBQQ__Type__c,
            'Type should be Renewal as SBQQ__Renewal__c = true on opportunity'
    );
  }

  @isTest
  static void quoteTypeIsSetToQuote() {
    Account account = getAccount();
    insert account;

    Opportunity opportunity = getOpportunity(account);
    opportunity.SBQQ__Renewal__c = false;
    insert opportunity;

    SBQQ__Quote__c quote = getQuote(opportunity, account);

    Test.startTest();
    insert quote;
    Test.stopTest();

    quote = [SELECT Id, SBQQ__Type__c FROM SBQQ__Quote__c WHERE id = :quote.id];

    System.assertEquals(
            Constants.QUOTE_QUOTE_TYPE,
            quote.SBQQ__Type__c,
            'Type should be Quote as SBQQ__Renewal__c = false on the opportunity'
    );
  }

  private static SBQQ__Quote__c getQuote(Opportunity opportunity, Account account) {
    SBQQ__Quote__c quote = new SBQQ__Quote__c(
            SBQQ__Opportunity2__c = opportunity.Id,
            SBQQ__Account__c = account.Id,
            SBQQ__StartDate__c = System.today(),
            SBQQ__EndDate__c = System.today().addMonths(1)
    );
    return quote;
  }

  private static Opportunity getOpportunity(Account account) {
    Opportunity opportunity = new Opportunity(
            Name = ' CPQ Opportunity',
            RecordTypeId = getRecordTypeId(),
            StageName = 'Discovery',
            CloseDate = System.today().addMonths(1),
            LeadSource = 'Call Inbound',
            AccountId = account.Id,
            Deal_Type__c = 'Public Preview'
    );
    return opportunity;
  }

  private static Account getAccount() {
    Account account = new Account(Name = 'Test Account', BillingCountry = 'United Kingdom', Industry = 'Apparel');
    return account;
  }

  private static Id getRecordTypeId() {
    Id recordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
            .get('CPQ_Default')
            .getRecordTypeId();
    return recordTypeId;
  }

  //020-02-05 Doina Popa Added for testing the resetting of the Multi-Year-Dear fields on the opportunity in case the corresponding Quote is deleted

  private static Product2 getProduct(String productName, String productFamily) {
    //Create the products
    Product2 prod = new Product2(
            Name = productName,
            ProductCode = 'Pro-X1',
            isActive = true,
            License_Model__c = 'N/A',
            Unit_of_measure__c = 'N/A',
            Ext_Id__c = 'Product X 002',
            Family = productFamily
    );
    return prod;
  }

  private static PricebookEntry getPricebookEntry(Product2 prod, Id pricebookId) {
    PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = pricebookId,
            Product2Id = prod.Id,
            UnitPrice = 100.00,
            IsActive = true
    );
    return pbe;
  }

  private static SBQQ__QuoteLine__c getQuoteLineItem(
          Id quoteId,
          Id pbEntryId,
          Id productId,
          Integer quant,
          Decimal unitPrice,
          Date startDate
  ) {
    SBQQ__QuoteLine__c qli = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = quoteId,
            SBQQ__PricebookEntryId__c = pbEntryId,
            SBQQ__Quantity__c = quant,
            SBQQ__ListPrice__c = unitPrice,
            SBQQ__Product__c = productId,
            SBQQ__StartDate__c = startDate
    );
    return qli;
  }

  @isTest
  static void calculateFirstAnniDate_CreateQuote_3YR_20Days_Upfront_Test() {
    Account account = getAccount();
    insert account;

    Opportunity opportunity = getOpportunity(account);
    insert opportunity;

    SBQQ__Quote__c quote = getQuote(opportunity, account);
    quote.SBQQ__Primary__c = true;
    quote.SBQQ__StartDate__c = Date.newInstance(2020, 11, 1);
    quote.SBQQ__EndDate__c = Date.newInstance(2023, 11, 20);
    quote.SBQQ__BillingFrequency__c = Constants.QUOTE_BILLING_FREQ_UPFRONT;
    quote.SBQQ__Type__c = Constants.QUOTE_TYPE_NEW;

    Test.startTest();
    //create quote for 3 years 20 days with Billing Freq = Upfront
    insert quote;
    Test.stopTest();

    SBQQ__Quote__c quoteRec = [
            SELECT Id, First_Billing_Segment_Duration__c, First_Anniversary_Date__c
            FROM SBQQ__Quote__c
            WHERE id = :quote.id
            LIMIT 1
    ];

    System.assertEquals(
            null,
            quoteRec.First_Billing_Segment_Duration__c,
            'should be set to blank, as billing freq is Upfront'
    );
    System.assertEquals(null, quoteRec.First_Anniversary_Date__c, 'should be set to blank, as billing freq is Upfront');
  }

  @isTest
  static void calculateFirstAnniDate_CreateQuote_3YR_20Days_Annual_Test() {
    Account account = getAccount();
    insert account;

    Opportunity opportunity = getOpportunity(account);
    insert opportunity;

    SBQQ__Quote__c quote = getQuote(opportunity, account);
    quote.SBQQ__Primary__c = true;
    quote.SBQQ__StartDate__c = Date.newInstance(2020, 11, 1);
    quote.SBQQ__EndDate__c = Date.newInstance(2023, 11, 20);
    quote.SBQQ__BillingFrequency__c = Constants.QUOTE_BILLING_FREQ_ANNUAL;
    quote.SBQQ__Type__c = Constants.QUOTE_TYPE_NEW;

    Test.startTest();
    //create quote for 3 years 20 days with Billing Freq = Annual
    insert quote;
    Test.stopTest();

    SBQQ__Quote__c quoteRec = [
            SELECT Id, First_Billing_Segment_Duration__c, First_Anniversary_Date__c
            FROM SBQQ__Quote__c
            WHERE id = :quote.id
            LIMIT 1
    ];

    System.assertEquals(
            Constants.QUOTE_FIRST_BILLSEG_DURATION_PRORATED_WITH_ONEYEAR,
            quoteRec.First_Billing_Segment_Duration__c,
            '3 year 20 days deal, hence prorated period + 1yr'
    );
    System.assertEquals(
            Date.newInstance(2021, 11, 20),
            quoteRec.First_Anniversary_Date__c,
            'first anniversary date in 1 yr 20 days'
    );
  }

  @isTest
  static void calculateFirstAnniDate_CreateQuote_3YR_3M_Annual_Test() {
    Account account = getAccount();
    insert account;

    Opportunity opportunity = getOpportunity(account);
    insert opportunity;

    SBQQ__Quote__c quote = getQuote(opportunity, account);
    quote.SBQQ__Primary__c = true;
    quote.SBQQ__StartDate__c = Date.newInstance(2020, 11, 1);
    quote.SBQQ__EndDate__c = Date.newInstance(2024, 1, 31);
    quote.SBQQ__BillingFrequency__c = Constants.QUOTE_BILLING_FREQ_ANNUAL;
    quote.SBQQ__Type__c = Constants.QUOTE_TYPE_NEW;

    Test.startTest();
    //create quote for 3 years 3 months with Billing Freq = Annual
    insert quote;
    Test.stopTest();

    SBQQ__Quote__c quoteRec = [
            SELECT Id, First_Billing_Segment_Duration__c, First_Anniversary_Date__c
            FROM SBQQ__Quote__c
            WHERE id = :quote.id
            LIMIT 1
    ];

    System.assertEquals(
            Constants.QUOTE_FIRST_BILLSEG_DURATION_PRORATED,
            quoteRec.First_Billing_Segment_Duration__c,
            '3 year 3 months deal, hence prorated period'
    );
    System.assertEquals(
            Date.newInstance(2021, 1, 31),
            quoteRec.First_Anniversary_Date__c,
            'first anniversary date in 3 month'
    );
  }

  @isTest
  static void calculateFirstAnniDate_CreateQuote_3YR_4M_Annual_Test() {
    Account account = getAccount();
    insert account;

    Opportunity opportunity = getOpportunity(account);
    insert opportunity;

    SBQQ__Quote__c quote = getQuote(opportunity, account);
    quote.SBQQ__Primary__c = true;
    quote.SBQQ__StartDate__c = Date.newInstance(2020, 11, 1);
    quote.SBQQ__EndDate__c = Date.newInstance(2024, 2, 29);
    quote.SBQQ__BillingFrequency__c = Constants.QUOTE_BILLING_FREQ_ANNUAL;
    quote.SBQQ__Type__c = Constants.QUOTE_TYPE_NEW;

    Test.startTest();
    //create quote for 3 years 4 months with Billing Freq = Annual
    insert quote;
    Test.stopTest();

    SBQQ__Quote__c quoteRec = [
            SELECT Id, First_Billing_Segment_Duration__c, First_Anniversary_Date__c
            FROM SBQQ__Quote__c
            WHERE id = :quote.id
            LIMIT 1
    ];

    System.assertEquals(
            Constants.QUOTE_FIRST_BILLSEG_DURATION_PRORATED,
            quoteRec.First_Billing_Segment_Duration__c,
            '3 year 4 months deal, hence prorated period'
    );
    System.assertEquals(
            Date.newInstance(2021, 2, 28),
            quoteRec.First_Anniversary_Date__c,
            'first anniversary date in 4 month'
    );
  }

  @isTest
  static void calculateFirstAnniDate_UpdateQuote_To_Upfront_Test() {
    Account account = getAccount();
    insert account;

    Opportunity opportunity = getOpportunity(account);
    insert opportunity;

    SBQQ__Quote__c quote = getQuote(opportunity, account);
    quote.SBQQ__Primary__c = true;
    quote.SBQQ__StartDate__c = Date.newInstance(2020, 11, 1);
    quote.SBQQ__EndDate__c = Date.newInstance(2023, 12, 31);
    quote.SBQQ__BillingFrequency__c = Constants.QUOTE_BILLING_FREQ_ANNUAL;
    quote.SBQQ__Type__c = Constants.QUOTE_TYPE_NEW;

    Test.startTest();
    //create quote for 3 years 2 months with Billing Freq = Annual
    insert quote;

    SBQQ__Quote__c quoteRec = [
            SELECT Id, First_Billing_Segment_Duration__c, First_Anniversary_Date__c
            FROM SBQQ__Quote__c
            WHERE id = :quote.id
            LIMIT 1
    ];
    System.assertEquals(
            Constants.QUOTE_FIRST_BILLSEG_DURATION_PRORATED_WITH_ONEYEAR,
            quoteRec.First_Billing_Segment_Duration__c,
            '3 year 2 months deal, hence prorated period + 1yr'
    );
    System.assertEquals(
            Date.newInstance(2021, 12, 31),
            quoteRec.First_Anniversary_Date__c,
            'first anniversary date in 1 yr 2 month'
    );

    //update quote and change Billing Freq to Upfront
    quote.SBQQ__BillingFrequency__c = Constants.QUOTE_BILLING_FREQ_UPFRONT;
    update quote;

    quoteRec = [
            SELECT Id, First_Billing_Segment_Duration__c, First_Anniversary_Date__c
            FROM SBQQ__Quote__c
            WHERE id = :quote.id
            LIMIT 1
    ];
    System.assertEquals(
            null,
            quoteRec.First_Billing_Segment_Duration__c,
            'should be set to blank, as billing freq is Upfront'
    );
    System.assertEquals(null, quoteRec.First_Anniversary_Date__c, 'should be set to blank, as billing freq is Upfront');

    Test.stopTest();
  }

  @isTest
  static void calculateFirstAnniDate_UpdateQuote_To_Annual_Test() {
    Account account = getAccount();
    insert account;

    Opportunity opportunity = getOpportunity(account);
    insert opportunity;

    SBQQ__Quote__c quote = getQuote(opportunity, account);
    quote.SBQQ__Primary__c = true;
    quote.SBQQ__StartDate__c = Date.newInstance(2020, 11, 1);
    quote.SBQQ__EndDate__c = Date.newInstance(2024, 4, 30);
    quote.SBQQ__BillingFrequency__c = Constants.QUOTE_BILLING_FREQ_UPFRONT;
    quote.SBQQ__Type__c = Constants.QUOTE_TYPE_NEW;

    Test.startTest();
    //create quote for 3 years 6 months with Billing Freq = Upfront
    insert quote;

    SBQQ__Quote__c quoteRec = [
            SELECT Id, First_Billing_Segment_Duration__c, First_Anniversary_Date__c
            FROM SBQQ__Quote__c
            WHERE id = :quote.id
            LIMIT 1
    ];
    System.assertEquals(
            null,
            quoteRec.First_Billing_Segment_Duration__c,
            'should be set to blank, as billing freq is Upfront'
    );
    System.assertEquals(null, quoteRec.First_Anniversary_Date__c, 'should be set to blank, as billing freq is Upfront');

    //update quote and change Billing Freq to Annual
    quote.SBQQ__BillingFrequency__c = Constants.QUOTE_BILLING_FREQ_ANNUAL;
    update quote;

    quoteRec = [
            SELECT Id, First_Billing_Segment_Duration__c, First_Anniversary_Date__c
            FROM SBQQ__Quote__c
            WHERE id = :quote.id
            LIMIT 1
    ];
    System.assertEquals(
            Constants.QUOTE_FIRST_BILLSEG_DURATION_PRORATED,
            quoteRec.First_Billing_Segment_Duration__c,
            '3 year 6 months deal, hence prorated period'
    );
    System.assertEquals(
            Date.newInstance(2021, 4, 30),
            quoteRec.First_Anniversary_Date__c,
            'first anniversary date in 6 month'
    );

    Test.stopTest();
  }

  @isTest
  static void calculateFirstAnniDate_UpdateQuote_EndDate_Test() {
    Account account = getAccount();
    insert account;

    Opportunity opportunity = getOpportunity(account);
    insert opportunity;

    SBQQ__Quote__c quote = getQuote(opportunity, account);
    quote.SBQQ__Primary__c = true;
    quote.SBQQ__StartDate__c = Date.newInstance(2020, 11, 1);
    quote.SBQQ__EndDate__c = Date.newInstance(2023, 11, 20);
    quote.SBQQ__BillingFrequency__c = Constants.QUOTE_BILLING_FREQ_ANNUAL;
    quote.SBQQ__Type__c = Constants.QUOTE_TYPE_NEW;

    Test.startTest();
    //create quote for 3 years 20 days with Billing Freq = Annual
    insert quote;

    SBQQ__Quote__c quoteRec = [
            SELECT Id, First_Billing_Segment_Duration__c, First_Anniversary_Date__c
            FROM SBQQ__Quote__c
            WHERE id = :quote.id
            LIMIT 1
    ];
    System.assertEquals(
            Constants.QUOTE_FIRST_BILLSEG_DURATION_PRORATED_WITH_ONEYEAR,
            quoteRec.First_Billing_Segment_Duration__c,
            '3 year 20 days deal, hence prorated period + 1yr'
    );
    System.assertEquals(
            Date.newInstance(2021, 11, 20),
            quoteRec.First_Anniversary_Date__c,
            'first anniversary date in 1 yr 20 days'
    );

    //update quote and change end date to make deal 3 year 6 months
    quote.SBQQ__EndDate__c = Date.newInstance(2024, 4, 30);
    update quote;

    quoteRec = [
            SELECT Id, First_Billing_Segment_Duration__c, First_Anniversary_Date__c
            FROM SBQQ__Quote__c
            WHERE id = :quote.id
            LIMIT 1
    ];
    System.assertEquals(
            Constants.QUOTE_FIRST_BILLSEG_DURATION_PRORATED,
            quoteRec.First_Billing_Segment_Duration__c,
            '3 year 6 months deal, hence prorated period'
    );
    System.assertEquals(
            Date.newInstance(2021, 4, 30),
            quoteRec.First_Anniversary_Date__c,
            'first anniversary date in 6 month'
    );

    Test.stopTest();
  }

  @isTest
  static void calculateFirstAnniDate_UpdateQuote_EndDateBillingSeg_Test() {
    Account account = getAccount();
    insert account;

    Opportunity opportunity = getOpportunity(account);
    insert opportunity;

    SBQQ__Quote__c quote = getQuote(opportunity, account);
    quote.SBQQ__Primary__c = true;
    quote.SBQQ__StartDate__c = Date.newInstance(2020, 11, 1);
    quote.SBQQ__EndDate__c = Date.newInstance(2023, 11, 20);
    quote.SBQQ__BillingFrequency__c = Constants.QUOTE_BILLING_FREQ_ANNUAL;
    quote.SBQQ__Type__c = Constants.QUOTE_TYPE_NEW;

    Test.startTest();
    //create quote for 3 years 20 days with Billing Freq = Annual
    insert quote;

    SBQQ__Quote__c quoteRec = [
            SELECT Id, First_Billing_Segment_Duration__c, First_Anniversary_Date__c
            FROM SBQQ__Quote__c
            WHERE id = :quote.id
            LIMIT 1
    ];
    System.assertEquals(
            Constants.QUOTE_FIRST_BILLSEG_DURATION_PRORATED_WITH_ONEYEAR,
            quoteRec.First_Billing_Segment_Duration__c,
            '3 year 20 days deal, hence prorated period + 1yr'
    );
    System.assertEquals(
            Date.newInstance(2021, 11, 20),
            quoteRec.First_Anniversary_Date__c,
            'first anniversary date in 1 yr 20 days'
    );

    //update quote and change end date to make deal 3 year 25 days and set First_Billing_Segment_Duration__c = Prorated
    quote.SBQQ__EndDate__c = Date.newInstance(2023, 11, 25);
    quote.First_Billing_Segment_Duration__c = Constants.QUOTE_FIRST_BILLSEG_DURATION_PRORATED;
    update quote;

    quoteRec = [
            SELECT Id, First_Billing_Segment_Duration__c, First_Anniversary_Date__c
            FROM SBQQ__Quote__c
            WHERE id = :quote.id
            LIMIT 1
    ];
    System.assertEquals(
            Constants.QUOTE_FIRST_BILLSEG_DURATION_PRORATED_WITH_ONEYEAR,
            quoteRec.First_Billing_Segment_Duration__c,
            'Date is changed hence First_Billing_Segment_Duration__c will be set as per default logic'
    );
    System.assertEquals(
            Date.newInstance(2021, 11, 25),
            quoteRec.First_Anniversary_Date__c,
            '3 year 25 days deal, first anniversary date in 1 year 25 days'
    );

    Test.stopTest();
  }

  @isTest
  static void calculateFirstAnniDate_UpdateQuote_BillingSeg_Test() {
    Account account = getAccount();
    insert account;

    Opportunity opportunity = getOpportunity(account);
    insert opportunity;

    SBQQ__Quote__c quote = getQuote(opportunity, account);
    quote.SBQQ__Primary__c = true;
    quote.SBQQ__StartDate__c = Date.newInstance(2020, 11, 1);
    quote.SBQQ__EndDate__c = Date.newInstance(2023, 11, 20);
    quote.SBQQ__BillingFrequency__c = Constants.QUOTE_BILLING_FREQ_ANNUAL;
    quote.SBQQ__Type__c = Constants.QUOTE_TYPE_NEW;

    Test.startTest();
    //create quote for 3 years 20 days with Billing Freq = Annual
    insert quote;

    SBQQ__Quote__c quoteRec = [
            SELECT Id, First_Billing_Segment_Duration__c, First_Anniversary_Date__c
            FROM SBQQ__Quote__c
            WHERE id = :quote.id
            LIMIT 1
    ];
    System.assertEquals(
            Constants.QUOTE_FIRST_BILLSEG_DURATION_PRORATED_WITH_ONEYEAR,
            quoteRec.First_Billing_Segment_Duration__c,
            '3 year 20 days deal, hence prorated period + 1yr'
    );
    System.assertEquals(
            Date.newInstance(2021, 11, 20),
            quoteRec.First_Anniversary_Date__c,
            'first anniversary date in 1 yr 20 days'
    );

    //update quote and change First_Billing_Segment_Duration__c to Prorated
    quote.First_Billing_Segment_Duration__c = Constants.QUOTE_FIRST_BILLSEG_DURATION_PRORATED;
    update quote;

    quoteRec = [
            SELECT Id, First_Billing_Segment_Duration__c, First_Anniversary_Date__c
            FROM SBQQ__Quote__c
            WHERE id = :quote.id
            LIMIT 1
    ];
    System.assertEquals(
            Constants.QUOTE_FIRST_BILLSEG_DURATION_PRORATED,
            quoteRec.First_Billing_Segment_Duration__c,
            'First_Billing_Segment_Duration__c will be set as per user choice'
    );
    System.assertEquals(
            Date.newInstance(2020, 11, 20),
            quoteRec.First_Anniversary_Date__c,
            'first anniversary date in 20 days'
    );

    Test.stopTest();
  }

  @isTest
  static void calculateFirstAnniDate_UpdateQuote_AnyInfo_Test() {
    Account account = getAccount();
    insert account;

    Opportunity opportunity = getOpportunity(account);
    insert opportunity;

    SBQQ__Quote__c quote = getQuote(opportunity, account);
    quote.SBQQ__Primary__c = true;
    quote.SBQQ__StartDate__c = Date.newInstance(2020, 11, 1);
    quote.SBQQ__EndDate__c = Date.newInstance(2023, 11, 20);
    quote.SBQQ__BillingFrequency__c = Constants.QUOTE_BILLING_FREQ_ANNUAL;
    quote.SBQQ__Type__c = Constants.QUOTE_TYPE_NEW;

    Test.startTest();
    //create quote for 3 years 20 days with Billing Freq = Annual.
    insert quote;

    SBQQ__Quote__c quoteRec = [
            SELECT Id, First_Billing_Segment_Duration__c, First_Anniversary_Date__c
            FROM SBQQ__Quote__c
            WHERE id = :quote.id
            LIMIT 1
    ];
    System.assertEquals(
            Constants.QUOTE_FIRST_BILLSEG_DURATION_PRORATED_WITH_ONEYEAR,
            quoteRec.First_Billing_Segment_Duration__c,
            '3 year 20 days deal, hence prorated period + 1yr'
    );
    System.assertEquals(
            Date.newInstance(2021, 11, 20),
            quoteRec.First_Anniversary_Date__c,
            'first anniversary date in 1 yr 20 days'
    );

    //update quote and change First Anniversary Date to be in 1 year.
    quote.First_Anniversary_Date__c = Date.newInstance(2021, 11, 1);
    update quote;
    quoteRec = [
            SELECT Id, First_Billing_Segment_Duration__c, First_Anniversary_Date__c
            FROM SBQQ__Quote__c
            WHERE id = :quote.id
            LIMIT 1
    ];
    System.assertEquals(
            Date.newInstance(2021, 11, 1),
            quoteRec.First_Anniversary_Date__c,
            'first anniversary date should be the same as admin user has changed'
    );

    Test.stopTest();
  }

  @isTest
  static void calculateFirstAnniDate_ExactYearQuote_UpdateQuote_BillingSeg_Test() {
    Account account = getAccount();
    insert account;

    Opportunity opportunity = getOpportunity(account);
    insert opportunity;

    SBQQ__Quote__c quote = getQuote(opportunity, account);
    quote.SBQQ__Primary__c = true;
    quote.SBQQ__StartDate__c = Date.newInstance(2020, 11, 21);
    quote.SBQQ__EndDate__c = Date.newInstance(2023, 11, 20);
    quote.SBQQ__BillingFrequency__c = Constants.QUOTE_BILLING_FREQ_ANNUAL;
    quote.SBQQ__Type__c = Constants.QUOTE_TYPE_NEW;

    Test.startTest();
    //create quote for exact 3 years with Billing Freq = Annual
    insert quote;

    SBQQ__Quote__c quoteRec = [
            SELECT Id, First_Billing_Segment_Duration__c, First_Anniversary_Date__c
            FROM SBQQ__Quote__c
            WHERE id = :quote.id
            LIMIT 1
    ];
    System.assertEquals(
            Constants.QUOTE_FIRST_BILLSEG_DURATION_PRORATED_WITH_ONEYEAR,
            quoteRec.First_Billing_Segment_Duration__c,
            'exact 3 year deal, hence prorated period + 1yr as prorated part is 0'
    );
    System.assertEquals(
            Date.newInstance(2021, 11, 20),
            quoteRec.First_Anniversary_Date__c,
            'first anniversary date in 1Year'
    );

    //update the quote and change First_Billing_Segment_Duration__c to Prorated
    quote.First_Billing_Segment_Duration__c = Constants.QUOTE_FIRST_BILLSEG_DURATION_PRORATED;
    update quote;

    quoteRec = [
            SELECT Id, First_Billing_Segment_Duration__c, First_Anniversary_Date__c
            FROM SBQQ__Quote__c
            WHERE id = :quote.id
            LIMIT 1
    ];
    System.assertEquals(
            Constants.QUOTE_FIRST_BILLSEG_DURATION_PRORATED,
            quoteRec.First_Billing_Segment_Duration__c,
            'First_Billing_Segment_Duration__c will be set as per user choice'
    );
    System.assertEquals(
            Date.newInstance(2021, 11, 20),
            quoteRec.First_Anniversary_Date__c,
            'first anniversary date is still 1 Year as its exact 3 year deal'
    );

    Test.stopTest();
  }

  @isTest
  static void testCreateBillingSegmentsUpdate() {
    // Create Account
    Account testAccount = getAccount();
    insert testAccount;
    // Create  Opportunity
    Opportunity testOpportunity = DataFactory_SL.createOpportunity(testAccount.Id, true);
    // Create Product
    Product2 testProduct = DataFactory_SL.createProduct(true);

    // Create Quote
    SBQQ__Quote__c testQuote = DataFactory_SL.createCPQQuote(testAccount.Id, testOpportunity.Id, false);
    testQuote.SBQQ__Primary__c = true;
    testQuote.SBQQ__StartDate__c = System.today();
    testQuote.SBQQ__EndDate__c = System.today().addYears(3);
    testQuote.SBQQ__BillingFrequency__c = Constants.QUOTE_BILLING_FREQ_ANNUAL;
    testQuote.SBQQ__Type__c = Constants.QUOTE_TYPE_NEW;
    insert testQuote;

    // Create Quoteline
    List<SBQQ__QuoteLine__c> quoteLines = new List<SBQQ__QuoteLine__c>();

    for (Integer i = 0; i < 2; i++) {
      quoteLines.add(DataFactory_SL.createCPQQuoteLine(testProduct.Id, testQuote.Id, false));
    }

    insert quoteLines;

    Test.startTest();
    // Update Quote to Approved
    testQuote.SBQQ__Status__c = Constants.QUOTE_STATUS_3;
    update testQuote;

    // Re-query Quote
    List<SBQQ__Quote__c> testQuoteRequeried = [
            SELECT
                    Id,
                    Name,
                    SBQQ__BillingFrequency__c,
                    First_Anniversary_Date__c,
                    SBQQ__StartDate__c,
                    SBQQ__EndDate__c,
                    Quote_Duration__c,
                    SBQQ__NetAmount__c,
                    SBQQ__Type__c,
                    SBQQ__MasterContract__c,
                    CurrencyIsoCode,
                    Quote_Duration_YMD__c,
            (
                    SELECT
                            Id,
                            SBQQ__Product__r.Name,
                            SBQQ__EffectiveStartDate__c,
                            SBQQ__EffectiveEndDate__c,
                            SBQQ__NetTotal__c,
                            SBQQ__Number__c,
                            SBQQ__Dimension__c,
                            SBQQ__ProrateMultiplier__c,
                            SBQQ__SubscriptionPricing__c,
                            CurrencyIsoCode,
                            SBQQ__Quote__r.SBQQ__Opportunity2__c
                    FROM SBQQ__LineItems__r
                    ORDER BY SBQQ__Number__c ASC
            )
            FROM SBQQ__Quote__c
            WHERE Id = :testQuote.Id
    ];

    // Create Utility class
    BillingSegmentationCalculation_SL util = new BillingSegmentationCalculation_SL();
    util.calculateSegments(testQuoteRequeried.get(0), testQuoteRequeried[0].SBQQ__LineItems__r);
    insert util.wrapper.billingSegments;

    Test.stopTest();

    // Re-query Quote
    testQuote = [SELECT Id, (SELECT Id FROM Billing_Segments__r) FROM SBQQ__Quote__c WHERE Id = :testQuote.Id LIMIT 1];

    System.assertEquals(3, testQuote.Billing_Segments__r.size(), 'Billing Segments were not created.');
  }

  /* @isTest static void testCreateBillingSegmentsApproved(){
        // Create Account
        Account testAccount = getAccount();
        insert testAccount;
        // Create  Opportunity
        Opportunity testOpportunity = DataFactory_SL.createOpportunity(testAccount.Id, true);
        // Create Product
        Product2 testProduct = DataFactory_SL.createProduct(true);

        // Create Quote
        SBQQ__Quote__c testQuote = DataFactory_SL.createCPQQuote(testAccount.Id, testOpportunity.Id, false);
        testQuote.SBQQ__Primary__c = true;
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

        // Update Quote to Approved
        testQuote.SBQQ__Status__c = Constants.QUOTE_STATUS_3;
        update testQuote;

        Test.startTest();
        	// Update Quote to Approved
            testQuote.SBQQ__EndDate__c = System.today().addYears(4);
            update testQuote;
        Test.stopTest();

        // Re-query Quote
       	testQuote = [SELECT Id, (SELECT Id FROM Billing_Segments__r) FROM SBQQ__Quote__c WHERE Id = :testQuote.Id LIMIT 1];

        System.assertEquals(4, testQuote.Billing_Segments__r.size(), 'Billing Segments were not created.');
    }*/

  @isTest
  static void testDeleteBillingSegments() {
    // Create Account
    Account testAccount = getAccount();
    insert testAccount;
    // Create Opportunity
    Opportunity testOpportunity = DataFactory_SL.createOpportunity(testAccount.Id, true);
    // Create Product
    Product2 testProduct = DataFactory_SL.createProduct(true);

    // Create Quote
    SBQQ__Quote__c testQuote = DataFactory_SL.createCPQQuote(testAccount.Id, testOpportunity.Id, false);
    testQuote.SBQQ__Primary__c = true;
    testQuote.SBQQ__StartDate__c = System.today();
    testQuote.SBQQ__EndDate__c = System.today().addYears(3);
    testQuote.SBQQ__BillingFrequency__c = Constants.QUOTE_BILLING_FREQ_ANNUAL;
    testQuote.SBQQ__Type__c = Constants.QUOTE_TYPE_NEW;
    insert testQuote;

    // Create Quoteline
    // Create Quoteline
    List<SBQQ__QuoteLine__c> quoteLines = new List<SBQQ__QuoteLine__c>();

    for (Integer i = 0; i < 2; i++) {
      quoteLines.add(DataFactory_SL.createCPQQuoteLine(testProduct.Id, testQuote.Id, false));
    }

    insert quoteLines;

    Test.startTest();
    // Update Quote to Approved
    testQuote.SBQQ__Status__c = Constants.QUOTE_STATUS_3;
    update testQuote;

    // Update Quote to Draft
    testQuote.SBQQ__Status__c = Constants.QUOTE_STATUS_1;
    update testQuote;
    Test.stopTest();

    // Re-query Quote
    testQuote = [SELECT Id, (SELECT Id FROM Billing_Segments__r) FROM SBQQ__Quote__c WHERE Id = :testQuote.Id LIMIT 1];

    System.assertEquals(0, testQuote.Billing_Segments__r.size(), 'Billing Segments were not deleted.');
  }
}