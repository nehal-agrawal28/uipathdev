public without sharing class UsersSelector_ET extends fflib_SObjectSelector {
  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField>{ User.ID, User.ManagerID, User.Name, User.IsActive };
  }

  public Schema.SObjectType getSObjectType() {
    return User.sObjectType;
  }

  public List<User> selectById(Set<Id> ids) {
    return (List<User>) Database.query(newQueryFactory(false, false, true).setCondition('Id IN :ids').toSOQL());
  }

  public List<User> selectByIdWithManager(Set<Id> ids) {
    return (List<User>) Database.query(
      newQueryFactory(false, false, true).setCondition('Id IN :ids and ManagerId != null').toSOQL()
    );
  }

  public List<User> selectByIdAndActive(Set<Id> ids) {
    return (List<User>) Database.query(
      newQueryFactory(false, false, true).setCondition('Id IN :ids AND isActive = true').toSOQL()
    );
  }
}