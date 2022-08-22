@isTest
private class UsersTest_PP {
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
      RecordTypeId = accountPartnerRT
    );
    insert partnerAccount;

    final Contact partnerContact = new Contact(
      LastName = 'Partner Admin Contact',
      AccountId = partnerAccount.Id,
      Email = 'partner_userContact6543@testemail.com',
      Department__c = 'IT'
    );
    insert partnerContact;

    final User partnerAdminUser = new User(
      ContactId = partnerContact.Id,
      Alias = 'alias',
      Email = partnerContact.Email,
      EmailEncodingKey = 'UTF-8',
      LanguageLocaleKey = 'en_US',
      LastName = 'Test Apex',
      LocaleSidKey = 'en_US',
      TimeZoneSidKey = 'America/Los_Angeles',
      ProfileId = [SELECT Id FROM Profile WHERE Name = :System.Label.UiPath_Partner_Comm_Admin_Profile_Name]
      .Id,
      Username = 'TestAdmin@UiPath.com'
    );
    insert partnerAdminUser;

    System.debug('partnerAdminUser Id: ' + partnerAdminUser.Id);
  }

  @isTest
  static void changingProfileUserToManager() {
    final Id partnerAccountId = [SELECT Id FROM Account WHERE Name = 'Partner Account'].Id;

    final Contact partnerContact = new Contact(
      LastName = 'Partner User Contact',
      AccountId = partnerAccountId,
      Email = 'partner_userContact243@testemail.com',
      Department__c = 'IT'
    );
    insert partnerContact;

    User partnerUser = new User(
      ContactId = partnerContact.Id,
      Alias = 'alias',
      Email = partnerContact.Email,
      EmailEncodingKey = 'UTF-8',
      LanguageLocaleKey = 'en_US',
      LastName = 'Test Apex',
      LocaleSidKey = 'en_US',
      TimeZoneSidKey = 'America/Los_Angeles',
      ProfileId = [SELECT Id FROM Profile WHERE Name = :System.Label.UiPath_Partner_Comm_Content_User_Profile_Name]
      .Id,
      Username = 'TestUser@UiPath.com'
    );
    insert partnerUser;

    partnerUser = [SELECT Id FROM User WHERE Id = :partnerUser.Id];
    partnerUser.ProfileId = [SELECT Id FROM Profile WHERE Name = :System.Label.UiPath_Partner_Comm_Manager_Profile_Name]
    .Id;
    User partnerAdminUser = [
      SELECT Id
      FROM User
      WHERE Profile.Name = 'System Administrator' AND isActive = TRUE
      LIMIT 1
    ];
    Test.startTest();
    System.runAs(partnerAdminUser) {
      update partnerUser;
    }
    Test.stopTest();
    partnerUser = [SELECT Profile.Name, UserRole.Name FROM User WHERE Username = 'TestUser@UiPath.com' LIMIT 1];
    System.assertEquals('Partner Account Partner Manager', partnerUser.UserRole.Name);
  }

  @isTest
  static void changingProfileManagerToUser() {
    final Id partnerAccountId = [SELECT Id FROM Account WHERE Name = 'Partner Account'].Id;

    final Contact partnerContact = new Contact(
      LastName = 'Partner User Contact',
      AccountId = partnerAccountId,
      Email = 'partner_userContact23@testemail.com',
      Department__c = 'IT'
    );
    insert partnerContact;

    User partnerManagerUser = new User(
      ContactId = partnerContact.Id,
      Alias = 'alias',
      Email = partnerContact.Email,
      EmailEncodingKey = 'UTF-8',
      LanguageLocaleKey = 'en_US',
      LastName = 'Test Apex',
      LocaleSidKey = 'en_US',
      TimeZoneSidKey = 'America/Los_Angeles',
      ProfileId = [SELECT Id FROM Profile WHERE Name = :System.Label.UiPath_Partner_Comm_Manager_Profile_Name]
      .Id,
      Username = 'TestUser@UiPath.com'
    );
    insert partnerManagerUser;

    partnerManagerUser = [SELECT Id FROM User WHERE Id = :partnerManagerUser.Id];
    partnerManagerUser.ProfileId = [
      SELECT Id
      FROM Profile
      WHERE Name = :System.Label.UiPath_Partner_Comm_Content_User_Profile_Name
    ]
    .Id;
    User partnerAdminUser = [
      SELECT Id
      FROM User
      WHERE Profile.Name = 'System Administrator' AND isActive = TRUE
      LIMIT 1
    ];
    Test.startTest();
    System.runAs(partnerAdminUser) {
      update partnerManagerUser;
    }
    Test.stopTest();

    partnerManagerUser = [SELECT Profile.Name, UserRole.Name FROM User WHERE Username = 'TestUser@UiPath.com' LIMIT 1];
    System.assertEquals('Partner Account Partner User', partnerManagerUser.UserRole.Name);
  }

  @isTest
  public static void shouldGetManagerIds() {
    //given 2 users with manager
    Id partnerAccountId = [SELECT Id FROM User WHERE Username = 'TestAdmin@UiPath.com'].Id;

    List<User> users = new List<User>();
    users.add(new User(ManagerId = partnerAccountId));
    users.add(new User(ManagerId = partnerAccountId));

    //when running getManagersIds
    Users_PP usersDomain = (Users_PP) Application_PP.Domain.newInstance(users, User.sObjectType);
    List<Id> managerIds = new List<Id>(usersDomain.getManagerIds());

    //then manager ids should be returned
    System.assertEquals(partnerAccountId, managerIds[0]);
  }
}