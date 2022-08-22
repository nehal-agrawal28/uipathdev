@IsTest
private class PartnerApplicationFormsSelectorTest_PP {
  @TestSetup
  static void setup() {
    TestFactory_PP.init();
    TestFactory_PP.initPortalUsers();
  }

  @IsTest
  static void itShouldSelectById() {
    // given
    List<Contact> contacts = [
      SELECT Id, Account.BillingCountry
      FROM Contact
      WHERE Account.BillingCountry != NULL
      LIMIT 1
    ];

    Partner_Application_Form__c partnerApplicationForm = new Partner_Application_Form__c(
      Contact__c = contacts.get(0).Id
    );

    insert partnerApplicationForm;

    Set<Id> partnerApplicationFormIds = new Set<Id>{ partnerApplicationForm.Id };

    PartnerApplicationFormsSelector_PP selector = (PartnerApplicationFormsSelector_PP) Application_PP.Selector.newInstance(
      Partner_Application_Form__c.SObjectType
    );

    // when
    List<Partner_Application_Form__c> recordsWithSharing = selector.selectById(partnerApplicationFormIds, true);
    List<Partner_Application_Form__c> recordsWithoutSharing = selector.selectById(partnerApplicationFormIds, false);

    // then
    System.assertEquals(false, recordsWithSharing.isEmpty());
    System.assertEquals(false, recordsWithoutSharing.isEmpty());

    System.assertEquals(partnerApplicationFormIds.size(), recordsWithSharing.size());
    System.assertEquals(partnerApplicationFormIds.size(), recordsWithoutSharing.size());
  }

  @IsTest
  static void itShouldQueryLocatorWithCountries() {
    // given
    List<Contact> contacts = [
      SELECT Id, Account.BillingCountry
      FROM Contact
      WHERE Account.BillingCountry != NULL
      LIMIT 1
    ];

    Partner_Application_Form__c partnerApplicationForm = new Partner_Application_Form__c(
      Contact__c = contacts.get(0).Id
    );

    insert partnerApplicationForm;

    PartnerApplicationFormsSelector_PP selector = (PartnerApplicationFormsSelector_PP) Application_PP.Selector.newInstance(
      Partner_Application_Form__c.SObjectType
    );

    // when
    List<Partner_Application_Form__c> records = Database.query(selector.queryLocatorWithCountries().getQuery());

    // then
    System.assertEquals(false, records.isEmpty());
    System.assertEquals(1, records.size());
  }
}