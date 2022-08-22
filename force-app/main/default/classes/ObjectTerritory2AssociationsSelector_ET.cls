/**
 * @AUTHOR: UIPath
 * @DATE: 01/10/2021
 * @DESCRIPTION: This is ObjectTerritory2Association object selector class
 */
public without sharing class ObjectTerritory2AssociationsSelector_ET extends fflib_SObjectSelector {
  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField>{
      ObjectTerritory2Association.ObjectId,
      ObjectTerritory2Association.SystemModstamp
    };
  }

  public Schema.SObjectType getSObjectType() {
    return ObjectTerritory2Association.getSobjectType();
  }

  public List<ObjectTerritory2Association> selectById(Set<Id> objectTerrAssIds) {
    return (List<ObjectTerritory2Association>) Database.query(
      newQueryFactory(false, false, true).setCondition('Id IN :objectTerrAssIds').toSOQL()
    );
  }

  public List<ObjectTerritory2Association> selectByObjectId(Set<Id> objectIds) {
    return (List<ObjectTerritory2Association>) Database.query(
      newQueryFactory(false, false, true)
        .selectField('Territory2.Interim_Account_Manager_Id__c')
        .selectField('Territory2.Primary_Account_Manager_Id__c')
        .selectField('Territory2.Ultimate_Geo__c')
        .selectField('Territory2.Area__c')
        .selectField('Territory2.Region__c')
        .selectField('Territory2.Sales_Territory__c')
        .selectField('Territory2.Territory2Type.MasterLabel')
        .selectField('Territory2.Territory2Type.DeveloperName')
        .selectField('Territory2.Sub_Region_Text__c')
        .selectField('Territory2.Sub_Region_Checkbox__c')
        .addOrdering('SystemModstamp', fflib_QueryFactory.SortOrder.DESCENDING)
        .setCondition('ObjectId IN :objectIds')
        .toSOQL()
    );
  }

  public List<ObjectTerritory2Association> selectByObjectIdAndSalesTerritory(Set<Id> objectIds) {
    return (List<ObjectTerritory2Association>) Database.query(
      newQueryFactory(false, false, true)
        .selectField('Territory2.Interim_Account_Manager_Id__c')
        .selectField('Territory2.Primary_Account_Manager_Id__c')
        .selectField('Territory2.Ultimate_Geo__c')
        .selectField('Territory2.Area__c')
        .selectField('Territory2.Region__c')
        .selectField('Territory2.Sales_Territory__c')
        .selectField('Territory2.Name')
        .selectField('Territory2.Id')
        .selectField('AssociationCause')
        .selectField('Territory2.Sub_Region_Text__c')
        .selectField('Territory2.Sub_Region_Checkbox__c')
        .selectField('Territory2.Territory2Type.MasterLabel')
        .setCondition('ObjectId IN :objectIds AND Territory2.Sales_Territory__c = TRUE')
        .addOrdering('SystemModstamp', fflib_QueryFactory.SortOrder.ASCENDING)
        .toSOQL()
    );
  }

  public List<ObjectTerritory2Association> selectByObjectIdAndNonSalesTerritory(
    Set<Id> objectIds,
    Set<String> territoryTypes
  ) {
    return (List<ObjectTerritory2Association>) Database.query(
      newQueryFactory(false, false, true)
        .selectField('Territory2.Interim_Account_Manager_Id__c')
        .selectField('Territory2.Primary_Account_Manager_Id__c')
        .selectField('Territory2.Ultimate_Geo__c')
        .selectField('Territory2.Area__c')
        .selectField('Territory2.Region__c')
        .selectField('Territory2.Sales_Territory__c')
        .selectField('Territory2.Name')
        .selectField('AssociationCause')
        .selectField('Territory2.Territory2Type.MasterLabel')
        .setCondition(
          'ObjectId IN :objectIds AND Territory2.Sales_Territory__c = FALSE AND Territory2.Territory2Type.MasterLabel =: territoryTypes'
        )
        .addOrdering('SystemModstamp', fflib_QueryFactory.SortOrder.ASCENDING)
        .toSOQL()
    );
  }

  public List<ObjectTerritory2Association> selectByObjectIdAndTerritoryType(
    Set<Id> objectIds,
    Set<String> territoryTypes
  ) {
    return (List<ObjectTerritory2Association>) Database.query(
      newQueryFactory(false, false, true)
        .selectField('Territory2.Interim_Account_Manager_Id__c')
        .selectField('Territory2.Primary_Account_Manager_Id__c')
        .selectField('Territory2.Ultimate_Geo__c')
        .selectField('Territory2.Area__c')
        .selectField('Territory2.Region__c')
        .selectField('Territory2.Sales_Territory__c')
        .selectField('Territory2.Name')
        .selectField('AssociationCause')
        .selectField('Territory2.Territory2Type.MasterLabel')
        .setCondition('ObjectId IN :objectIds AND Territory2.Territory2Type.MasterLabel =: territoryTypes')
        .addOrdering('SystemModstamp', fflib_QueryFactory.SortOrder.ASCENDING)
        .toSOQL()
    );
  }
}