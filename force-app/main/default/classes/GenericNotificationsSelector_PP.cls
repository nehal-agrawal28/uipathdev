public without sharing class GenericNotificationsSelector_PP extends fflib_SObjectSelector {
  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField>{
      GenericNotification_PP__c.Account__c,
      GenericNotification_PP__c.Email__c,
      GenericNotification_PP__c.Id,
      GenericNotification_PP__c.Name,
      GenericNotification_PP__c.Type__c
    };
  }

  public Schema.SObjectType getSObjectType() {
    return GenericNotification_PP__c.sObjectType;
  }

  public static GenericNotificationsSelector_PP newInstance() {
    return (GenericNotificationsSelector_PP) Application_PP.Selector.newInstance(GenericNotification_PP__c.SObjectType);
  }

  public List<GenericNotification_PP__c> selectById(Set<Id> ids, Boolean withSharing) {
    if (withSharing) {
      return (List<GenericNotification_PP__c>) selectSObjectsById(ids);
    } else {
      return (List<GenericNotification_PP__c>) Database.query(
        newQueryFactory(false, false, true).setCondition('Id IN :ids').toSOQL()
      );
    }
  }

  public List<GenericNotification_PP__c> selectByAccountId(Set<Id> accountIds) {
    return (List<GenericNotification_PP__c>) Database.query(
      newQueryFactory(false, false, true).setCondition('Account__c IN :accountIds').toSOQL()
    );
  }

  public List<GenericNotification_PP__c> selectByAccountIdsAndTypes(
    Set<Id> accountIds,
    Set<String> types,
    Boolean withSharing
  ) {
    if (withSharing) {
      return (List<GenericNotification_PP__c>) Database.query(
        newQueryFactory(true, true, true)
          .setCondition('Account__c IN :accountIds')
          .setCondition('Type__c IN :types')
          .toSOQL()
      );
    } else {
      return (List<GenericNotification_PP__c>) Database.query(
        newQueryFactory(false, false, true)
          .setCondition('Account__c IN :accountIds')
          .setCondition('Type__c IN :types')
          .toSOQL()
      );
    }
  }
}