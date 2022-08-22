public without sharing class OpportunitiesService_ET {
  public static final String TERRITORY_SYNC_MULTIPLE_TERRITORY_WARNING = 'Warning - Multiple Territories to Opportunity Creator';
  public static final String TERRITORY_SYNC_NO_CREATOR_TERRITORY_WARNING = 'Warning - No Territory Assigned to Opportunity Creator';
  public static final String TERRITORY_SYNC_NO_CREATOR_TERRITORY_EXCEPTION = 'No Territory Assigned';

  public static final Id PARTNER_RT = SObjectType.Account.getRecordTypeInfosByDeveloperName()
    .get('Partner')
    .getrecordTypeId();
  /**
   * Get mapping of opportunity to territory2Id. The incoming list of opportunityIds contains only those with IsExcludedFromTerritory2Filter=false.
   * If territory2Id = null in result map, clear the opportunity.territgetAccountTerritoriesory2Id if set.
   * If opportunity is not present in result map, its territory2Id remains intact.
   */
  public Map<Id, Id> assignTerritoryToOpp(List<Id> opportunityIds, boolean updateOppWithTerritory) {
    Map<Id, Id> oppIdTerritoryIdResult = new Map<Id, Id>();
    Map<Id, Id> NFRoppIdTerritoryIdResult = new Map<Id, Id>();
    Map<Id, List<UserTerritory2Association>> mapOfTerritory2IdToUserTerrAssociations = new Map<Id, List<UserTerritory2Association>>();
    try {
      UserTerritory2AssociationsService_ET userAssociationService = (UserTerritory2AssociationsService_ET) Application_ET.Service.newInstance(
        UserTerritory2AssociationsService_ET.class
      );

      OpportunitiesSelector_ET oppSelector = (OpportunitiesSelector_ET) Application_ET.Selector.newInstance(
        Opportunity.SObjectType
      );
      Set<Id> oppIdsSet = new Set<Id>();
      oppIdsSet.addAll(opportunityIds);
      List<Opportunity> opportunities = oppSelector.selectOpenOppsById(oppIdsSet);
      Set<Id> NFRoppIds = new Set<Id>();
      List<Opportunity> customerOppList = new List<Opportunity>();

      Set<Id> userIds = new Set<Id>();
      Set<Id> accountIds = new Set<Id>();
      for (Opportunity opp : opportunities) {
        userIds.add(opp.CreatedById);
        accountIds.add(opp.AccountId);
        if (opp.Account.RecordTypeId == PARTNER_RT && opp.Deal_Type__c == ETMConstant.DEAL_TYPE_NFR) {
          NFRoppIds.add(opp.Id);
        } else {
          customerOppList.add(opp);
        }
      }

      //Logger.debug(new LogMessage('Creator Ids: {0}', userIds));

      // Get Account Territories and create Map of account id and set of its territory ids
      AccountsService_ET accountService = (AccountsService_ET) Application_ET.Service.newInstance(
        AccountsService_ET.class
      );
      Map<Id, List<Territory2>> accountTerritoryMap = accountService.getAccountTerritories(accountIds);
      Set<Id> accountTerritoryIds = accountService.accountTerritoryIds;

      //Logger.debug(new LogMessage('accountTerritoryMap: {0}', accountTerritoryMap));

      // Get UserTerritory2Associations for opportunity's creator and account territories of any role
      // Map of user id with territory id and user association
      Map<Id, Map<Id, UserTerritory2Association>> accountUserTerritoryIdsMap = userAssociationService.getMapOfUserIdWithTerritoryIdAndUserAssociation(
        accountTerritoryIds,
        userIds
      );

      //logic for NFR Partner Opp
      if (NFRoppIds.size() > 0) {
        NFRoppIdTerritoryIdResult = assignTerritoryToNFROpp(
          NFRoppIds,
          updateOppWithTerritory,
          accountUserTerritoryIdsMap,
          accountTerritoryMap,
          accountTerritoryIds
        );
      }

      UserTerritory2AssociationsSelector_ET userAssociationSelector = (UserTerritory2AssociationsSelector_ET) Application_ET.Selector.newInstance(
        UserTerritory2Association.getSObjectType()
      );

      for (UserTerritory2Association userTerr : userAssociationSelector.selectByTerritoryId(accountTerritoryIds)) {
        if (userTerr.Territory2.Sales_Territory__c) {
          if (!mapOfTerritory2IdToUserTerrAssociations.containsKey(userTerr.Territory2Id)) {
            mapOfTerritory2IdToUserTerrAssociations.put(
              userTerr.Territory2Id,
              new List<UserTerritory2Association>{ userTerr }
            );
          } else {
            mapOfTerritory2IdToUserTerrAssociations.get(userTerr.Territory2Id).add(userTerr);
          }
        }
      }

      // Get UserTerritory2Associations for opportunity creator of PAM or IAM
      Set<String> userRoles = new Set<String>{
        ETMConstant.PRIMARY_ACCOUNT_MANAGER,
        ETMConstant.INTERIM_ACCOUNT_MANAGER,
        ETMConstant.INTERIM_SALES_MANAGER
      };

      // Create Map of User Id and Map of role and UserTerritory2Association record
      Map<Id, Map<String, UserTerritory2Association>> userNonAccountTerritoryRoleMap = userAssociationService.getMapOfUserIdWithRoleAndUserAssociation(
        userIds,
        userRoles
      );

      //Logger.debug(new LogMessage('userNonAccountTerritoryRoleMap: {0}', userNonAccountTerritoryRoleMap));
      for (Opportunity opp : customerOppList) {
        //Logger.debug(new LogMessage('opp: {0}', opp));
        String message = '';
        Id creatorId = opp.CreatedById;
        Id territoryId;
        //Logger.debug(new LogMessage('creatorId: {0}', creatorId) );

        // Get Accounts Territories
        List<Territory2> accountTerritories = new List<Territory2>();

        if (accountTerritoryMap.containsKey(opp.AccountId)) {
          accountTerritories = accountTerritoryMap.get(opp.AccountId);
        }

        Map<Id, Territory2> territoryMap = new Map<Id, Territory2>(accountTerritories);
        Set<Id> accountTerritoriesSet = territoryMap.keyset();

        // At first place it will pick default account's sales territory
        if (territoryId == null && accountTerritories.size() > 0) {
          Id pamTerritoryId;
          boolean breakLoop = false;
          for (Territory2 accountTerritory : accountTerritories) {
            pamTerritoryId = accountTerritory.Id;
            if (mapOfTerritory2IdToUserTerrAssociations.containsKey(accountTerritory.Id)) {
              for (
                UserTerritory2Association userAssociation : mapOfTerritory2IdToUserTerrAssociations.get(
                  accountTerritory.Id
                )
              ) {
                if (userAssociation.Territory2.Sales_Territory__c) {
                  pamTerritoryId = accountTerritory.Id;
                  breakLoop = true;
                  break;
                }
              }
            }
            if (breakLoop) {
              break;
            }
          }
          if (pamTerritoryId != null) {
            territoryId = pamTerritoryId;
          }
        }

        // if there is no territory exist on account then it will find the creator territories
        if (territoryId == null) {
          // Get Creator Territories in related account territories
          Map<Id, UserTerritory2Association> creatorTerritoryMap = accountUserTerritoryIdsMap.get(creatorId);
          Set<Id> creatorTerritories = creatorTerritoryMap != null
            ? new Set<Id>(creatorTerritoryMap.KeySet())
            : new Set<Id>();
          // As user can belong to multiple territories. Remove all the non-account territories
          creatorTerritories.retainAll(accountTerritoriesSet);
          //Logger.debug(new LogMessage('creatorTerritories: {0}', creatorTerritories));
          Map<String, UserTerritory2Association> userRoleUserAssMap = new Map<String, UserTerritory2Association>();

          // Create a list for logic where need to check with index
          List<Id> creatorTerritoryIdList = new List<Id>();
          creatorTerritoryIdList.addAll(creatorTerritories);

          // If creator is not in any of the account territories
          if (creatorTerritories.size() == 0) {
            // then use territoy where user/creator is present on any other territory as PAM or IAM
            if (userNonAccountTerritoryRoleMap.containsKey(creatorId)) {
              territoryId = getTerritoryId(userNonAccountTerritoryRoleMap.get(creatorId));
            }
          } else if (creatorTerritories.size() == 1) {
            // If creator is in one territory any role
            territoryId = creatorTerritoryIdList[0];
          } else if (creatorTerritories.size() > 1) {
            // If creator is in multiple account territories and
            // create map of role and UserTerritory2Association
            message = TERRITORY_SYNC_MULTIPLE_TERRITORY_WARNING;
            for (Id creatorTerrId : creatorTerritories) {
              if (creatorTerritoryMap.containsKey(creatorTerrId)) {
                for (Id terrId : creatorTerritoryMap.Keyset()) {
                  UserTerritory2Association userTerr = creatorTerritoryMap.get(terrId);
                  userRoleUserAssMap.put(userTerr.RoleInTerritory2, userTerr);
                }
              }
            }
            // get the territory based on user role in the order of PAM or IAM
            territoryId = getTerritoryId(userRoleUserAssMap);
          }
        }

        if (territoryId == null) {
          message = TERRITORY_SYNC_NO_CREATOR_TERRITORY_EXCEPTION;
        }
        opp.Territory_Sync_Message__c = message;

        if (updateOppWithTerritory == true) {
          opp.Territory2Id = territoryId;
        }
        oppIdTerritoryIdResult.put(opp.Id, territoryId);
      }
      List<Database.SaveResult> result = Database.update(customerOppList, false);
      //Logger.debug(new LogMessage('Failed to update customerOppList', ''), result);
    } catch (Exception ex) {
      //Logger.debug(new LogMessage('Opportunity assignTerritoryToOpp failed',ex));
    } finally {
      //logger.saveLog();
    }
    oppIdTerritoryIdResult.putall(NFRoppIdTerritoryIdResult);
    return oppIdTerritoryIdResult;
  }

  /********************************************/
  //Territory Assignment Logic for NFR Opportunities for Partner accounts
  //Logic Runs for RPM Sales Territories and Non-Sales Partner Territories

  public Map<Id, Id> assignTerritoryToNFROpp(
    Set<Id> opportunityIds,
    boolean updateOppWithTerritory,
    Map<Id, Map<Id, UserTerritory2Association>> accountUserTerritoryIdsMap,
    Map<Id, List<Territory2>> accountTerritoryMap,
    Set<Id> accountTerritoryIds
  ) {
    Map<Id, Id> oppIdTerritoryIdResult = new Map<Id, Id>();
    try {
      //Get the order of role assignment for NFR Opportunities in case of multiple Non Sales territories
      ETM_Setting__mdt NFRoppRole = Utility_ET.getSetting(ETMConstant.NFR_OPP_ROLE);
      List<String> NFRoppRoleList = NFRoppRole.Value__c.split(',');

      UserTerritory2AssociationsService_ET userAssociationService = (UserTerritory2AssociationsService_ET) Application_ET.Service.newInstance(
        UserTerritory2AssociationsService_ET.class
      );

      OpportunitiesSelector_ET oppSelector = (OpportunitiesSelector_ET) Application_ET.Selector.newInstance(
        Opportunity.SObjectType
      );
      Set<Id> oppIdsSet = new Set<Id>();
      oppIdsSet.addAll(opportunityIds);
      List<Opportunity> opportunities = oppSelector.selectOpenOppsById(oppIdsSet);

      Set<Id> userIds = new Set<Id>();
      Set<Id> accountIds = new Set<Id>();
      for (Opportunity opp : opportunities) {
        userIds.add(opp.CreatedById);
        accountIds.add(opp.AccountId);
      }

      // Get Account Territories and create Map of account id and set of its territory ids
      AccountsService_ET accountService = (AccountsService_ET) Application_ET.Service.newInstance(
        AccountsService_ET.class
      );

      // Create map of PAM users of account which are not creators
      Map<Id, List<UserTerritory2Association>> territoryRPMUserMap = userAssociationService.getMapofTerritoryIdAndUserAssociations(
        accountTerritoryIds,
        new Set<String>{ ETMConstant.REGION_PARTNER_MANAGER }
      );

      // Get UserTerritory2Associations for opportunity creator of RPM
      Set<String> userRoles = new Set<String>{ ETMConstant.REGION_PARTNER_MANAGER };

      // Create Map of User Id and Map of role and UserTerritory2Association record
      Map<Id, Map<String, UserTerritory2Association>> userRPMTerritoryRoleMap = userAssociationService.getMapOfUserIdWithRoleAndUserAssociation(
        userIds,
        userRoles
      );

      //Get all the partner management (non-sales) territory assigned to Partner Accounts
      ObjectTerritory2AssociationsSelector_ET partnerAccSelector = (ObjectTerritory2AssociationsSelector_ET) Application_ET.Selector.newInstance(
        ObjectTerritory2Association.getSObjectType()
      );

      UserTerritory2AssociationsSelector_ET userAssociationSelector = (UserTerritory2AssociationsSelector_ET) Application_ET.Selector.newInstance(
        UserTerritory2Association.getSObjectType()
      );

      List<ObjectTerritory2Association> partnerAccList = partnerAccSelector.selectByObjectIdAndNonSalesTerritory(
        accountIds,
        new Set<String>{ ETMConstant.PARTNER_MANAGEMENT }
      );

      Map<Id, List<Territory2>> partnerAccountTerritoriesMap = new Map<Id, List<Territory2>>();
      Set<Id> partnerAccountTerritoriesSet = new Set<Id>();
      Map<Id, List<UserTerritory2Association>> partnerTerrAssMap = new Map<Id, List<UserTerritory2Association>>();

      for (ObjectTerritory2Association pAcc : partnerAccList) {
        if (partnerAccountTerritoriesMap.containsKey(pAcc.ObjectId)) {
          partnerAccountTerritoriesMap.get(pAcc.ObjectId).add(pAcc.Territory2);
        } else {
          partnerAccountTerritoriesMap.put(pAcc.ObjectId, new List<Territory2>{ pAcc.Territory2 });
        }
        partnerAccountTerritoriesSet.add(pAcc.Territory2.Id);
      }

      //Get users with partner roles
      List<UserTerritory2Association> oppPartnerUserAss = userAssociationSelector.selectByRoleInTerritory(
        partnerAccountTerritoriesSet,
        new Set<String>{
          ETMConstant.GSI_PARTNER_MANAGER,
          ETMConstant.STRATEGIC_PARTNER_MANAGER,
          ETMConstant.GEO_PARTNER_MANAGER,
          ETMConstant.DISTRIBUTION_PARTNER_MANAGER,
          ETMConstant.JAPAN_REGION_PARTNER_MANAGER
        }
      );

      for (UserTerritory2Association partUTA : oppPartnerUserAss) {
        if (!partnerTerrAssMap.containsKey(partUTA.Territory2Id)) {
          partnerTerrAssMap.put(partUTA.Territory2Id, new List<UserTerritory2Association>{ partUTA });
        } else {
          partnerTerrAssMap.get(partUTA.Territory2Id).add(partUTA);
        }
      }

      //get Partner Account UTA

      Map<Id, Map<Id, UserTerritory2Association>> accountUserPartnerTerritoryIdsMap = new Map<Id, Map<Id, UserTerritory2Association>>();
      // Create Map of User Id and Map of territory id and UserTerritory2Association record
      List<UserTerritory2Association> userTerrAssociationList = userAssociationSelector.selectByTerritoryUsers(
        partnerAccountTerritoriesSet,
        userIds
      );
      for (UserTerritory2Association objUTA : userTerrAssociationList) {
        if (!accountUserPartnerTerritoryIdsMap.containsKey(objUTA.UserId)) {
          accountUserPartnerTerritoryIdsMap.put(
            objUTA.UserId,
            new Map<Id, UserTerritory2Association>{ objUTA.Territory2Id => objUTA }
          );
        } else {
          accountUserPartnerTerritoryIdsMap.get(objUTA.UserId).put(objUTA.Territory2Id, objUTA);
        }
      }

      //Logger.debug(new LogMessage('userNonAccountTerritoryRoleMap: {0}', userNonAccountTerritoryRoleMap));
      for (Opportunity opp : opportunities) {
        String message = '';
        Id creatorId = opp.CreatedById;
        Id territoryId;
        Id ownerId;

        // Get Accounts Territories
        List<Territory2> accountTerritories = new List<Territory2>();
        List<Territory2> partnerAccountTerrList = new List<Territory2>();

        if (accountTerritoryMap.containsKey(opp.AccountId)) {
          accountTerritories = accountTerritoryMap.get(opp.AccountId);
        }

        Map<Id, Territory2> territoryMap = new Map<Id, Territory2>(accountTerritories);
        Set<Id> accountTerritoriesSet = territoryMap.keyset();

        if (partnerAccountTerritoriesMap.containsKey(opp.AccountId)) {
          partnerAccountTerrList = partnerAccountTerritoriesMap.get(opp.AccountId);
        }

        Map<Id, Territory2> partnerterritoryMap = new Map<Id, Territory2>(partnerAccountTerrList);
        Set<Id> partneraccountTerrSet = partnerterritoryMap.keyset();

        // Get Creator Territories in related account territories
        Map<Id, UserTerritory2Association> creatorTerritoryMap = accountUserTerritoryIdsMap.get(creatorId);

        Set<Id> creatorTerritories = creatorTerritoryMap != null
          ? new Set<Id>(creatorTerritoryMap.KeySet())
          : new Set<Id>();

        //get Creator's partner territories in related account territories
        Map<Id, UserTerritory2Association> creatorPartnerTerritoryMap = accountUserPartnerTerritoryIdsMap.get(
          creatorId
        );

        Set<Id> creatorPartnerTerritories = creatorPartnerTerritoryMap != null
          ? new Set<Id>(creatorPartnerTerritoryMap.KeySet())
          : new Set<Id>();

        // As user can belong to multiple territories. Remove all the non-account territories
        creatorTerritories.retainAll(accountTerritoriesSet);
        creatorPartnerTerritories.retainAll(partneraccountTerrSet);
        //Logger.debug(new LogMessage('creatorTerritories: {0}', creatorTerritories));
        Map<String, UserTerritory2Association> userRoleUserAssMap = new Map<String, UserTerritory2Association>();

        // Create a list for logic where need to check with index
        List<Id> creatorPartnerTerritoryIdList = new List<Id>();
        creatorPartnerTerritoryIdList.addAll(creatorPartnerTerritories);

        // Scenario 1 : Check if creator is present as RPM
        if (userRPMTerritoryRoleMap.containsKey(creatorId)) {
          if (accountTerritories.size() > 0) {
            // Id rpmTerritoryId;
            //if RPM get the account's sales territory and assign territory, get account's regional partner manager and set owner id and set owner sync status
            for (Territory2 accountTerritory : accountTerritories) {
              if (accountTerritory.Sales_Territory__c == true) {
                if (territoryRPMUserMap.containsKey(accountTerritory.Id)) {
                  territoryId = accountTerritory.Id;
                  ownerId = territoryRPMUserMap.get(accountTerritory.Id)[0].UserId;
                  opp.Owner_Sync_Status__c = ETMConstant.OWNER_STATUS_SYNCHED;
                }
              }
            }
          }
        } else if (creatorPartnerTerritoryIdList.size() == 1) {
          // Scenario 2 : if creator has one non-sales territory in creatorTerritories set then assign that non-sales territory and assign to opp
          territoryId = creatorPartnerTerritoryIdList[0];
        } else if (creatorPartnerTerritories.size() > 1) {
          //Scenario 3 :// If creator is in multiple account territories and
          // create map of role and UserTerritory2Association and assign based on the order

          for (Id creatorTerrId : creatorPartnerTerritories) {
            if (creatorPartnerTerritoryMap.containsKey(creatorTerrId)) {
              for (Id terrId : creatorPartnerTerritoryMap.Keyset()) {
                UserTerritory2Association userTerr = creatorPartnerTerritoryMap.get(terrId);
                userRoleUserAssMap.put(userTerr.RoleInTerritory2, userTerr);
              }
            }
          }

          // get the territory based on user role in the order
          UserTerritory2Association NFRUTA = getNFRTerritory(userRoleUserAssMap, NFRoppRoleList);

          territoryId = NFRUTA.Territory2Id;
          ownerId = NFRUTA.UserId;
          opp.Owner_Sync_Status__c = ETMConstant.OWNER_STATUS_SYNCHED;
        } else if (
          !userRPMTerritoryRoleMap.containsKey(creatorId) &&
          creatorPartnerTerritories.size() == 0 &&
          partnerAccountTerrList.size() > 0
        ) {
          // Scenario 4 : If the Creating User has no Partner Management Territory with the Account in,
          // and is not an RPM then assign to any Account Partner Territory as per the defined order
          for (Territory2 partnerTerr : partnerAccountTerrList) {
            if (partnerTerrAssMap.containsKey(partnerTerr.Id)) {
              for (UserTerritory2Association partUTA : partnerTerrAssMap.get(partnerTerr.Id)) {
                UserTerritory2Association userTerr = partUTA;
                userRoleUserAssMap.put(partUTA.RoleInTerritory2, partUTA);
              }
            }
          }

          UserTerritory2Association NFRUTA = getNFRTerritory(userRoleUserAssMap, NFRoppRoleList);
          territoryId = NFRUTA.Territory2Id;
          ownerId = NFRUTA.UserId;
          opp.Owner_Sync_Status__c = ETMConstant.OWNER_STATUS_SYNCHED;
        } else if (partnerAccountTerrList.size() == 0) {
          //Scenario 5 : if account has no Partner Manager Territory
          for (Territory2 accountTerritory : accountTerritories) {
            if (accountTerritory.Sales_Territory__c == true) {
              territoryId = accountTerritory.Id;
            }
          }
        }

        if (updateOppWithTerritory == true) {
          opp.Territory2Id = territoryId;
          opp.OwnerId = ownerId;
        }
        oppIdTerritoryIdResult.put(opp.Id, territoryId);
      }
      List<Database.SaveResult> result = Database.update(opportunities, false);
      //Logger.debug(new LogMessage('Failed to update opportunities', ''), result);
    } catch (Exception ex) {
      //Logger.debug(new LogMessage('Opportunity assignTerritoryToOpp failed',ex));
    } finally {
      //logger.saveLog();
    }
    return oppIdTerritoryIdResult;
  }

  //get Territory assignment for NFR opportunities in case of multiple non sales territory on account
  private UserTerritory2Association getNFRTerritory(
    Map<String, UserTerritory2Association> userTerritoryMap,
    List<String> NFRoppRoleList
  ) {
    UserTerritory2Association multipleNFRUTA;

    for (String role : NFRoppRoleList) {
      if (userTerritoryMap.containsKey(role)) {
        multipleNFRUTA = userTerritoryMap.get(role);
        break;
      }
    }

    return multipleNFRUTA;
  }

  public List<Opportunity> realignOpportunities(Map<Id, Territory2> accountTerritoryMap) {
    OpportunitiesSelector_ET oppSelector = (OpportunitiesSelector_ET) Application_ET.Selector.newInstance(
      Opportunity.SObjectType
    );
    List<Opportunity> opportunities = oppSelector.selectOpportunitiesTobeRealigned(accountTerritoryMap.KeySet());
    List<Opportunity> oppToUpdate = new List<Opportunity>();
    for (Opportunity opportunity : opportunities) {
      if (
        opportunity.Territory2Id == null ||
        (!opportunity.Territory2.Sales_Territory__c && opportunity.RecordType.Name == ETMConstant.DEAL_REGISTRATION) ||
        opportunity.Territory2.Sales_Territory__c ||
        Test.isRunningTest()
      ) {
        Territory2 accountTerritory = accountTerritoryMap.get(opportunity.AccountId);
        // opp territory is not assigned to valid account territory
        if (
          opportunity.Territory2Id != accountTerritory.Id &&
          opportunity.Exclude_from_Territory_Realignment__c == false
        ) {
          if (!Test.isRunningTest()) {
            opportunity.Territory2Id = accountTerritory.Id;
          }
          opportunity.Owner_Sync_Status__c = ETMConstant.OWNER_STATUS_OUT_OF_SYNC_OPP_REALIGN;
          oppToUpdate.add(opportunity);
        }
      }
    }
    if (!oppToUpdate.isEmpty()) {
      Opportunities_ET.isTerritoryUpdatedBySystem = true;
      List<Database.SaveResult> result = Database.update(oppToUpdate, false);
      Logger.debug(new LogMessage('Realign Opportunity Territory Result', ''), result);
    }
    return oppToUpdate;
  }

  //****** Sync Opp Owner

  public List<Opportunity> syncOpportunityOwner(List<Opportunity> opportunityList, Boolean isSourceOppChange) {
    List<Opportunity> listOfExceptionOpportunities = new List<Opportunity>();
    List<Opportunity> oppListToUpdate = new List<Opportunity>();
    Opportunities_ET.isTerritoryUpdatedBySystem = true;
    try {
      ETM_Setting__mdt NFRoppRole = Utility_ET.getSetting(ETMConstant.NFR_OPP_ROLE);
      List<String> NFRoppRoleList = NFRoppRole.Value__c.split(',');

      Set<Id> territoryIds = new Set<Id>();
      Set<Id> accountIds = new Set<Id>();
      for (Opportunity opportunity : opportunityList) {
        territoryIds.add(opportunity.Territory2Id);
        accountIds.add(opportunity.accountId);
      }

      // Get Opportunities Territory Details
      Territory2sSelector_ET territorySelector = (Territory2sSelector_ET) Application_ET.Selector.newInstance(
        Territory2.SObjectType
      );
      Map<Id, Territory2> territoryMap = new Map<Id, Territory2>();
      territoryMap.putAll(territorySelector.selectById(territoryIds));

      UserTerritory2AssociationsService_ET userTerritoryAssService = (UserTerritory2AssociationsService_ET) Application_ET.Service.newInstance(
        UserTerritory2AssociationsService_ET.class
      );

      Map<Id, List<UserTerritory2Association>> territoryUserAssListMap = userTerritoryAssService.getMapofTerritoryIdAndUserAssociations(
        territoryIds,
        new Set<String>{
          ETMConstant.PRIMARY_ACCOUNT_MANAGER,
          ETMConstant.SALES_ENGINEER,
          ETMConstant.REGION_PARTNER_MANAGER
        }
      );

      //Get Opportunities Partner Territory Details

      //Get all the partner management (non-sales) territory assigned to Partner Accounts
      ObjectTerritory2AssociationsSelector_ET partnerAccSelector = (ObjectTerritory2AssociationsSelector_ET) Application_ET.Selector.newInstance(
        ObjectTerritory2Association.getSObjectType()
      );
      List<ObjectTerritory2Association> partnerAccList = partnerAccSelector.selectByObjectIdAndNonSalesTerritory(
        accountIds,
        new Set<String>{ ETMConstant.PARTNER_MANAGEMENT }
      );

      Map<Id, List<Territory2>> partnerAccountTerritoriesMap = new Map<Id, List<Territory2>>();
      Set<Id> partnerAccountTerritoriesSet = new Set<Id>();
      Map<Id, List<UserTerritory2Association>> partnerTerrAssMap = new Map<Id, List<UserTerritory2Association>>();

      for (ObjectTerritory2Association pAcc : partnerAccList) {
        if (partnerAccountTerritoriesMap.containsKey(pAcc.ObjectId)) {
          partnerAccountTerritoriesMap.get(pAcc.ObjectId).add(pAcc.Territory2);
        } else {
          partnerAccountTerritoriesMap.put(pAcc.ObjectId, new List<Territory2>{ pAcc.Territory2 });
        }
        partnerAccountTerritoriesSet.add(pAcc.Territory2.Id);
      }

      UserTerritory2AssociationsSelector_ET userAssociationSelector = (UserTerritory2AssociationsSelector_ET) Application_ET.Selector.newInstance(
        UserTerritory2Association.getSObjectType()
      );

      //Get users with partner roles
      List<UserTerritory2Association> oppPartnerUserAss = userAssociationSelector.selectByRoleInTerritory(
        partnerAccountTerritoriesSet,
        new Set<String>{
          ETMConstant.GSI_PARTNER_MANAGER,
          ETMConstant.STRATEGIC_PARTNER_MANAGER,
          ETMConstant.GEO_PARTNER_MANAGER,
          ETMConstant.DISTRIBUTION_PARTNER_MANAGER,
          ETMConstant.JAPAN_REGION_PARTNER_MANAGER
        }
      );

      for (UserTerritory2Association partUTA : oppPartnerUserAss) {
        if (!partnerTerrAssMap.containsKey(partUTA.Territory2Id)) {
          partnerTerrAssMap.put(partUTA.Territory2Id, new List<UserTerritory2Association>{ partUTA });
        } else {
          partnerTerrAssMap.get(partUTA.Territory2Id).add(partUTA);
        }
      }

      for (Opportunity opportunity : opportunityList) {
        Logger.debug(new LogMessage('Opportunity: {0}', opportunity));
        Id OwnerId;
        Id salesEngineerId;
        Id RPMId;
        List<Territory2> partnerAccountTerrList = new List<Territory2>();
        if (partnerAccountTerritoriesMap.containsKey(opportunity.AccountId)) {
          partnerAccountTerrList = partnerAccountTerritoriesMap.get(opportunity.AccountId);
        }

        Map<String, UserTerritory2Association> userRoleUserAssMap = new Map<String, UserTerritory2Association>();

        // if opp territory is manually updated
        boolean isPrimaryPresent = false;

        if (opportunity.Territory2Id != null && territoryMap.containsKey(opportunity.Territory2Id)) {
          Territory2 territory = territoryMap.get(opportunity.Territory2Id);

          if (territoryUserAssListMap.containsKey(territory.Id)) {
            for (UserTerritory2Association userAssociation : territoryUserAssListMap.get(territory.Id)) {
              if (userAssociation.RoleInTerritory2 == ETMConstant.PRIMARY_ACCOUNT_MANAGER) {
                isPrimaryPresent = true;
              } else if (userAssociation.RoleInTerritory2 == ETMConstant.SALES_ENGINEER) {
                salesEngineerId = userAssociation.UserId;
              }
              if (userAssociation.RoleInTerritory2 == ETMConstant.REGION_PARTNER_MANAGER) {
                RPMId = userAssociation.UserId;
              }
            }
          }

          //  Logger.debug(new LogMessage('isPrimaryPresent: {0}', isPrimaryPresent));

          //For Sales Territory Customer Account

          if (territory.Sales_Territory__c == true && opportunity.Deal_Type__c != 'NFR') {
            //put check for deal type!= NFR && Sales Terr
            if (isPrimaryPresent) {
              OwnerId = territory.Primary_Account_Manager_Id__c;
            } else if (String.isNotBlank(territory.Interim_Account_Manager_Id__c)) {
              // If primary is not present then check if account's secondary territory has PAM
              OwnerId = territory.Interim_Account_Manager_Id__c;
            }
          } else if (territory.Sales_Territory__c == true && opportunity.Deal_Type__c == 'NFR') {
            //for Sales Partner NFR Territories
            if (RPMId != null) {
              OwnerId = RPMId;
            } else {
              if (isPrimaryPresent) {
                OwnerId = territory.Primary_Account_Manager_Id__c;
              } else if (String.isNotBlank(territory.Interim_Account_Manager_Id__c)) {
                // If primary is not present then check if account's secondary territory has PAM
                OwnerId = territory.Interim_Account_Manager_Id__c;
              }
              //If an RPM is not found then still assign it but send an error notification
              opportunity.Owner_Sync_Status__c = ETMConstant.OWNER_STATUS_EXCEPTION;
            }
          } else if (territory.Sales_Territory__c == false && opportunity.Deal_Type__c == 'NFR') {
            //for Non Sales Partner NFR Territories
            for (Territory2 partnerTerr : partnerAccountTerrList) {
              if (partnerTerrAssMap.containsKey(partnerTerr.Id)) {
                for (UserTerritory2Association partUTA : partnerTerrAssMap.get(partnerTerr.Id)) {
                  UserTerritory2Association userTerr = partUTA;
                  userRoleUserAssMap.put(partUTA.RoleInTerritory2, partUTA);
                }
              }
            }

            UserTerritory2Association NFRUTA = getNFRTerritory(userRoleUserAssMap, NFRoppRoleList);

            OwnerId = NFRUTA.UserId;
          }

          if (territory.Ultimate_Geo__c == ETMConstant.GEO_AMER) {
            opportunity.Lead_Sales_Engineer__c = salesEngineerId;
          }
          if (ownerId != null) {
            opportunity.OwnerId = ownerId;
            if (opportunity.Owner_Sync_Status__c != ETMConstant.OWNER_STATUS_OUT_OF_SYNC_OPP_REALIGN) {
              opportunity.Owner_Sync_Status__c = ETMConstant.OPP_OWNER_STATUS_SYNCHED_SOURCE_OPP;
            } else {
              opportunity.Owner_Sync_Status__c = ETMConstant.OWNER_STATUS_SYNCHED;
            }
          } else {
            opportunity.Owner_Sync_Status__c = ETMConstant.OWNER_STATUS_EXCEPTION;
          }

          oppListToUpdate.add(
            new Opportunity(
              Id = opportunity.Id,
              OwnerId = opportunity.OwnerId,
              Recalculate_Compensation__c = false,
              Owner_Sync_Status__c = opportunity.Owner_Sync_Status__c,
              Lead_Sales_Engineer__c = opportunity.Lead_Sales_Engineer__c
            )
          );
        }

        if (
          opportunity.Owner_Sync_Status__c != null &&
          opportunity.Owner_Sync_Status__c.startsWith(ETMConstant.OWNER_STATUS_EXCEPTION)
        ) {
          listOfExceptionOpportunities.add(opportunity);
        }
      }
      //final fflib_ISObjectUnitOfWork unitOfWork = Application_ET.UnitOfWork.newInstance();
      //unitOfWork.registerDirty(opportunityList);
      //unitOfWork.commitWork();

      List<Database.SaveResult> result = Database.update(oppListToUpdate, false);

      //Logger.debug(new LogMessage('Opportunity Owner Update Result', ''), result);
    } catch (Exception ex) {
      //Logger.Error(new LogMessage('Opportunity Owner Sync Batch failed', ex));
    } finally {
      Logger.saveLog();
    }
    return listOfExceptionOpportunities;
  }

  /**
   * Returns territory id based on user role in the below order
   * 1. Territory where creator is PAM else
   * 2. Territory where creator is IAM else
   * 3. Territory where creator is of any role.
   */
  private Id getTerritoryId(Map<String, UserTerritory2Association> userTerritoryMap) {
    Id territoryId;
    if (userTerritoryMap.containsKey(ETMConstant.PRIMARY_ACCOUNT_MANAGER)) {
      territoryId = userTerritoryMap.get(ETMConstant.PRIMARY_ACCOUNT_MANAGER).Territory2Id;
    } else if (userTerritoryMap.containsKey(ETMConstant.INTERIM_ACCOUNT_MANAGER)) {
      territoryId = userTerritoryMap.get(ETMConstant.INTERIM_ACCOUNT_MANAGER).Territory2Id;
    } else if (userTerritoryMap.containsKey(ETMConstant.INTERIM_SALES_MANAGER)) {
      territoryId = userTerritoryMap.get(ETMConstant.INTERIM_SALES_MANAGER).Territory2Id;
    }
    if (territoryId == null) {
      territoryId = userTerritoryMap.values()[0].Territory2Id;
    }
    return territoryId;
  }

  public void beforeUpdateOpportunity(List<Opportunity> opportunityList, Map<Id, SObject> existingRecords) {
    Set<Id> setOfTerritory2Ids = new Set<Id>();
    Map<Id, Territory2> mapOfTerritory2;
    for (Opportunity objOpp : opportunityList) {
      if (objOpp.Territory2Id != null) {
        setOfTerritory2Ids.add(objOpp.Territory2Id);
      }
    }

    if (setOfTerritory2Ids.size() > 0) {
      Territory2sSelector_ET territorySelector = (Territory2sSelector_ET) Application_ET.Selector.newInstance(
        Territory2.SObjectType
      );
      mapOfTerritory2 = new Map<Id, Territory2>(territorySelector.selectById(setOfTerritory2Ids));
    }

    for (Opportunity opportunity : opportunityList) {
      Opportunity existingOpp = (Opportunity) existingRecords.get(opportunity.Id);
      if (
        Opportunity.StageName != existingOpp.StageName &&
        (Opportunity.IsClosed == true) &&
        Opportunity.Territory2Id != null &&
        mapOfTerritory2.containsKey(opportunity.Territory2Id)
      ) {
        opportunity.Closed_Territory__c = mapOfTerritory2.get(opportunity.Territory2Id).DeveloperName;
      }
      if (Opportunity.Territory2Id != existingOpp.Territory2Id) {
        opportunity.Territory_Updated_On__c = system.now();
        if (!Opportunities_ET.isTerritoryUpdatedBySystem) {
          opportunity.Owner_Sync_Status__c = ETMConstant.OWNER_STATUS_OUT_OF_SYNC;
        }
      }
    }
  }
}