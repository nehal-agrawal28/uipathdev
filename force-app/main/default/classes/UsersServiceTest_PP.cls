@isTest(IsParallel=false)
public class UsersServiceTest_PP {
  private static final String TEST_ADMIN_UI_PATH_COM = 'TestAdmin@UiPath.com';
  private static final String AMERICA_LOS_ANGELES = 'America/Los_Angeles';

  @isTest
  public static void shouldGetManagerByUserId() {
    //given 2 users and a manager
    Set<Id> userIds = new Set<Id>();
    User manager = new User(
      Alias = 'mng',
      Email = TEST_ADMIN_UI_PATH_COM,
      EmailEncodingKey = 'UTF-8',
      LanguageLocaleKey = 'en_US',
      LastName = 'Mng Apex',
      LocaleSidKey = 'en_US',
      TimeZoneSidKey = AMERICA_LOS_ANGELES,
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator']
      .Id,
      Username = 'TestAdminMng_a@UiPath.com'
    );
    insert manager;

    User userWithManager = new User(
      Alias = 'usr1',
      ManagerId = manager.Id,
      Email = TEST_ADMIN_UI_PATH_COM,
      EmailEncodingKey = 'UTF-8',
      LanguageLocaleKey = 'en_US',
      LastName = 'Usr1 Apex',
      LocaleSidKey = 'en_US',
      TimeZoneSidKey = AMERICA_LOS_ANGELES,
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator']
      .Id,
      Username = 'TestAdminUsr1@UiPath.com'
    );
    insert userWithManager;
    userIds.add(userWithManager.Id);

    User userWithoutManager = new User(
      Alias = 'ur2',
      Email = TEST_ADMIN_UI_PATH_COM,
      EmailEncodingKey = 'UTF-8',
      LanguageLocaleKey = 'en_US',
      LastName = 'Usr2 Apex',
      LocaleSidKey = 'en_US',
      TimeZoneSidKey = AMERICA_LOS_ANGELES,
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator']
      .Id,
      Username = 'TestAdminUsr2@UiPath.com'
    );
    insert userWithoutManager;
    userIds.add(userWithoutManager.Id);

    //when running getManagerByUserId
    UsersService_PP usersService = new UsersService_PP();
    Map<Id, User> managerIds = usersService.getManagerByUserId(userIds);

    //then it should return a map with userIds as keys and Manager records as values
    System.assertEquals(1, managerIds.size());
    System.assertEquals(manager.id, managerIds.get(userWithManager.Id).Id);
  }
}