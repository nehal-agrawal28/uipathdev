@IsTest
public with sharing class SubmitDealRegControllerTest_PP {
  @testSetup
  static void setup() {
    final Id pricebookId = Test.getStandardPricebookId();

    final Product2 product = new Product2(Name = 'Test Product');
    insert product;

    final Product2 product2 = new Product2(Name = 'Test Product 2');
    insert product2;

    insert new List<PricebookEntry>{
      new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = product.Id, UnitPrice = 100, IsActive = true),
      new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = product2.Id, UnitPrice = 200, IsActive = true)
    };

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
      DealType__c = 'Resale',
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

    ProductSelectionController_PP.createDealRegWithProducts(
      dealReg,
      new List<DealRegistrationProduct__c>{ dealRegProduct }
    );

    final Id accountPartnerRT = SObjectType.Account.getRecordTypeInfosByDeveloperName()
      .get('Partner')
      .getRecordTypeId();
    insert new Account(
      Name = 'Deal Reg Partner Account',
      Industry = 'Apparel',
      BillingCountry = 'Germany',
      Bypass_validation__c = true,
      Account_Type__c = 'Standard',
      RecordTypeId = accountPartnerRT
    );
  }

  @isTest
  static void create_Deal_Registration_with_Products() {
    final Id dealRegId = [SELECT Id, Name FROM DealRegistration__c LIMIT 1].Id;

    Test.startTest();
    SubmitDealRegController_PP.createOpportunityWithProducts(dealRegId);
    Test.stopTest();

    System.assertNotEquals(null, [SELECT Id FROM Opportunity WHERE Name = 'Test Deal Reg']);
    System.debug('Opp Team: ' + [SELECT Id FROM OpportunityTeamMember]);
    System.debug('Partner Involvement: ' + [SELECT Id FROM Partner_Involvement__c]);
  }
}