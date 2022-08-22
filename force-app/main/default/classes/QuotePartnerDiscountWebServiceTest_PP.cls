/**
 * File Name: QuotePartnerDiscountWebServiceTest_PP
 *
 * @author: architect ir. Wilhelmus G.J. Velzeboer
 */
@IsTest
private class QuotePartnerDiscountWebServiceTest_PP {
  private static Product2 supportProduct;
  private static Product2 serviceProduct;
  private static Product2 thirdPartyProduct;
  private static Product2 product;
  private static Product2 restrictedProduct;
  private static Product2 nonCategoryProduct;
  private static Map<Id, Product2> productsById;

  private static Map<Id, Decimal> discountByProductId;
  private static Map<Id, Decimal> upliftByProductId;

  private static Account account;
  private static SBQQ__Quote__c quote;
  private static List<SBQQ__QuoteLine__c> lineItems;
  private static DiscountSchedule__c discountSchedule;
  private static DiscountUplift__c discountUpliftA;
  private static DiscountUplift__c discountUpliftB;
  private static DiscountTable__c discountTable;
  private static DiscountTable__c upliftTable;

  @IsTest
  static void itShouldGetTheDiscountValues_IntegratedTest() {
    // GIVEN
    createTestData();

    RestContext.request = new RestRequest();
    RestContext.response = new RestResponse();
    RestContext.request.httpMethod = 'POST';
    RestContext.request.requestURI =
      Url.getSalesforceBaseUrl().toExternalForm() +
      '/services/apexrest/Quote/PartnerDiscount/v1.0/' +
      quote.Id;
    RestContext.request.requestBody = getRequestBody();
    System.debug(RestContext.request.requestBody);

    // WHEN
    System.Test.startTest();
    QuotePartnerDiscountWebService_PP.doPost();
    System.Test.stopTest();

    // THEN
    System.assertEquals(
      200,
      RestContext.response.statusCode,
      'Unexpected exception encountered: ' + RestContext.response.responseBody.toString()
    );

    QuotePartnerDiscountWebService_PP.PostResponse result = (QuotePartnerDiscountWebService_PP.PostResponse) JSON.deserializeStrict(
      RestContext.response.responseBody.toString(),
      QuotePartnerDiscountWebService_PP.PostResponse.class
    );

    System.assertEquals(quote.Id, result.quoteId);
    System.assertEquals(6, result.products.size());
    System.debug(RestContext.response.responseBody.toString()); // todo - remove debug
    for (QuotePartnerDiscountWebService_PP.QuoteProductDiscount quoteProductDiscount : result.products) {
      Decimal expectedDiscount = discountByProductId.get(quoteProductDiscount.productId);
      System.assertEquals(
        expectedDiscount,
        quoteProductDiscount.discountPercentage,
        'Unexpected discount percentage for product discount category ' + expectedDiscount
      );

      Decimal expectedUplift = upliftByProductId.get(quoteProductDiscount.productId);
      System.assertEquals(
        expectedUplift,
        quoteProductDiscount.upliftPercentage,
        'Unexpected uplift percentage for product discount category ' + expectedUplift
      );

      System.assertEquals(1, quoteProductDiscount.discountReason.schedules.size(), 'Unexpected number of Schedules');
      System.assertEquals(2, quoteProductDiscount.discountReason.uplifts.size(), 'Unexpected number of Uplifts');
    }
  }

  @IsTest
  static void itShouldGetTheDiscountValues_Failure_NoQuoteIdProvided() {
    // GIVEN
    RestContext.request = new RestRequest();
    RestContext.response = new RestResponse();
    RestContext.request.httpMethod = 'POST';
    RestContext.request.requestURI =
      Url.getSalesforceBaseUrl().toExternalForm() + '/services/apexrest/Quote/PartnerDiscount/v1.0/';

    // WHEN
    System.Test.startTest();
    QuotePartnerDiscountWebService_PP.doPost();
    System.Test.stopTest();

    // THEN
    System.assertEquals(400, RestContext.response.statusCode);
    QuotePartnerDiscountWebService_PP.FailureResponse failureResponse = getFailureResponse();
    System.assert(failureResponse.message?.contains('Missing Quote Id'));
  }

