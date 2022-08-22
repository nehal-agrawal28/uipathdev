public without sharing class AccountRelatedEmailDomainsSelector_PP extends fflib_SObjectSelector {
  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField>{
      AccountRelatedEmailDomain__c.Id,
      AccountRelatedEmailDomain__c.Account__c,
      AccountRelatedEmailDomain__c.EmailDomain__c
    };
  }

  public Schema.SObjectType getSObjectType() {
    return AccountRelatedEmailDomain__c.sObjectType;
  }

  public List<AccountRelatedEmailDomain__c> selectById(Set<Id> ids, Boolean withSharing) {
    if (withSharing)
      return (List<AccountRelatedEmailDomain__c>) selectSObjectsById(ids);
    else
      return (List<AccountRelatedEmailDomain__c>) Database.query(
        newQueryFactory(false, false, true).setCondition('Id IN :ids').toSOQL()
      );
  }

  public List<AccountRelatedEmailDomain__c> selectByEmailDomain(Set<String> emailDomains, Boolean withSharing) {
    if (withSharing)
      return (List<AccountRelatedEmailDomain__c>) Database.query(
        newQueryFactory(true, true, true).setCondition('EmailDomain__r.EmailDomainName__c IN :emailDomains').toSOQL()
      );
    else
      return (List<AccountRelatedEmailDomain__c>) Database.query(
        newQueryFactory(false, false, true).setCondition('EmailDomain__r.EmailDomainName__c IN :emailDomains').toSOQL()
      );
  }

  public List<AccountRelatedEmailDomain__c> selectByAccountIds(List<Id> accountIds, Boolean withSharing) {
    if (withSharing)
      return (List<AccountRelatedEmailDomain__c>) Database.query(
        newQueryFactory(true, true, true).setCondition('Account__c IN :accountIds').toSOQL()
      );
    else
      return (List<AccountRelatedEmailDomain__c>) Database.query(
        newQueryFactory(false, false, true).setCondition('Account__c IN :accountIds').toSOQL()
      );
  }

  public List<AccountRelatedEmailDomain__c> selectBySelfRegCriterias(Set<String> emailDomains, Boolean withSharing) {
    if (withSharing)
      return (List<AccountRelatedEmailDomain__c>) Database.query(
        newQueryFactory(true, true, true)
          .setCondition(
            'EmailDomain__r.EmailDomainName__c IN :emailDomains AND (Account__r.Business_Partner_Status__c = \'Good Standing\' OR Account__r.DisplayasExceptioninPartnerCommunity__c = true)'
          )
          .toSOQL()
      );
    else
      return (List<AccountRelatedEmailDomain__c>) Database.query(
        newQueryFactory(false, false, true)
          .setCondition(
            'EmailDomain__r.EmailDomainName__c IN :emailDomains AND (Account__r.Business_Partner_Status__c = \'Good Standing\' OR Account__r.DisplayasExceptioninPartnerCommunity__c = true)'
          )
          .toSOQL()
      );
  }
}