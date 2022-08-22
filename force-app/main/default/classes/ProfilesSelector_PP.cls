public without sharing class ProfilesSelector_PP extends fflib_SObjectSelector {
  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField>{ Profile.Id, Profile.Name };
  }

  public Schema.SObjectType getSObjectType() {
    return Profile.sObjectType;
  }

  public List<Profile> selectById(Set<Id> idSet) {
    return (List<Profile>) selectSObjectsById(idSet);
  }

  public List<Profile> elevatedSelectByName(Set<String> names) {
    return (List<Profile>) Database.query(newQueryFactory(false, false, true).setCondition('Name IN :names').toSOQL());
  }

  public List<Profile> selectByName(Set<String> names) {
    return (List<Profile>) Database.query(newQueryFactory(true, true, true).setCondition('Name IN :names').toSOQL());
  }
}