@IsTest
public with sharing class SelfRegControllerTest_PP {
  @testSetup
  static void setup() {
    final Id accountPartnerRT = SObjectType.Account.getRecordTypeInfosByDeveloperName()
      .get('Partner')
      .getRecordTypeId();
    final Account partnerAccount = new Account(
      Name = 'Partner Account',
      Industry = 'Apparel',
      BillingCountry = 'Germany',
      Bypass_validation__c = true,
      Account_Type__c = 'Standard',
      DisplayasExceptioninPartnerCommunity__c = true,
      RecordTypeId = accountPartnerRT
    );
    insert partnerAccount;

    final EmailDomain__c emailDomain = new EmailDomain__c(EmailDomainName__c = 'UiPath.com');
    insert emailDomain;

    final AccountRelatedEmailDomain__c accountRelatedEmailDomain = new AccountRelatedEmailDomain__c(
      Account__c = partnerAccount.Id,
      EmailDomain__c = emailDomain.Id
    );
    insert accountRelatedEmailDomain;
  }

  @isTest
  static void create_Partner_User() {
    Test.startTest();

    SelfRegController_PP.getSelfRegData('TestSelfRegApex@UiPath.com');
    final Boolean isSuccess = SelfRegController_PP.createPartner(
      null,
      [SELECT Id FROM Account WHERE Name = 'Partner Account' LIMIT 1]
      .Id,
      'Test Apex',
      'United States',
      true,
      'Self Reg',
      'TestSelfRegApex@UiPath.com'
    );

    Test.stopTest();

    //System.assert(isSuccess);
  }

  @isTest
  static void create_Partner_User_InvalidEmail() {
    Test.startTest();
    SelfRegController_PP.getSelfRegData(' TestSelfRegApex_UiPath.com ');
    final Boolean isSuccess = SelfRegController_PP.createPartner(
      null,
      [SELECT Id FROM Account WHERE Name = 'Partner Account' LIMIT 1]
      .Id,
      'Test Apex',
      'United States',
      true,
      'Self Reg',
      ' TestSelfRegApex_UiPath.com '
    );
    Test.stopTest();

    System.assert(isSuccess == false, 'Expected an exception');
  }

  @isTest
  static void create_Partner_User_with_Error() {
    Test.startTest();

    SelfRegController_PP.getSelfRegData('TestSelfRegApex@UiPath.com');
    final Boolean isSuccess = SelfRegController_PP.createPartner(null, null, '', '', true, '', null);

    Test.stopTest();

    System.assertEquals(false, isSuccess);
  }

  @isTest
  static void try_creating_existing_Partner_User() {
    insert new User(
      ProfileId = [SELECT Id FROM Profile LIMIT 1]
      .Id,
      LastName = 'Test Apex',
      Email = 'TestSelfRegApex@UiPath.com',
      Username = 'TestSelfRegApex@UiPath.com',
      Alias = 'alias',
      TimeZoneSidKey = 'America/Los_Angeles',
      EmailEncodingKey = 'UTF-8',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US'
    );

    Test.startTest();

    SelfRegController_PP.getSelfRegData('TestSelfRegApex@UiPath.com');

    Test.stopTest();
  }
}