/**
 * @AUTHOR: UIPath
 * @DATE: 26/10/2021
 * @DESCRIPTION: This is ValidateTerritoryAssignment_ET class
 */
public without sharing class ValidateTerritoryAssignment_ET implements IGenericBatch {
  public static Map<Id, List<ObjectTerritory2Association>> mapOfAccountIdToObjTerritories = new Map<Id, List<ObjectTerritory2Association>>();
  public static List<ObjectTerritory2Association> listOfObjTerr2AssToDelete = new List<ObjectTerritory2Association>();
  public static Map<Id, List<UserTerritory2Association>> mapOfTerritory2IdToUserTerritories = new Map<Id, List<UserTerritory2Association>>();
  public Map<Id, Set<String>> mapOfAccountIdToTerritoriesName = new Map<Id, Set<String>>();

  // Implemented execute method which gets called from generic batch execute
  public void execute(Database.BatchableContext BC, List<Sobject> sobjectList) {
    Set<Id> setOfAccountIds = new Set<Id>();
    Set<Id> setOfTerritory2Ids = new Set<Id>();

    ObjectTerritory2AssociationsSelector_ET objAssociationSelector = (ObjectTerritory2AssociationsSelector_ET) Application_ET.Selector.newInstance(
      ObjectTerritory2Association.getSObjectType()
    );
    UserTerritory2AssociationsSelector_ET userAssociationSelector = (UserTerritory2AssociationsSelector_ET) Application_ET.Selector.newInstance(
      UserTerritory2Association.getSObjectType()
    );

    for (ObjectTerritory2Association objTerrAssociation : (List<ObjectTerritory2Association>) sobjectList) {
      if (objTerrAssociation.ObjectId != null) {
        // collecting all account Ids from territories which has recently added/modified
        setOfAccountIds.add(objTerrAssociation.ObjectId);
      }
    }
    if (setOfAccountIds.size() > 0) {
      // Getting all Object Territory Association Record for Sales Territory
      for (
        ObjectTerritory2Association objTerr2Ass : objAssociationSelector.selectByObjectIdAndSalesTerritory(
          setOfAccountIds
        )
      ) {
        setOfTerritory2Ids.add(objTerr2Ass.Territory2Id);
        if (!mapOfAccountIdToObjTerritories.containsKey(objTerr2Ass.ObjectId)) {
          mapOfAccountIdToObjTerritories.put(
            objTerr2Ass.ObjectId,
            new List<ObjectTerritory2Association>{ objTerr2Ass }
          );
        } else {
          mapOfAccountIdToObjTerritories.get(objTerr2Ass.ObjectId).add(objTerr2Ass);
        }
      }
      // Getting all User Territory Association Records which has Primary Account Manager and Primary Temporary - Absence in RoleInTerritory
      for (
        UserTerritory2Association objUserTerr2Ass : userAssociationSelector.selectByRoleInTerritory(
          setOfTerritory2Ids,
          new Set<String>{ ETMConstant.PRIMARY_ACCOUNT_MANAGER, ETMConstant.PRIMARY_TEMPORARY_ABSENCE }
        )
      ) {
        if (!mapOfTerritory2IdToUserTerritories.containsKey(objUserTerr2Ass.Territory2Id)) {
          mapOfTerritory2IdToUserTerritories.put(
            objUserTerr2Ass.Territory2Id,
            new List<UserTerritory2Association>{ objUserTerr2Ass }
          );
        } else {
          mapOfTerritory2IdToUserTerritories.get(objUserTerr2Ass.Territory2Id).add(objUserTerr2Ass);
        }
      }
      for (Id accountId : mapOfAccountIdToObjTerritories.keySet()) {
        // Finding the 0th/Oldest Object Territory Record which is assigned by Territory Assignment Rule
        ObjectTerritory2Association objTerr2Association0th = mapOfAccountIdToObjTerritories.get(accountId)[0];
        Boolean primaryTemporaryAbsenceExist = false;
        Boolean primaryAccountManagerExist = false;
        if (mapOfTerritory2IdToUserTerritories.containsKey(objTerr2Association0th.Territory2Id)) {
          for (
            UserTerritory2Association userAssociation : mapOfTerritory2IdToUserTerritories.get(
              objTerr2Association0th.Territory2Id
            )
          ) {
            if (userAssociation.RoleInTerritory2 == ETMConstant.PRIMARY_TEMPORARY_ABSENCE) {
              primaryTemporaryAbsenceExist = true;
              break;
            }
          }
        }
        // If Primary Temporary - Absence user territory doesn't exists in first territory then delete all other object territories except the territory assigned by Territory Assignment Rule
        if (!primaryTemporaryAbsenceExist) {
          buildObjTerr2AssList(accountId, new Set<Id>{ objTerr2Association0th.Id });
        } else {
          // If Primary Temporary - Absence user territory exists in first territory then we are checking the second territory which is a Manual Territory for Primary Account Manager
          if (mapOfAccountIdToObjTerritories.get(accountId).size() > 1) {
            ObjectTerritory2Association objTerr2Association1st = mapOfAccountIdToObjTerritories.get(accountId)[1];
            for (
              UserTerritory2Association userAssociation : mapOfTerritory2IdToUserTerritories.get(
                objTerr2Association1st.Territory2Id
              )
            ) {
              if (userAssociation.RoleInTerritory2 == ETMConstant.PRIMARY_ACCOUNT_MANAGER) {
                primaryAccountManagerExist = true;
                break;
              }
            }
            // If Primary Account Manager territory exists in secondary assignment then we are deleting all the object territories on account except the first which is assigned by Territory Assignment Rule and second which has Primary Account Manager RoleInTerritory
            if (primaryAccountManagerExist) {
              buildObjTerr2AssList(accountId, new Set<Id>{ objTerr2Association0th.Id, objTerr2Association1st.Id });
            } else {
              // If Primary Account Manager territory doesn't exists in secondary assignment then we are deleting all the object territories on account except the first which is assigned by Territory Assignment Rule
              buildObjTerr2AssList(accountId, new Set<Id>{ objTerr2Association0th.Id });
            }
          }
        }
      }

      prepareAccountWithTerritoriesMapForNotifications(listOfObjTerr2AssToDelete);
      List<Database.DeleteResult> result = Database.delete(listOfObjTerr2AssToDelete, false);
      Logger.debug(new LogMessage('Failed to delete invalid territories', result));
      listOfObjTerr2AssToDelete.clear();
      mapOfTerritory2IdToUserTerritories.clear();
      mapOfAccountIdToObjTerritories.clear();
    }
  }
  public void finish(Database.BatchableContext BC) {
    ETMSystemNotificationService etmSystem = new ETMSystemNotificationService();
    etmSystem.secondaryTerritoryRemovalNotification(mapOfAccountIdToTerritoriesName);
  }
  private void prepareAccountWithTerritoriesMapForNotifications(
    List<ObjectTerritory2Association> listOfObjTerr2AssToDelete
  ) {
    for (ObjectTerritory2Association objTerrAss : listOfObjTerr2AssToDelete) {
      if (!mapOfAccountIdToTerritoriesName.containsKey(objTerrAss.ObjectId)) {
        mapOfAccountIdToTerritoriesName.put(objTerrAss.ObjectId, new Set<String>{ objTerrAss.Territory2.Name });
      } else {
        mapOfAccountIdToTerritoriesName.get(objTerrAss.ObjectId).add(objTerrAss.Territory2.Name);
      }
    }
  }
  private static void buildObjTerr2AssList(Id accountId, Set<Id> excludeObjTerrAssIds) {
    for (ObjectTerritory2Association objTerr2Association : mapOfAccountIdToObjTerritories.get(accountId)) {
      if (
        !excludeObjTerrAssIds.contains(objTerr2Association.Id) &&
        objTerr2Association.AssociationCause != ETMConstant.TERRITORY_ASSIGNMENT_RULE
      ) {
        listOfObjTerr2AssToDelete.add(objTerr2Association);
      }
    }
  }
}