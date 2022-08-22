@IsTest
private class UsersSelectorTest_PP {
  @TestSetup
  static void setup() {
    TestFactory_PP.init();
    TestFactory_PP.initPortalUsers();
  }

  @IsTest
  static void itShouldSelectById() {
    // given
    List<User> usersBefore = [SELECT Id FROM User LIMIT 10];

    Set<Id> userIds = new Set<Id>();

    for (User user : usersBefore) {
      userIds.add(user.Id);
    }

    UsersSelector_PP selector = (UsersSelector_PP) Application_PP.Selector.newInstance(User.SObjectType);

    // when
    List<User> recordsWithSharing = selector.selectById(userIds, true);
    List<User> recordsWithoutSharing = selector.selectById(userIds, false);

    // then
    System.Test.startTest();
    System.assertEquals(false, recordsWithSharing.isEmpty());
    System.assertEquals(false, recordsWithoutSharing.isEmpty());

    System.assertEquals(usersBefore.size(), recordsWithSharing.size());
    System.assertEquals(usersBefore.size(), recordsWithoutSharing.size());
    System.Test.stopTest();
  }

  @IsTest
  static void itShouldselectByEmail() {
    // given
    List<User> usersBefore = [SELECT Email FROM User WHERE Email != NULL AND IsActive = TRUE LIMIT 10];

    Set<String> emails = new Set<String>();

    for (User user : usersBefore) {
      emails.add(user.Email);
    }

    UsersSelector_PP selector = (UsersSelector_PP) Application_PP.Selector.newInstance(User.SObjectType);

    // when
    List<User> recordsWithSharing = selector.selectByEmail(emails, true);
    List<User> recordsWithoutSharing = selector.selectByEmail(emails, false);

    // then
    System.Test.startTest();
    System.assertEquals(false, recordsWithSharing.isEmpty());
    System.assertEquals(false, recordsWithoutSharing.isEmpty());

    System.assert(usersBefore.size() <= recordsWithSharing.size()); //there might be duplicates created
    System.assert(usersBefore.size() <= recordsWithoutSharing.size());
    System.Test.stopTest();
  }

  @IsTest
  static void itShouldSelectByUsernames() {
    // given
    List<User> usersBefore = [SELECT Username FROM User WHERE Username != NULL LIMIT 10];

    Set<String> usernames = new Set<String>();

    for (User user : usersBefore) {
      usernames.add(user.Username);
    }

    UsersSelector_PP selector = (UsersSelector_PP) Application_PP.Selector.newInstance(User.SObjectType);

    // when
    List<User> recordsWithSharing = selector.selectByUsernames(usernames, true);
    List<User> recordsWithoutSharing = selector.selectByUsernames(usernames, false);

    // then
    System.Test.startTest();
    System.assertEquals(false, recordsWithSharing.isEmpty());
    System.assertEquals(false, recordsWithoutSharing.isEmpty());

    System.assertEquals(usersBefore.size(), recordsWithSharing.size());
    System.assertEquals(usersBefore.size(), recordsWithoutSharing.size());
    System.Test.stopTest();
  }

  @IsTest
  static void itShouldSelectByContactIdAndProfileName() {
    // given
    List<User> usersBefore = [
      SELECT ContactId, Profile.Name
      FROM User
      WHERE ContactId != NULL AND IsActive = TRUE
      LIMIT 100
    ];

    Set<Id> contactIds = new Set<Id>();
    Set<String> profileNames = new Set<String>();

    for (User user : usersBefore) {
      contactIds.add(user.ContactId);
      profileNames.add(user.Profile.Name);
    }

    UsersSelector_PP selector = (UsersSelector_PP) Application_PP.Selector.newInstance(User.SObjectType);

    // when
    List<User> recordsWithSharing = selector.selectByContactIdAndProfileName(contactIds, profileNames, true);
    List<User> recordsWithoutSharing = selector.selectByContactIdAndProfileName(contactIds, profileNames, false);

    // then
    System.Test.startTest();
    System.assertEquals(false, recordsWithoutSharing.isEmpty());

    System.assertEquals(usersBefore.size(), recordsWithoutSharing.size());
    System.Test.stopTest();
  }

  @IsTest
  static void itShouldSelectByAccountIds() {
    // given
    List<User> usersBefore = [SELECT AccountId FROM User WHERE AccountId != NULL AND IsActive = TRUE LIMIT 10];

    Set<Id> accountIds = new Set<Id>();

    for (User user : usersBefore) {
      accountIds.add(user.AccountId);
    }

    UsersSelector_PP selector = (UsersSelector_PP) Application_PP.Selector.newInstance(User.SObjectType);

    // when
    List<User> recordsWithSharing = selector.selectByAccountIds(accountIds, true);
    List<User> recordsWithoutSharing = selector.selectByAccountIds(accountIds, false);

    // then
    System.Test.startTest();
    System.assertEquals(false, recordsWithSharing.isEmpty());
    System.assertEquals(false, recordsWithoutSharing.isEmpty());

    System.assert(usersBefore.size() <= recordsWithSharing.size());
    System.assert(usersBefore.size() <= recordsWithoutSharing.size());
    System.Test.stopTest();
  }

  @IsTest
  static void itShouldQueryLocatorDistributorUsers() {
    // given
    UsersSelector_PP selector = (UsersSelector_PP) Application_PP.Selector.newInstance(User.SObjectType);

    // when
    List<User> records = Database.query(selector.queryLocatorDistributorUsers().getQuery());

    // then
    System.Test.startTest();
    System.assertEquals(false, records.isEmpty());
    System.Test.stopTest();
  }
}