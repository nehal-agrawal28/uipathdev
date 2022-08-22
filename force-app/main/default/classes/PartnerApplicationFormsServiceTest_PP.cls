@IsTest
private class PartnerApplicationFormsServiceTest_PP {
  @IsTest
  static void itShouldShareWithDistributors() {
    // given
    TestFactory_PP.init();
    TestFactory_PP.initPortalUsers();

    String country = 'United States';

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

  @isTest
  public static void shouldGetOwnerIds() {
    //given 2 forms with owner
    List<Partner_Application_Form__c> forms = new List<Partner_Application_Form__c>();
    forms.add(new Partner_Application_Form__c(OwnerId = '0058G000000FXeL'));
    forms.add(new Partner_Application_Form__c(OwnerId = '0058G000000FXeM'));

    //when running getManagersIds
    PartnerApplicationForms_PP formsDomain = (PartnerApplicationForms_PP) Application_PP.Domain.newInstance(
      forms,
      Partner_Application_Form__c.sObjectType
    );
    List<Id> ownerIds = new List<Id>(formsDomain.getOwnerIds());

    //then manager ids should be returned
    System.assertEquals(2, ownerIds.size());
  }

  @isTest
  public static void shouldGetByStatus() {
    //given 2 forms with owner
    List<Partner_Application_Form__c> forms = new List<Partner_Application_Form__c>();
    forms.add(new Partner_Application_Form__c(UIPath_Status__c = 'Approved'));
    forms.add(new Partner_Application_Form__c(UIPath_Status__c = 'Declined'));

    //when running getManagersIds
    PartnerApplicationForms_PP formsDomain = (PartnerApplicationForms_PP) Application_PP.Domain.newInstance(
      forms,
      Partner_Application_Form__c.sObjectType
    );
    List<Partner_Application_Form__c> pafs = formsDomain.selectByStatus(new Set<String>{ 'Approved' }).getRecords();

    //then manager ids should be returned
    System.assertEquals(1, pafs.size());
  }

  @isTest
  public static void shouldGetByComplianceStatus() {
    //given 2 forms with owner
    List<Partner_Application_Form__c> forms = new List<Partner_Application_Form__c>();
    forms.add(new Partner_Application_Form__c(UiPath_Compliance_Status__c = 'Approved'));
    forms.add(new Partner_Application_Form__c(UiPath_Compliance_Status__c = 'Declined'));

    //when running getManagersIds
    PartnerApplicationForms_PP formsDomain = (PartnerApplicationForms_PP) Application_PP.Domain.newInstance(
      forms,
      Partner_Application_Form__c.sObjectType
    );
    List<Partner_Application_Form__c> pafs = formsDomain.selectByComplianceStatusNotIn(
        new Set<String>{ 'In Review', 'Approved' }
      )
      .getRecords();

    //then manager ids should be returned
    System.assertEquals(1, pafs.size());
  }

  @isTest
  public static void itShouldConvertLeadForPAF() {
    // given
    TestFactory_PP.init();
    TestFactory_PP.initPortalUsers();

    String country = 'United States';

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

    Lead lead = new Lead(LastName = 'Test', Company = 'Test', Country = 'Albania', Email = 'test@1234341.uipath.com');
    insert lead;

    Partner_Application_Form__c partnerApplicationForm = new Partner_Application_Form__c(
      Account__c = accountId,
      Contact__c = contactId,
      Country__c = country,
      UiPath_Compliance_Status__c = 'Approved',
      Lead__c = lead.Id
    );
    insert partnerApplicationForm;

    //when
    Test.startTest();
    PartnerApplicationFormsService_PP.aSyncConvertLeadForPAFs(new Set<Id>{ partnerApplicationForm.Id });
    Test.stopTest();

    //then
    List<Lead> leadAfter = [SELECT Id, IsConverted FROM Lead WHERE id = :lead.id];
    System.assert(leadAfter[0].IsConverted);
  }
}