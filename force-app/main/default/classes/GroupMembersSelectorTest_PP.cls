@IsTest
private class GroupMembersSelectorTest_PP {
  static testMethod void itShouldReturnTheSObjectType() {
    System.assertEquals(Schema.GroupMember.SObjectType, new GroupMembersSelector_PP().getSObjectType());
  }

  static testMethod void itShouldReturnGroupMemberById() {
    System.assert(
      new GroupMembersSelector_PP()
        .selectById(new Set<Id>{ fflib_IDGenerator.generate(GroupMember.SObjectType) })
        .isEmpty()
    );
  }

  static testMethod void itShouldReturnGroupMemberByGroupId() {
    System.assert(
      new GroupMembersSelector_PP()
        .selectByGroupId(new Set<Id>{ fflib_IDGenerator.generate(Group.SObjectType) })
        .isEmpty()
    );
  }
}