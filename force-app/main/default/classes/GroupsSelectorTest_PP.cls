@IsTest
private class GroupsSelectorTest_PP {
  static testMethod void itShouldReturnTheSObjectType() {
    System.assertEquals(Schema.Group.SObjectType, new GroupsSelector_PP().getSObjectType());
  }

  static testMethod void itShouldReturnGroupById() {
    System.assert(
      new GroupsSelector_PP().selectById(new Set<Id>{ fflib_IDGenerator.generate(Group.SObjectType) }).isEmpty()
    );
  }

  static testMethod void itShouldQueryGroupByName() {
    System.assert(new GroupsSelector_PP().selectGroupByDeveloperName(new Set<String>{ 'NonExistingGroup' }).isEmpty());
  }

  static testMethod void itShouldQueryQueueByName() {
    System.assert(new GroupsSelector_PP().selectQueueByDeveloperName(new Set<String>{ 'NonExistingGroup' }).isEmpty());
  }

  static testMethod void itShouldQueryAllQueues() {
    System.assertEquals(
      [SELECT COUNT() FROM Group WHERE Type = :GroupsSelector_PP.GROUP_TYPE_QUEUE],
      new GroupsSelector_PP().selectAllQueues().size()
    );
  }

  static testMethod void itShouldQueryAllGroups() {
    System.assertEquals(
      [SELECT COUNT() FROM Group WHERE Type = :GroupsSelector_PP.GROUP_TYPE_REGULAR],
      new GroupsSelector_PP().selectAllGroups().size()
    );
  }
}