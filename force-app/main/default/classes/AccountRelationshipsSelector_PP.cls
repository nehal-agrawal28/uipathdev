public without sharing class AccountRelationshipsSelector_PP extends fflib_SObjectSelector {
  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField>{
      AccountRelationship.AccountFromId,
      AccountRelationship.AccountToId,
      AccountRelationship.Id,
      AccountRelationship.Name,
      AccountRelationship.Type
    };
  }

  public Schema.SObjectType getSObjectType() {
    return AccountRelationship.SObjectType;
  }

  public List<AccountRelationship> selectById(Set<Id> ids, Boolean withSharing) {
    if (withSharing)
      return (List<AccountRelationship>) selectSObjectsById(ids);
    else
      return (List<AccountRelationship>) Database.query(
        newQueryFactory(false, false, true).setCondition('Id IN :ids').toSOQL()
      );
  }

  public List<AccountRelationship> selectByIds(Set<Id> ids, Boolean withSharing) {
    return [
      SELECT AccountFromId, AccountFrom.Name, AccountToId, AccountTo.Name, Type
      FROM AccountRelationship
      WHERE Id IN :ids
    ];
  }

  public List<AccountRelationship> selectByType(String type, Boolean withSharing) {
    if (withSharing)
      return (List<AccountRelationship>) Database.query(
        newQueryFactory(true, true, true).setCondition('Type = :type').toSOQL()
      );
    else
      return (List<AccountRelationship>) Database.query(
        newQueryFactory(false, false, true).setCondition('Type = :type').toSOQL()
      );
  }

  public List<AccountRelationship> selectByAccountIdsAndTypes(
    Set<Id> accountIds,
    Set<String> types,
    Boolean withSharing
  ) {
    /*
		if (withSharing)
			return (List<AccountRelationship>) Database.query(
					newQueryFactory(true, true, true)
							.setCondition('AccountToId IN :accountIds AND AccountFromId IN :accountIds AND Type IN :types')
							.toSOQL()
			);
		else
			return (List<AccountRelationship>) Database.query(
					newQueryFactory(false, false, true)
							.setCondition('AccountToId IN :accountIds AND AccountFromId IN :accountIds AND Type IN :types')
							.toSOQL()
			);
		*/

    return [
      SELECT AccountFromId, AccountFrom.Name, AccountToId, AccountTo.Name, Type
      FROM AccountRelationship
      WHERE AccountToId IN :accountIds AND AccountFromId IN :accountIds AND Type IN :types
    ];
  }

  public List<AccountRelationship> selectByAccountToIdsAndTypes(
    Set<Id> accountToIds,
    Set<String> types,
    Boolean withSharing
  ) {
    if (withSharing)
      return (List<AccountRelationship>) Database.query(
        newQueryFactory(true, true, true).setCondition('AccountToId IN :accountToIds AND Type IN :types').toSOQL()
      );
    else
      return (List<AccountRelationship>) Database.query(
        newQueryFactory(false, false, true).setCondition('AccountToId IN :accountToIds AND Type IN :types').toSOQL()
      );
  }

  public List<AccountRelationship> selectByAccountIds(Set<Id> accountIds, Boolean withSharing) {
    if (withSharing)
      return (List<AccountRelationship>) Database.query(
        newQueryFactory(true, true, true)
          .setCondition('AccountToId IN :accountIds OR AccountFromId IN :accountIds')
          .toSOQL()
      );
    else
      return (List<AccountRelationship>) Database.query(
        newQueryFactory(false, false, true)
          .setCondition('AccountToId IN :accountIds OR AccountFromId IN :accountIds')
          .toSOQL()
      );
  }

  public Database.QueryLocator queryLocatorByCreatedDate(Date createdDate) {
    return Database.getQueryLocator(newQueryFactory().setCondition('CreatedDate >= :createdDate').toSOQL());
  }

  public Database.QueryLocator queryLocatorByType(String type) {
    return Database.getQueryLocator(newQueryFactory().setCondition('Type = :type').toSOQL());
  }

  public Database.QueryLocator queryLocatorAll() {
    return Database.getQueryLocator(newQueryFactory().toSOQL());
  }
}