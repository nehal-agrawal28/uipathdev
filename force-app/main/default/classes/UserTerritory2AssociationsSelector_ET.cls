/**
 * @AUTHOR: UIPath
 * @DATE: 01/10/2021
 * @DESCRIPTION: This is UserTerritory2Association object selector class
 */
public without sharing class UserTerritory2AssociationsSelector_ET extends fflib_SObjectSelector {
  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField>{
      UserTerritory2Association.Territory2Id,
      UserTerritory2Association.UserId,
      UserTerritory2Association.RoleInTerritory2
    };
  }
  public Schema.SObjectType getSObjectType() {
    return UserTerritory2Association.sObjectType;
  }

  public List<UserTerritory2Association> selectByTerritoryId(Set<Id> territoryIds) {
    return (List<UserTerritory2Association>) Database.query(
      newQueryFactory(false, false, true)
        .selectField('Territory2.Area__c')
        .selectField('Territory2.Sales_Area__c')
        .selectField('Territory2.Sales_Territory__c')
        .selectField('Territory2.Territory2Type.MasterLabel')
        .selectField('User.Email')
        .selectField('User.Name')
        .selectField('User.Manager.Name')
        .setCondition('Territory2Id =: territoryIds')
        .toSOQL()
    );
  }
  public List<UserTerritory2Association> selectByTerritoryUsers(Set<Id> territoryIds, Set<Id> userIds) {
    return (List<UserTerritory2Association>) Database.query(
      newQueryFactory(false, false, true)
        .selectField('Territory2.Area__c')
        .selectField('Territory2.Sales_Area__c')
        .setCondition('Territory2Id =: territoryIds and UserId =: userIds')
        .toSOQL()
    );
  }

  public List<UserTerritory2Association> selectByRoleInTerritory(Set<Id> territoryIds, Set<String> userTerritoryRoles) {
    return (List<UserTerritory2Association>) Database.query(
      newQueryFactory(false, false, true)
        .selectField('Territory2.Area__c')
        .selectField('Territory2.Sales_Territory__c')
        .selectField('Territory2.Sales_Area__c')
        .selectField('Territory2.Sales_Geo__c')
        .selectField('Territory2.Sales_Region__c')
        .selectField('Territory2.Territory2Type.MasterLabel')
        .selectField('User.Email')
        .selectField('User.Name')
        .selectField('User.Manager.Name')
        .setCondition('Territory2Id =: territoryIds AND RoleInTerritory2 =: userTerritoryRoles')
        .toSOQL()
    );
  }

  public List<UserTerritory2Association> selectByRoleAndTypeInTerritory(
    Set<Id> userIds,
    Set<String> userTerritoryRoles,
    Set<String> territoryTypes
  ) {
    return (List<UserTerritory2Association>) Database.query(
      newQueryFactory(false, false, true)
        .selectField('Territory2.Area__c')
        .selectField('Territory2.Sales_Territory__c')
        .selectField('Territory2.Territory2Type.MasterLabel')
        .setCondition(
          'UserId =: userIds AND RoleInTerritory2 =: userTerritoryRoles AND Territory2.Territory2Type.MasterLabel =: territoryTypes'
        )
        .toSOQL()
    );
  }

  public List<UserTerritory2Association> selectByRoleInTerritoryExcludingIds(
    Set<Id> territoryIds,
    Set<String> userTerritoryRoles,
    List<UserTerritory2Association> userTerritories
  ) {
    return (List<UserTerritory2Association>) Database.query(
      newQueryFactory(false, false, true)
        .selectField('Territory2.Area__c')
        .selectField('Territory2.Sales_Territory__c')
        .setCondition(
          'Territory2Id =: territoryIds AND RoleInTerritory2 =: userTerritoryRoles AND Id !=: userTerritories'
        )
        .toSOQL()
    );
  }

  public List<UserTerritory2Association> selectByAreaTerritories(Set<String> area, Set<String> userTerritoryRoles) {
    return (List<UserTerritory2Association>) Database.query(
      newQueryFactory(false, false, true)
        .selectField('Territory2.Area__c')
        .setCondition(
          'Territory2.Sales_Area__c = true AND Territory2.Area__c =: area AND RoleInTerritory2 =: userTerritoryRoles'
        )
        .toSOQL()
    );
  }

  public List<UserTerritory2Association> selectByGeoAreaRegionTerritories(
    Set<String> geo,
    Set<String> area,
    Set<String> region,
    Set<String> userTerritoryRoles
  ) {
    return (List<UserTerritory2Association>) Database.query(
      newQueryFactory(false, false, true)
        .selectField('Territory2.Ultimate_Geo__c')
        .selectField('Territory2.Area__c')
        .selectField('Territory2.Region__c')
        .selectField('Territory2.Sales_Area__c')
        .selectField('Territory2.Sales_Region__c')
        .selectField('Territory2.Sales_Territory__c')
        .selectField('Territory2.Name')
        .setCondition(
          'Territory2.Ultimate_Geo__c =: geo AND Territory2.Area__c =: area AND Territory2.Region__c =: region AND RoleInTerritory2 =: userTerritoryRoles'
        )
        .toSOQL()
    );
  }
  public List<UserTerritory2Association> selectByUserIds(Set<Id> userIds, Set<String> userTerritoryRoles) {
    return (List<UserTerritory2Association>) Database.query(
      newQueryFactory(false, false, true)
        .selectField('Territory2.Name')
        .selectField('Territory2.Area__c')
        .selectField('Territory2.Sales_Territory__c')
        .setCondition('UserId =: userIds AND RoleInTerritory2 =: userTerritoryRoles')
        .toSOQL()
    );
  }

  public List<UserTerritory2Association> selectByUserIds(Set<Id> userIds) {
    return (List<UserTerritory2Association>) Database.query(
      newQueryFactory(false, false, true)
        .selectField('Territory2.Name')
        .selectField('Territory2.Area__c')
        .selectField('Territory2.Sales_Territory__c')
        .selectField('Territory2.Named_List_Assignment__c')
        .selectField('Territory2.DeveloperName')
        .setCondition('UserId =: userIds  AND Territory2.Sales_Territory__c = true')
        .toSOQL()
    );
  }

  public List<UserTerritory2Association> selectByTerritoryIdsAndDescRoles(Set<Id> territoryIds) {
    return (List<UserTerritory2Association>) Database.query(
      newQueryFactory(false, false, true)
        .selectField('Territory2Id')
        .selectField('RoleInTerritory2')
        .setCondition('Territory2Id IN :territoryIds')
        .addOrdering('RoleInTerritory2', fflib_QueryFactory.SortOrder.DESCENDING)
        .toSOQL()
    );
  }

  public List<UserTerritory2Association> selectAllUsersByTerritory(Set<Id> territoryIds) {
    return (List<UserTerritory2Association>) Database.query(
      newQueryFactory(false, false, true)
        .selectField('UserId')
        .selectField('User.Name')
        .selectField('Territory2Id')
        .selectField('Territory2.Sales_Area__c')
        .selectField('Territory2.Sales_Geo__c')
        .selectField('Territory2.Sales_Region__c')
        .selectField('RoleInTerritory2')
        .setCondition('Territory2Id IN :territoryIds')
        .toSOQL()
    );
  }
}