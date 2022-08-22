/**
 * @AUTHOR: UIPath
 * @DATE: 21/10/2021
 * @DESCRIPTION: This is the test class for UserTerritory2Association Trigger test
 */
public without sharing class UsersService_ET {
  // This method validates users which are deactivating
  // Throws error if user is associated as primary account manager
  public void validateUsers(List<User> userList) {
    Set<Id> userIds = new Set<Id>();
    Set<String> setOfPrimaryEmailIds = new Set<String>();
    List<User> userListToProcess = new List<User>();
    // Create list of users who are deactivating
    for (User user : userList) {
      if (user.IsActive == false) {
        userIds.add(user.Id);
        userListToProcess.add(user);
      }
    }
    for (ETM_System_Notification__mdt etmMetadata : ETM_System_Notification__mdt.getAll().values()) {
      setOfPrimaryEmailIds.add(etmMetadata.Primary_Email__c);
    }
    // Query UserTerritory2Association where is PAM, IAM or Primary Temporary Absence
    UserTerritory2AssociationsSelector_ET userAssSelector = (UserTerritory2AssociationsSelector_ET) Application_ET.Selector.newInstance(
      UserTerritory2Association.SObjectType
    );
    List<UserTerritory2Association> userAssociationList = userAssSelector.selectByUserIds(
      userIds,
      new Set<String>{
        ETMConstant.PRIMARY_ACCOUNT_MANAGER,
        ETMConstant.PRIMARY_TEMPORARY_ABSENCE,
        ETMConstant.INTERIM_ACCOUNT_MANAGER
      }
    );
    Set<Id> pamUserIds = new Set<Id>();
    Set<Id> iamUserIds = new Set<Id>();
    Set<Id> territoryIds = new Set<Id>();
    Map<Id, UserTerritory2Association> userTerritoryAssociationMap = new Map<Id, UserTerritory2Association>();
    for (UserTerritory2Association userAssociation : userAssociationList) {
      // Create set of PAM user ids
      if (
        userAssociation.RoleInTerritory2 == ETMConstant.PRIMARY_ACCOUNT_MANAGER ||
        userAssociation.RoleInTerritory2 == ETMConstant.PRIMARY_TEMPORARY_ABSENCE
      ) {
        pamUserIds.add(userAssociation.UserId);
      } else if (userAssociation.RoleInTerritory2 == ETMConstant.INTERIM_ACCOUNT_MANAGER) {
        // Create set of IAM user ids
        iamUserIds.add(userAssociation.UserId);
      }
      territoryIds.add(userAssociation.Territory2Id);
      userTerritoryAssociationMap.put(userAssociation.UserId, userAssociation);
    }
    Set<Id> territoryWithPAM = new Set<Id>();

    // Query territory with Primary Account Manager
    for (
      UserTerritory2Association userAss : userAssSelector.selectByRoleInTerritory(
        territoryIds,
        new Set<String>{ ETMConstant.PRIMARY_ACCOUNT_MANAGER }
      )
    ) {
      territoryWithPAM.add(userAss.Territory2Id);
    }
    for (User user : userListToProcess) {
      if (setOfPrimaryEmailIds.contains(user.Email)) {
        user.addError(Label.ETM_System_Notification_User_Deactivation);
      }
      if (pamUserIds.contains(user.Id)) {
        user.addError(Label.ETM_PAM_User_Deactivation_Error_Msg);
      } else if (iamUserIds.contains(user.Id) && userTerritoryAssociationMap.containsKey(user.Id)) {
        UserTerritory2Association userAsso = userTerritoryAssociationMap.get(user.Id);
        // if territoryWithPAM not contains territory id means there is no PAM in the territory
        if (
          userAsso.RoleInTerritory2 == ETMConstant.INTERIM_ACCOUNT_MANAGER &&
          !territoryWithPAM.contains(userAsso.Territory2Id)
        ) {
          user.addError(Label.ETM_Interim_User_Deactivation_Error_Msg);
        }
      }
    }
  }
}