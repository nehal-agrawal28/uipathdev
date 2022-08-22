/**
 * @AUTHOR: UIPath
 * @DATE: 01/10/2021
 * @DESCRIPTION: This is UserTerritory2Association object service class
 */
public without sharing class UserTerritory2AssociationsService_ET {
  private UserTerritory2AssociationsSelector_ET userAssociationSelector = (UserTerritory2AssociationsSelector_ET) Application_ET.Selector.newInstance(
    UserTerritory2Association.SObjectType
  );

  public void setRecalculateCompensationFlag(
    List<UserTerritory2Association> userTerrAssociationList,
    Map<Id, UserTerritory2Association> userTerrAssociationMap
  ) {
    Set<String> setOfSalesRoles = new Set<String>{
      ETMConstant.PRIMARY_ACCOUNT_MANAGER,
      ETMConstant.INTERIM_ACCOUNT_MANAGER,
      ETMConstant.INTERIM_SALES_MANAGER,
      ETMConstant.VACANT_TERRITORY_COMP_USER,
      ETMConstant.REGION_PARTNER_MANAGER
    };

    Set<String> setOfPartnerRoles = new Set<String>{
      ETMConstant.GSI_PARTNER_MANAGER,
      ETMConstant.STRATEGIC_PARTNER_MANAGER,
      ETMConstant.DISTRIBUTION_PARTNER_MANAGER,
      ETMConstant.GLOBAL_GSI_PARTNER_MANAGER,
      ETMConstant.JAPAN_REGION_PARTNER_MANAGER
    };
    Set<Id> setOfTerritory2Ids = new Set<Id>();
    List<Territory2> listOfTerritory2ToUpdate = new List<Territory2>();
    Territory2sSelector_ET territorySelector = (Territory2sSelector_ET) Application_ET.Selector.newInstance(
      Territory2.SObjectType
    );
    Map<Id, Territory2> mapOfTerritory2IdToRecord = getTerritoryMap(userTerrAssociationList);
    for (UserTerritory2Association userTerr : userTerrAssociationList) {
      UserTerritory2Association oldUserTerr;
      Territory2 territory;
      if (userTerrAssociationMap != null) {
        oldUserTerr = userTerrAssociationMap.get(userTerr.Id);
      }
      // If there is a Sales Territory and a new User Territory Association record has created with role from the roles in setOfSalesRoles then the flag Recalculate Compensation set to true to recalculate Opportunity Splits
      // or if there is a non-sales territory and a new User Territory Association record has created with role from the roles in setOfPartnerRoles then the flag Recalculate Compensation set to true to recalculate Opportunity Splits
      if (oldUserTerr == null) {
        if (mapOfTerritory2IdToRecord.containsKey(userTerr.Territory2Id)) {
          territory = mapOfTerritory2IdToRecord.get(userTerr.Territory2Id);
        }
        if (
          territory != null &&
          ((territory.Sales_Territory__c && setOfSalesRoles.contains(userTerr.RoleInTerritory2)) ||
          (!territory.Sales_Territory__c &&
          territory.Territory2Type.MasterLabel == ETMConstant.PARTNER_MANAGEMENT &&
          setOfPartnerRoles.contains(userTerr.RoleInTerritory2)))
        ) {
          setOfTerritory2Ids.add(userTerr.Territory2Id);
        }
      } else if (oldUserTerr != null && oldUserTerr.RoleInTerritory2 != userTerr.RoleInTerritory2) {
        // If there is a Sales Territory and User Territory Association record has changed any roles from the roles in setOfSalesRoles then the flag Recalculate Compensation set to true to recalculate Opportunity Splits
        // If there is a non-sales territory and User Territory Association record has changed any role from the roles in setOfPartnerRoles then the flag Recalculate Compensation set to true to recalculate Opportunity Splits
        if (mapOfTerritory2IdToRecord.containsKey(userTerr.Territory2Id)) {
          territory = mapOfTerritory2IdToRecord.get(userTerr.Territory2Id);
        }
        if (
          territory != null &&
          ((territory.Sales_Territory__c && setOfSalesRoles.contains(userTerr.RoleInTerritory2)) ||
          (!territory.Sales_Territory__c &&
          territory.Territory2Type.MasterLabel == ETMConstant.PARTNER_MANAGEMENT &&
          setOfPartnerRoles.contains(userTerr.RoleInTerritory2)))
        ) {
          setOfTerritory2Ids.add(userTerr.Territory2Id);
        }
        // Assinment of a Non-Japan Region Partner Manager
        if (
          territory != null &&
          territory.Territory2Type.MasterLabel != ETMConstant.PARTNER_MANAGEMENT &&
          userTerr.RoleInTerritory2 == ETMConstant.REGION_PARTNER_MANAGER
        ) {
          setOfTerritory2Ids.add(userTerr.Territory2Id);
        }
      }
    }
    if (setOfTerritory2Ids.size() > 0) {
      // Territory2 is a setup object, therefore calling TerritoryQueueable_ET queuable class to set Recalculate Compensation flag to true
      AbstractQueueable.enqueue(new TerritoryQueueable_ET(setOfTerritory2Ids, true));
    }
  }

  /**
   * This method prevent adding UserTerritory2Association record if one of the below roles is already exist:
   * GSI Partner Manager / Distribution Partner Manager / Strategic Partner Manager / Geo Partner Manager
   */
  public void validatePartnerManagerRoles(
    List<UserTerritory2Association> userTerrAssociationList,
    Map<Id, UserTerritory2Association> existingRecords
  ) {
    Set<Id> setOfTerritory2Id = new Set<Id>();
    Set<String> partnerManagerRoles = new Set<String>{
      ETMConstant.GEO_PARTNER_MANAGER,
      ETMConstant.STRATEGIC_PARTNER_MANAGER,
      ETMConstant.DISTRIBUTION_PARTNER_MANAGER,
      ETMConstant.GSI_PARTNER_MANAGER
    };

    Map<Id, List<UserTerritory2Association>> mapOfTerritory2IdToUsers = new Map<Id, List<UserTerritory2Association>>();
    for (UserTerritory2Association userTerr : userTerrAssociationList) {
      setOfTerritory2Id.add(userTerr.Territory2Id);
    }
    UserTerritory2AssociationsSelector_ET userAssociationSelector = (UserTerritory2AssociationsSelector_ET) Application_ET.Selector.newInstance(
      UserTerritory2Association.getSObjectType()
    );
    for (UserTerritory2Association userTerr : userAssociationSelector.selectByTerritoryId(setOfTerritory2Id)) {
      if (!mapOfTerritory2IdToUsers.containsKey(userTerr.Territory2Id)) {
        mapOfTerritory2IdToUsers.put(userTerr.Territory2Id, new List<UserTerritory2Association>{ userTerr });
      } else {
        mapOfTerritory2IdToUsers.get(userTerr.Territory2Id).add(userTerr);
      }
    }
    for (UserTerritory2Association userTerr : userTerrAssociationList) {
      UserTerritory2Association oldUserTerr;
      if (existingRecords != null) {
        oldUserTerr = existingRecords.get(userTerr.Id);
      }
      if (mapOfTerritory2IdToUsers.containsKey(userTerr.Territory2Id)) {
        for (UserTerritory2Association existingUserTerr : mapOfTerritory2IdToUsers.get(userTerr.Territory2Id)) {
          if (
            oldUserTerr == null &&
            partnerManagerRoles.contains(userTerr.RoleInTerritory2) &&
            partnerManagerRoles.contains(existingUserTerr.RoleInTerritory2)
          ) {
            userTerr.addError(
              'cannot add role: ' +
              userTerr.RoleInTerritory2 +
              ', because some other user is already exist with one of the roles: ' +
              ETMConstant.GEO_PARTNER_MANAGER +
              ', ' +
              ETMConstant.STRATEGIC_PARTNER_MANAGER +
              ', ' +
              ETMConstant.DISTRIBUTION_PARTNER_MANAGER +
              ' or ' +
              ETMConstant.GSI_PARTNER_MANAGER
            );
          } else if (
            oldUserTerr != null &&
            partnerManagerRoles.contains(userTerr.RoleInTerritory2) &&
            oldUserTerr.RoleInTerritory2 != userTerr.RoleInTerritory2 &&
            partnerManagerRoles.contains(existingUserTerr.RoleInTerritory2)
          ) {
            userTerr.addError(
              'cannot add role: ' +
              userTerr.RoleInTerritory2 +
              ', because some other user is already exist with one of the roles: ' +
              ETMConstant.GEO_PARTNER_MANAGER +
              ', ' +
              ETMConstant.STRATEGIC_PARTNER_MANAGER +
              ', ' +
              ETMConstant.DISTRIBUTION_PARTNER_MANAGER +
              ' or ' +
              ETMConstant.GSI_PARTNER_MANAGER
            );
          }
        }
      }
    }
  }

  /**
   * This method rollup the primary account manager and interim account manager's details
   * to the associated territory
   */
  public void validateUserTerritory2Association(List<UserTerritory2Association> userTerrAssociationList) {
    Set<Id> pamTerritoryIds = new Set<Id>();
    Set<Id> territoryIds = new Set<Id>();
    Set<String> rolesInTerr = getRolesInTerritory2();

    for (UserTerritory2Association userAssociation : userTerrAssociationList) {
      // If user role in primary account manager or interim account manager
      if (
        rolesInTerr.contains(userAssociation.RoleInTerritory2) ||
        userAssociation.RoleInTerritory2 == ETMConstant.PRIMARY_TEMPORARY_ABSENCE
      ) {
        territoryIds.add(userAssociation.Territory2Id);
      }
    }

    validateDuplicateUsers(territoryIds, userTerrAssociationList);
  }

  private void validateDuplicateUsers(
    Set<Id> setOfTerritory2Ids,
    List<UserTerritory2Association> userTerritory2Associations
  ) {
    Set<String> rolesInTerr = getRolesInTerritory2();
    Set<String> interimRoles = getInterimManagerRole();
    Set<String> roleToCheckDuplicate = new Set<String>{ ETMConstant.PRIMARY_TEMPORARY_ABSENCE };
    roleToCheckDuplicate.addall(rolesInTerr);
    Map<Id, Set<String>> terrIdExistingUserRoleMap = new Map<Id, Set<String>>();
    if (setOfTerritory2Ids.size() > 0) {
      for (
        UserTerritory2Association objUTA : userAssociationSelector.selectByRoleInTerritoryExcludingIds(
          setOfTerritory2Ids,
          roleToCheckDuplicate,
          userTerritory2Associations
        )
      ) {
        if (!terrIdExistingUserRoleMap.containsKey(objUTA.Territory2Id)) {
          terrIdExistingUserRoleMap.put(objUTA.Territory2Id, new Set<String>{ objUTA.RoleInTerritory2 });
        } else {
          terrIdExistingUserRoleMap.get(objUTA.Territory2Id).add(objUTA.RoleInTerritory2);
        }
      }
      for (UserTerritory2Association objUTA : userTerritory2Associations) {
        if (terrIdExistingUserRoleMap.containsKey(objUTA.Territory2Id)) {
          Set<String> userRoleInTerr = terrIdExistingUserRoleMap.get(objUTA.Territory2Id);
          if (
            interimRoles.contains(objUTA.RoleInTerritory2) &&
            (userRoleInTerr.contains(ETMConstant.INTERIM_ACCOUNT_MANAGER) ||
            userRoleInTerr.contains(ETMConstant.INTERIM_SALES_MANAGER))
          ) {
            objUTA.addError(System.Label.Duplicate_Interim_Account_Manager_Error_Message);
          } else if (
            (objUTA.RoleInTerritory2 == ETMConstant.PRIMARY_ACCOUNT_MANAGER ||
            objUTA.RoleInTerritory2 == ETMConstant.PRIMARY_TEMPORARY_ABSENCE) &&
            (userRoleInTerr.contains(ETMConstant.PRIMARY_ACCOUNT_MANAGER) ||
            userRoleInTerr.contains(ETMConstant.PRIMARY_TEMPORARY_ABSENCE))
          ) {
            objUTA.addError(Label.ETM_Duplicate_PAM_Error_Msg);
          }
        }
      }
    }
  }

  private Map<Id, Territory2> getTerritoryMap(List<UserTerritory2Association> userTerritory2Associations) {
    Set<Id> territoryIds = new Set<Id>();

    for (UserTerritory2Association newUTA : userTerritory2Associations) {
      territoryIds.add(newUTA.Territory2Id);
    }
    Territory2sSelector_ET territorySelector = (Territory2sSelector_ET) Application_ET.Selector.newInstance(
      Territory2.SObjectType
    );
    Map<Id, Territory2> territoryMap = new Map<Id, Territory2>();

    //fetch territory records
    if (territoryIds.size() > 0) {
      territoryMap = new Map<Id, territory2>(territorySelector.selectById(territoryIds));
    }
    return territoryMap;
  }
  /*
   * This method runs on After Update event and validates if any user updates the
   * UserTerritory2Association record with RoleInTerritory2 from Primary Account Manager to
   * Primary - Temporary Absence then a new UserTerritory2Association will be created
   * as Interim Account Manager with the users Manager Id
   * */
  public void processUserAssociationUpdate(
    Map<Id, UserTerritory2Association> existingRecords,
    List<UserTerritory2Association> userTerritory2Associations
  ) {
    Set<Id> territoryIdsForInterim = new Set<Id>();
    Map<Id, UserTerritory2Association> pamUsersToCreateInterimUser = new Map<Id, UserTerritory2Association>();
    Map<Id, UserTerritory2Association> IAMUsersToCreateVACUser = new Map<Id, UserTerritory2Association>();
    Set<Id> pamTerritoryIds = new Set<Id>();
    Set<Id> terrToUpdateIds = new Set<Id>();
    Set<Id> leadTerrIds = new Set<Id>();
    Set<Id> leadUserIds = new Set<Id>();
    Set<Id> RPMTerrIds = new Set<Id>();
    Set<Id> deleteVACTerrIds = new Set<Id>();
    Set<Id> territoryIdsForVAC = new Set<Id>();
    Map<Id, UserTerritory2Association> mapOfOldUTA = existingRecords;
    Map<Id, UserTerritory2Association> userAssMap = new Map<Id, UserTerritory2Association>();
    Map<Id, List<UserTerritory2Association>> TerrAssMap = new Map<Id, List<UserTerritory2Association>>();
    Boolean isDelete = true;
    List<UserTerritory2Association> deletedPAMIAM = new List<UserTerritory2Association>();
    Map<Id, Territory2> territoryMap = getTerritoryMap(userTerritory2Associations);
    Set<String> rolesInTerr = getRolesInTerritory2();
    Set<String> interimRoles = getInterimManagerRole();
    for (UserTerritory2Association newUTA : userTerritory2Associations) {
      Territory2 territory = territoryMap.get(newUTA.Territory2Id);
      UserTerritory2Association oldUTA = mapOfOldUTA != null ? mapOfOldUTA.get(newUTA.Id) : null;
      if (territory != null && territory.Sales_Territory__c == true) {
        // If role changed from Primary Account Manager to Primary Temporary Absence
        if (oldUTA != null) {
          // Rollup IAM details on territory and create IAM
          if (
            oldUTA.RoleInTerritory2 == ETMConstant.PRIMARY_ACCOUNT_MANAGER &&
            newUTA.RoleInTerritory2 == ETMConstant.PRIMARY_TEMPORARY_ABSENCE
          ) {
            territoryIdsForInterim.add(newUTA.Territory2Id);
            pamUsersToCreateInterimUser.put(newUTA.UserId, newUTA);
          } else if (
            interimRoles.contains(oldUTA.RoleInTerritory2) && (!interimRoles.contains(newUTA.RoleInTerritory2))
          ) {
            // Nullify IAM Details on territory
            deletedPAMIAM.add(oldUTA);
          } else if (
            (oldUTA.RoleInTerritory2 == ETMConstant.PRIMARY_ACCOUNT_MANAGER ||
            oldUTA.RoleInTerritory2 == ETMConstant.PRIMARY_TEMPORARY_ABSENCE) &&
            (newUTA.RoleInTerritory2 != ETMConstant.PRIMARY_ACCOUNT_MANAGER &&
            newUTA.RoleInTerritory2 != ETMConstant.PRIMARY_TEMPORARY_ABSENCE)
          ) {
            // If role gets changed from PAM to other role then delete PAM details on territory
            deletedPAMIAM.add(oldUTA);
          } else if (oldUTA.RoleInTerritory2 == ETMConstant.RENEWAL && newUTA.RoleInTerritory2 != ETMConstant.RENEWAL) {
            //if role gets changed from Renewal to other then delete Renewal Specialist details on territory
            // Nullify Renewal Specialist Details on territory
            deletedPAMIAM.add(oldUTA);
          }
        }

        // If new user is IAM or PAM then rollup values on territory
        if (rolesInTerr.contains(newUTA.RoleInTerritory2) || newUTA.RoleInTerritory2 == ETMConstant.RENEWAL) {
          userAssMap.put(newUTA.UserId, newUTA);
          // If primary account manager then delete any interim account manager
          if (newUTA.RoleInTerritory2 == ETMConstant.PRIMARY_ACCOUNT_MANAGER) {
            pamTerritoryIds.add(newUTA.Territory2Id);
          }
          //if Interim Sales Manager is added, then add Vacant Compensation User
          if (newUTA.RoleInTerritory2 == ETMConstant.INTERIM_SALES_MANAGER) {
            territoryIdsForVAC.add(newUTA.Territory2Id);
            IAMUsersToCreateVACUser.put(newUTA.UserId, newUTA);
          }
        } else if (newUTA.RoleInTerritory2 == ETMConstant.GSI_PARTNER_MANAGER) {
          terrToUpdateIds.add(newUTA.Territory2Id);
        }
      }
      if (oldUTA == null || (newUTA.RoleInTerritory2 != oldUTA.RoleInTerritory2)) {
        //Logic to assign Lead based on Role and Territory Type
        if (
          newUTA.RoleInTerritory2 == ETMConstant.GEO_LEADER ||
          newUTA.RoleInTerritory2 == ETMConstant.AREA_VP ||
          newUTA.RoleInTerritory2 == ETMConstant.REGION_VP
        )
          isDelete = false;
        else if (newUTA.RoleInTerritory2 == ETMConstant.REGION_PARTNER_MANAGER) {
          if (!RPMTerrIds.contains(newUTA.Territory2Id))
            RPMTerrIds.add(newUTA.Territory2Id);
        } else if (
          newUTA.RoleInTerritory2 == ETMConstant.GSI_PARTNER_MANAGER ||
          newUTA.RoleInTerritory2 == ETMConstant.STRATEGIC_PARTNER_MANAGER ||
          newUTA.RoleInTerritory2 == ETMConstant.DISTRIBUTION_PARTNER_MANAGER
        ) {
          //logic to delete user with role Vacant Territory Compensation Partner Mgr
          deleteVACTerrIds.add(newUTA.Territory2Id);
        }

        List<UserTerritory2Association> lstUTA = new List<UserTerritory2Association>();
        leadTerrIds.add(newUTA.Territory2Id);
        leadUserIds.add(newUTA.UserId);
        if (!TerrAssMap.containsKey(newUTA.Territory2Id))
          lstUTA.add(newUTA);
        else {
          List<UserTerritory2Association> lstoldUTA = TerrAssMap.get(newUTA.Territory2Id);
          lstUTA.addall(lstoldUTA);
          lstUTA.add(newUTA);
        }
        TerrAssMap.put(newUTA.Territory2Id, lstUTA);
      }
    }

    if (territoryIdsForInterim.size() > 0) {
      List<UserTerritory2Association> newInterimUsers = setPAMManagerAsInterim(
        territoryIdsForInterim,
        pamUsersToCreateInterimUser
      );
      for (UserTerritory2Association userTerr : newInterimUsers) {
        userAssMap.put(userTerr.UserId, userTerr);
      }
    }
    // Delete interim account manager from the territory if primary account manager is created
    deletedPAMIAM.addAll(deleteInterimAccountManagers(pamTerritoryIds));

    if (userAssMap.size() > 0 || terrToUpdateIds.size() > 0) {
      updateUserDetailsOnTerritory(userAssMap, terrToUpdateIds);
    }
    if (leadTerrIds.size() > 0) {
      updateLeadonTerritory(TerrAssMap, leadTerrIds);
    }
    if (deletedPAMIAM.size() > 0) {
      processUserAssociationDelete(deletedPAMIAM, false);
    }

    if (RPMTerrIds.size() > 0) {
      updateRPMonTerritory(RPMTerrIds);
    }
    if (deleteVACTerrIds.size() > 0) {
      deleteVacantTerritoryManagers(deleteVACTerrIds, new Set<String>{ ETMConstant.VACANT_TERR_COMP_PART_MANAGER });
    }

    if (territoryIdsForVAC.size() > 0) {
      updateVACUserOnTerritory(territoryIdsForVAC, IAMUsersToCreateVACUser);
    }
  }

  /**
   * Case 1: When primary account manager is deleted
   *            a. Nullify the PAM details from territory
   *            b. set its manager as interim account manager and set its details on territory
   * Case 2: When interim account manager is deleted
   *         a. Nullify its details from territory
   */
  public void processUserAssociationDelete(
    List<UserTerritory2Association> userTerrAssociationList,
    boolean createInterim
  ) {
    Set<Id> setOfTerritory2Ids = new Set<Id>();
    Map<Id, UserTerritory2Association> mapOfTerritory2IdToUTARecord = new Map<Id, UserTerritory2Association>();
    final fflib_ISObjectUnitOfWork unitOfWork = Application_ET.UnitOfWork.newInstance();
    Map<Id, UserTerritory2Association> pamUserIds = new Map<Id, UserTerritory2Association>();

    Set<Id> leadTerrIds = new Set<Id>();
    Set<Id> leadUserIds = new Set<Id>();
    Set<Id> RPMTerrIds = new Set<Id>();
    Set<Id> deleteVACTerrIds = new Set<Id>();
    Set<Id> territoryIdsForVAC = new Set<Id>();
    Map<Id, UserTerritory2Association> PTAUsersToCreateVACUser = new Map<Id, UserTerritory2Association>();
    Map<Id, List<UserTerritory2Association>> TerrAssMap = new Map<Id, List<UserTerritory2Association>>();
    Boolean isDelete = true;
    Map<Id, Territory2> territoryMap = getTerritoryMap(userTerrAssociationList);
    Map<Id, Territory2> territoryMapToUpdate = getTerritoryMap(userTerrAssociationList);
    Set<String> interimRole = getInterimManagerRole();
    for (UserTerritory2Association userAssociation : userTerrAssociationList) {
      Territory2 terr = territoryMap.get(userAssociation.Territory2Id);

      if (terr != null) {
        // If primary account manager & primary temporary Absense is deleted then nullify PAM details on territory
        if (
          terr.Sales_Territory__c == true &&
          (userAssociation.RoleInTerritory2 == ETMConstant.PRIMARY_ACCOUNT_MANAGER ||
          userAssociation.RoleInTerritory2 == ETMConstant.PRIMARY_TEMPORARY_ABSENCE)
        ) {
          // If PAM is deleted add interim account manager
          if (userAssociation.RoleInTerritory2 == ETMConstant.PRIMARY_ACCOUNT_MANAGER) {
            pamUserIds.put(userAssociation.UserId, userAssociation);
          }

          //if Primary Temp Absence is deleted, then add Vacant compensation user
          if (userAssociation.RoleInTerritory2 == ETMConstant.PRIMARY_TEMPORARY_ABSENCE) {
            territoryIdsForVAC.add(userAssociation.Territory2Id);
            PTAUsersToCreateVACUser.put(userAssociation.UserId, userAssociation);
          }
          setOfTerritory2Ids.add(userAssociation.Territory2Id);
          terr.Primary_Account_Manager_Id__c = null;
          terr.Primary_Account_Manager_Name__c = null;
          territoryMapToUpdate.put(userAssociation.Territory2Id, terr);

          // If primary account manager is deleted then nullify IAM details on territory
        } else if (terr.Sales_Territory__c == true && interimRole.contains(userAssociation.RoleInTerritory2)) {
          terr.Interim_Account_Manager_Id__c = null;
          terr.Interim_Account_Manager_Name__c = null;
          territoryMapToUpdate.put(userAssociation.Territory2Id, terr);
          //If IAM deleted, then delete Vacant Compensation user
          deleteVACTerrIds.add(userAssociation.Territory2Id);
        } else if (
          userAssociation.RoleInTerritory2 != null &&
          (userAssociation.RoleInTerritory2 == ETMConstant.GEO_LEADER ||
          userAssociation.RoleInTerritory2 == ETMConstant.AREA_VP ||
          userAssociation.RoleInTerritory2 == ETMConstant.REGION_VP)
        ) {
          List<UserTerritory2Association> lstUTA = new List<UserTerritory2Association>();
          leadTerrIds.add(userAssociation.Territory2Id);
          leadUserIds.add(userAssociation.UserId);

          if (!TerrAssMap.containsKey(userAssociation.Territory2Id))
            lstUTA.add(userAssociation);
          else {
            List<UserTerritory2Association> lstoldUTA = TerrAssMap.get(userAssociation.Territory2Id);
            lstUTA.addall(lstoldUTA);
            lstUTA.add(userAssociation);
          }

          TerrAssMap.put(userAssociation.Territory2Id, lstUTA);
        } else if (userAssociation.RoleInTerritory2 == ETMConstant.REGION_PARTNER_MANAGER) {
          if (!RPMTerrIds.contains(userAssociation.Territory2Id))
            RPMTerrIds.add(userAssociation.Territory2Id);
        } else if (terr.Sales_Territory__c == true && userAssociation.RoleInTerritory2 == ETMConstant.RENEWAL) {
          //Delete Renewal User details on territory if User with role deleted
          terr.Renewal_Specialist__c = null;
          territoryMapToUpdate.put(userAssociation.Territory2Id, terr);
        }
      }
    }
    if (territoryMap.values().size() > 0) {
      unitOfWork.registerDirty(territoryMapToUpdate.values());
      unitOfWork.commitWork();
    }
    if (pamUserIds.size() > 0 && createInterim) {
      Map<Id, UserTerritory2Association> userAssMap = new Map<Id, UserTerritory2Association>();
      List<UserTerritory2Association> newInterimUsers = setPAMManagerAsInterim(setOfTerritory2Ids, pamUserIds);
      for (UserTerritory2Association userTerr : newInterimUsers) {
        userAssMap.put(userTerr.UserId, userTerr);
      }
      if (userAssMap.size() > 0) {
        updateUserDetailsOnTerritory(userAssMap, new Set<Id>{});
      }
    }
    if (leadTerrIds.size() > 0) {
      updateLeadonTerritory(TerrAssMap, leadTerrIds);
    }

    if (RPMTerrIds.size() > 0) {
      updateRPMonTerritory(RPMTerrIds);
    }

    if (deleteVACTerrIds.size() > 0) {
      deleteVacantTerritoryManagers(deleteVACTerrIds, new Set<String>{ ETMConstant.VACANT_TERRITORY_COMP_USER });
    }

    if (territoryIdsForVAC.size() > 0) {
      updateVACUserOnTerritory(territoryIdsForVAC, PTAUsersToCreateVACUser);
    }
  }

  private void updateUserDetailsOnTerritory(Map<Id, UserTerritory2Association> userAssMap, Set<Id> terrToUpdateIds) {
    List<Territory2> territoryList = new List<Territory2>();
    Territory2sSelector_ET territorySelector = (Territory2sSelector_ET) Application_ET.Selector.newInstance(
      Territory2.SObjectType
    );

    List<Territory2> salesTerritories = territorySelector.selectSalesTerritory();
    Set<Id> salesTerritoryIds = (new Map<Id, Territory2>(salesTerritories)).keyset();
    Set<String> interimRole = getInterimManagerRole();

    UsersSelector_ET userSelector = (UsersSelector_ET) Application_ET.Selector.newInstance(User.SObjectType);

    // Populate interim and primary account managers details on territory
    for (User user : userSelector.selectById(userAssMap.KeySet())) {
      UserTerritory2Association userTerr = userAssMap.get(user.Id);

      // If user is associated with sales territory
      if (salesTerritoryIds.contains(userTerr.Territory2Id)) {
        Territory2 terr = new Territory2(Id = userTerr.Territory2Id);

        if (userTerr.RoleInTerritory2 == ETMConstant.PRIMARY_ACCOUNT_MANAGER) {
          terr.Primary_Account_Manager_Name__c = user.Name;
          terr.Primary_Account_Manager_Id__c = user.Id;
        } else if (interimRole.contains(userTerr.RoleInTerritory2)) {
          terr.Interim_Account_Manager_Name__c = user.Name;
          terr.Interim_Account_Manager_Id__c = user.Id;
        } else if (userTerr.RoleInTerritory2 == ETMConstant.RENEWAL) {
          terr.Renewal_Specialist__c = user.Name;
        }
        terrToUpdateIds.remove(terr.Id);
        territoryList.add(terr);
      }
    }
    for (Id terrId : terrToUpdateIds) {
      territoryList.add(new Territory2(Id = terrId));
    }
    final fflib_ISObjectUnitOfWork unitOfWork = Application_ET.UnitOfWork.newInstance();
    unitOfWork.registerDirty(territoryList);
    unitOfWork.commitWork();
  }

  private Map<String, ETM_Vacant_User__mdt> getETM_Vacant_UserMetadata() {
    Map<String, ETM_Vacant_User__mdt> mapOfUsertoIdETMMetadata = new Map<String, ETM_Vacant_User__mdt>();
    for (ETM_Vacant_User__mdt etmMetadata : ETM_Vacant_User__mdt.getAll().values()) {
      if (!mapOfUsertoIdETMMetadata.containsKey(etmMetadata.DeveloperName)) {
        //setOfPrimaryEmailIds.add(etmMetadata.User_Id__c);
        mapOfUsertoIdETMMetadata.put(etmMetadata.DeveloperName, etmMetadata);
      }
    }
    system.debug('mapOfUsertoIdETMMetadata' + mapOfUsertoIdETMMetadata);
    return mapOfUsertoIdETMMetadata;
  }

  private void updateVACUserOnTerritory(
    Set<Id> territoryIdsForVAC,
    Map<Id, UserTerritory2Association> IAMUsersToCreateVACUser
  ) {
    List<UserTerritory2Association> VACUserList = new List<UserTerritory2Association>();
    Map<Id, UserTerritory2Association> PTAUTAMap = new Map<Id, UserTerritory2Association>();
    Map<String, ETM_Vacant_User__mdt> VACUserMap = getETM_Vacant_UserMetadata();

    Territory2sSelector_ET territorySelector = (Territory2sSelector_ET) Application_ET.Selector.newInstance(
      Territory2.SObjectType
    );

    List<Territory2> salesTerritories = territorySelector.selectSalesTerritoryById(territoryIdsForVAC);

    Map<Id, Territory2> terrIdToGeoMap = new Map<Id, Territory2>();

    for (Territory2 geoTerr : salesTerritories) {
      if (!terrIdToGeoMap.containsKey(geoTerr.Id)) {
        terrIdToGeoMap.put(geoTerr.Id, geoTerr);
      }
    }

    List<UserTerritory2Association> PTAUser = new List<UserTerritory2Association>();
    PTAUser = userAssociationSelector.selectByRoleInTerritory(
      territoryIdsForVAC,
      new Set<String>{ ETMConstant.PRIMARY_TEMPORARY_ABSENCE }
    );

    for (UserTerritory2Association ptaUTA : PTAUser) {
      if (!PTAUTAMap.containsKey(ptaUTA.Territory2Id)) {
        PTAUTAMap.put(ptaUTA.Territory2Id, ptaUTA);
      }
    }

    UsersSelector_ET userSelector = (UsersSelector_ET) Application_ET.Selector.newInstance(User.SObjectType);

    for (User user : userSelector.selectById(IAMUsersToCreateVACUser.keyset())) {
      Id iamTerrId = IAMUsersToCreateVACUser.get(user.Id).Territory2Id;
      if (!PTAUTAMap.containsKey(iamTerrId)) {
        String territoryGeo = iamTerrId != null ? terrIdToGeoMap.get(iamTerrId).Ultimate_Geo__c : null;
        UserTerritory2Association userAss = IAMUsersToCreateVACUser.get(user.Id).clone();
        userAss.RoleInTerritory2 = ETMConstant.VACANT_TERRITORY_COMP_USER;
        if (territoryGeo != null && VACUserMap.containsKey(territoryGeo)) {
          userAss.UserId = VACUserMap.get(territoryGeo).User_Id__c;
          VACUserList.add(userAss);
        }
      }
    }

    Database.UpsertResult[] saveresultVACUser = Database.upsert(VACUserList, false);
  }

  private List<UserTerritory2Association> deleteInterimAccountManagers(Set<Id> interimTerrToDelete) {
    List<UserTerritory2Association> interimAccountManagers = new List<UserTerritory2Association>();
    Set<String> interimRole = getInterimManagerRole();
    if (interimTerrToDelete.size() > 0) {
      interimAccountManagers = userAssociationSelector.selectByRoleInTerritory(interimTerrToDelete, interimRole);
      if (interimAccountManagers.size() > 0) {
        /*final fflib_ISObjectUnitOfWork unitOfWork = Application_ET.UnitOfWork.newInstance();
                unitOfWork.registerDeleted(interimAccountManagers);
                unitOfWork.commitWork();*/
        List<Database.DeleteResult> resultList = Database.delete(interimAccountManagers, false);
      }
    }
    return interimAccountManagers;
  }

  private void deleteVacantTerritoryManagers(Set<Id> vacantTerrToDelete, Set<String> roleToDelete) {
    List<UserTerritory2Association> vacantTerrManagers = new List<UserTerritory2Association>();
    try {
      if (vacantTerrToDelete.size() > 0) {
        vacantTerrManagers = userAssociationSelector.selectByRoleInTerritory(vacantTerrToDelete, roleToDelete);
        if (vacantTerrManagers.size() > 0) {
          List<Database.DeleteResult> vacresultList = Database.delete(vacantTerrManagers, false);
        }
      }
    } catch (Exception ex) {
      Logger.debug(
        new LogMessage('Unable to delete Vacant Compensation Partner Manager', ex.getLineNumber() + ex.getMessage())
      );
    }
  }

  private List<UserTerritory2Association> setPAMManagerAsInterim(
    Set<Id> territoryIds,
    Map<Id, UserTerritory2Association> pamUserIds
  ) {
    List<UserTerritory2Association> interimUserList = new List<UserTerritory2Association>();
    Set<String> interimRole = getInterimManagerRole();
    List<User> activeManager = new List<User>();
    Set<Id> managerId = new Set<Id>();
    if (territoryIds.size() > 0) {
      final fflib_ISObjectUnitOfWork unitOfWork = Application_ET.UnitOfWork.newInstance();
      Map<Id, UserTerritory2Association> mapOfTerritory2IdToUTARecord = new Map<Id, UserTerritory2Association>();
      // Query Interim Account Managers of Territories
      for (
        UserTerritory2Association userAssociation : userAssociationSelector.selectByRoleInTerritory(
          territoryIds,
          interimRole
        )
      ) {
        if (!mapOfTerritory2IdToUTARecord.containsKey(userAssociation.Territory2Id)) {
          mapOfTerritory2IdToUTARecord.put(userAssociation.Territory2Id, userAssociation);
        }
      }

      UsersSelector_ET userSelector = (UsersSelector_ET) Application_ET.Selector.newInstance(User.SObjectType);

      // Loop through all the Primary Account Manager Users
      for (User user : userSelector.selectByIdWithManager(pamUserIds.keyset())) {
        // If interim account manager does not exist
        if (!mapOfTerritory2IdToUTARecord.containsKey(pamUserIds.get(user.Id).Territory2Id)) {
          UserTerritory2Association userAss = pamUserIds.get(user.Id).clone();
          userAss.RoleInTerritory2 = ETMConstant.INTERIM_SALES_MANAGER;
          //check and assign only active manager
          managerId.add(user.ManagerId);
          activeManager = userSelector.selectByIdAndActive(managerId);
          if (activeManager.size() > 0) {
            userAss.UserId = activeManager[0].Id;
            interimUserList.add(userAss);
          }
        }
      }
      if (interimUserList.size() > 0) {
        unitOfWork.registerNew(interimUserList);
        unitOfWork.commitWork();
      }
    }
    return interimUserList;
  }

  public Map<Id, List<UserTerritory2Association>> getMapofTerritoryIdAndUserAssociations(
    Set<Id> territoryIds,
    Set<String> roleSet
  ) {
    Map<Id, List<UserTerritory2Association>> territoryUserAssListMap = new Map<Id, List<UserTerritory2Association>>();
    List<UserTerritory2Association> userAssociationList = userAssociationSelector.selectByRoleInTerritory(
      territoryIds,
      roleSet
    );

    for (UserTerritory2Association userAssociation : userAssociationList) {
      if (territoryUserAssListMap.containsKey(userAssociation.Territory2Id)) {
        territoryUserAssListMap.get(userAssociation.Territory2Id).add(userAssociation);
      } else {
        territoryUserAssListMap.put(
          userAssociation.Territory2Id,
          new List<UserTerritory2Association>{ userAssociation }
        );
      }
    }
    return territoryUserAssListMap;
  }

  private void updateLeadonTerritory(Map<Id, List<UserTerritory2Association>> TerrAssMap, Set<Id> leadTerrIds) {
    List<Territory2> terrtoUpdateList = new List<Territory2>();
    List<UserTerritory2Association> allTerritoryUsersList = new List<UserTerritory2Association>();

    Territory2sSelector_ET leadterritorySelector = (Territory2sSelector_ET) Application_ET.Selector.newInstance(
      Territory2.SObjectType
    );
    UserTerritory2AssociationsSelector_ET territoryuserSelector = (UserTerritory2AssociationsSelector_ET) Application_ET.Selector.newInstance(
      UserTerritory2Association.SObjectType
    );

    //fetch territory records to update the lead field
    if (leadTerrIds.size() > 0) {
      terrtoUpdateList = leadterritorySelector.selectById(leadTerrIds);
      allTerritoryUsersList = territoryuserSelector.selectAllUsersByTerritory(leadTerrIds);
    }

    if (terrtoUpdateList.size() > 0) {
      Map<Id, List<UserTerritory2Association>> eligibleTerritoryUsersMap = getEligibleTerritoryUsers(
        allTerritoryUsersList
      );
      //loop through the territories to update the Geo, Area & Region VP in the territories heirarchy.
      for (Territory2 terr : terrtoUpdateList) {
        if (eligibleTerritoryUsersMap.containsKey(terr.Id)) {
          for (UserTerritory2Association terrUta : eligibleTerritoryUsersMap.get(terr.Id)) {
            if (terr.Sales_Area__c == true) {
              //only update if the role matches the heirarchy
              if (terrUta.RoleInTerritory2 == ETMConstant.AREA_VP) {
                terr.AVP_Id__c = terrUta.UserId;
                terr.AVP_Name__c = terrUta.User.Name;
              }
            }

            if (terr.Sales_Geo__c == true) {
              if (terrUta.RoleInTerritory2 == ETMConstant.GEO_LEADER) {
                terr.GVP_Id__c = terrUta.UserId;
                terr.GVP_Name__c = terrUta.User.Name;
              }
            }

            if (terr.Sales_Region__c == true) {
              if (terrUta.RoleInTerritory2 == ETMConstant.REGION_VP) {
                terr.RVP_Id__c = terrUta.UserId;
                terr.RVP_Name__c = terrUta.User.Name;
              }
            }
          }
        } else {
          if (terr.Sales_Area__c == true) {
            terr.AVP_Id__c = null;
            terr.AVP_Name__c = null;
          }
          if (terr.Sales_Geo__c == true) {
            terr.GVP_Id__c = null;
            terr.GVP_Name__c = null;
          }
          if (terr.Sales_Region__c == true) {
            terr.RVP_Id__c = null;
            terr.RVP_Name__c = null;
          }
        }
      }
      Database.SaveResult[] updateLeadLst = Database.update(terrtoUpdateList, false);
    }
  }

  private static Map<Id, List<UserTerritory2Association>> getEligibleTerritoryUsers(
    List<UserTerritory2Association> allTerrUsers
  ) {
    Set<String> rolesSet = new Set<String>{ ETMConstant.AREA_VP, ETMConstant.GEO_LEADER, ETMConstant.REGION_VP };
    Map<Id, List<UserTerritory2Association>> eligibleTerritoryUsersMap = new Map<Id, List<UserTerritory2Association>>();

    for (UserTerritory2Association terrUser : allTerrUsers) {
      String UTARole = (terrUser.Territory2.Sales_Area__c == true
        ? ETMConstant.AREA_VP
        : (terrUser.Territory2.Sales_Geo__c == true
            ? ETMConstant.GEO_LEADER
            : (terrUser.Territory2.Sales_Region__c ? ETMConstant.REGION_VP : '')));
      if (rolesSet.contains(UTARole) && rolesSet.contains(terrUser.RoleInTerritory2)) {
        if (!eligibleTerritoryUsersMap.containsKey(terrUser.Territory2Id)) {
          eligibleTerritoryUsersMap.put(terrUser.Territory2Id, new List<UserTerritory2Association>{ terrUser });
        } else {
          List<UserTerritory2Association> existingList = eligibleTerritoryUsersMap.get(terrUser.Territory2Id);
          existingList.add(terrUser);
          eligibleTerritoryUsersMap.put(terrUser.Territory2Id, existingList);
        }
      }
    }
    return eligibleTerritoryUsersMap;
  }

  private void updateRPMonTerritory(Set<Id> RPMTerrIds) {
    //logic to validate Region Partner Manager for Sales Region and Sales Territory
    List<Territory2> RPMterrtoUpdateList = new List<Territory2>();

    Territory2sSelector_ET RPMterritorySelector = (Territory2sSelector_ET) Application_ET.Selector.newInstance(
      Territory2.SObjectType
    );
    Map<Id, List<UserTerritory2Association>> mapOfRPMTerrUTARecord = new Map<Id, List<UserTerritory2Association>>();

    RPMterrtoUpdateList = RPMterritorySelector.selectById(RPMTerrIds);
    List<UserTerritory2Association> RPMUTA = userAssociationSelector.selectByRoleInTerritory(
      RPMTerrIds,
      new Set<String>{ ETMConstant.REGION_PARTNER_MANAGER }
    );

    for (UserTerritory2Association existingUTA : RPMUTA) {
      if (!mapOfRPMTerrUTARecord.containsKey(existingUTA.Territory2Id))
        mapOfRPMTerrUTARecord.put(existingUTA.Territory2Id, new List<UserTerritory2Association>{ existingUTA });
      else
        mapOfRPMTerrUTARecord.get(existingUTA.Territory2Id).add(existingUTA);
    }

    for (Territory2 terr : RPMterrtoUpdateList) {
      if (
        terr.Sales_Region__c == true ||
        terr.Sales_Territory__c == true ||
        (terr.Sales_Region__c == false &&
        terr.Sales_Territory__c == false &&
        terr.Sales_Area__c == false)
      ) {
        Integer RPMcount = 0;
        if (mapOfRPMTerrUTARecord.containsKey(terr.Id)) {
          for (UserTerritory2Association terrUta : mapOfRPMTerrUTARecord.get(terr.Id)) {
            RPMcount = RPMcount + 1;
            if (RPMcount >= 2 && terr.Partner_Manager_Team_Credit__c == false)
              terr.Partner_Manager_Team_Credit__c = true;
            else if (RPMcount < 2 && terr.Partner_Manager_Team_Credit__c == true)
              terr.Partner_Manager_Team_Credit__c = false;
          }
        } else
          terr.Partner_Manager_Team_Credit__c = false;
      }
    }

    Database.SaveResult[] updateRPMLst = Database.update(RPMterrtoUpdateList, false);
  }

  public Map<Id, Map<Id, UserTerritory2Association>> getMapOfUserIdWithTerritoryIdAndUserAssociation(
    Set<Id> territoryIds,
    Set<id> userIds
  ) {
    Map<Id, Map<Id, UserTerritory2Association>> accountUserTerritoryIdsMap = new Map<Id, Map<Id, UserTerritory2Association>>();
    // Create Map of User Id and Map of territory id and UserTerritory2Association record
    List<UserTerritory2Association> userTerrAssociationList = userAssociationSelector.selectByTerritoryUsers(
      territoryIds,
      userIds
    );
    for (UserTerritory2Association objUTA : userTerrAssociationList) {
      if (!accountUserTerritoryIdsMap.containsKey(objUTA.UserId)) {
        accountUserTerritoryIdsMap.put(
          objUTA.UserId,
          new Map<Id, UserTerritory2Association>{ objUTA.Territory2Id => objUTA }
        );
      } else {
        accountUserTerritoryIdsMap.get(objUTA.UserId).put(objUTA.Territory2Id, objUTA);
      }
    }
    return accountUserTerritoryIdsMap;
  }

  public Map<Id, Map<String, UserTerritory2Association>> getMapOfUserIdWithRoleAndUserAssociation(
    Set<id> userIds,
    Set<String> userRoles
  ) {
    Map<Id, Map<String, UserTerritory2Association>> userIdTerritoryRoleMap = new Map<Id, Map<String, UserTerritory2Association>>();
    Set<String> rolesInTerr = getRolesInTerritory2();
    for (UserTerritory2Association objUTA : userAssociationSelector.selectByUserIds(userIds, userRoles)) {
      if (rolesInTerr.contains(objUTA.RoleInTerritory2) && objUTA.Territory2.Sales_Territory__c) {
        if (!userIdTerritoryRoleMap.containsKey(objUTA.UserId)) {
          userIdTerritoryRoleMap.put(
            objUTA.UserId,
            new Map<String, UserTerritory2Association>{ objUTA.RoleInTerritory2 => objUTA }
          );
        } else {
          userIdTerritoryRoleMap.get(objUTA.UserId).put(objUTA.RoleInTerritory2, objUTA);
        }
      }
    }
    return userIdTerritoryRoleMap;
  }

  public static Set<String> getInterimManagerRole() {
    Set<String> interimRoles = new Set<String>();
    interimRoles.addall(ETMConstant.INTERIM_ACCOUNT_MANAGERS.Split(','));
    return interimRoles;
  }

  public static Set<String> getRolesInTerritory2() {
    Set<String> rolesInTerr = getInterimManagerRole();
    rolesInTerr.add(ETMConstant.PRIMARY_ACCOUNT_MANAGER);
    rolesInTerr.add(ETMConstant.REGION_PARTNER_MANAGER);

    return rolesInTerr;
  }
}