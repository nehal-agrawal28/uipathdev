/**
 * File Name: PartnerDiscountsServiceTest_PP
 *
 * @author : architect ir. Wilhelmus G.J. Velzeboer
 */
@IsTest
private class PartnerDiscountsServiceTest_PP {
  private static final String GOLD_PARTNER = 'Gold Partner';
  private static final String PARTNER = 'Partner';

  @IsTest
  static void itShouldApplySchedulesInSequence() {
    // GIVEN - a quote with two discount schedules

    // Quote generation
    final String categoryName = 'Support';
    final Id pricebookId = Test.getStandardPricebookId();
    Map<String, Product2> products = generateProducts(pricebookId, new Set<String>{ categoryName });

    Account partnerAccount = DataFactory_CM.createAccount('Partner', true);
    Account customerAccount = DataFactory_CM.createAccount('Customer', true);
    SBQQ__Quote__c quote = generateQuote(partnerAccount, customerAccount, pricebookId);
    IQuoteLineItems_PP quoteLines = generateQuoteLines(quote, products);

    // Discount generation
    DiscountSchedule__c scheduleA = generateDiscountSchedule(
      'A',
      2,
      partnerAccount.Id,
      new Map<String, Decimal>{ categoryName => 6 }
    );
    DiscountSchedule__c scheduleB = generateDiscountSchedule(
      'B',
      1,
      partnerAccount.Id,
      new Map<String, Decimal>{ categoryName => 7 }
    );

    // Test data validation
    System.assertEquals(1, [SELECT COUNT() FROM SBQQ__Quote__c], 'Too many quotes generated');
    System.assertEquals(1, [SELECT COUNT() FROM SBQQ__QuoteLine__c], 'Too many quote lines generated');
    System.assertEquals(2, [SELECT COUNT() FROM DiscountSchedule__c], 'Too many Schedules generated');

    // WHEN - We calculate the discount for the given quote and line items
    System.Test.startTest();
    ProductDiscountInfos_PP result = new PartnerDiscountsServiceImpl_PP()
      .calculateProductDiscount(Quotes_PP.newInstance(new List<SBQQ__Quote__c>{ quote }), quoteLines);
    System.Test.stopTest();

    // THEN it should apply 7% discount
    for (SBQQ__QuoteLine__c lineItem : quoteLines.getQuoteLineItems()) {
      System.assertEquals(7, lineItem.Partner_Tier_Level_Discount__c, 'Incorrect discount value applied');
    }
  }

