@isTest
public class GroupsServiceTest_PP {
  @isTest
  public static void getFirstLevelUsers() {
    //given there is a group with 2 members one other group and one user
    User user1 = new User(
      Alias = 'mng',
      Email = 'TestAdmin5645@UiPath.com',
      EmailEncodingKey = 'UTF-8',
      LanguageLocaleKey = 'en_US',
      LastName = 'Test Apex',
      LocaleSidKey = 'en_US',
      TimeZoneSidKey = 'America/Los_Angeles',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator']
      .Id,
      Username = 'TestAdminMng3258@UiPath.com'
    );
    insert user1;
    Group group1 = new Group(Name = 'QUEUE NAME TEST', Type = 'Queue');
    insert group1;
    Group group2 = new Group(Name = 'OTHER QUEUE NAME TEST', DeveloperName = 'OTHERQUEUENAMETEST');
    insert group2;
    QueuesObject testQueue = new QueueSObject(QueueID = group1.id, SObjectType = 'Lead');
    GroupMember gmem1 = new GroupMember(UserOrGroupId = user1.id, GroupId = group1.id);
    GroupMember gmem2 = new GroupMember(UserOrGroupId = group2.id, GroupId = group1.id);
    System.runAs(new User(Id = UserInfo.getUserId())) {
      insert testQueue;
      insert gmem1;
      insert gmem2;
    }

    //when calling getFirstLevelUsersByGroupId
    GroupsService_PP gService = new GroupsService_PP();
    Map<Id, List<User>> firstLevelUsersByGroupId = gService.getFirstLevelUsersByGroupId(new Set<Id>{ group1.Id });

    //when calling getFirstLevelUsers
    Set<Id> firstLevelUserId = gService.getFirstLevelUserIds(new Set<Id>{ group1.Id });

    //then only one member should be returned
    System.assertEquals(
      1,
      firstLevelUsersByGroupId.get(group1.Id).size(),
      'Only one of the members was a user, it should return 1 not ' + firstLevelUsersByGroupId.get(group1.Id).size()
    );
    System.assertEquals(
      1,
      firstLevelUserId.size(),
      'Only one of the members was a user, it should return 1 not ' + firstLevelUserId.size()
    );
    System.assertEquals(user1.Id, firstLevelUsersByGroupId.get(group1.Id)[0].Id);
  }
}