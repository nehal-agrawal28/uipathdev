public without sharing class PartnerApplicationFormsSelector_PP extends fflib_SObjectSelector {
  public static PartnerApplicationFormsSelector_PP newWithoutSharingInstance() {
    return (PartnerApplicationFormsSelector_PP) Application_PP.ElevatedSelector.newInstance(
      Schema.Partner_Application_Form__c.SObjectType
    );
  }

  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField>{
      Partner_Application_Form__c.Account__c,
      Partner_Application_Form__c.Application_Status__c,
      Partner_Application_Form__c.Application_Status_Date__c,
      Partner_Application_Form__c.Authorized_Signatory_Contact__c,
      Partner_Application_Form__c.Authorized_Signatory_Phone__c,
      Partner_Application_Form__c.Authorized_Signatory_Email__c,
      Partner_Application_Form__c.Authorized_Signatory_Title__c,
      Partner_Application_Form__c.Authorized_Signatory_Name__c,
      Partner_Application_Form__c.Contact__c,
      Partner_Application_Form__c.Country__c,
      Partner_Application_Form__c.Email__c,
      Partner_Application_Form__c.Full_Name__c,
      Partner_Application_Form__c.Id,
      Partner_Application_Form__c.Lead__c,
      Partner_Application_Form__c.MPA_Sent_Date__c,
      Partner_Application_Form__c.OwnerId,
      Partner_Application_Form__c.Phone__c,
      Partner_Application_Form__c.UiPath_Status__c,
      Partner_Application_Form__c.UiPath_Compliance_Status__c
    };
  }

  public Schema.SObjectType getSObjectType() {
    return Partner_Application_Form__c.sObjectType;
  }

  public List<Partner_Application_Form__c> selectByAccountId(Set<Id> accountIds) {
    return (List<Partner_Application_Form__c>) Database.query(
      newQueryFactory(false, false, true).setCondition('Account__c IN :accountIds').toSOQL()
    );
  }

  public List<Partner_Application_Form__c> selectById(Set<Id> ids, Boolean withSharing) {
    if (withSharing)
      return (List<Partner_Application_Form__c>) selectSObjectsById(ids);
    else
      return (List<Partner_Application_Form__c>) Database.query(
        newQueryFactory(false, false, true).setCondition('Id IN :ids').toSOQL()
      );
  }

  public List<Partner_Application_Form__c> selectByLeadId(Set<Id> ids) {
    return (List<Partner_Application_Form__c>) Database.query(
      newQueryFactory(false, false, true).setCondition('Lead__c IN :ids').toSOQL()
    );
  }

  public Database.QueryLocator queryLocatorWithStatuses(String applicationStatus, String uipathStatus) {
    return Database.getQueryLocator(
      newQueryFactory()
        .setCondition('Application_Status__c = :applicationStatus')
        .setCondition('UiPath_Status__c = :uipathStatus')
        .toSOQL()
    );
  }

  public Database.QueryLocator queryLocatorWithCountries() {
    return Database.getQueryLocator(
      newQueryFactory()
        .setCondition('Country__c <> NULL')
        .setCondition('NOT Email__c LIKE \'%@qq.com\'')
        .setCondition('NOT Email__c LIKE \'%@delete.com\'')
        .toSOQL()
    );
  }
}