  private static void createTestData() {
    Id pricebookId = Test.getStandardPricebookId();

    account = DataFactory_CM.createAccount('Partner', true);
    Opportunity opportunity = DataFactory_SL.createOpportunity(account.Id, true);
    quote = DataFactory_SL.createCPQQuote(account.Id, opportunity.Id, true);

    List<SBQQ__QuoteLine__c> quoteLines = new List<SBQQ__QuoteLine__c>();

    supportProduct = generateProduct('Support', 'Support');
    quoteLines.add(DataFactory_SL.createCPQQuoteLine(supportProduct.Id, quote.Id, false));

    serviceProduct = generateProduct('Services', 'Services');
    quoteLines.add(DataFactory_SL.createCPQQuoteLine(serviceProduct.Id, quote.Id, false));

    thirdPartyProduct = generateProduct('3rd Party', 'Product');
    quoteLines.add(DataFactory_SL.createCPQQuoteLine(thirdPartyProduct.Id, quote.Id, false));

    product = generateProduct('Product', 'Product');
    quoteLines.add(DataFactory_SL.createCPQQuoteLine(product.Id, quote.Id, false));

    restrictedProduct = generateProduct('Restricted', 'Product');
    quoteLines.add(DataFactory_SL.createCPQQuoteLine(restrictedProduct.Id, quote.Id, false));

    nonCategoryProduct = generateProduct('Product');
    quoteLines.add(DataFactory_SL.createCPQQuoteLine(nonCategoryProduct.Id, quote.Id, false));

    insert quoteLines;

    productsById = new Map<Id, Product2>{
      supportProduct.Id => supportProduct,
      serviceProduct.Id => serviceProduct,
      thirdPartyProduct.Id => thirdPartyProduct,
      product.Id => product,
      restrictedProduct.Id => restrictedProduct,
      nonCategoryProduct.Id => nonCategoryProduct
    };
    generatePricebookEntry(pricebookId, supportProduct, 100);
    generatePricebookEntry(pricebookId, serviceProduct, 50);
    generatePricebookEntry(pricebookId, thirdPartyProduct, 1000);
    generatePricebookEntry(pricebookId, product, 10);
    generatePricebookEntry(pricebookId, restrictedProduct, 750);
    generatePricebookEntry(pricebookId, nonCategoryProduct, 20);

    Account customer = DataFactory_CM.createAccount('Customer', true);
    quote = generateQuote(customer, pricebookId, opportunity);
    quote.SBQQ__Partner__c = account.Id;
    quote.SBQQ__Distributor__c = account.Id;
    update quote;

    discountTable = new DiscountTable__c(Name = 'Test Discount Schedule Table');

    upliftTable = new DiscountTable__c(Name = 'Test Discount Uplift Table');
    insert new List<DiscountTable__c>{ discountTable, upliftTable };

    upliftTable = new DiscountTable__c(Name = 'Test Discount Uplift Table');
    insert upliftTable;

    List<DiscountTableItem__c> discountTableItems = new List<DiscountTableItem__c>{
      generateDiscountTableItem(DiscountCategoryNames_PP.SUPPORT, 1, discountTable.Id),
      generateDiscountTableItem(DiscountCategoryNames_PP.SERVICES, 2, discountTable.Id),
      generateDiscountTableItem(DiscountCategoryNames_PP.THIRD_PARTY, 4, discountTable.Id),
      generateDiscountTableItem(DiscountCategoryNames_PP.PRODUCT, 8, discountTable.Id),
      generateDiscountTableItem(DiscountCategoryNames_PP.RESTRICTED, 16, discountTable.Id),
      generateDiscountTableItem(nonCategoryProduct, 32, discountTable.Id),
      generateDiscountTableItem(DiscountCategoryNames_PP.SUPPORT, 1, upliftTable.Id),
      generateDiscountTableItem(DiscountCategoryNames_PP.SERVICES, 1, upliftTable.Id),
      generateDiscountTableItem(DiscountCategoryNames_PP.THIRD_PARTY, 1, upliftTable.Id),
      generateDiscountTableItem(DiscountCategoryNames_PP.PRODUCT, 1, upliftTable.Id),
      generateDiscountTableItem(DiscountCategoryNames_PP.RESTRICTED, 1, upliftTable.Id),
      generateDiscountTableItem(nonCategoryProduct, 1, upliftTable.Id)
    };
    insert discountTableItems;

    discountSchedule = new DiscountSchedule__c(
      Name = 'Test Discount Schedule',
      Account__c = account.Id,
      Active__c = true,
      DiscountTable__c = discountTable.Id,
      EndDate__c = Date.today().addDays(2),
      StartDate__c = Date.today().addDays(-1),
      ConditionFormula__c = '1'
    );
    insert discountSchedule;

    discountUpliftA = new DiscountUplift__c(
      Name = 'Test Discount uplift A',
      Account__c = account.Id,
      Active__c = true,
      DiscountTable__c = upliftTable.Id,
      EndDate__c = Date.today().addDays(2),
      StartDate__c = Date.today().addDays(-1),
      ConditionFormula__c = '1'
    );
    discountUpliftB = new DiscountUplift__c(
      Name = 'Test Discount uplift B',
      Account__c = account.Id,
      Active__c = true,
      DiscountTable__c = upliftTable.Id,
      EndDate__c = Date.today().addDays(2),
      StartDate__c = Date.today().addDays(-1),
      ConditionFormula__c = '1'
    );
    insert new List<DiscountUplift__c>{ discountUpliftA, discountUpliftB };

    discountByProductId = new Map<Id, Decimal>{
      supportProduct.Id => 1,
      serviceProduct.Id => 2,
      thirdPartyProduct.Id => 4,
      product.Id => 8,
      restrictedProduct.Id => 16,
      nonCategoryProduct.Id => 32
    };
    upliftByProductId = new Map<Id, Decimal>{
      supportProduct.Id => 2,
      serviceProduct.Id => 2,
      thirdPartyProduct.Id => 2,
      product.Id => 2,
      restrictedProduct.Id => 2,
      nonCategoryProduct.Id => 2
    };
  }

