public without sharing class GroupMembersSelector_PP extends fflib_SObjectSelector {
  public static GroupMembersSelector_PP newInstance() {
    return (GroupMembersSelector_PP) Application_PP.Selector.newInstance(Schema.GroupMember.SObjectType);
  }

  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField>{ GroupMember.Id, GroupMember.UserOrGroupId, GroupMember.GroupId };
  }

  public Schema.SObjectType getSObjectType() {
    return GroupMember.SObjectType;
  }

  public List<GroupMember> selectById(Set<Id> idSet) {
    return (List<GroupMember>) selectSObjectsById(idSet);
  }

  public List<GroupMember> selectByGroupId(Set<Id> idSet) {
    return (List<GroupMember>) Database.query(
      newQueryFactory(false, false, true).setCondition('GroupId=:idSet').toSOQL()
    );
  }
}