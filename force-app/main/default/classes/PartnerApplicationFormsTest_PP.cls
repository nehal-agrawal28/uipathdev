@IsTest
private class PartnerApplicationFormsTest_PP {
  private static final String UNITED_STATES = 'United States';
  private static final String GEO_AMER = 'AMER';
  private static final String ROMANIA = 'Romania';

  @IsTest
  static void itShouldShareWithDistributors() {
    // given
    TestFactory_PP.init();
    TestFactory_PP.initPortalUsers();

    String country = UNITED_STATES;

    List<Contact> contacts = [
      SELECT Id, AccountId
      FROM Contact
      WHERE Account.Business_Partner_Type__c = 'Distributor' AND Account.BillingCountry = :country
    ];

    System.assertEquals(false, contacts.isEmpty());

    Id accountId = contacts.get(0).AccountId;
    Id contactId = contacts.get(0).Id;

    List<User> users = [SELECT Id FROM User WHERE ContactId = :contactId];

    System.assertEquals(false, users.isEmpty());

    Id userId = users.get(0).Id;

    DistributorConfiguration__c distributorConfiguration = new DistributorConfiguration__c(
      Account__c = accountId,
      Country__c = country
    );

    insert distributorConfiguration;

    Partner_Application_Form__c partnerApplicationForm = new Partner_Application_Form__c(
      Contact__c = contactId,
      Country__c = country
    );

    // when
    Test.startTest();
    //PartnerApplicationFormsService_PP.shareWithDistributors(new List<Partner_Application_Form__c> { partnerApplicationForm });
    insert partnerApplicationForm;
    Test.stopTest();

    // then
    List<Partner_Application_Form__Share> shares = [
      SELECT Id, ParentId, UserOrGroupId
      FROM Partner_Application_Form__Share
    ];

    System.assertEquals(false, shares.isEmpty());
    System.assertEquals(partnerApplicationForm.Id, shares.get(0).ParentId);
    System.assertEquals(userId, shares.get(0).UserOrGroupId);
  }

  @IsTest
  static void itShouldSendApplicationStatusChangeEmail() {
    // given
    Lead lead = new Lead();
    lead.LastName = 'TestSendEmail';
    lead.Company = 'TestCompany';
    lead.Email = 'TestCompany@something.uipath.com';
    lead.Country = ROMANIA;
    insert lead;

    Partner_Application_Form__c partnerApplicationForm = new Partner_Application_Form__c();
    partnerApplicationForm.Lead__c = lead.Id;
    insert partnerApplicationForm;

    // when
    Test.startTest();
    partnerApplicationForm.Application_Status__c = 'Accept';
    partnerApplicationForm.Authorized_Signatory_Email__c = 'test_authSignatory@test.uipath.com';
    partnerApplicationForm.Authorized_Signatory_Name__c = 'Test Auth Signatory';
    partnerApplicationForm.Authorized_Signatory_Phone__c = '+32111111111';
    partnerApplicationForm.Authorized_Signatory_Title__c = 'Mr.';
    update partnerApplicationForm;
    Test.stopTest();

    // then
    System.assertEquals('Accept', partnerApplicationForm.Application_Status__c);
  }

  @IsTest
  static void itShouldUpdateStatusDateChange() {
    // given
    Lead lead = generateLead(ROMANIA);
    insert lead;

    Partner_Application_Form__c partnerApplicationForm = new Partner_Application_Form__c();
    partnerApplicationForm.Lead__c = lead.Id;
    insert partnerApplicationForm;

    // when
    Test.startTest();
    partnerApplicationForm.Application_Status__c = 'Accept';
    partnerApplicationForm.Authorized_Signatory_Email__c = 'test_authSignatory@test.uipath.com';
    partnerApplicationForm.Authorized_Signatory_Name__c = 'Test Auth Signatory';
    partnerApplicationForm.Authorized_Signatory_Phone__c = '+32111111111';
    partnerApplicationForm.Authorized_Signatory_Title__c = 'Mr.';
    partnerApplicationForm.UIPath_Status__c = 'Approved';
    update partnerApplicationForm;
    Test.stopTest();

    // then
    Partner_Application_Form__c partnerApplicationFormUpdated = [
      SELECT Id, Application_Status__c, UIPath_Status__c, Application_Status_Date__c, UIPath_Status_Date__c
      FROM Partner_Application_Form__c
      WHERE Id = :partnerApplicationForm.Id
    ];
    System.assert(partnerApplicationFormUpdated.Application_Status_Date__c != null);
    System.assert(partnerApplicationFormUpdated.UIPath_Status_Date__c != null);
  }

