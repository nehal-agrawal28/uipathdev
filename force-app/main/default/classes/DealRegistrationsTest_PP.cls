@IsTest
public with sharing class DealRegistrationsTest_PP {
  private static final String INCORRECT_ERROR_MESSAGE = 'Incorrect error message: ';

  @testSetup
  static void setup() {
    final Id pricebookId = Test.getStandardPricebookId();

    final Product2 product = new Product2(Name = 'Test Product');
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
      RecordTypeId = DealRegistrationsService_PP.DRAFT_DEAL_REGISTRATION_RT,
      City__c = 'Frankfurt',
      CloseDate__c = Date.today(),
      Competition__c = 'Automation Anywhere',
      Country__c = 'Germany',
      CurrencyIsoCode = 'USD',
      DealRegNotesComments__c = 'Notes',
      DealRegistrationAmount__c = null,
      DealType__c = 'Resale',
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
  static void update_Amount_with_Product() {
    final DealRegistration__c dealReg = [SELECT Id, DealRegistrationAmount__c FROM DealRegistration__c LIMIT 1];
    DmlException expectedException;

    Test.startTest();
    try {
      dealReg.DealRegistrationAmount__c = 4000;
      update dealReg;
    } catch (DmlException d) {
      expectedException = d;
    }
    Test.stopTest();

    System.assertNotEquals(null, expectedException);
  }

  @isTest
  static void try_deleting_submitted_Deal_Registration() {
    DealRegistration__c dealReg = [SELECT Id FROM DealRegistration__c LIMIT 1];
    dealReg.RecordTypeId = DealRegistrationsService_PP.SUBMITTED_DEAL_REGISTRATION_RT;
    update dealReg;
    dealReg = [SELECT Id FROM DealRegistration__c LIMIT 1];
    DmlException expectedException;

    Test.startTest();
    try {
      delete dealReg;
    } catch (DmlException d) {
      expectedException = d;
    }
    Test.stopTest();

    System.assertNotEquals(null, expectedException);
  }

  @isTest
  static void itShouldAutoSubmitNewDealRegistrations() {
    // GIVEN a deal registration
    TestFactory_PP.init();
    TestFactory_PP.initPortalUsers();

    User resellerUser = [SELECT Id, Contact_Account_Id__c FROM User WHERE Name LIKE 'reselleruser%' LIMIT 1];
    Account distributorAccount = [SELECT Id FROM Account WHERE Name LIKE 'distributoraccount%' LIMIT 1];

    DealRegistration__c dealRegistration = TestFactory_PP.buildDealRegistration(
      resellerUser,
      distributorAccount.Id,
      resellerUser.Contact_Account_Id__c,
      null,
      false, // bpo = false
      false // submitted record type
    );
    dealRegistration.DealType__c = 'NFR';

    System.assert([SELECT COUNT() FROM Opportunity] == 0, 'Whoops there is already an Opportunity');

    // WHEN we create a DealRegistration with DealType__c = 'NFR'
    System.Test.startTest();
    insert dealRegistration;
    System.Test.stopTest();

    // THEN the recordType should be changed to Submitted and an opportunity record should be created
    final DealRegistration__c result = [
      SELECT Id, RecordTypeId
      FROM DealRegistration__c
      WHERE Id = :dealRegistration.Id
    ];

    System.assertEquals(
      DealRegistrationsService_PP.SUBMITTED_DEAL_REGISTRATION_RT,
      result.RecordTypeId,
      'The RecordType did not change'
    );
  }

  @isTest
  static void itShouldAutoSubmitUpdatedDealRegistrations() {
    // GIVEN a deal registration
    TestFactory_PP.init();
    TestFactory_PP.initPortalUsers();

    User resellerUser = [SELECT Id, Contact_Account_Id__c FROM User WHERE Name LIKE 'reselleruser%' LIMIT 1];
    Account distributorAccount = [SELECT Id FROM Account WHERE Name LIKE 'distributoraccount%' LIMIT 1];

    DealRegistration__c dealRegistration = TestFactory_PP.buildDealRegistration(
      resellerUser,
      distributorAccount.Id,
      resellerUser.Contact_Account_Id__c,
      null,
      false, // bpo = false
      false // submitted record type
    );
    insert dealRegistration;

    System.assert([SELECT COUNT() FROM Opportunity] == 0, 'Whoops there is already an Opportunity');

    // WHEN we update the DealRegistration to DealType__c = 'NFR'
    System.Test.startTest();
    dealRegistration.DealType__c = 'NFR';
    update dealRegistration;
    System.Test.stopTest();

    // THEN the recordType should be changed to Submitted and an opportunity record should be created
    final DealRegistration__c result = [
      SELECT Id, RecordTypeId
      FROM DealRegistration__c
      WHERE Id = :dealRegistration.Id
    ];

    System.assertEquals(
      DealRegistrationsService_PP.SUBMITTED_DEAL_REGISTRATION_RT,
      result.RecordTypeId,
      'The RecordType did not change'
    );
    System.assert([SELECT COUNT() FROM Opportunity] == 1, 'There should be an opportunity created');
  }

  @IsTest
  static void itShouldValidateTheDealTypeBPO() {
    // GIVEN an Account with BPO business partner contract
    Account account = [SELECT Id, Business_Partner_Contract__c FROM Account LIMIT 1];
    account.Business_Partner_Contract__c = 'BPO';
    account.RecordTypeId = SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Partner').getRecordTypeId();
    update account;
    DealRegistration__c dealRegistration = [SELECT Id FROM DealRegistration__c LIMIT 1];

    // WHEN the deal type is BPO and the deal registration is being submitted
    System.Test.startTest();
    dealRegistration.Account__c = account.Id;
    dealRegistration.BPOOpportunity__c = true;
    dealRegistration.DealType__c = 'BPO';
    dealRegistration.RecordTypeId = DealRegistrationsService_PP.SUBMITTED_DEAL_REGISTRATION_RT;
    update dealRegistration;
    System.Test.stopTest();

    // THEN the deal should be updated
    System.assertEquals(1, [SELECT COUNT() FROM DealRegistration__c WHERE DealType__c = 'BPO' LIMIT 1]);
  }

  @IsTest
  static void itShouldValidateTheDealTypeResale() {
    // GIVEN an Account with Resale business partner contract
    Account account = [SELECT Id, Business_Partner_Contract__c FROM Account LIMIT 1];
    account.Business_Partner_Contract__c = 'License Solution Provider (Resale)';
    account.RecordTypeId = SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Partner').getRecordTypeId();
    update account;
    DealRegistration__c dealRegistration = [SELECT Id FROM DealRegistration__c LIMIT 1];

    // WHEN the deal type is Resale and the deal registration is being submitted
    System.Test.startTest();
    dealRegistration.Account__c = account.Id;
    dealRegistration.BPOOpportunity__c = true;
    dealRegistration.DealType__c = 'Resale';
    dealRegistration.RecordTypeId = DealRegistrationsService_PP.SUBMITTED_DEAL_REGISTRATION_RT;
    update dealRegistration;
    System.Test.stopTest();

    // THEN the deal should be updated
    System.assertEquals(1, [SELECT COUNT() FROM DealRegistration__c WHERE DealType__c = 'Resale' LIMIT 1]);
  }

  @IsTest
  static void itShouldValidateTheDealTypeBPO_Failing() {
    // GIVEN an Account with BPO business partner contract
    Account account = [SELECT Id, Business_Partner_Contract__c FROM Account LIMIT 1];
    account.Business_Partner_Contract__c = 'Resale';
    account.RecordTypeId = SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Partner').getRecordTypeId();
    update account;
    DealRegistration__c dealRegistration = [SELECT Id FROM DealRegistration__c LIMIT 1];

    // WHEN the deal type is BPO and the deal registration is being submitted
    Boolean exceptionThrown = false;
    try {
      System.Test.startTest();
      dealRegistration.Account__c = account.Id;
      dealRegistration.BPOOpportunity__c = true;
      dealRegistration.DealType__c = 'BPO';
      dealRegistration.RecordTypeId = DealRegistrationsService_PP.SUBMITTED_DEAL_REGISTRATION_RT;
      update dealRegistration;
      System.Test.stopTest();
    } catch (Exception e) {
      exceptionThrown = true;
      System.assert(
        e.getMessage().contains(DealRegistrations_PP.BPO_DEALTYPE_IS_NOT_ALLOWED),
        INCORRECT_ERROR_MESSAGE + e.getMessage()
      );
    }

    // THEN the deal should not be updated
    System.assert(exceptionThrown, 'Expected an exception but none thrown');
    System.assertEquals(
      0,
      [
        SELECT COUNT()
        FROM DealRegistration__c
        WHERE
          DealType__c = 'BPO'
          AND Id = :dealRegistration.Id
          AND RecordTypeId = :DealRegistrationsService_PP.SUBMITTED_DEAL_REGISTRATION_RT
        LIMIT 1
      ]
    );
  }

  @IsTest
  static void itShouldValidateTheDealTypeResale_Failing() {
    // GIVEN an Account with BPO only business partner contract
    Account account = [SELECT Id, Business_Partner_Contract__c FROM Account LIMIT 1];
    account.Business_Partner_Contract__c = 'BPO';
    account.RecordTypeId = SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Partner').getRecordTypeId();
    update account;
    DealRegistration__c dealRegistration = [SELECT Id FROM DealRegistration__c LIMIT 1];

    // WHEN the deal type is Resale and the deal registration is being submitted
    Boolean exceptionThrown = false;
    try {
      System.Test.startTest();
      dealRegistration.Account__c = account.Id;
      dealRegistration.BPOOpportunity__c = true;
      dealRegistration.DealType__c = 'Resale';
      dealRegistration.RecordTypeId = DealRegistrationsService_PP.SUBMITTED_DEAL_REGISTRATION_RT;
      update dealRegistration;
      System.Test.stopTest();
    } catch (Exception e) {
      exceptionThrown = true;
      System.assert(
        e.getMessage().contains(DealRegistrations_PP.RESALE_DEALTYPE_IS_NOT_ALLOWED),
        INCORRECT_ERROR_MESSAGE + e.getMessage()
      );
    }

    // THEN the deal should not be updated
    System.assert(exceptionThrown, 'Expected an exception but none thrown');
    System.assertEquals(
      0,
      [
        SELECT COUNT()
        FROM DealRegistration__c
        WHERE
          DealType__c = 'Resale'
          AND Id = :dealRegistration.Id
          AND RecordTypeId = :DealRegistrationsService_PP.SUBMITTED_DEAL_REGISTRATION_RT
        LIMIT 1
      ]
    );
  }

  @IsTest
  static void itShouldValidateTheDealTypeBPO_ReportExceptionToUI() {
    // GIVEN an Account with BPO business partner contract
    Account account = [SELECT Id, Business_Partner_Contract__c FROM Account LIMIT 1];
    account.Business_Partner_Contract__c = 'Resale';
    account.RecordTypeId = SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Partner').getRecordTypeId();
    update account;
    DealRegistration__c dealRegistration = [SELECT Id FROM DealRegistration__c LIMIT 1];

    // WHEN the deal type is BPO and the deal registration is being submitted
    Boolean exceptionThrown = false;
    try {
      System.Test.startTest();
      dealRegistration.Account__c = account.Id;
      dealRegistration.BPOOpportunity__c = true;
      dealRegistration.DealType__c = 'BPO';
      dealRegistration.RecordTypeId = DealRegistrationsService_PP.DRAFT_DEAL_REGISTRATION_RT;
      update dealRegistration;
      SubmitDealRegController_PP.createOpportunityWithProducts(dealRegistration.Id);
      System.Test.stopTest();
    } catch (Exception e) {
      exceptionThrown = true;
      System.assert(
        e.getMessage().contains(DealRegistrations_PP.BPO_DEALTYPE_IS_NOT_ALLOWED),
        INCORRECT_ERROR_MESSAGE + e.getMessage()
      );
    }

    // THEN the deal should not be updated
    System.assert(exceptionThrown, 'Expected an exception but none thrown');
    System.assertEquals(
      0,
      [
        SELECT COUNT()
        FROM DealRegistration__c
        WHERE
          DealType__c = 'BPO'
          AND Id = :dealRegistration.Id
          AND RecordTypeId = :DealRegistrationsService_PP.SUBMITTED_DEAL_REGISTRATION_RT
        LIMIT 1
      ]
    );
  }
}