  // Creates products and pricebook entries
  private static Map<String, Product2> generateProducts(Id pricebookId, Set<String> productCategories) {
    Map<String, Product2> result = new Map<String, Product2>();
    for (String category : productCategories) {
      result.put(
        category,
        new Product2(
          Name = category + ' Product',
          ProductCode = 'Pro-X',
          IsActive = true,
          License_Model__c = 'N/A',
          Unit_of_measure__c = 'N/A',
          Family = category,
          PartnerDiscountCategory__c = category
        )
      );
    }
    insert result.values(); // products

    List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
    for (Product2 product : result.values()) {
      pricebookEntries.add(
        new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = product.Id, UnitPrice = 100, IsActive = true)
      );
    }
    insert pricebookEntries;
    return result;
  }

  private static DiscountSchedule__c generateDiscountSchedule(
    String name,
    Integer sequence,
    Id accountId,
    Map<String, Decimal> discountByProductCategory
  ) {
    DiscountTable__c table = new DiscountTable__c(Name = name + ' Table');
    insert table;

    List<DiscountTableItem__c> tableItems = new List<DiscountTableItem__c>();
    for (String category : discountByProductCategory.keySet()) {
      tableItems.add(
        new DiscountTableItem__c(
          DiscountTable__c = table.Id,
          Category__c = category,
          DiscountPercentage__c = discountByProductCategory.get(category)
        )
      );
    }
    insert tableItems;

    DiscountSchedule__c result = new DiscountSchedule__c(
      Name = name,
      Account__c = accountId,
      ConditionFormula__c = '1',
      DiscountTable__c = table.Id,
      Sequence__c = sequence,
      EndDate__c = Date.today().addDays(2),
      StartDate__c = Date.today().addDays(-1),
      Active__c = true
    );
    insert result;

    insert new DiscountCondition__c(
      Field__c = 'Conga_Status__c',
      Operator__c = 'Equals',
      Value__c = 'Completed',
      DiscountSchedule__c = result.Id
    );

    return result;
  }

  // Creates opportunity and quote
  private static SBQQ__Quote__c generateQuote(Account partnerAccount, Account customerAccount, Id pricebookId) {
    Opportunity opportunity = DataFactory_SL.createOpportunity(partnerAccount.Id, true);

    SBQQ__Quote__c quote = new SBQQ__Quote__c(
      SBQQ__Account__c = customerAccount.Id,
      SBQQ__PriceBook__c = pricebookId,
      SBQQ__Opportunity2__c = opportunity.Id,
      SBQQ__Partner__c = partnerAccount.Id,
      SBQQ__Distributor__c = partnerAccount.Id,
      Conga_Status__c = 'Completed'
    );
    insert quote;
    return quote;
  }

  // Create the quote line items for each product and links them to the quote
  private static IQuoteLineItems_PP generateQuoteLines(SBQQ__Quote__c quote, Map<String, Product2> product2sByStrings) {
    List<SBQQ__QuoteLine__c> result = new List<SBQQ__QuoteLine__c>();
    for (String category : product2sByStrings.keySet()) {
      result.add(DataFactory_SL.createCPQQuoteLine(product2sByStrings.get(category).Id, quote.Id, false));
    }
    insert result;

    return QuoteLineItems_PP.newInstance(result);
  }

  private static Product2 generateProduct(String productCategory, String productFamily) {
    Product2 supportProduct = new Product2(
      Name = productFamily + ' Product',
      ProductCode = 'Pro-X',
      IsActive = true,
      License_Model__c = 'N/A',
      Unit_of_measure__c = 'N/A',
      Family = productFamily,
      PartnerDiscountCategory__c = productCategory
    );
    insert supportProduct;
    return supportProduct;
  }

  private static PricebookEntry generatePricebookEntry(Id pricebookId, Product2 supportProduct, Decimal price) {
    PricebookEntry pricebookEntry = new PricebookEntry(
      Pricebook2Id = pricebookId,
      Product2Id = supportProduct.Id,
      UnitPrice = price,
      IsActive = true
    );
    insert pricebookEntry;
    return pricebookEntry;
  }

  private static SBQQ__Quote__c generateQuote(Account account, Id pricebookId, Opportunity opportunity) {
    SBQQ__Quote__c quote = new SBQQ__Quote__c();
    quote.SBQQ__Account__c = account.Id;
    quote.SBQQ__PriceBook__c = pricebookId;
    quote.SBQQ__Opportunity2__c = opportunity.Id;
    insert quote;
    return quote;
  }

  @IsTest
  static void itShouldNotApplyAnySchedule() {
    // GIVEN a Quote for a Partner without any active Discount Schedule
    TestData data = new TestData().createScenario(new List<String>{ GOLD_PARTNER });

    fflib_ApexMocks mocks = new fflib_ApexMocks();
    data.stubMock(mocks, Application_PP.Selector, Application_PP.ElevatedSelector);

    // WHEN the Discounts are calculated
    System.Test.startTest();
    IQuoteLineItems_PP lineItems = data.getQuoteLineItems();
    ProductDiscountInfos_PP result = new PartnerDiscountsServiceImpl_PP()
      .calculateProductDiscount(data.getQuotes(), lineItems);
    System.Test.stopTest();

    // THEN it should apply 0% discount
    System.assertEquals(5, lineItems.getRecords().size(), 'Incorrect amount of returned lineItems');
    for (SBQQ__QuoteLine__c lineItem : lineItems.getQuoteLineItems()) {
      System.assertEquals(0, lineItem.Partner_Tier_Level_Discount__c, 'Incorrect discount value applied');
    }
    for (SBQQ__QuoteLine__c lineItem : lineItems.getQuoteLineItems()) {
      System.assertEquals(0, lineItem.Business_Partner_Type_Discount__c, 'Incorrect uplift value applied');
    }

    assertThatTheMockingWorked();
  }

  @IsTest
  static void itShouldApplyZeroDiscount() {
    // GIVEN a Quote for a Partner with two active Discount Schedules the first sequence with zero discount
    TestData data = new TestData()
      .createScenario(new List<String>{ GOLD_PARTNER })
      .addDiscountSchedule(GOLD_PARTNER, 0, 0, 0, 0, 0, 0)
      .addDiscountSchedule(GOLD_PARTNER, 1, 10, 10, 10, 10, 10);

    fflib_ApexMocks mocks = new fflib_ApexMocks();
    data.stubMock(mocks, Application_PP.Selector, Application_PP.ElevatedSelector);

    // WHEN the Discounts are calculated
    System.Test.startTest();
    IQuoteLineItems_PP lineItems = data.getQuoteLineItems();
    ProductDiscountInfos_PP result = new PartnerDiscountsServiceImpl_PP()
      .calculateProductDiscount(data.getQuotes(), lineItems);
    System.Test.stopTest();

    // THEN it should apply the discount with the schedule of highest priority (= 5%)
    System.assertEquals(5, lineItems.getRecords().size(), 'Incorrect amount of returned lineItems');
    for (SBQQ__QuoteLine__c lineItem : lineItems.getQuoteLineItems()) {
      System.assertEquals(0, lineItem.Partner_Tier_Level_Discount__c, 'Incorrect discount value applied');
    }

    assertThatTheMockingWorked();
  }

  @IsTest
  static void itShouldApplyOnlyHighestPrioritySchedule() {
    // GIVEN a Quote for a Partner with two active Discount Schedules with different priorities
    TestData data = new TestData()
      .createScenario(new List<String>{ GOLD_PARTNER })
      .addDiscountSchedule(GOLD_PARTNER, 0, 5, 5, 5, 5, 5)
      .addDiscountSchedule(GOLD_PARTNER, 1, 10, 15, 20, 25, 30);

    fflib_ApexMocks mocks = new fflib_ApexMocks();
    data.stubMock(mocks, Application_PP.Selector, Application_PP.ElevatedSelector);

    // WHEN the Discounts are calculated
    System.Test.startTest();
    IQuoteLineItems_PP lineItems = data.getQuoteLineItems();
    ProductDiscountInfos_PP result = new PartnerDiscountsServiceImpl_PP()
      .calculateProductDiscount(data.getQuotes(), lineItems);
    System.Test.stopTest();

    // THEN it should apply the discount with the schedule of highest priority (= 5%)
    System.assertEquals(5, lineItems.getRecords().size(), 'Incorrect amount of returned lineItems');
    for (SBQQ__QuoteLine__c lineItem : lineItems.getQuoteLineItems()) {
      System.assert(hasDiscount(lineItem, 5), 'Incorrect discount value applied');
      System.assert(hasUplift(lineItem, 0), 'Incorrect uplift value applied');
    }

    assertThatTheMockingWorked();
  }

  @IsTest
  static void itShouldApplyPartialSchedulesInSequence() {
    // GIVEN a Quote for a Partner with two active but partial Discount Schedules with different priorities,
    TestData data = new TestData()
      .createScenario(new List<String>{ GOLD_PARTNER })
      .addDiscountSchedule(GOLD_PARTNER, 0, 5, null, 5, null, 5)
      .addDiscountSchedule(GOLD_PARTNER, 1, null, 5, null, 5, null);

    fflib_ApexMocks mocks = new fflib_ApexMocks();
    data.stubMock(mocks, Application_PP.Selector, Application_PP.ElevatedSelector);

    // WHEN the Discounts are calculated
    System.Test.startTest();
    IQuoteLineItems_PP lineItems = data.getQuoteLineItems();
    ProductDiscountInfos_PP result = new PartnerDiscountsServiceImpl_PP()
      .calculateProductDiscount(data.getQuotes(), lineItems);
    System.Test.stopTest();

    // THEN it should apply the discount first of the schedule with highest priority,
    //      if the discount category is not there it should apply the discount of the second schedule
    System.assertEquals(5, lineItems.getRecords().size(), 'Incorrect amount of returned lineItems');
    for (SBQQ__QuoteLine__c lineItem : lineItems.getQuoteLineItems()) {
      System.debug(
        lineItem.SBQQ__Product__c +
        ' = ' +
        data.productById.get(lineItem.SBQQ__Product__c) +
        ' => ' +
        lineItem.Partner_Tier_Level_Discount__c
      );
      System.assertEquals(5, lineItem.Partner_Tier_Level_Discount__c, 'Incorrect discount value applied');
    }

    assertThatTheMockingWorked();
  }

  @IsTest
  static void itShouldOnlyApplyApplicableSchedule() {
    // GIVEN a Quote for a Partner with two active Discount Schedules with different criteria,
    System.debug('Creating Test Data - Start');
    TestData data = new TestData()
      .createScenario(new List<String>{ GOLD_PARTNER })
      .addDiscountSchedule(GOLD_PARTNER, 0, 3, 3, 3, 3, 3)
      .addDiscountCondition(0, 'SBQQ__Account__r.Industry', 'Equals', 'Engineering')
      .addDiscountSchedule(GOLD_PARTNER, 1, 7, 7, 7, 7, 7)
      .addDiscountCondition(1, 'SBQQ__Account__r.Industry', 'Equals', 'Energy');
    System.assertEquals(1, data.quoteById.size());
    System.debug('Creating Test Data - Done');

    fflib_ApexMocks mocks = new fflib_ApexMocks();
    Account account = data.accountsByName.get(GOLD_PARTNER);
    account.Industry = 'Energy';
    SBQQ__Quote__c quote = data.quoteById.get(new List<Id>(data.quoteById.keySet()).get(0));
    SBQQ__Quote__c quoteWithRelatedData = (SBQQ__Quote__c) fflib_MockSObjectUtil.addRelatedParentObject(
      quote,
      account,
      'SBQQ__Account__r'
    );
    data.quoteById.put(quoteWithRelatedData.Id, quoteWithRelatedData);
    data.stubMock(mocks, Application_PP.Selector, Application_PP.ElevatedSelector);

    // WHEN the account industry is set to Engineering and then changed to Energy
    System.Test.startTest();
    IQuoteLineItems_PP lineItems = data.getQuoteLineItems();
    ProductDiscountInfos_PP result = new PartnerDiscountsServiceImpl_PP()
      .calculateProductDiscount(data.getQuotes(), lineItems);
    System.Test.stopTest();

    // THEN the discount should be first 3% and after that to 7%
    System.assertEquals(5, lineItems.getRecords().size(), 'Incorrect amount of returned lineItems for Energy');

    for (SBQQ__QuoteLine__c lineItem : lineItems.getQuoteLineItems()) {
      System.debug(
        lineItem.SBQQ__Product__c +
        ' = ' +
        data.productById.get(lineItem.SBQQ__Product__c) +
        ' => ' +
        lineItem.Partner_Tier_Level_Discount__c
      );
      System.assertEquals(
        7,
        lineItem.Partner_Tier_Level_Discount__c,
        'Incorrect discount value applied for Energy Schedule'
      );
    }

    assertThatTheMockingWorked();
  }

  @IsTest
  static void itShouldApplyScheduleAndUplift() {
    // GIVEN a Quote for a Partner with an active schedule and uplift
    TestData data = new TestData()
      .createScenario(new List<String>{ GOLD_PARTNER })
      .addDiscountSchedule(GOLD_PARTNER, 0, 3, 3, 3, 3, 3)
      .addUplift(
        GOLD_PARTNER,
        2,
        2,
        2,
        2,
        2,
        '1',
        new List<DiscountUpliftCondition__c>{
          new DiscountUpliftCondition__c(
            Field__c = 'SBQQ__Account__r.Industry',
            Operator__c = 'Equals',
            Value__c = 'Energy',
            Sequence__c = 0
          )
        }
      )
      .addUplift(
        GOLD_PARTNER,
        2,
        2,
        2,
        2,
        2,
        '1',
        new List<DiscountUpliftCondition__c>{
          new DiscountUpliftCondition__c(
            Field__c = 'SBQQ__Account__r.NumberOfEmployees',
            Operator__c = 'Equals',
            Value__c = '100',
            Sequence__c = 0
          )
        }
      );

    Account account = data.accountsByName.get(GOLD_PARTNER);
    account.Industry = 'Energy';
    account.NumberOfEmployees = 100;
    fflib_ApexMocks mocks = new fflib_ApexMocks();
    data.stubMock(mocks, Application_PP.Selector, Application_PP.ElevatedSelector);

    // WHEN the Discounts is calculated
    System.Test.startTest();
    IQuoteLineItems_PP lineItems = data.getQuoteLineItems();
    ProductDiscountInfos_PP result = new PartnerDiscountsServiceImpl_PP()
      .calculateProductDiscount(data.getQuotes(), lineItems);
    System.Test.stopTest();

    // THEN the schedule and the uplift should be applied.
    System.assertEquals(5, lineItems.getRecords().size(), 'Incorrect amount of returned lineItems');
    for (SBQQ__QuoteLine__c lineItem : lineItems.getQuoteLineItems()) {
      System.assertEquals(3, lineItem.Partner_Tier_Level_Discount__c, 'Incorrect discount value applied for Discount');
      System.assertEquals(4, lineItem.Business_Partner_Type_Discount__c, 'Incorrect discount value applied for uplift');
    }

    assertThatTheMockingWorked();
  }

  private static void assertThatTheMockingWorked() {
    System.assertEquals(0, Limits.getQueries(), 'Whoops, it seems we hit the Database with a Query.');
    System.assertEquals(0, Limits.getDmlStatements(), 'Whoops, it seems we hit the Database with a DML statement.');
  }

  private static Boolean hasDiscount(SBQQ__QuoteLine__c lineItem, Decimal value) {
    return lineItem.Partner_Tier_Level_Discount__c == value;
  }

  private static Boolean hasUplift(SBQQ__QuoteLine__c lineItem, Decimal value) {
    return lineItem.Business_Partner_Type_Discount__c == value;
  }

  private class TestData {
    public Id accountPartnerRecordType = Schema.SObjectType.Account
      .getRecordTypeInfosByDeveloperName()
      .get('Prospect')
      .getRecordTypeId();

    public Id pricebookId = Test.getStandardPricebookId();

    public Map<String, Account> accountsByName = new Map<String, Account>();
    public Map<Id, Account> accountsById = new Map<Id, Account>();

    public Map<String, Product2> productByDiscountCategory = new Map<String, Product2>();
    public Map<Id, Product2> productById = new Map<Id, Product2>();
    public Map<String, SBQQ__Quote__c> quoteByScenarioName = new Map<String, SBQQ__Quote__c>();
    public Map<Id, SBQQ__Quote__c> quoteById = new Map<Id, SBQQ__Quote__c>();
    public Map<String, SBQQ__QuoteLine__c> quoteLineItemByScenarioName = new Map<String, SBQQ__QuoteLine__c>();
    public Map<String, List<DiscountTable__c>> discountTablesByScenarioName = new Map<String, List<DiscountTable__c>>();
    public Map<Id, DiscountTable__c> discountTablesById = new Map<Id, DiscountTable__c>();
    public Map<String, DiscountSchedule__c> discountSchedulesByScenarioName = new Map<String, DiscountSchedule__c>();
    public Map<Id, DiscountSchedule__c> discountSchedulesById = new Map<Id, DiscountSchedule__c>();

    public Map<Id, DiscountUplift__c> discountUpliftsById = new Map<Id, DiscountUplift__c>();
    public Map<String, DiscountUplift__c> discountUpliftsByScenarioName = new Map<String, DiscountUplift__c>();

    private Set<String> discountCategories = new Set<String>{
      DiscountCategoryNames_PP.SUPPORT,
      DiscountCategoryNames_PP.SERVICES,
      DiscountCategoryNames_PP.THIRD_PARTY,
      DiscountCategoryNames_PP.PRODUCT,
      DiscountCategoryNames_PP.RESTRICTED
    };
    private List<DiscountCondition__c> discountConditions = new List<DiscountCondition__c>();

    public TestData createScenario(List<String> scenarioNames) {
      for (String scenarioName : scenarioNames) {
        Account account = generateAccount(scenarioName);
        generateQuote(scenarioName, account.Id);
      }
      return this;
    }

    private Account generateAccount(String name) {
      Account result = new Account(
        Id = fflib_IDGenerator.generate(Schema.Account.SObjectType),
        Name = name + ' Account',
        RecordTypeId = accountPartnerRecordType,
        Country__c = 'Ireland',
        Geo__c = 'EMEA',
        BillingCountry = 'Ireland',
        Classification__c = 'SMB',
        AnnualRevenue = 100000,
        Industry = 'Engineering',
        Overwrite_Classification__c = true,
        Top_Account__c = true
      );
      this.accountsByName.put(name, result);
      this.accountsById.put(result.Id, result);
      return result;
    }

    private SBQQ__Quote__c generateQuote(String name, Id accountId) {
      SBQQ__Quote__c quote = new SBQQ__Quote__c(
        Id = fflib_IDGenerator.generate(SBQQ__Quote__c.SObjectType),
        SBQQ__Account__c = accountId,
        SBQQ__Distributor__c = accountId,
        SBQQ__Partner__c = accountId,
        SBQQ__PriceBook__c = pricebookId
      );

      quoteByScenarioName.put(name, quote);
      quoteById.put(quote.Id, quote);

      for (String category : discountCategories) {
        Product2 product = generateProduct(category, category);
        generateQuoteLineItem(category, quote, product);
      }

      return quote;
    }

    private Product2 generateProduct(String productCategory, String productFamily) {
      Product2 result = new Product2(
        Id = fflib_IDGenerator.generate(Product2.SObjectType),
        Name = productFamily + ' Product',
        ProductCode = 'Pro-X',
        IsActive = true,
        License_Model__c = 'N/A',
        Unit_of_measure__c = 'N/A',
        Family = productFamily,
        PartnerDiscountCategory__c = productCategory
      );
      this.productByDiscountCategory.put(productCategory, result);
      this.productById.put(result.Id, result);
      return result;
    }

    private SBQQ__QuoteLine__c generateQuoteLineItem(
      String scenarioName,
      SBQQ__Quote__c quote,
      Product2 supportProduct
    ) {
      SBQQ__QuoteLine__c quoteLineItem = new SBQQ__QuoteLine__c(
        Id = fflib_IDGenerator.generate(SBQQ__QuoteLine__c.SObjectType),
        SBQQ__Quote__c = quote.Id,
        SBQQ__Quantity__c = 5,
        SBQQ__Product__c = supportProduct.Id
      );
      this.quoteLineItemByScenarioName.put(scenarioName, quoteLineItem);
      return quoteLineItem;
    }

    private TestData addDiscountSchedule(
      String scenarioName,
      Integer sequence,
      Decimal supportDiscount,
      Decimal serviceDiscount,
      Decimal thirdPartyDiscount,
      Decimal productDiscount,
      Decimal restrictedDiscount
    ) {
      Id discountTableId = fflib_IDGenerator.generate(DiscountTable__c.SObjectType);

      List<DiscountTableItem__c> tableItems = addDiscountTableItems(
        discountTableId,
        supportDiscount,
        serviceDiscount,
        thirdPartyDiscount,
        productDiscount,
        restrictedDiscount
      );

      DiscountTable__c discountTable = generateDiscountTable(discountTableId, scenarioName);

      generateDiscountTables(scenarioName, discountTable, tableItems);

      generateDiscountSchedule(scenarioName, discountTable, sequence);

      return this;
    }

    private void generateDiscountSchedule(String scenarioName, DiscountTable__c discountTable, Integer sequence) {
      DiscountSchedule__c schedule = new DiscountSchedule__c(
        Id = fflib_IDGenerator.generate(DiscountSchedule__c.SObjectType),
        Name = scenarioName + ' Schedule',
        DiscountTable__c = discountTable.Id,
        Sequence__c = sequence,
        Account__c = accountsByName.get(scenarioName).Id,
        Active__c = true,
        ConditionFormula__c = '1'
      );
      discountSchedulesByScenarioName.put(scenarioName, schedule);
      discountSchedulesById.put(schedule.Id, schedule);
    }

    private List<DiscountTable__c> generateDiscountTables(
      String scenarioName,
      DiscountTable__c discountTable,
      List<DiscountTableItem__c> tableItems
    ) {
      List<DiscountTable__c> discountTables = (List<DiscountTable__c>) fflib_MockSOQLResult.makeRelationship(
        List<DiscountTable__c>.class,
        new List<DiscountTable__c>{ discountTable },
        DiscountTableItem__c.DiscountTable__c,
        new List<List<DiscountTableItem__c>>{ tableItems }
      );

      if (discountTablesByScenarioName.containsKey(scenarioName))
        discountTablesByScenarioName.get(scenarioName).add(discountTables.get(0));
      else
        discountTablesByScenarioName.put(scenarioName, new List<DiscountTable__c>{ discountTables.get(0) });

      discountTablesById.put(discountTables.get(0).Id, discountTables.get(0));
      return discountTables;
    }

    private DiscountTable__c generateDiscountTable(Id discountTableId, String scenarioName) {
      DiscountTable__c discountTable = new DiscountTable__c(
        Id = discountTableId,
        Name = 'Discount Table ' + scenarioName
      );
      return discountTable;
    }

    private List<DiscountTableItem__c> addDiscountTableItems(
      Id discountTableId,
      Decimal supportDiscount,
      Decimal serviceDiscount,
      Decimal thirdPartyDiscount,
      Decimal productDiscount,
      Decimal restrictedDiscount
    ) {
      List<DiscountTableItem__c> tableItems = new List<DiscountTableItem__c>();
      if (supportDiscount != null)
        tableItems.add(generateDiscountTableItem(DiscountCategoryNames_PP.SUPPORT, discountTableId, supportDiscount));
      if (serviceDiscount != null)
        tableItems.add(generateDiscountTableItem(DiscountCategoryNames_PP.SERVICES, discountTableId, serviceDiscount));
      if (thirdPartyDiscount != null)
        tableItems.add(
          generateDiscountTableItem(DiscountCategoryNames_PP.THIRD_PARTY, discountTableId, thirdPartyDiscount)
        );
      if (productDiscount != null)
        tableItems.add(generateDiscountTableItem(DiscountCategoryNames_PP.PRODUCT, discountTableId, productDiscount));
      if (restrictedDiscount != null)
        tableItems.add(
          generateDiscountTableItem(DiscountCategoryNames_PP.RESTRICTED, discountTableId, restrictedDiscount)
        );
      return tableItems;
    }

    private TestData addUplift(
      String scenarioName,
      Decimal supportDiscount,
      Decimal serviceDiscount,
      Decimal thirdPartyDiscount,
      Decimal productDiscount,
      Decimal restrictedDiscount,
      String conditionFormula,
      List<DiscountUpliftCondition__c> discountUpliftConditions
    ) {
      Id discountTableId = fflib_IDGenerator.generate(DiscountTable__c.SObjectType);
      List<DiscountTableItem__c> tableItems = addDiscountTableItems(
        discountTableId,
        supportDiscount,
        serviceDiscount,
        thirdPartyDiscount,
        productDiscount,
        restrictedDiscount
      );

      DiscountTable__c discountTable = generateDiscountTable(discountTableId, scenarioName);
      generateDiscountTables(scenarioName, discountTable, tableItems);

      DiscountUplift__c discountUplift = new DiscountUplift__c(
        Id = fflib_IDGenerator.generate(DiscountUplift__c.SObjectType),
        Account__c = accountsByName.get(scenarioName).Id,
        Active__c = true,
        ConditionFormula__c = conditionFormula,
        DiscountTable__c = discountTable.Id,
        StartDate__c = Datetime.now().addDays(-1),
        EndDate__c = Datetime.now().addDays(1)
      );

      List<DiscountUplift__c> discountUplifts = (List<DiscountUplift__c>) fflib_MockSOQLResult.makeRelationship(
        List<DiscountUplift__c>.class,
        new List<DiscountUplift__c>{ discountUplift },
        DiscountUpliftCondition__c.DiscountUplift__c,
        new List<List<DiscountUpliftCondition__c>>{ discountUpliftConditions }
      );

      this.discountUpliftsById.put(discountUplift.Id, discountUplifts.get(0));
      this.discountUpliftsByScenarioName.put(scenarioName, discountUplifts.get(0));
      return this;
    }

    private DiscountTableItem__c generateDiscountTableItem(String category, Id discountTableId, Decimal discount) {
      return new DiscountTableItem__c(
        DiscountTable__c = discountTableId,
        Category__c = category,
        DiscountPercentage__c = discount
      );
    }

    private IQuotes_PP getQuotes() {
      return new Quotes_PP(quoteByScenarioName.values());
    }

    private IQuoteLineItems_PP getQuoteLineItems() {
      return new QuoteLineItems_PP(quoteLineItemByScenarioName.values());
    }

    private void stubMock(
      fflib_ApexMocks mocks,
      fflib_Application.SelectorFactory selectorFactory,
      fflib_Application.SelectorFactory elevatedSelectorFactory
    ) {
      IDiscountSchedulesSelector_PP schedulesSelectorMock = (IDiscountSchedulesSelector_PP) mocks.mock(
        IDiscountSchedulesSelector_PP.class
      );

      IDiscountConditionsSelector_PP discountConditionsSelectorMock = (IDiscountConditionsSelector_PP) mocks.mock(
        IDiscountConditionsSelector_PP.class
      );

      IDiscountTablesSelector_PP tablesSelectorMock = (IDiscountTablesSelector_PP) mocks.mock(
        IDiscountTablesSelector_PP.class
      );

      IProductsSelector_PP productsSelectorMock = (IProductsSelector_PP) mocks.mock(IProductsSelector_PP.class);

      IQuotesSelector_PP quotesSelectorMock = (IQuotesSelector_PP) mocks.mock(IQuotesSelector_PP.class);

      IDiscountUpliftsSelector_PP upliftsSelectorMock = (IDiscountUpliftsSelector_PP) mocks.mock(
        IDiscountUpliftsSelector_PP.class
      );

      IDiscountUpliftConditionsSelector_PP upliftConditionsSelectorMock = (IDiscountUpliftConditionsSelector_PP) mocks.mock(
        IDiscountUpliftConditionsSelector_PP.class
      );

      mocks.startStubbing();
      mocks.when(schedulesSelectorMock.sObjectType()).thenReturn(DiscountSchedule__c.SObjectType);
      mocks.when(schedulesSelectorMock.selectActiveByAccountId(accountsById.keySet()))
        .thenReturn(this.discountSchedulesById.values());

      mocks.when(discountConditionsSelectorMock.sObjectType()).thenReturn(DiscountCondition__c.SObjectType);
      mocks.when(discountConditionsSelectorMock.selectByScheduleId(discountSchedulesById.keySet()))
        .thenReturn(this.discountConditions);

      mocks.when(tablesSelectorMock.sObjectType()).thenReturn(DiscountTable__c.SObjectType);
      mocks.when(tablesSelectorMock.selectByIdWithItems((Set<Id>) fflib_Match.anyObject()))
        .thenReturn(discountTablesById.values());

      mocks.when(productsSelectorMock.sObjectType()).thenReturn(Product2.SObjectType);
      mocks.when(productsSelectorMock.selectSObjectsById(productById.keySet())).thenReturn(productById.values());

      mocks.when(quotesSelectorMock.sObjectType()).thenReturn(SBQQ__Quote__c.SObjectType);
      mocks.when(quotesSelectorMock.selectByIdWithReferences(quoteById.keySet(), new Set<String>()))
        .thenReturn(quoteById.values());
      mocks.when(
          quotesSelectorMock.selectByIdWithReferences(
            (Set<Id>) fflib_Match.anyObject(),
            (Set<String>) fflib_Match.anyObject()
          )
        )
        .thenReturn(quoteById.values());

      mocks.when(upliftsSelectorMock.sObjectType()).thenReturn(DiscountUplift__c.SObjectType);
      mocks.when(upliftsSelectorMock.selectByAccountIdWithConditionsAndItems((Set<Id>) fflib_Match.anyObject()))
        .thenReturn(this.discountUpliftsById.values());

      mocks.when(upliftConditionsSelectorMock.sObjectType()).thenReturn(DiscountUpliftCondition__c.SObjectType);
      mocks.when(upliftConditionsSelectorMock.selectByUpliftId((Set<Id>) fflib_Match.anyObject()))
        .thenReturn(new List<DiscountUpliftCondition__c>());

      mocks.stopStubbing();

      selectorFactory.setMock(schedulesSelectorMock);
      selectorFactory.setMock(discountConditionsSelectorMock);
      selectorFactory.setMock(tablesSelectorMock);
      selectorFactory.setMock(productsSelectorMock);
      selectorFactory.setMock(quotesSelectorMock);
      selectorFactory.setMock(upliftsSelectorMock);
      selectorFactory.setMock(upliftConditionsSelectorMock);
      elevatedSelectorFactory.setMock(schedulesSelectorMock);
      elevatedSelectorFactory.setMock(discountConditionsSelectorMock);
      elevatedSelectorFactory.setMock(tablesSelectorMock);
      elevatedSelectorFactory.setMock(productsSelectorMock);
      elevatedSelectorFactory.setMock(upliftsSelectorMock);
      elevatedSelectorFactory.setMock(quotesSelectorMock);
      elevatedSelectorFactory.setMock(upliftConditionsSelectorMock);
    }

    private TestData addDiscountCondition(Integer scheduleSequence, String field, String operator, String value) {
      Id scheduleId;
      for (DiscountSchedule__c schedule : discountSchedulesById.values()) {
        if (schedule.Sequence__c == scheduleSequence)
          scheduleId = schedule.Id;
      }

      DiscountCondition__c condition = new DiscountCondition__c(
        DiscountSchedule__c = scheduleId,
        Field__c = field,
        Operator__c = operator,
        Value__c = value
      );
      discountConditions.add(condition);
      return this;
    }
  }
}