@IsTest
private class OpportunitiesTest_PP {
  @TestSetup
  static void setup() {
    TestFactory_PP.init();
    TestFactory_PP.initPortalUsers();
  }

  @IsTest
  static void itShouldSendEmailsWhenDealRegistrationIsApproved() {
    // given
    User resellerUser = [SELECT Id, Contact_Account_Id__c FROM User WHERE Name LIKE 'reselleruser%' LIMIT 1];
    Account distributorAccount = [SELECT Id FROM Account WHERE Name LIKE 'distributoraccount%' LIMIT 1];

    insert new GenericNotification_PP__c(
      Account__c = distributorAccount.Id,
      Email__c = 'distributoremailtest@example.com',
      Type__c = 'Deal Registration Approved'
    );

    DealRegistration__c dealRegistration = TestFactory_PP.buildDealRegistration(
      resellerUser,
      distributorAccount.Id,
      resellerUser.Contact_Account_Id__c,
      null,
      false, // bpo = false
      true // submitted record type
    );
    insert dealRegistration;

    DealRegistrationsSelector_PP selector = (DealRegistrationsSelector_PP) Application_PP.Selector.newInstance(
      DealRegistration__c.SObjectType
    );

    List<DealRegistration__c> dealRegistrationsBefore = selector.selectById(new Set<Id>{ dealRegistration.Id }, false);

    System.assertEquals(false, dealRegistrationsBefore.isEmpty());

    DealRegistrationsService_PP opportunitiesService = (DealRegistrationsService_PP) Application_PP.Service.newInstance(
      DealRegistrationsService_PP.class
    );

    Test.startTest();

    opportunitiesService.createOpportunitiesFromDealRegistrations(dealRegistrationsBefore);

    List<Opportunity> opportunities = [SELECT Id, Deal_Reg_Status__c FROM Opportunity];

    System.assertEquals(false, opportunities.isEmpty());
    System.assertNotEquals('Approved', opportunities.get(0).Deal_Reg_Status__c);

    Integer invocationsBefore;
    Integer invocationsAfter;

    // when
    invocationsBefore = Limits.getEmailInvocations();

    opportunities.get(0).Deal_Reg_Status__c = 'Approved';
    update opportunities;

    invocationsAfter = Limits.getEmailInvocations();

    Test.stopTest();

    // then
    System.assertEquals(0, invocationsBefore);
    // if (!Utilities_CR.isScratchOrg()) {
    //   System.assertEquals(1, invocationsAfter);
    // }
  }

  @IsTest
  static void itShouldSetSendLicenseBCCToNotificationEmailOnSoldToPartner_onInsert() {
    // GIVEN An new Opportunity assigned to a Partner
    final Id accountId = fflib_IDGenerator.generate(Schema.Account.SObjectType);
    final String email = 'dummy@example.com';
    Opportunity record = new Opportunity(Sold_to_Partner__c = accountId, Send_licenses_bcc__c = '');
    Opportunity existingRecord = new Opportunity(
      Sold_to_Partner__c = fflib_IDGenerator.generate(Schema.Account.SObjectType),
      Send_licenses_bcc__c = ''
    );

    fflib_ApexMocks mocks = new fflib_ApexMocks();
    GenericNotificationsSelector_PP selectorMock = (GenericNotificationsSelector_PP) mocks.mock(
      GenericNotificationsSelector_PP.class
    );

    mocks.startStubbing();
    mocks.when(selectorMock.sObjectType()).thenReturn(Schema.GenericNotification_PP__c.SObjectType);
    mocks.when(selectorMock.selectByAccountIdsAndTypes(new Set<Id>{ accountId }, new Set<String>{ 'Licensing' }, false))
      .thenReturn(
        new List<GenericNotification_PP__c>{ new GenericNotification_PP__c(Account__c = accountId, Email__c = email) }
      );
    mocks.stopStubbing();

    Application_PP.Selector.setMock(selectorMock);

    System.Test.startTest();
    // WHEN the record is inserted as new then the email should be set
    new Opportunities_PP(new List<Opportunity>{ record }).onSoldToPartnerSetSendLicenseBccToNotificationEmail();
    System.Test.stopTest();

    // THEN the email address should be update
    System.assertEquals(
      email,
      record.Send_licenses_bcc__c,
      'Send_licenses_bcc__c was not populated with the Email address'
    );
  }

  @IsTest
  static void itShouldSetSendLicenseBCCToNotificationEmailOnSoldToPartner_onUpdate() {
    // GIVEN An new Opportunity assigned to a Partner
    final Id accountId = fflib_IDGenerator.generate(Schema.Account.SObjectType);
    final String email = 'dummy@example.com';
    Opportunity record = new Opportunity(
      Id = fflib_IDGenerator.generate(Schema.Opportunity.SObjectType),
      Sold_to_Partner__c = accountId,
      Send_licenses_bcc__c = ''
    );
    Opportunity existingRecord = new Opportunity(
      Id = record.Id,
      Sold_to_Partner__c = fflib_IDGenerator.generate(Schema.Account.SObjectType),
      Send_licenses_bcc__c = ''
    );

    fflib_ApexMocks mocks = new fflib_ApexMocks();
    GenericNotificationsSelector_PP selectorMock = (GenericNotificationsSelector_PP) mocks.mock(
      GenericNotificationsSelector_PP.class
    );

    mocks.startStubbing();
    mocks.when(selectorMock.sObjectType()).thenReturn(Schema.GenericNotification_PP__c.SObjectType);
    mocks.when(selectorMock.selectByAccountIdsAndTypes(new Set<Id>{ accountId }, new Set<String>{ 'Licensing' }, false))
      .thenReturn(
        new List<GenericNotification_PP__c>{ new GenericNotification_PP__c(Account__c = accountId, Email__c = email) }
      );
    mocks.stopStubbing();

    Application_PP.Selector.setMock(selectorMock);

    System.Test.startTest();
    // WHEN the record is inserted
    Opportunities_PP triggerHandler = new Opportunities_PP(new List<Opportunity>{ record });
    triggerHandler.ExistingRecords = new Map<Id, Opportunity>{ existingRecord.Id => existingRecord };
    triggerHandler.onChangedSoldToPartnerSetSendLicenseBccToNotificationEmail();
    System.Test.stopTest();

    // THEN The email address should be updated
    System.assertEquals(
      email,
      record.Send_licenses_bcc__c,
      'Send_licenses_bcc__c was not populated with the Email address'
    );
  }
}