public without sharing class GroupMembers_PP extends fflib_SObjects {
  public GroupMembers_PP(List<GroupMember> records) {
    super(records, GroupMember.SObjectType);
  }

  public static GroupMembers_PP newInstance(Set<Id> ids) {
    return (GroupMembers_PP) Application_PP.Domain.newInstance(ids);
  }

  public static GroupMembers_PP newInstance(List<GroupMember> records) {
    return (GroupMembers_PP) Application_PP.Domain.newInstance(records);
  }

  public List<GroupMember> getGroupMembers() {
    return (List<GroupMember>) getRecords();
  }

  public Map<Id, List<String>> getMembersByQueueIds() {
    Map<Id, List<String>> usersByQueueId = new Map<Id, List<String>>();
    for (GroupMember record : getGroupMembers()) {
      List<String> toUsers;
      if (usersByQueueId.get(record.GroupId) == null) {
        toUsers = new List<String>();
      } else {
        toUsers = usersByQueueId.get(record.GroupId);
        toUsers.add(record.UserOrGroupId);
      }
      usersByQueueId.put(record.GroupId, toUsers);
    }
    return usersByQueueId;
  }

  public Set<Id> getUserIds() {
    Set<Id> result = new Set<Id>();
    for (GroupMember record : getGroupMembers()) {
      if (record.UserOrGroupId.getSobjectType() == Schema.User.SObjectType) {
        result.add(record.UserOrGroupId);
      }
    }
    return result;
  }

  public class Constructor implements fflib_IDomainConstructor {
    public fflib_IDomain construct(List<Object> objects) {
      return new GroupMembers_PP((List<SObject>) objects);
    }
  }
}