public without sharing class UsersSelector_PP extends fflib_SObjectSelector {
  private static final String PARTNER_RECORDTYPE_NAME = 'Partner';
  private static final String BUSINESS_PARTNER_STATUS = 'Good Standing';

  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField>{
      User.AccountId,
      User.ContactAccountBusinessPartnerType__c,
      User.ContactAccountName__c,
      User.Contact_Account_Id__c,
      User.FirstName,
      User.Id,
      User.IsActive,
      User.LastName,
      User.ManagerId,
      User.Name,
      User.ProfileId,
      User.ContactId
    };
  }

  public Schema.SObjectType getSObjectType() {
    return User.sObjectType;
  }

  public List<User> selectById(Set<Id> ids, Boolean withSharing) {
    if (withSharing)
      return (List<User>) selectSObjectsById(ids);
    else
      return (List<User>) Database.query(newQueryFactory(false, false, true).setCondition('Id IN :ids').toSOQL());
  }

  public List<User> selectByEmail(Set<String> emails, Boolean withSharing) {
    if (withSharing)
      return (List<User>) Database.query(newQueryFactory(true, true, true).setCondition('Email IN :emails').toSOQL());
    else
      return (List<User>) Database.query(newQueryFactory(false, false, true).setCondition('Email IN :emails').toSOQL());
  }

  public List<User> selectByUsernames(Set<String> usernames, Boolean withSharing) {
    if (withSharing)
      return (List<User>) Database.query(
        newQueryFactory(true, true, true).setCondition('Username IN :usernames').toSOQL()
      );
    else
      return (List<User>) Database.query(
        newQueryFactory(false, false, true).setCondition('Username IN :usernames').toSOQL()
      );
  }

  public List<User> selectByContactIdAndProfileName(Set<Id> contactIds, Set<String> profileNames, Boolean withSharing) {
    if (withSharing)
      return (List<User>) Database.query(
        newQueryFactory(true, true, true)
          .setCondition('ContactId IN :contactIds AND Profile.Name IN :profileNames AND isActive = true')
          .toSOQL()
      );
    else
      return (List<User>) Database.query(
        newQueryFactory(false, false, true)
          .setCondition('ContactId IN :contactIds AND Profile.Name IN :profileNames AND isActive = true')
          .toSOQL()
      );
  }

  public List<User> selectByAccountIds(Set<Id> accountIds, Boolean withSharing) {
    String condition = 'IsActive = TRUE AND AccountId IN :accountIds';

    if (withSharing)
      return (List<User>) Database.query(newQueryFactory(true, true, true).setCondition(condition).toSOQL());
    else
      return (List<User>) Database.query(newQueryFactory(false, false, true).setCondition(condition).toSOQL());
  }

  public Database.QueryLocator queryLocatorDistributorUsers() {
    return Database.getQueryLocator(
      newQueryFactory()
        .setCondition('IsActive = TRUE AND ContactAccountBusinessPartnerType__c = \'Distributor\'')
        .toSOQL()
    );
  }

  public Database.QueryLocator getUsersByAccountBusinessPartnerType() {
    Set<String> businessPartnerTypes = new Set<String>{ 'VAR', 'LSP', 'GSI' };
    return Database.getQueryLocator(
      newQueryFactory()
        .setCondition(
          'isActive = true AND ContactAccountBusinessPartnerType__c IN: businessPartnerTypes ' +
          'AND Account.RecordType.Name =: PARTNER_RECORDTYPE_NAME AND Account.Business_Partner_Status__c =: BUSINESS_PARTNER_STATUS'
        )
        .toSOQL()
    );
  }
}