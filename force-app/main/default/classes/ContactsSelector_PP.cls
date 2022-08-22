public without sharing class ContactsSelector_PP extends fflib_SObjectSelector {
  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField>{
      Contact.Id,
      Contact.AccountId,
      Contact.Email,
      Contact.Firstname,
      Contact.Lastname,
      Contact.Name,
      Contact.OwnerId
    };
  }

  public static ContactsSelector_PP newInstance() {
    return (ContactsSelector_PP) Application_PP.Selector.newInstance(Schema.Contact.SObjectType);
  }

  public Schema.SObjectType getSObjectType() {
    return Contact.sObjectType;
  }

  public List<Contact> selectById(Set<Id> ids, Boolean withSharing) {
    if (withSharing)
      return (List<Contact>) selectSObjectsById(ids);
    else
      return (List<Contact>) Database.query(newQueryFactory(false, false, true).setCondition('Id IN :ids').toSOQL());
  }

  public List<Contact> selectByEmail(Set<String> emails, Boolean withSharing) {
    if (withSharing)
      return (List<Contact>) Database.query(
        newQueryFactory(true, true, true).setCondition('Email IN :emails').toSOQL()
      );
    else
      return (List<Contact>) Database.query(
        newQueryFactory(false, false, true).setCondition('Email IN :emails').toSOQL()
      );
  }

  public List<Contact> selectByAccountId(Set<Id> ids, Boolean withSharing) {
    if (withSharing)
      return (List<Contact>) Database.query(
        newQueryFactory(true, true, true).setCondition('AccountId IN :ids').toSOQL()
      );
    else
      return (List<Contact>) Database.query(
        newQueryFactory(false, false, true).setCondition('AccountId IN :ids').toSOQL()
      );
  }

  public List<Contact> selectBySearchTermAndAccountIds(
    String searchTerm,
    Set<Id> accountIds,
    Integer limitCount,
    Boolean withSharing
  ) {
    String sanitizedSearchTerm = String.escapeSingleQuotes(searchTerm) + '%';

    fflib_QueryFactory queryFactory = withSharing
      ? newQueryFactory(true, true, true)
      : newQueryFactory(false, false, true);

    return Database.query(
      queryFactory
        .setCondition(
          '(FirstName LIKE :sanitizedSearchTerm OR LastName LIKE :sanitizedSearchTerm)' +
          ' AND AccountId IN :accountIds'
        )
        .setOrdering(Contact.Name, fflib_QueryFactory.SortOrder.ASCENDING)
        .setLimit(limitCount)
        .toSOQL()
    );
  }

  public List<Contact> selectRecentlyViewedByAccountIds(Set<Id> accountIds, Integer limitCount, Boolean withSharing) {
    fflib_QueryFactory queryFactory = withSharing
      ? newQueryFactory(true, true, true)
      : newQueryFactory(false, false, true);

    return Database.query(
      queryFactory
        .setCondition('AccountId IN :accountIds')
        .setOrdering(Contact.LastViewedDate, fflib_QueryFactory.SortOrder.DESCENDING)
        .setLimit(limitCount)
        .toSOQL()
    );
  }
}