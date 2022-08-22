/**
 * @AUTHOR: UIPath
 * @DATE: 01/10/2021
 * @DESCRIPTION: This is territory2 object selector class
 */
public without sharing class Territory2sSelector_ET extends fflib_SObjectSelector {
  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField>{
      Territory2.ID,
      Territory2.Ultimate_Geo__c,
      Territory2.Area__c,
      Territory2.Region__c,
      Territory2.Sales_Territory__c,
      Territory2.Primary_Account_Manager_Id__c,
      Territory2.Interim_Account_Manager_Id__c,
      Territory2.Sales_Area__c,
      Territory2.Sales_Geo__c,
      Territory2.Sales_Region__c,
      Territory2.DeveloperName,
      Territory2.Partner_Manager_Team_Credit__c,
      Territory2.Name,
      Territory2.ParentTerritory2Id,
      Territory2.Recalculate_Compensation__c
    };
  }

  public Schema.SObjectType getSObjectType() {
    return Territory2.sObjectType;
  }

  public List<Territory2> selectById(Set<Id> ids) {
    return (List<Territory2>) Database.query(
      newQueryFactory(false, false, true)
        .setCondition('Id IN :ids')
        .selectField('RVP_Id__c')
        .selectField('AVP_Id__c')
        .selectField('Territory2Type.MasterLabel')
        .toSOQL()
    );
  }

  public List<Territory2> selectSalesTerritory() {
    return (List<Territory2>) Database.query(
      newQueryFactory(false, false, true).setCondition('Sales_Territory__c = true ').toSOQL()
    );
  }

  public List<Territory2> selectSalesTerritoryById(Set<Id> ids) {
    return (List<Territory2>) Database.query(
      newQueryFactory(false, false, true).setCondition('Sales_Territory__c = true AND Id IN :ids').toSOQL()
    );
  }

  public List<Territory2> selectSalesTerritoryByAreaOrRegion(Set<String> area, Set<String> region, Set<String> geo) {
    return (List<Territory2>) Database.query(
      newQueryFactory(false, false, true)
        .setCondition(' ( Area__c IN :area OR region__c in: region OR Ultimate_Geo__c in: geo)')
        .toSOQL()
    );
  }
}