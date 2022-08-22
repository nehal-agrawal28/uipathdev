public without sharing class AccountsSelector_PP extends fflib_SObjectSelector {
  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField>{
      Account.BillingCity,
      Account.BillingCountry,
      Account.BillingCountryCode,
      Account.BillingState,
      Account.BillingStreet,
      Account.Billing_Address_Concatenated__c,
      Account.Business_Partner_Level__c,
      Account.Business_Partner_Type__c,
      Account.Business_Partner_Contract__c,
      Account.Country__c,
      Account.Date_Joined_Program__c,
      Account.DistributionRelationship__c,
      Account.Id,
      Account.KAM_Id__c,
      Account.Name,
      Account.OwnerId,
      Account.Regional_Business_Partner_Type__c,
      Account.Partner_Application_Form__c,
      Account.Partner_Locator_Contact_Email__c,
      Account.Partner_Reporting_Name__c
    };
  }

  public static AccountsSelector_PP newInstance() {
    return (AccountsSelector_PP) Application_PP.Selector.newInstance(Schema.Account.SObjectType);
  }

  public Schema.SObjectType getSObjectType() {
    return Account.sObjectType;
  }

  public List<Account> selectById(Set<Id> ids, Boolean withSharing) {
    if (withSharing)
      return (List<Account>) selectSObjectsById(ids);
    else
      return (List<Account>) Database.query(newQueryFactory(false, false, true).setCondition('Id IN :ids').toSOQL());
  }

  public List<Account> selectByName(Set<String> names, Boolean withSharing) {
    if (withSharing)
      return (List<Account>) Database.query(newQueryFactory(true, true, true).setCondition('Name IN :names').toSOQL());
    else
      return (List<Account>) Database.query(
        newQueryFactory(false, false, true).setCondition('Name IN :names').toSOQL()
      );
  }

  public List<Account> selectBySearchTermAndRecordTypeIds(
    String searchTerm,
    Set<Id> recordTypeIds,
    Integer limitCount,
    Boolean withSharing
  ) {
    String sanitizedSearchTerm = String.escapeSingleQuotes(searchTerm) + '%';

    fflib_QueryFactory queryFactory = withSharing
      ? newQueryFactory(true, true, true)
      : newQueryFactory(false, false, true);

    return Database.query(
      queryFactory
        .setCondition('Name LIKE :sanitizedSearchTerm AND RecordTypeId IN :recordTypeIds')
        .setOrdering(Account.Name, fflib_QueryFactory.SortOrder.ASCENDING)
        .setLimit(limitCount)
        .toSOQL()
    );
  }

  public Database.QueryLocator queryLocatorByPartnerContributionStatusOlderThanOneYear() {
    Date aYearAgo = System.today().addYears(-1);
    return Database.getQueryLocator(
      newQueryFactory()
        .selectField(Account.Partner_Buys_Through_Disti__c)
        .selectField(Account.Date_Joined_Program__c)
        .selectField(Account.PartnerContributingStatus__c)
        .setCondition(
          'Partner_Buys_Through_Disti__c = TRUE AND ' +
          'PartnerContributingStatus__c = \'Inactive\' AND ' +
          'Date_Joined_Program__c = : aYearAgo'
        )
        .toSOQL()
    );
  }

  public List<Account> selectRecentlyViewedByRecordTypeIds(
    Set<Id> recordTypeIds,
    Integer limitCount,
    Boolean withSharing
  ) {
    fflib_QueryFactory queryFactory = withSharing
      ? newQueryFactory(true, true, true)
      : newQueryFactory(false, false, true);

    return Database.query(
      queryFactory
        .setCondition('RecordTypeId IN :recordTypeIds')
        .setOrdering(Account.LastViewedDate, fflib_QueryFactory.SortOrder.DESCENDING)
        .setLimit(limitCount)
        .toSOQL()
    );
  }
}