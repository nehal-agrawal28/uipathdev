public without sharing class OrgWideEmailAddressesSelector_PP extends fflib_SObjectSelector {
  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField>{ OrgWideEmailAddress.Address, OrgWideEmailAddress.Id };
  }

  public Schema.SObjectType getSObjectType() {
    return OrgWideEmailAddress.sObjectType;
  }

  public List<OrgWideEmailAddress> selectById(Set<Id> ids, Boolean withSharing) {
    if (withSharing) {
      return (List<OrgWideEmailAddress>) selectSObjectsById(ids);
    } else {
      return (List<OrgWideEmailAddress>) Database.query(
        newQueryFactory(false, false, true).setCondition('Id IN :ids').toSOQL()
      );
    }
  }

  public List<OrgWideEmailAddress> selectByAddresses(Set<String> addresses, Boolean withSharing) {
    if (withSharing) {
      return (List<OrgWideEmailAddress>) Database.query(
        newQueryFactory(true, true, true).setCondition('Address IN :addresses').toSOQL()
      );
    } else {
      return (List<OrgWideEmailAddress>) Database.query(
        newQueryFactory(false, false, true).setCondition('Address IN :addresses').toSOQL()
      );
    }
  }
}