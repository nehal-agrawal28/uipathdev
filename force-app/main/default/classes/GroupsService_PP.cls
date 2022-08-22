public without sharing class GroupsService_PP {
  public void assignGroup(List<User> users, String groupName) {
    fflib_ISObjectUnitOfWork uow = Application_PP.UnitOfWork.newInstance();

    List<Group> groups = ((GroupsSelector_PP) Application_PP.Selector.newInstance(Group.SObjectType))
      .selectGroupByDeveloperName(new Set<String>{ groupName });
    Group assignedGroup = groups[0];

    List<GroupMember> groupMembers = new List<GroupMember>();

    for (User user : users) {
      GroupMember member = new GroupMember();
      member.GroupId = assignedGroup.Id;
      member.UserOrGroupId = user.Id;

      groupMembers.add(member);
    }

    uow.registerNew(groupMembers);
    uow.commitWork();
  }

  public Set<Id> getFirstLevelUserIds(Set<Id> groupIds) {
    GroupMembersSelector_PP gMemberSelector = (GroupMembersSelector_PP) Application_PP.Selector.newInstance(
      GroupMember.SObjectType
    );
    List<GroupMember> groupMembers = gMemberSelector.selectByGroupId(groupIds);

    GroupMembers_PP membersDomain = new GroupMembers_PP(groupMembers);
    return membersDomain.getUserIds();
  }

  public Map<Id, List<User>> getFirstLevelUsersByGroupId(Set<Id> groupIds) {
    Map<Id, List<User>> firstLevelUsersByGroupId = new Map<Id, List<User>>();
    UsersSelector_PP userSelector = (UsersSelector_PP) Application_PP.Selector.newInstance(User.SObjectType);
    GroupMembersSelector_PP gMemberSelector = (GroupMembersSelector_PP) Application_PP.Selector.newInstance(
      GroupMember.SObjectType
    );
    List<GroupMember> groupMembers = gMemberSelector.selectByGroupId(groupIds);

    GroupMembers_PP membersDomain = new GroupMembers_PP(groupMembers);
    Map<Id, User> usersByUserId = new Map<Id, User>(userSelector.selectById(membersDomain.getUserIds(), false));

    for (GroupMember objMember : groupMembers) {
      if (String.valueOf(objMember.UserOrGroupId).startsWith('005')) {
        List<User> userList = new List<User>();
        if (firstLevelUsersByGroupId.get(objMember.GroupId) != null) {
          userList = firstLevelUsersByGroupId.get(objMember.GroupId);
        }
        userList.add(usersByUserId.get(objMember.UserOrGroupId));
        firstLevelUsersByGroupId.put(objMember.GroupId, userList);
      }
    }

    return firstLevelUsersByGroupId;
  }
}