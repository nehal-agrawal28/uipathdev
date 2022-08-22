public with sharing class DealRegistrationProductsSelector_PP extends fflib_SObjectSelector {
  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField>{
      DealRegistrationProduct__c.DealRegistration__c,
      DealRegistrationProduct__c.Id,
      DealRegistrationProduct__c.PricebookEntryId__c,
      DealRegistrationProduct__c.Quantity__c,
      DealRegistrationProduct__c.UnitPrice__c
    };
  }

  public Schema.SObjectType getSObjectType() {
    return DealRegistrationProduct__c.sObjectType;
  }

  public List<DealRegistrationProduct__c> selectById(Set<Id> ids, Boolean withSharing) {
    if (withSharing)
      return (List<DealRegistrationProduct__c>) selectSObjectsById(ids);
    else
      return (List<DealRegistrationProduct__c>) Database.query(
        newQueryFactory(false, false, true).setCondition('Id IN :ids').toSOQL()
      );
  }

  public List<DealRegistrationProduct__c> selectByDealRegistrationId(Set<Id> ids, Boolean withSharing) {
    if (withSharing)
      return (List<DealRegistrationProduct__c>) Database.query(
        newQueryFactory(true, true, true).setCondition('DealRegistration__c IN :ids').toSOQL()
      );
    else
      return (List<DealRegistrationProduct__c>) Database.query(
        newQueryFactory(false, false, true).setCondition('DealRegistration__c IN :ids').toSOQL()
      );
  }
}