  @IsTest
  static void itShouldSetComplianceLevelToOne() {
    // GIVEN a PAF with only a lead and a PAF with only an contact
    String country = 'Ireland';
    CPI__c cpi = new CPI__c(Name = country, ISO3__c = 'IRE', Score__c = 99);
    insert cpi;
    Lead lead = generateLead();
    lead.Country = country;
    insert lead;
    Account account = new Account(Name = 'Test', BillingCountry = country, Industry = 'Utilities');
    insert account;
    Contact contact = new Contact(
      AccountId = account.Id,
      LastName = 'Smith',
      Email = 'smith@example.com',
      Department__c = 'IT'
    );
    insert contact;

    Partner_Application_Form__c formWithLead = new Partner_Application_Form__c();
    formWithLead.Lead__c = lead.Id;
    Partner_Application_Form__c formWithContact = new Partner_Application_Form__c();
    formWithContact.Contact__c = contact.Id;

    System.Test.startTest();
    insert new List<Partner_Application_Form__c>{ formWithLead, formWithContact };
    System.Test.stopTest();

    Map<Id, Partner_Application_Form__c> result = new Map<Id, Partner_Application_Form__c>(
      [
        SELECT CorruptionPerceptionRisk__c
        FROM Partner_Application_Form__c
        WHERE Id IN :new Set<Id>{ formWithLead.Id, formWithContact.Id }
      ]
    );

    System.assertEquals(
      false,
      result.get(formWithLead.Id).CorruptionPerceptionRisk__c,
      'Incorrect Compliance level added'
    );
    System.assertEquals(
      false,
      result.get(formWithContact.Id).CorruptionPerceptionRisk__c,
      'Incorrect Compliance level added'
    );
  }

  @IsTest
  static void itShouldAssignPartnerApplicationFormToCountriesDefaultManager() {
    // GIVEN a new Application form with country USA
    User user = DataFactory_PP.createUser('John', 'Smith', 'Super Admin', true);
    Lead lead = generateLead(UNITED_STATES);
    lead.OwnerId = user.Id;
    insert lead;
    Partner_Application_Form__c partnerApplicationForm = new Partner_Application_Form__c(Lead__c = lead.Id);

    final Id managerId = UserInfo.getUserId();
    System.assertNotEquals(managerId, [SELECT OwnerId FROM Lead WHERE Id = :lead.Id].OwnerId, 'Oops invalid test data');

    Default_Application_Manager_PP__mdt metadataRecord = generateMetadataRecord(
      UNITED_STATES,
      GEO_AMER,
      managerId,
      true
    );
    List<Default_Application_Manager_PP__mdt> metadataRecords = new List<Default_Application_Manager_PP__mdt>{
      metadataRecord
    };

    fflib_ApexMocks mocks = new fflib_ApexMocks();
    IDefaultApplicationManagersSelector_PP selectorMock = (IDefaultApplicationManagersSelector_PP) mocks.mock(
      IDefaultApplicationManagersSelector_PP.class
    );
    mocks.startStubbing();
    mocks.when(selectorMock.sObjectType()).thenReturn(Default_Application_Manager_PP__mdt.SObjectType);
    mocks.when(selectorMock.selectAll()).thenReturn(metadataRecords);
    mocks.stopStubbing();
    Application_PP.Selector.setMock(selectorMock);

    // WHEN the create the form
    System.Test.startTest();
    insert partnerApplicationForm;
    System.Test.stopTest();

    // THEN the form owner should be set to the managerId from the custom metadata setting
    Partner_Application_Form__c result = [
      SELECT Id, OwnerId
      FROM Partner_Application_Form__c
      WHERE Id = :partnerApplicationForm.Id
    ];
    System.assertEquals(managerId, result.OwnerId, 'The application form was not assigned to the right OwnerId');
  }

  private static Default_Application_Manager_PP__mdt generateMetadataRecord(
    String country,
    String geo,
    Id managerId,
    Boolean mock
  ) {
    Default_Application_Manager_PP__mdt result = new Default_Application_Manager_PP__mdt(
      Country__c = country,
      Geo__c = geo,
      Manager__c = managerId
    );
    if (mock)
      result.Id = fflib_IDGenerator.generate(Schema.Default_Application_Manager_PP__mdt.SObjectType);
    return result;
  }

  private static Lead generateLead(String country) {
    return new Lead(
      LastName = 'TestUpdate',
      Company = 'TestCompany',
      Email = 'TestCompany@something.uipath.com',
      Country = country,
      Department__c = 'IT',
      Department1__c = 'IT'
    );
  }

  private static Lead generateLead() {
    return generateLead(ROMANIA);
  }
}