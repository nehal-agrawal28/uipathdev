@IsTest
public with sharing class ProductSelectionControllerTest_PP {
  @testSetup
  static void setup() {
    final Product2 product = new Product2(Name = 'Test Product', External_Pricebook_Y_N__c = true);
    insert product;

    final Product2 product2 = new Product2(Name = 'Test Product 2', External_Pricebook_Y_N__c = true);
    insert product2;

    insert new List<PricebookEntry>{
      new PricebookEntry(
        Pricebook2Id = Test.getStandardPricebookId(),
        Product2Id = product.Id,
        UnitPrice = 100,
        IsActive = true
      ),
      new PricebookEntry(
        Pricebook2Id = Test.getStandardPricebookId(),
        Product2Id = product2.Id,
        UnitPrice = 200,
        IsActive = true
      )
    };
  }

  @isTest
  static void create_Deal_Registration_with_Products() {
    final Id pricebookId = Test.getStandardPricebookId();

    final DealRegistration__c dealReg = new DealRegistration__c(
      BPOOpportunity__c = false,
      City__c = 'Frankfurt',
      CloseDate__c = Date.today(),
      Competition__c = 'Automation Anywhere',
      Country__c = 'Germany',
      CurrencyIsoCode = 'USD',
      DealRegNotesComments__c = 'Notes',
      DealRegistrationAmount__c = null,
      Name = 'Test Deal Reg',
      EndCustomerAccountName__c = 'UiPath',
      EndCustomerWebsite__c = 'UiPath.com',
      PartnerCompanySalesEmail__c = 'Test@UiPath.com',
      PartnerCompanySalesPhone__c = '0178945244',
      PartnerCompanySalesRep__c = 'Test Sales Rep',
      PartnerLeadSource__c = 'Advertisement',
      PriceBook__c = pricebookId
    );

    final PricebookEntry pricebookEntry = [SELECT Id, Product2Id FROM PricebookEntry WHERE UnitPrice = 100 LIMIT 1];

    final DealRegistrationProduct__c dealRegProduct = new DealRegistrationProduct__c(
      CurrencyIsoCode = 'USD',
      ListPrice__c = 100,
      Name = 'Test Product',
      PricebookId__c = pricebookId,
      PricebookEntryId__c = pricebookEntry.Id,
      Product__c = pricebookEntry.Product2Id,
      Quantity__c = 2,
      UnitPrice__c = 100
    );

    Test.startTest();

    ProductSelectionController_PP.getPricebookEntries('Standard Pricebook', 'USD');
    final Id dealRegId = ProductSelectionController_PP.createDealRegWithProducts(
      dealReg,
      new List<DealRegistrationProduct__c>{ dealRegProduct }
    );
    ProductSelectionController_PP.getPriceBookAndCurrency(dealReg.Id);

    Test.stopTest();

    System.assertNotEquals(null, dealRegId);
  }

  @isTest
  static void add_Products() {
    final DealRegistration__c dealReg = new DealRegistration__c(
      BPOOpportunity__c = false,
      City__c = 'Frankfurt',
      CloseDate__c = Date.today(),
      Competition__c = 'Automation Anywhere',
      Country__c = 'Germany',
      CurrencyIsoCode = 'USD',
      DealRegNotesComments__c = 'Notes',
      DealRegistrationAmount__c = null,
      Name = 'Test Deal Reg',
      EndCustomerAccountName__c = 'UiPath',
      EndCustomerWebsite__c = 'UiPath.com',
      PartnerCompanySalesEmail__c = 'Test@UiPath.com',
      PartnerCompanySalesPhone__c = '0178945244',
      PartnerCompanySalesRep__c = 'Test Sales Rep',
      PartnerLeadSource__c = 'Advertisement',
      PriceBook__c = Test.getStandardPricebookId()
    );
    insert dealReg;

    final PricebookEntry pricebookEntry = [SELECT Id, Product2Id FROM PricebookEntry WHERE UnitPrice = 200 LIMIT 1];
    final DealRegistrationProduct__c dealRegProduct = new DealRegistrationProduct__c(
      CurrencyIsoCode = 'USD',
      ListPrice__c = 200,
      Name = 'Test Product 2',
      PricebookId__c = Test.getStandardPricebookId(),
      PricebookEntryId__c = pricebookEntry.Id,
      Product__c = pricebookEntry.Product2Id,
      Quantity__c = 2,
      UnitPrice__c = 200
    );

    Test.startTest();
    final Boolean isSuccess = ProductSelectionController_PP.addProducts(
      dealReg.Id,
      new List<DealRegistrationProduct__c>{ dealRegProduct }
    );
    Test.stopTest();

    System.assert(isSuccess);
  }
}