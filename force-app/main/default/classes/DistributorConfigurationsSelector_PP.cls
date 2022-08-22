public without sharing class DistributorConfigurationsSelector_PP extends fflib_SObjectSelector {
  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField>{
      DistributorConfiguration__c.Account__c,
      DistributorConfiguration__c.Country__c,
      DistributorConfiguration__c.Id
    };
  }

  public Schema.SObjectType getSObjectType() {
    return DistributorConfiguration__c.sObjectType;
  }

  public List<DistributorConfiguration__c> selectById(Set<Id> ids, Boolean withSharing) {
    if (withSharing)
      return (List<DistributorConfiguration__c>) selectSObjectsById(ids);
    else
      return (List<DistributorConfiguration__c>) Database.query(
        newQueryFactory(false, false, true).setCondition('Id IN :ids').toSOQL()
      );
  }

  public List<DistributorConfiguration__c> selectByBusinessPartnerTypesAndCountries(
    Set<String> businessPartnerTypes,
    Set<String> countries,
    Boolean withSharing
  ) {
    // skipping query factory to make Account__r.Business_Partner_Type__c work
    return [
      SELECT Id, Account__c, Country__c
      FROM DistributorConfiguration__c
      WHERE Account__r.Business_Partner_Type__c IN :businessPartnerTypes AND Country__c IN :countries
    ];
  }
}