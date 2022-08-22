@isTest
private class CommunityAccountTriggerHandlerTest {
  @testSetup
  private static void createData() {
    UserRole r = [SELECT Id FROM UserRole WHERE DeveloperName = 'Operations' LIMIT 1];
    User OperationsUser = [
      SELECT Id, UserRoleId
      FROM User
      WHERE UserRoleId = :r.Id AND Profile.Name = 'System Administrator' AND isActive = TRUE
      LIMIT 1
    ];

    // Create Account
    Account acc = new Account();
    System.runAs(OperationsUser) {
      acc = new Account(Name = 'TestAccount', Country__c = 'Japan', Industry = 'Chemicals', BillingCountry = 'Japan');

      insert acc;
    }
    // Create Contact
    List<Contact> conList = new List<Contact>();
    conList.add(new Contact(AccountId = acc.Id, LastName = 'TestContact01', Email = 'test.contact01@testemail.com', Department__c = 'IT'));
    conList.add(new Contact(AccountId = acc.Id, LastName = 'TestContact02', Email = 'test.contact02@testemail.com', Department__c = 'IT'));
    insert conList;

    // Community Profile
    Profile p = [SELECT Id FROM Profile WHERE Name = 'UiPath Japan Partner Community' LIMIT 1];

    // Create Community User
    List<User> comUserList = new List<User>();
    comUserList.add(
      new User(
        LastName = 'TestCommunityUser1',
        Alias = 'user1',
        Email = 'user1' + Date.today().format() + '@uipath.com.community.testuser',
        UserName = 'user1' + Date.today().format() + '@uipath.com.community.testuser',
        EmailEncodingKey = 'ISO-2022-JP',
        TimeZoneSidKey = 'Asia/Tokyo',
        LocaleSidKey = 'ja_JP',
        LanguageLocaleKey = 'ja',
        ProfileId = p.Id,
        ContactId = conList[0].Id
      )
    );
    comUserList.add(
      new User(
        LastName = 'TestCommunityUser2',
        Alias = 'user2',
        Email = 'user2' + Date.today().format() + '@uipath.com.community.testuser',
        UserName = 'user2' + Date.today().format() + '@uipath.com.community.testuser',
        EmailEncodingKey = 'ISO-2022-JP',
        TimeZoneSidKey = 'Asia/Tokyo',
        LocaleSidKey = 'ja_JP',
        LanguageLocaleKey = 'ja',
        ProfileId = p.Id,
        ContactId = conList[1].Id
      )
    );
    insert comUserList;

    System.runAs(comUserList[0]) {
      Id recordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName()
        .get('UiPath_Japan_Partner_standard')
        .getRecordTypeId();
      // Create Lead
      insert new Lead(
        RecordTypeId = recordTypeId,
        Company = 'TestCompany',
        Status = 'New',
        Country = 'United States',
        LastName = 'NewLead',
        CurrencyIsoCode = 'JPY'
      );
    }
  }

  @isTest
  private static void testcase_01() {
    Lead l = [SELECT Id, OwnerId FROM Lead LIMIT 1];
    UserRole r = [SELECT Id FROM UserRole WHERE DeveloperName = 'Operations' LIMIT 1];
    User OperationsUser = [
      SELECT Id, UserRoleId
      FROM User
      WHERE UserRoleId = :r.Id AND Profile.Name = 'System Administrator' AND isActive = TRUE
      LIMIT 1
    ];

    System.runAs(OperationsUser) {
      insert new Account(
        Name = 'New Account',
        Country__c = 'Japan',
        Industry = 'Chemicals',
        OwnerFromLead__c = l.OwnerId
      );
    }
  }
}