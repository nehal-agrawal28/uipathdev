/**
 * @AUTHOR: UIPath
 * @DATE: 12/01/2022
 * @DESCRIPTION: This is OpportunityDataBatch_ET class
 * to populate territories on existing open opportunities
 */
public without sharing class OpportunityDataBatch_ET implements IGenericBatch {
  public void execute(Database.BatchableContext bc, List<Sobject> sobjectList) {
    // Store each Id from the field so we can read the Owner information

    // disable CPQ triggers
    SBQQ.TriggerControl.disable();

    try {
      Set<Id> oppIds = new Set<Id>();
      Set<Id> userIds = new Set<Id>();
      Set<Id> closedOppIds = new Set<Id>();
      Map<Id, List<UserTerritory2Association>> userTerritoryAssociationMap = new Map<Id, List<UserTerritory2Association>>();
      Map<Id, List<UserTerritory2Association>> salesUserTerritoryAssociationMap = new Map<Id, List<UserTerritory2Association>>();

      List<Opportunity> opportunities = (List<Opportunity>) sobjectList;
      OpportunitiesSelector_ET oppSelector = (OpportunitiesSelector_ET) Application_ET.Selector.newInstance(
        Opportunity.SObjectType
      );
      Set<id> accountIds = new Set<Id>();
      for (Opportunity opp : opportunities) {
        userIds.add(opp.OwnerId);
        accountIds.add(opp.AccountId);
        if (opp.IsClosed == true) {
          closedOppIds.add(opp.Id);
        }
      }

      // Opp Split logic for closed opportunities
      //
      OpportunitySplitSelector_ET oppSplitSelector = (OpportunitySplitSelector_ET) Application_ET.Selector.newInstance(
        Opportunity_Split__c.SObjectType
      );
      List<Opportunity_Split__c> oppSplitList = oppSplitSelector.selectByOppId(closedOppIds);

      for (Opportunity_Split__c split : oppSplitList) {
        if (split.User__c != null) {
          userIds.add(split.User__c);
        }
      }
      UserTerritory2AssociationsSelector_ET userAssSelector = (UserTerritory2AssociationsSelector_ET) Application_ET.Selector.newInstance(
        UserTerritory2Association.SObjectType
      );
      List<UserTerritory2Association> userAssociationList = [
        SELECT
          id,
          Territory2Id,
          UserId,
          Territory2.Name,
          Territory2.DeveloperName,
          RoleInTerritory2,
          Territory2.Sales_Territory__c
        FROM UserTerritory2Association
        WHERE UserId IN :userIds
      ];

      for (UserTerritory2Association userTerr : userAssociationList) {
        if (!userTerritoryAssociationMap.containsKey(userTerr.UserId)) {
          userTerritoryAssociationMap.put(userTerr.UserId, new List<userTerritory2association>{ userTerr });
        } else {
          userTerritoryAssociationMap.get(userTerr.UserId).add(userTerr);
        }
        if (userTerr.Territory2.Sales_Territory__c == true) {
          if (!salesUserTerritoryAssociationMap.containsKey(userTerr.UserId)) {
            salesUserTerritoryAssociationMap.put(userTerr.UserId, new List<userTerritory2association>{ userTerr });
          } else {
            salesUserTerritoryAssociationMap.get(userTerr.UserId).add(userTerr);
          }
        }
      }
      AccountsService_ET service = (AccountsService_ET) Application_ET.Service.newInstance(AccountsService_ET.class);
      Map<Id, List<Territory2>> accountIdTerritoryMap = service.getAccountTerritories(accountIds);

      for (Opportunity oppNew : opportunities) {
        Id accountTerritoryId = null;
        if (accountIdTerritoryMap.containsKey(oppNew.AccountId)) {
          for (Territory2 terr : accountIdTerritoryMap.get(oppNew.AccountId)) {
            if (terr.Sales_Territory__c == true) {
              accountTerritoryId = terr.Id;
            }
          }
          if (accountTerritoryId == null) {
            accountTerritoryId = accountIdTerritoryMap.get(oppNew.AccountId)[0].Id;
          }
        }
        // Assign territory if owner is a primary account manager
        if (oppNew.IsClosed == false) {
          if (salesUserTerritoryAssociationMap.containsKey(oppNew.OwnerId)) {
            List<UserTerritory2Association> userAssList = salesUserTerritoryAssociationMap.get(oppNew.OwnerId);
            // if only one territory found then assign that territory else assign to account's territory
            if (userAssList.size() == 1) {
              oppNew.Territory2Id = userAssList[0].Territory2Id;
            }
          }
        }
        // This logic will work for closed as well as for open opp where user is in more than one territory
        if (oppNew.Territory2Id == null) {
          oppNew.Territory2Id = accountTerritoryId;
        }
      }

      List<Database.SaveResult> result = Database.update(opportunities, false);

      Logger.debug(new LogMessage('opp result', ''), result);
      //Map<Id, Opportunity> oppMap = new Map<Id, opportunity>(opportunities);
      Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>(oppSelector.selectOppById(closedOppIds));
      for (Opportunity_Split__c split : oppSplitList) {
        if (split.User__c != null) {
          if (userTerritoryAssociationMap.containsKey(split.User__c)) {
            List<UserTerritory2Association> userAssList = userTerritoryAssociationMap.get(split.User__c);

            if (userAssList.size() == 1) {
              // If one terr found then use that
              Territory2 territory = userAssList[0].Territory2;
              split.Territory_Reason__c = territory.Name;
              split.Territory_Id__c = territory.DeveloperName;
            } else if (userAssList.size() > 1) {
              // if more than one then use the one with opp if not found then one with account else blank
              Set<id> accountTerritories = new Set<Id>();
              if (accountIdTerritoryMap.containsKey(split.Opportunity__r.AccountId)) {
                for (Territory2 terr : accountIdTerritoryMap.get(split.Opportunity__r.AccountId)) {
                  accountTerritories.add(terr.Id);
                }
              }
              Territory2 oppTerr;
              Territory2 accountTerr;
              for (UserTerritory2Association userAss : userAssList) {
                if (userAss.Territory2Id == split.Opportunity__r.Territory2Id) {
                  oppTerr = userAss.Territory2;
                  break;
                } else if (accountTerritories.contains(userAss.Territory2Id)) {
                  accountTerr = userAss.Territory2;
                }
              }
              if (oppTerr != null) {
                split.Territory_Reason__c = oppTerr.Name;
                split.Territory_Id__c = oppTerr.DeveloperName;
              } else if (accountTerr != null) {
                split.Territory_Reason__c = accountTerr.Name;
                split.Territory_Id__c = accountTerr.DeveloperName;
              } else {
                Territory2 territory = userAssList[0].Territory2;
                split.Territory_Reason__c = territory.Name;
                split.Territory_Id__c = territory.DeveloperName;
              }
            }
          } else {
            // if no territory for user then use opp territory

            Opportunity opp = oppMap.get(split.Opportunity__c);

            if (opp != null && opp.Territory2Id != null) {
              split.Territory_Reason__c = opp.Territory2.Name;
              split.Territory_Id__c = opp.Territory2.DeveloperName;
            }
          }
        }
      }
      if (oppSplitList.size() > 0) {
        List<Database.SaveResult> splitresult = Database.update(oppSplitList, false);
        Logger.debug(new LogMessage('split result', ''), splitresult);
      }
    } catch (Exception e) {
      system.debug('Exception' + e.getLineNumber() + e.getMessage());
    } finally {
      Logger.saveLog();
    }
  }

  public void finish(Database.BatchableContext bc) {
  }
}