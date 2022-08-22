public without sharing class NetworksSelector_PP extends fflib_SObjectSelector {
  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField>{ Network.Id };
  }

  public Schema.SObjectType getSObjectType() {
    return Network.sObjectType;
  }

  public List<Network> selectById(Set<Id> ids, Boolean withSharing) {
    if (withSharing)
      return (List<Network>) selectSObjectsById(ids);
    else
      return (List<Network>) Database.query(newQueryFactory(false, false, true).setCondition('Id IN :ids').toSOQL());
  }

  public List<Network> selectByName(Set<String> names, Boolean withSharing) {
    if (withSharing)
      return (List<Network>) Database.query(newQueryFactory(true, true, true).setCondition('Name IN :names').toSOQL());
    else
      return (List<Network>) Database.query(
        newQueryFactory(false, false, true).setCondition('Name IN :names').toSOQL()
      );
  }
}