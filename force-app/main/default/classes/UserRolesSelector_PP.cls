public with sharing class UserRolesSelector_PP extends fflib_SObjectSelector {
  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField>{ UserRole.Id, UserRole.Name };
  }

  public Schema.SObjectType getSObjectType() {
    return UserRole.sObjectType;
  }

  public List<UserRole> selectById(Set<Id> ids, Boolean withSharing) {
    if (withSharing) {
      return (List<UserRole>) selectSObjectsById(ids);
    } else {
      return (List<UserRole>) Database.query(newQueryFactory(false, false, true).setCondition('Id IN :ids').toSOQL());
    }
  }

  public List<UserRole> selectByName(Set<String> names, Boolean withSharing) {
    if (withSharing) {
      return (List<UserRole>) Database.query(newQueryFactory(true, true, true).setCondition('Name IN :names').toSOQL());
    } else {
      return (List<UserRole>) Database.query(
        newQueryFactory(false, false, true).setCondition('Name IN :names').toSOQL()
      );
    }
  }
}