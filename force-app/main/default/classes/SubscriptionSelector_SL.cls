/**
 * Subscription fflib selector layer
 */
public with sharing class SubscriptionSelector_SL extends fflib_SObjectSelector {
  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField>{
      SBQQ__Subscription__c.SBQQ__NetPrice__c,
      SBQQ__Subscription__c.SBQQ__ListPrice__c,
      SBQQ__Subscription__c.SBQQ__RenewalPrice__c,
      SBQQ__Subscription__c.SBQQ__RenewalUpliftRate__c,
      SBQQ__Subscription__c.SBQQ__ProrateMultiplier__c
    };
  }

  public Schema.SObjectType getSObjectType() {
    return SBQQ__Subscription__c.SObjectType;
  }

  public List<SBQQ__Subscription__c> selectById(Set<Id> ids, Boolean enforceSecurity) {
    if (enforceSecurity) {
      return (List<SBQQ__Subscription__c>) selectSObjectsById(ids);
    } else {
      return (List<SBQQ__Subscription__c>) Database.query(
        newQueryFactory(false, false, true).setCondition('Id IN :ids').toSOQL()
      );
    }
  }

  public List<SBQQ__Subscription__c> selectSubscriptionsFromContractForUplift(Set<Id> contractIdSet) {
    return Database.query(
      newQueryFactory(true)
        .selectField('SBQQ__Product__r.Uplift_Exempt__c')
        .selectField('SBQQ__QuoteLine__c')
        .selectField('SBQQ__QuoteLine__r.SBQQ__ContractedPrice__c')
        .selectField('SBQQ__QuoteLine__r.SBQQ__ContractedPrice__r.SBQQ__ExpirationDate__c')
        .selectField('SBQQ__QuoteLine__r.SBQQ__ListPrice__c')
        .selectField('SBQQ__Account__r.Geo__c')
        .selectField('SBQQ__Account__r.Area__c')
        .setCondition('SBQQ__Contract__c IN :contractIdSet')
        .toSOQL()
    );
  }
}