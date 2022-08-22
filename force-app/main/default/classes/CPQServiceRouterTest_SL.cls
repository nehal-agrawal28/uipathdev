@IsTest(isParallel=false)
public with sharing class CPQServiceRouterTest_SL {
  @IsTest
  private static void addProduct_nullProduct_emtpyResult() {
    SBQQ.TriggerControl.disable();
    // Arrange
    Account account = DataFactory_CM.createAccount('Customer', false);
    insert account;

    Product2 prod = new Product2(
      Name = 'Product Uipath 2' + String.valueOf((Math.random() * 100) + 1),
      ProductCode = 'PROD' + String.valueOf((Math.random() * 100) + 1),
      isActive = true
    );
    insert new List<Product2>{ prod };

    Id standardPricebookId = Test.getStandardPricebookId();

    PricebookEntry pbe = new PricebookEntry(
      Pricebook2Id = standardPricebookId,
      Product2Id = prod.Id,
      UnitPrice = 1020.00,
      IsActive = true
    );
    insert new List<PricebookEntry>{ pbe };

    Opportunity opp = DataFactory_SL.createOpportunity(account.Id, true);

    OpportunityLineItem lineItem1 = new OpportunityLineItem(
      OpportunityID = opp.id,
      PriceBookEntryID = pbe.id,
      quantity = 4,
      totalprice = 200
    );
    insert lineItem1;

    SBQQ__Quote__c quote = new SBQQ__Quote__c(
      SBQQ__Account__c = account.Id,
      SBQQ__Opportunity2__c = opp.Id,
      SBQQ__PriceBook__c = standardPricebookId,
      SBQQ__Primary__c = true,
      SBQQ__StartDate__c = System.today(),
      SBQQ__SubscriptionTerm__c = 36
    );
    insert quote;
    opp.SBQQ__Contracted__c = true;
    update opp;
    Contract contract = new Contract(
      AccountId = account.Id,
      SBQQ__Opportunity__c = opp.Id,
      SBQQ__Quote__c = quote.Id,
      StartDate = System.today()
    );
    insert contract;

    // Act
    Test.startTest();
    CPQServiceRouter_SL serviceRouter = new CPQServiceRouter_SL();
    CPQModel_Quote_SL model = serviceRouter.loadContract(contract.Id);
    CPQModel_Product_SL productModel = serviceRouter.loadProductModel(prod.Id, standardPricebookId, 'USD');
    productModel = CPQServiceRouter_SL.setOptionsConfigured(productModel);

    CPQModel_Quote_SL quoteModel = serviceRouter.addProductsToQuote(
      model,
      new List<CPQModel_Product_SL>{ productModel },
      1
    );
    Test.stopTest();

    // Assert
    System.AssertEquals(1, quoteModel.lineItems.size(), 'Should have 1 product line item added');
    SBQQ.TriggerControl.enable();
  }
}