  private static DiscountTableItem__c generateDiscountTableItem(String category, Decimal discount, Id tableId) {
    return new DiscountTableItem__c(
      DiscountTable__c = tableId,
      Category__c = category,
      DiscountPercentage__c = discount
    );
  }

  private static DiscountTableItem__c generateDiscountTableItem(Product2 product, Decimal discount, Id tableId) {
    return new DiscountTableItem__c(
      DiscountTable__c = tableId,
      Product__c = product.Id,
      DiscountPercentage__c = discount
    );
  }

  private static QuotePartnerDiscountWebService_PP.FailureResponse getFailureResponse() {
    return (QuotePartnerDiscountWebService_PP.FailureResponse) JSON.deserialize(
      RestContext.response.responseBody?.toString(),
      QuotePartnerDiscountWebService_PP.FailureResponse.class
    );
  }

  private static Blob getRequestBody() {
    List<QuotePartnerDiscountWebService_PP.QuoteProducts> quoteProducts = new List<QuotePartnerDiscountWebService_PP.QuoteProducts>{
      new QuotePartnerDiscountWebService_PP.QuoteProducts(supportProduct.Id, 1),
      new QuotePartnerDiscountWebService_PP.QuoteProducts(serviceProduct.Id, 1),
      new QuotePartnerDiscountWebService_PP.QuoteProducts(thirdPartyProduct.Id, 1),
      new QuotePartnerDiscountWebService_PP.QuoteProducts(product.Id, 1),
      new QuotePartnerDiscountWebService_PP.QuoteProducts(restrictedProduct.Id, 1),
      new QuotePartnerDiscountWebService_PP.QuoteProducts(nonCategoryProduct.Id, 1)
    };

    QuotePartnerDiscountWebService_PP.GetRequest request = new QuotePartnerDiscountWebService_PP.GetRequest();
    request.products = quoteProducts;
    return Blob.valueOf(JSON.serialize(request));
  }

  private static SBQQ__Quote__c generateQuote(Account account, Id pricebookId, Opportunity opportunity) {
    SBQQ__Quote__c quote = new SBQQ__Quote__c();
    quote.SBQQ__Account__c = account.Id;
    quote.SBQQ__PriceBook__c = pricebookId;
    quote.SBQQ__Opportunity2__c = opportunity.Id;
    insert quote;
    return quote;
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

  private static Product2 generateProduct(String productFamily) {
    Product2 supportProduct = new Product2(
      Name = productFamily + ' Product',
      ProductCode = 'Pro-X',
      IsActive = true,
      License_Model__c = 'N/A',
      Unit_of_measure__c = 'N/A',
      Family = productFamily
    );
    insert supportProduct;
    return supportProduct;
  }
}