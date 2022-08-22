@IsTest
public with sharing class DealRegistrationProductsTest_PP {
  @testSetup
  static void setup() {
    final Id pricebookId = Test.getStandardPricebookId();

    final Product2 product = new Product2(Name = 'Test Product', External_Pricebook_Y_N__c = true);
    insert product;

    final Account acc = new Account(
      Name = 'Deal Reg Partner Account',
      BillingCountry = 'United Kingdom',
      Industry = 'Technology'
    );
    insert acc;

    final PricebookEntry pricebookEntry = new PricebookEntry(
      Pricebook2Id = pricebookId,
      Product2Id = product.Id,
      UnitPrice = 100,
      IsActive = true
    );
    insert pricebookEntry;

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

    ProductSelectionController_PP.createDealRegWithProducts(
      dealReg,
      new List<DealRegistrationProduct__c>{ dealRegProduct }
    );
  }

  @isTest
  static void try_deleting_product_of_submitted_Deal_Registration() {
    final DealRegistration__c dealReg = [SELECT Id FROM DealRegistration__c LIMIT 1];
    dealReg.RecordTypeId = DealRegistrationsService_PP.SUBMITTED_DEAL_REGISTRATION_RT;
    update dealReg;
    DealRegistrationProduct__c dealRegProduct = [SELECT Id FROM DealRegistrationProduct__c LIMIT 1];
    DmlException expectedException;

    Test.startTest();
    try {
      delete dealRegProduct;
    } catch (DmlException d) {
      expectedException = d;
    }
    Test.stopTest();

    System.assertNotEquals(null, expectedException);
  }

  @isTest
  static void changing_product_quantity() {
    final DealRegistrationProduct__c dealRegProduct = [SELECT Id, Quantity__c FROM DealRegistrationProduct__c LIMIT 1];
    Test.startTest();

    dealRegProduct.Quantity__c = 4;
    update dealRegProduct;

    Test.stopTest();

    final Decimal totalAmount = [SELECT Id, DealRegistrationAmount__c FROM DealRegistration__c LIMIT 1]
    .DealRegistrationAmount__c;
    System.assertEquals(400, totalAmount);
  }

  @isTest
  static void delete_product() {
    final DealRegistrationProduct__c dealRegProduct = [SELECT Id FROM DealRegistrationProduct__c LIMIT 1];

    Test.startTest();

    delete dealRegProduct;

    Test.stopTest();

    final Decimal totalAmount = [SELECT Id, DealRegistrationAmount__c FROM DealRegistration__c LIMIT 1]
    .DealRegistrationAmount__c;
    System.assertEquals(null, totalAmount);
  }
}