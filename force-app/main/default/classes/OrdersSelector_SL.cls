public with sharing class OrdersSelector_SL extends fflib_SObjectSelector {
  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField>{
      Order.AccountId,
      Order.EffectiveDate,
      Order.Status,
      Order.Replacement_Order__c,
      Order.SBQQ__Quote__c
    };
  }

  public Schema.SObjectType getSObjectType() {
    return Order.sObjectType;
  }

  public List<Order> selectById(Set<Id> ids, Boolean enforceSecurity) {
    if (enforceSecurity) {
      return (List<Order>) selectSObjectsById(ids);
    } else {
      return (List<Order>) Database.query(newQueryFactory(false, false, true).setCondition('Id IN :ids').toSOQL());
    }
  }

  //TODO - ideomatic fflib
  public List<Order> getCancelledOrdersByReplacedOrders(Set<Id> ids) {
    return [SELECT Id, Status, Replacement_Order__c FROM Order WHERE Replacement_Order__c IN :ids];
  }
}