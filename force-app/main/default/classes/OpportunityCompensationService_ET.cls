/**
 * @AUTHOR: UIPath
 * @DATE: 12/03/2022
 * @DESCRIPTION: This is OpportunityCompensationService_ET class
 * to populate Opportunity Splits for the Parter Compensation for Opportunity and Partner Territories
 */

public without sharing class OpportunityCompensationService_ET {
  public static final Id PARTNER_RT = SObjectType.Account.getRecordTypeInfosByDeveloperName()
    .get('Partner')
    .getrecordTypeId();
  public static final Id CUSTOMER_RT = SObjectType.Account.getRecordTypeInfosByDeveloperName()
    .get('Customer')
    .getrecordTypeId();
  public Set<Id> syncOpportunitySplit(List<Opportunity> oppList) {
    List<Opportunity_Split__c> upsertoppSplitList = new List<Opportunity_Split__c>();
    List<Opportunity_Split__c> deleteoppSplitList = new List<Opportunity_Split__c>();
    List<Partner_Involvement__c> updatePartnerInvList = new List<Partner_Involvement__c>();
    Set<Id> exceptionOppIds = new Set<Id>();
    try {
      Set<Id> oppIds = new Set<Id>();
      Set<Id> terrIds = new Set<Id>();
      Set<Id> accIds = new Set<Id>();
      Set<Id> allaccIds = new Set<Id>();
      Set<Id> RPMaccIds = new Set<Id>();
      Set<Id> japanRPMaccIds = new Set<Id>();
      Set<String> oppGeo = new Set<String>();
      Set<String> oppArea = new Set<String>();
      Set<String> oppRegion = new Set<String>();
      Set<Id> directPartnerAccountIds = new Set<Id>();
      Set<Id> partnerSourcedOppIds = new Set<Id>();
      Set<Id> distributionPartnerAccountIds = new Set<Id>();

      Map<String, Default_Compensation__mdt> defaultCompensationRoleMap = new Map<String, Default_Compensation__mdt>();
      CompensationSelector_ET compSelector = (CompensationSelector_ET) Application_ET.Selector.newInstance(
        Default_Compensation__mdt.SObjectType
      );
      List<Default_Compensation__mdt> defaultCompensation = compSelector.selectAll();

      //get japan area
      ETM_Setting__mdt japanSetting = Utility_ET.getSetting(ETMConstant.TERRITORY_AREA);

      Map<Id, List<UserTerritory2Association>> TerrAssMap = new Map<Id, List<UserTerritory2Association>>();
      Map<Id, List<UserTerritory2Association>> partnerTerrAssMap = new Map<Id, List<UserTerritory2Association>>();
      Map<Id, List<UserTerritory2Association>> distributionpartnerTerrAssMap = new Map<Id, List<UserTerritory2Association>>();
      Map<Id, List<UserTerritory2Association>> RPMTerrAssMap = new Map<Id, List<UserTerritory2Association>>();

      Map<Id, Account> accIdtoAccountMap = new Map<Id, Account>();
      //get opportunity's territory & account ids
      for (Opportunity op : oppList) {
        oppIds.add(op.Id);
        terrIds.add(op.Territory2Id);
        accIds.add(op.AccountId);

        //get partner sourced opp
        if (
          op.Account.RecordTypeId == PARTNER_RT &&
          (op.Deal_Type__c == ETMConstant.DEAL_TYPE_PARTNER_INTERNAL_INFRA ||
          op.Deal_Type__c == ETMConstant.DEAL_TYPE_MANAGED_SERVICES ||
          op.Deal_Type__c == ETMConstant.DEAL_TYPE_BPO)
        ) {
          directPartnerAccountIds.add(op.AccountId);
          if (op.BPO_MS_End_Customer__c != null)
            directPartnerAccountIds.add(op.BPO_MS_End_Customer__c);
        }

        if (op.Is_Partner_Sourced__c == true) {
          partnerSourcedOppIds.add(op.Id);
        }

        //logic for RPM Compensation
        if (
          op.BPO_MS_End_Customer__r.RecordTypeId == CUSTOMER_RT &&
          op.Deal_Type__c == ETMConstant.DEAL_TYPE_MANAGED_SERVICES
        ) {
          RPMaccIds.add(op.BPO_MS_End_Customer__c);
        }
      }
      allaccIds.addAll(accIds);
      allaccIds.addAll(RPMaccIds);
      PartnerInvolvementSelector_ET partnerInvSelector = (PartnerInvolvementSelector_ET) Application_ET.Selector.newInstance(
        Partner_Involvement__c.SObjectType
      );
      List<Partner_Involvement__c> partnerInvList = partnerInvSelector.selectByOppId(oppIds);
      Set<Id> partnerAccId = new Set<Id>();
      Set<Id> japanpartnerAccId = new Set<Id>();
      Map<Id, Partner_Involvement__c> oppPartnerInvolvementMap = new Map<Id, Partner_Involvement__c>();
      Map<Id, List<Partner_Involvement__c>> oppallPartnerInvolvementMap = new Map<Id, List<Partner_Involvement__c>>();
      Map<String, Partner_Involvement__c> oppdistPartnerInvolvementMap = new Map<String, Partner_Involvement__c>();
      for (Partner_Involvement__c pInv : partnerInvList) {
        distributionPartnerAccountIds.add(pInv.Partner_Account_Name__c);
        if (pInv.Opportunity_Sourced__c == true) {
          oppPartnerInvolvementMap.put(pInv.PartnerOpp_Name__c, pInv);
          directPartnerAccountIds.add(pInv.Partner_Account_Name__c);
        }

        if (oppallPartnerInvolvementMap.containsKey(pInv.PartnerOpp_Name__c)) {
          oppallPartnerInvolvementMap.get(pInv.PartnerOpp_Name__c).add(pInv);
        } else {
          oppallPartnerInvolvementMap.put(pInv.PartnerOpp_Name__c, new List<Partner_Involvement__c>{ pInv });
        }
      }

      //logic for RPM Opp
      for (Opportunity rpmOpp : oppList) {
        //get the partner involvement’s partner account and create partner account’s id set
        if (rpmOpp.Is_Partner_Sourced__c == true) {
          if (
            rpmOpp.Territory2.Ultimate_Geo__c == ETMConstant.GEO_APJ &&
            rpmOpp.Territory2.Area__c == japanSetting.Value__c
          )
            directPartnerAccountIds.add(oppPartnerInvolvementMap.get(rpmOpp.Id).Partner_Account_Name__c);
          else {
            oppGeo.add(rpmOpp.Territory2.Ultimate_Geo__c);
            oppArea.add(rpmOpp.Territory2.Area__c);
            oppRegion.add(rpmOpp.Territory2.Region__c);
          }
        }
      }

      //get UserterritoryAssociation details
      UserTerritory2AssociationsSelector_ET oppUserAssSelector = (UserTerritory2AssociationsSelector_ET) Application_ET.Selector.newInstance(
        UserTerritory2Association.SObjectType
      );

      //Get all the partner management (non-sales) territory assigned to Partner Accounts
      ObjectTerritory2AssociationsSelector_ET partnerAccSelector = (ObjectTerritory2AssociationsSelector_ET) Application_ET.Selector.newInstance(
        ObjectTerritory2Association.getSObjectType()
      );

      List<ObjectTerritory2Association> partnerAccList = partnerAccSelector.selectByObjectIdAndNonSalesTerritory(
        directPartnerAccountIds,
        new Set<String>{ ETMConstant.PARTNER_MANAGEMENT }
      );

      Map<Id, List<Territory2>> partnerAccountTerritoriesMap = new Map<Id, List<Territory2>>();
      Set<Id> partnerAccountTerritoriesSet = new Set<Id>();

      for (ObjectTerritory2Association pAcc : partnerAccList) {
        if (partnerAccountTerritoriesMap.containsKey(pAcc.ObjectId)) {
          partnerAccountTerritoriesMap.get(pAcc.ObjectId).add(pAcc.Territory2);
        } else {
          partnerAccountTerritoriesMap.put(pAcc.ObjectId, new List<Territory2>{ pAcc.Territory2 });
        }
        partnerAccountTerritoriesSet.add(pAcc.Territory2.Id);
      }

      //Get users with partner roles
      List<UserTerritory2Association> oppPartnerUserAss = oppUserAssSelector.selectByRoleInTerritory(
        partnerAccountTerritoriesSet,
        new Set<String>{
          ETMConstant.GEO_PARTNER_MANAGER,
          ETMConstant.GSI_PARTNER_MANAGER,
          ETMConstant.STRATEGIC_PARTNER_MANAGER,
          ETMConstant.GLOBAL_GSI_ALLI_PART_MANAGER,
          ETMConstant.DISTRIBUTION_PARTNER_MANAGER,
          ETMConstant.SEC_GSI_PARTNER_MANAGER,
          ETMConstant.GLOBAL_GSI_PARTNER_MANAGER,
          ETMConstant.VACANT_TERR_COMP_PART_MANAGER,
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

      //Distribution Partner Logic
      List<ObjectTerritory2Association> distributionpartnerAccList = partnerAccSelector.selectByObjectIdAndNonSalesTerritory(
        distributionPartnerAccountIds,
        new Set<String>{ ETMConstant.PARTNER_MANAGEMENT }
      );

      Map<Id, List<Territory2>> distributionpartnerAccountTerritoriesMap = new Map<Id, List<Territory2>>();
      Set<Id> distributionpartnerAccountTerritoriesSet = new Set<Id>();

      for (ObjectTerritory2Association pAcc : distributionpartnerAccList) {
        if (distributionpartnerAccountTerritoriesMap.containsKey(pAcc.ObjectId)) {
          distributionpartnerAccountTerritoriesMap.get(pAcc.ObjectId).add(pAcc.Territory2);
        } else {
          distributionpartnerAccountTerritoriesMap.put(pAcc.ObjectId, new List<Territory2>{ pAcc.Territory2 });
        }
        distributionpartnerAccountTerritoriesSet.add(pAcc.Territory2.Id);
      }

      //Get users with partner roles
      List<UserTerritory2Association> distributionoppPartnerUserAss = oppUserAssSelector.selectByRoleInTerritory(
        distributionpartnerAccountTerritoriesSet,
        new Set<String>{ ETMConstant.DISTRIBUTION_PARTNER_MANAGER }
      );
      for (UserTerritory2Association distpartUTA : distributionoppPartnerUserAss) {
        if (!distributionpartnerTerrAssMap.containsKey(distpartUTA.Territory2Id)) {
          distributionpartnerTerrAssMap.put(
            distpartUTA.Territory2Id,
            new List<UserTerritory2Association>{ distpartUTA }
          );
        } else {
          distributionpartnerTerrAssMap.get(distpartUTA.Territory2Id).add(distpartUTA);
        }
      }

      // Query all the userterritoryassociation records whose related territories has same geo, area and region as opp

      List<UserTerritory2Association> RPMPartnerUserAss = oppUserAssSelector.selectByGeoAreaRegionTerritories(
        oppGeo,
        oppArea,
        oppRegion,
        new Set<String>{ ETMConstant.REGION_PARTNER_MANAGER }
      );

      AccountsSelector_ET accountSelector = (AccountsSelector_ET) Application_ET.Selector.newInstance(
        Account.SObjectType
      );
      List<Account> accList = accountSelector.selectById(accIds);
      for (Account ac : accList) {
        if (ac.ParentId != null) {
          allaccIds.add(ac.Ultimate_Parent_Id__c);
        }
      }
      OpportunitySplitSelector_ET oppSplitSelector = (OpportunitySplitSelector_ET) Application_ET.Selector.newInstance(
        Opportunity_Split__c.SObjectType
      );
      List<Opportunity_Split__c> oppSplitList = oppSplitSelector.selectByOppId(oppIds);

      //get existing oppSplit details
      Map<String, Opportunity_Split__c> oppSplitMap = new Map<String, Opportunity_Split__c>();

      //Creating Map for Unique User Split for each Opp
      for (Opportunity_Split__c opsplit : oppSplitList) {
        oppSplitMap.put(opsplit.User__c + '#' + opsplit.Opportunity__c, opsplit);
      }

      // Get sales territory of accounts and their ultimate parent account
      AccountsService_ET accountService = (AccountsService_ET) Application_ET.Service.newInstance(
        AccountsService_ET.class
      );
      Map<Id, List<Territory2>> mapOfAccountIdToSalesTerritory2 = accountService.getAccountSalesTerritories(allaccIds);

      List<Account> allAccList = accountSelector.selectById(allaccIds);
      for (Account paracc : allAccList) {
        accIdtoAccountMap.put(paracc.Id, paracc);
      }

      Territory2sSelector_ET territorySelector = (Territory2sSelector_ET) Application_ET.Selector.newInstance(
        Territory2.SObjectType
      );

      Map<Id, Territory2> RPMterritoryParentMap = new Map<Id, Territory2>();

      if (oppArea.size() > 0 && oppRegion.size() > 0 && oppGeo.size() > 0) {
        RPMterritoryParentMap.putall(territorySelector.selectSalesTerritoryByAreaOrRegion(oppArea, oppRegion, oppGeo));
      }

      Map<String, List<UserTerritory2Association>> RPMTerritoriesMap = new Map<String, List<UserTerritory2Association>>();

      for (UserTerritory2Association rpmUTA : RPMPartnerUserAss) {
        if (!RPMTerritoriesMap.containsKey(rpmUTA.Territory2.Id)) {
          RPMTerritoriesMap.put(rpmUTA.Territory2.Id, new List<UserTerritory2Association>{ rpmUTA });
        } else {
          RPMTerritoriesMap.get(rpmUTA.Territory2.Id).add(rpmUTA);
        }
      }

      Map<Id, Territory2> territoryMap = new Map<Id, Territory2>();

      //Create a map of Opportunity Territories to fetch the RPM from Parent
      List<Territory2> ListOppTerritory = territorySelector.selectById(terrIds);

      //create Map to fetch Opportunity's and Account's Territory Details
      terrIds.addall(partnerAccountTerritoriesSet);
      terrIds.addall(distributionpartnerAccountTerritoriesSet);

      territoryMap.putAll(territorySelector.selectById(terrIds));
      territoryMap.putall(accountService.accountSalesTerritoryMap);

      List<UserTerritory2Association> oppUserAss = oppUserAssSelector.selectByRoleInTerritory(
        territoryMap.keyset(),
        new Set<String>{
          ETMConstant.PRIMARY_TEMPORARY_ABSENCE,
          ETMConstant.PRIMARY_ACCOUNT_MANAGER,
          ETMConstant.INTERIM_ACCOUNT_MANAGER,
          ETMConstant.VACANT_TERRITORY_COMP_USER,
          ETMConstant.REGION_PARTNER_MANAGER
        }
      );

      //get territory Id to Role Map
      for (UserTerritory2Association newUTA : oppUserAss) {
        if (!TerrAssMap.containsKey(newUTA.Territory2Id)) {
          TerrAssMap.put(newUTA.Territory2Id, new List<UserTerritory2Association>{ newUTA });
        } else {
          TerrAssMap.get(newUTA.Territory2Id).add(newUTA);
        }
      }
      for (Default_Compensation__mdt defcomp : defaultCompensation) {
        defaultCompensationRoleMap.put(defcomp.Role_In_Territory__c, defcomp);
      }

      //Map of Territory2Id to RPM UTA to fetch from the parent
      Map<Id, List<UserTerritory2Association>> RPMTerritoriestoUTAMap = new Map<Id, List<UserTerritory2Association>>();

      for (Territory2 oppSalesTerr : ListOppTerritory) {
        Boolean runWhile = false;
        Territory2 oppTerrrpm;
        if (RPMterritoryParentMap.containsKey(oppSalesTerr.Id)) {
          oppTerrrpm = RPMterritoryParentMap.get(oppSalesTerr.Id);
          runWhile = true;
        }

        //check that opp parent is a subregion or region

        while (runWhile) {
          //Create a map of Opportunity Territory Id against all the RPM UTAs from Sales Territory to Region Territory untill RPM found
          if (oppTerrrpm.Sales_Area__c != true) {
            if (RPMTerritoriesMap.containsKey(oppTerrrpm.Id)) {
              for (UserTerritory2Association opprpm : RPMTerritoriesMap.get(oppTerrrpm.Id)) {
                if (!RPMTerritoriestoUTAMap.containsKey(oppSalesTerr.Id)) {
                  RPMTerritoriestoUTAMap.put(oppSalesTerr.Id, new List<UserTerritory2Association>{ opprpm });
                } else {
                  RPMTerritoriestoUTAMap.get(oppSalesTerr.Id).add(opprpm);
                }
              }
              runWhile = false;
            } else if (
              oppTerrrpm.ParentTerritory2Id != null && RPMterritoryParentMap.containsKey(oppTerrrpm.ParentTerritory2Id)
            ) {
              oppTerrrpm = RPMterritoryParentMap.get(oppTerrrpm.ParentTerritory2Id);
            }
          } else {
            runWhile = false;
          }
        }
      }

      //FOR EACH OPP
      for (Opportunity opp : oppList) {
        Territory2 oppTerr = territoryMap.get(opp.Territory2Id);
        Partner_Involvement__c oppPartnInv = new Partner_Involvement__c();
        if (oppPartnerInvolvementMap.containsKey(opp.Id)) {
          oppPartnInv = oppPartnerInvolvementMap.get(opp.Id);
        }
        List<Partner_Involvement__c> oppallPartnInv = new List<Partner_Involvement__c>();
        if (oppallPartnerInvolvementMap.containsKey(opp.Id)) {
          oppallPartnInv = oppallPartnerInvolvementMap.get(opp.Id);
        }

        //Get IAM,VAC user details for opportunity territory
        Id IAMId, VACId;
        List<UserTerritory2Association> RpmOppUTA = new List<UserTerritory2Association>();
        if (TerrAssMap.containsKey(opp.Territory2Id)) {
          for (UserTerritory2Association oppUTA : TerrAssMap.get(opp.Territory2Id)) {
            if (oppUTA.RoleInTerritory2 == ETMConstant.INTERIM_ACCOUNT_MANAGER) {
              IAMId = territoryMap.get(oppUTA.Territory2Id).Interim_Account_Manager_Id__c;
            }
            if (oppUTA.RoleInTerritory2 == ETMConstant.VACANT_TERRITORY_COMP_USER) {
              VACId = oppUTA.UserId;
            }
          }
        }

        //get primary account manager of the related territory and if the user is not present in the opp split then add it to the upsertlist
        if (oppTerr.Primary_Account_Manager_Id__c != null) {
          //if Primary Temp Absence add PAM & IAM
          Id PAMId = oppTerr.Primary_Account_Manager_Id__c;

          if (oppSplitMap.get(PAMId + '#' + opp.Id) == null && PAMId != null) {
            Opportunity_Split__c opsp = addOpportunitySplit(
              opp,
              PAMId,
              defaultCompensationRoleMap.get(ETMConstant.PRIMARY_ACCOUNT_MANAGER),
              oppTerr
            );

            upsertoppSplitList.add(opsp);
            //adding to map to prevent duplicate record creation
            oppSplitMap.put(PAMId + '#' + opp.Id, opsp);
          }

          if (oppSplitMap.containsKey(VACId + '#' + opp.Id)) {
            if (!deleteoppSplitList.contains(oppSplitMap.get(VACId + '#' + opp.Id))) {
              deleteoppSplitList.add(oppSplitMap.get(VACId + '#' + opp.Id));
            }
          }

          //check for interim account manager only not sales manager and create split record for IAM.
          if (IAMId != null) {
            Opportunity_Split__c iamopsp = addOpportunitySplit(
              opp,
              IAMId,
              defaultCompensationRoleMap.get(ETMConstant.INTERIM_ACCOUNT_MANAGER),
              oppTerr
            );
            upsertoppSplitList.add(iamopsp);
            oppSplitMap.put(IAMId + '#' + opp.Id, iamopsp);
          }
        } else if (VACId != null) {
          // if pam is null then this condition will work
          Opportunity_Split__c vacopsp = addOpportunitySplit(
            opp,
            VACId,
            defaultCompensationRoleMap.get(ETMConstant.VACANT_TERRITORY_COMP_USER),
            oppTerr
          );
          upsertoppSplitList.add(vacopsp);
          oppSplitMap.put(VACId + '#' + opp.Id, vacopsp);
        }

        //logic for opp RPM

        if (opp.Is_Partner_Sourced__c == true && RPMTerritoriestoUTAMap.containsKey(oppTerr.Id)) {
          for (UserTerritory2Association opprpm : RPMTerritoriestoUTAMap.get(oppTerr.Id)) {
            //create split
            if (!oppSplitMap.containsKey(opprpm.UserId + '#' + opp.Id)) {
              Opportunity_Split__c OppRPMopsp = addOpportunitySplit(
                opp,
                opprpm.UserId,
                defaultCompensationRoleMap.get(ETMConstant.REGION_PARTNER_MANAGER),
                oppTerr
              );
              upsertoppSplitList.add(OppRPMopsp);

              oppSplitMap.put(opprpm.UserId + '#' + opp.Id, OppRPMopsp);

              //assign Partner Involvement RPM
              if (oppPartnInv != null) {
                oppPartnInv.Region_Partner_Manager__c = opprpm.UserId;
                oppPartnInv.Region_Partner_Manager_Territory__c = oppTerr.Name;
              }
            }
          }
        }

        //get related account’s sales territories and its Primary Account Manager for each territory,
        //if not already present in opp split the then create it
        if (mapOfAccountIdToSalesTerritory2.containsKey(opp.AccountId)) {
          for (Territory2 accter : mapOfAccountIdToSalesTerritory2.get(opp.AccountId)) {
            //check if primary account manager is not already present in opp split
            Id terrPAMId = territoryMap.get(accter.Id).Primary_Account_Manager_Id__c;
            if (oppSplitMap.get(terrPAMId + '#' + opp.Id) == null && terrPAMId != null) {
              Opportunity_Split__c accopsp = new Opportunity_Split__c();
              accopsp = addOpportunitySplit(
                opp,
                terrPAMId,
                defaultCompensationRoleMap.get(ETMConstant.PRIMARY_ACCOUNT_MANAGER),
                territoryMap.get(accter.Id)
              );
              upsertoppSplitList.add(accopsp);
              oppSplitMap.put(terrPAMId + '#' + opp.Id, accopsp);
            }
          }
        }

        //logic for ultimate parent
        if (accIdtoAccountMap.get(opp.AccountId).ParentId != null) {
          Id accparentId = accIdtoAccountMap.get(opp.AccountId).Ultimate_Parent_Id__c;
          String parentClassification = accIdtoAccountMap.get(accparentId).Classification__c;
          if (
            mapOfAccountIdToSalesTerritory2.containsKey(accparentId) &&
            KAPAccountClassification.contains(parentClassification)
          ) {
            for (Territory2 parterr : mapOfAccountIdToSalesTerritory2.get(accparentId)) {
              Id parentPAM = territoryMap.get(parterr.Id).Primary_Account_Manager_Id__c;

              if (parterr.Id != opp.Territory2Id && oppSplitMap.get(parentPAM + '#' + opp.Id) == null) {
                Opportunity_Split__c parAccopsp = new Opportunity_Split__c();

                parAccopsp = addOpportunitySplit(
                  opp,
                  parentPAM,
                  defaultCompensationRoleMap.get(ETMConstant.ULTIMATE_PRIMARY_PARENT),
                  territoryMap.get(parterr.Id)
                );
                upsertoppSplitList.add(parAccopsp);
                oppSplitMap.put(parentPAM + '#' + opp.Id, parAccopsp);
              }
            }
          }
        }

        //logic for partner accounts
        if (
          opp.Account.RecordTypeId == PARTNER_RT &&
          (opp.Deal_Type__c == ETMConstant.DEAL_TYPE_PARTNER_INTERNAL_INFRA ||
          opp.Deal_Type__c == ETMConstant.DEAL_TYPE_BPO) &&
          partnerAccountTerritoriesMap.containsKey(opp.AccountId)
        ) {
          for (Territory2 partTerr : partnerAccountTerritoriesMap.get(opp.AccountId)) {
            if (partnerTerrAssMap.containsKey(partTerr.Id)) {
              for (UserTerritory2Association GSIUTA : partnerTerrAssMap.get(partTerr.Id)) {
                //get the ‘Global GSI Alliances Partner Manager’ UserTerritoryAssociation using territoryRoleUserMap and create split record
                if (
                  GSIUTA.RoleInTerritory2 == ETMConstant.GLOBAL_GSI_ALLI_PART_MANAGER &&
                  !oppSplitMap.containsKey(GSIUTA.UserId + '#' + opp.Id)
                ) {
                  //check for user in opp
                  Opportunity_Split__c GDIopsp = new Opportunity_Split__c();
                  GDIopsp = addOpportunitySplit(
                    opp,
                    GSIUTA.UserId,
                    defaultCompensationRoleMap.get(ETMConstant.GLOBAL_GSI_ALLI_PART_MANAGER),
                    territoryMap.get(GSIUTA.Territory2Id)
                  );
                  upsertoppSplitList.add(GDIopsp);
                  oppSplitMap.put(GSIUTA.UserId + '#' + opp.Id, GDIopsp);
                }
              }
            } //end if
          } //end for
        }

        //logic for RPM for Managed Service Customer Account

        if (
          opp.BPO_MS_End_Customer__r.RecordTypeId == CUSTOMER_RT &&
          opp.Deal_Type__c == ETMConstant.DEAL_TYPE_MANAGED_SERVICES
        ) {
          if (mapOfAccountIdToSalesTerritory2.containsKey(opp.BPO_MS_End_Customer__c)) {
            for (Territory2 accter : mapOfAccountIdToSalesTerritory2.get(opp.BPO_MS_End_Customer__c)) {
              if (TerrAssMap.containsKey(accter.Id)) {
                for (UserTerritory2Association SalesRPMUTA : TerrAssMap.get(accter.Id)) {
                  //get the ‘Japan Region Partner Manager’ UserTerritoryAssociation using territoryRoleUserMap and create split record
                  if (
                    SalesRPMUTA.RoleInTerritory2 == ETMConstant.REGION_PARTNER_MANAGER &&
                    !oppSplitMap.containsKey(SalesRPMUTA.UserId + '#' + opp.Id)
                  ) {
                    //check for user in opp
                    Opportunity_Split__c SalesRPMopsp = new Opportunity_Split__c();
                    SalesRPMopsp = addOpportunitySplit(
                      opp,
                      SalesRPMUTA.UserId,
                      defaultCompensationRoleMap.get(ETMConstant.REGION_PARTNER_MANAGER),
                      territoryMap.get(SalesRPMUTA.Territory2Id)
                    );
                    upsertoppSplitList.add(SalesRPMopsp);
                    oppSplitMap.put(SalesRPMUTA.UserId + '#' + opp.Id, SalesRPMopsp);
                  }
                }
              }
            }
          }
        }

        //logic for Japan RPM for Managed Service Partner Account

        if (opp.Account.RecordTypeId == PARTNER_RT && opp.Deal_Type__c == ETMConstant.DEAL_TYPE_MANAGED_SERVICES) {
          if (partnerAccountTerritoriesMap.containsKey(opp.AccountId)) {
            for (Territory2 partTerr : partnerAccountTerritoriesMap.get(opp.AccountId)) {
              if (partnerTerrAssMap.containsKey(partTerr.Id)) {
                for (UserTerritory2Association JPRPMUTA : partnerTerrAssMap.get(partTerr.Id)) {
                  //get the ‘Japan Region Partner Manager’ UserTerritoryAssociation using territoryRoleUserMap and create split record
                  if (
                    JPRPMUTA.RoleInTerritory2 == ETMConstant.JAPAN_REGION_PARTNER_MANAGER &&
                    !oppSplitMap.containsKey(JPRPMUTA.UserId + '#' + opp.Id)
                  ) {
                    //check for user in opp
                    Opportunity_Split__c JRPMopsp = new Opportunity_Split__c();
                    JRPMopsp = addOpportunitySplit(
                      opp,
                      JPRPMUTA.UserId,
                      defaultCompensationRoleMap.get(ETMConstant.JAPAN_REGION_PARTNER_MANAGER),
                      territoryMap.get(JPRPMUTA.Territory2Id)
                    );
                    upsertoppSplitList.add(JRPMopsp);
                    oppSplitMap.put(JPRPMUTA.UserId + '#' + opp.Id, JRPMopsp);
                  }
                }
              } //end if
            } //end for
          }
        }

        //logic for Partner Non Sales Territories
        List<Territory2> partnerNonSalesTerritories = getPartnerManagedTerritory(
          opp,
          oppPartnInv,
          partnerAccountTerritoriesMap
        );
        if (partnerNonSalesTerritories != null && partnerNonSalesTerritories.size() > 0) {
          for (Territory2 PartNSTerr : partnerNonSalesTerritories) {
            if (partnerTerrAssMap.containsKey(PartNSTerr.Id)) {
              Set<String> GSIRole = new Set<String>();
              List<UserTerritory2Association> allPartTerrUTA = partnerTerrAssMap.get(PartNSTerr.Id);

              for (UserTerritory2Association GSIUTARole : allPartTerrUTA) {
                GSIRole.add(GSIUTARole.RoleInTerritory2);
              }

              for (UserTerritory2Association allGSIUTA : allPartTerrUTA) {
                if (
                  allGSIUTA.RoleInTerritory2 == ETMConstant.GLOBAL_GSI_PARTNER_MANAGER ||
                  allGSIUTA.RoleInTerritory2 == ETMConstant.GLOBAL_GSI_ALLI_PART_MANAGER
                ) {
                  if (!oppSplitMap.containsKey(allGSIUTA.UserId + '#' + opp.Id)) {
                    Opportunity_Split__c oppGSI = new Opportunity_Split__c();
                    oppGSI = addOpportunitySplit(
                      opp,
                      allGSIUTA.UserId,
                      defaultCompensationRoleMap.get(allGSIUTA.RoleInTerritory2),
                      territoryMap.get(allGSIUTA.Territory2Id)
                    );
                    upsertoppSplitList.add(oppGSI);
                    oppSplitMap.put(allGSIUTA.UserId + '#' + opp.Id, oppGSI);
                  }
                } else if (oppTerr.Ultimate_Geo__c == PartNSTerr.Ultimate_Geo__c) {
                  //end
                  if (
                    allGSIUTA.RoleInTerritory2 == ETMConstant.SEC_GSI_PARTNER_MANAGER ||
                    allGSIUTA.RoleInTerritory2 == ETMConstant.GSI_PARTNER_MANAGER ||
                    allGSIUTA.RoleInTerritory2 == ETMConstant.STRATEGIC_PARTNER_MANAGER ||
                    allGSIUTA.RoleInTerritory2 == ETMConstant.DISTRIBUTION_PARTNER_MANAGER
                  ) {
                    //if GSI Partner Manager and Secondary GSI Partner Manager both are present in then set percentage split accordingly
                    if (
                      GSIRole.contains(ETMConstant.SEC_GSI_PARTNER_MANAGER) &&
                      (allGSIUTA.RoleInTerritory2 == ETMConstant.SEC_GSI_PARTNER_MANAGER ||
                      allGSIUTA.RoleInTerritory2 == ETMConstant.GSI_PARTNER_MANAGER)
                    ) {
                      Decimal perc = defaultCompensationRoleMap.get(ETMConstant.GSI_WITH_SECONDARY_MANAGER)
                        .Default_Percentage__c;

                      if (!oppSplitMap.containsKey(allGSIUTA.UserId + '#' + opp.Id)) {
                        Opportunity_Split__c alloppGSI = new Opportunity_Split__c();
                        alloppGSI = addOpportunitySplit(
                          opp,
                          allGSIUTA.UserId,
                          allGSIUTA.RoleInTerritory2,
                          perc,
                          territoryMap.get(allGSIUTA.Territory2Id)
                        );
                        upsertoppSplitList.add(alloppGSI);
                        oppSplitMap.put(allGSIUTA.UserId + '#' + opp.Id, alloppGSI);
                      }
                    } else if (!oppSplitMap.containsKey(allGSIUTA.UserId + '#' + opp.Id)) {
                      Opportunity_Split__c alloppGSI = new Opportunity_Split__c();
                      alloppGSI = addOpportunitySplit(
                        opp,
                        allGSIUTA.UserId,
                        defaultCompensationRoleMap.get(allGSIUTA.RoleInTerritory2),
                        territoryMap.get(allGSIUTA.Territory2Id)
                      );
                      upsertoppSplitList.add(alloppGSI);
                      oppSplitMap.put(allGSIUTA.UserId + '#' + opp.Id, alloppGSI);
                    }

                    //Get the user with role GSI Partner Manager,  ‘Strategic Partner Manager’ or ‘Distribution Partner Manager' and populate partner involvement’s
                    if (
                      allGSIUTA.RoleInTerritory2 == ETMConstant.GSI_PARTNER_MANAGER ||
                      allGSIUTA.RoleInTerritory2 == ETMConstant.STRATEGIC_PARTNER_MANAGER ||
                      allGSIUTA.RoleInTerritory2 == ETMConstant.DISTRIBUTION_PARTNER_MANAGER
                    ) {
                      if (oppPartnInv != null) {
                        oppPartnInv.Partner_Manager__c = allGSIUTA.UserId;
                        oppPartnInv.Partner_Manager_Territory__c = territoryMap.get(allGSIUTA.Territory2Id).Name;
                      }
                    }
                  } else if (
                    allGSIUTA.RoleInTerritory2 == ETMConstant.VACANT_TERR_COMP_PART_MANAGER &&
                    !oppSplitMap.containsKey(allGSIUTA.UserId + '#' + opp.Id)
                  ) {
                    //if user not found in above step then get the user with role Vacant Territory Compensation Partner Mgr and create split record
                    Opportunity_Split__c vacCompoppGSI = new Opportunity_Split__c();
                    vacCompoppGSI = addOpportunitySplit(
                      opp,
                      allGSIUTA.UserId,
                      defaultCompensationRoleMap.get(ETMConstant.VACANT_TERR_COMP_PART_MANAGER),
                      territoryMap.get(allGSIUTA.Territory2Id)
                    );
                    upsertoppSplitList.add(vacCompoppGSI);
                    oppSplitMap.put(allGSIUTA.UserId + '#' + opp.Id, vacCompoppGSI);
                  } else {
                    if (allGSIUTA.RoleInTerritory2 != ETMConstant.GEO_PARTNER_MANAGER) {
                      //If we dont get any partner manager or vacant partner manager then send mail to geo ops
                      exceptionOppIds.add(opp.Id);
                    }
                  }
                }
                //logic for Japan RPM
                if (opp.Is_Partner_Sourced__c == true) {
                  if (
                    PartNSTerr.Region__c == japanSetting.Value__c &&
                    allGSIUTA.RoleInTerritory2 == ETMConstant.JAPAN_REGION_PARTNER_MANAGER &&
                    !oppSplitMap.containsKey(allGSIUTA.UserId + '#' + opp.Id)
                  ) {
                    Opportunity_Split__c JapanoppRPM = new Opportunity_Split__c();
                    JapanoppRPM = addOpportunitySplit(
                      opp,
                      allGSIUTA.UserId,
                      defaultCompensationRoleMap.get(ETMConstant.JAPAN_REGION_PARTNER_MANAGER),
                      territoryMap.get(allGSIUTA.Territory2Id)
                    );

                    upsertoppSplitList.add(JapanoppRPM);
                    oppSplitMap.put(allGSIUTA.UserId + '#' + opp.Id, JapanoppRPM);
                    //assign Partner Involvement RPM

                    if (oppPartnInv != null) {
                      oppPartnInv.Region_Partner_Manager__c = allGSIUTA.UserId;
                      oppPartnInv.Region_Partner_Manager_Territory__c = territoryMap.get(allGSIUTA.Territory2Id).Name;
                    }
                  }
                }
              }
            } else {
              // end if partnerTerrAssMap
              //If we dont get any partner manager then send mail to geo ops
              exceptionOppIds.add(opp.Id);
            }
          }
        }

        if (oppPartnInv != null) {
          updatePartnerInvList.add(oppPartnInv);
        }

        //logic for Distribution Partner Non Sales Territories
        if (oppallPartnInv != null && oppallPartnInv.size() > 0) {
          for (Partner_Involvement__c distpartnerInvolvement : oppallPartnInv) {
            if (distributionpartnerAccountTerritoriesMap.containsKey(distpartnerInvolvement.Partner_Account_Name__c)) {
              List<Territory2> distributionPartnerTerritories = distributionpartnerAccountTerritoriesMap.get(
                distpartnerInvolvement.Partner_Account_Name__c
              );
              if (distributionPartnerTerritories != null && distributionPartnerTerritories.size() > 0) {
                for (Territory2 distPartnerTerr : distributionPartnerTerritories) {
                  if (
                    distributionpartnerTerrAssMap.containsKey(distPartnerTerr.Id) &&
                    (oppTerr.Ultimate_Geo__c == distPartnerTerr.Ultimate_Geo__c)
                  ) {
                    List<UserTerritory2Association> alldistPartTerrUTA = distributionpartnerTerrAssMap.get(
                      distPartnerTerr.Id
                    );

                    for (UserTerritory2Association distUTA : alldistPartTerrUTA) {
                      if (!oppSplitMap.containsKey(distUTA.UserId + '#' + opp.Id)) {
                        Opportunity_Split__c distoppsplit = new Opportunity_Split__c();
                        distoppsplit = addOpportunitySplit(
                          opp,
                          distUTA.UserId,
                          defaultCompensationRoleMap.get(distUTA.RoleInTerritory2),
                          territoryMap.get(distUTA.Territory2Id)
                        );
                        upsertoppSplitList.add(distoppsplit);
                        oppSplitMap.put(distUTA.UserId + '#' + opp.Id, distoppsplit);

                        distpartnerInvolvement.Partner_Manager__c = distUTA.UserId;
                        distpartnerInvolvement.Partner_Manager_Territory__c = territoryMap.get(distUTA.Territory2Id)
                          .Name;

                        updatePartnerInvList.add(distpartnerInvolvement);
                      }
                    }
                  }
                }
              }
            }
          }
        } //end distribution logic
      } // for loop closing
      Database.UpsertResult[] saveresultopp = Database.upsert(upsertoppSplitList, false);
      Database.DeleteResult[] deleteresultopp = Database.delete(deleteoppSplitList, false);
      Database.SaveResult[] saveresultPI = Database.update(updatePartnerInvList, false);

      Logger.debug(new LogMessage('Updated OppSplit Result', ''), saveresultopp);
      Logger.debug(new LogMessage('Deleted OppSplit Result', ''), deleteresultopp);
      Logger.debug(new LogMessage('Updated Partner Inv Result', ''), saveresultPI);
    } catch (Exception ex) {
      Logger.debug(new LogMessage('Opportunity syncOpportunitySplit failed', ex.getLineNumber()));
    } finally {
      logger.saveLog();
    }
    return exceptionOppIds;
  }

  private Opportunity_Split__c addOpportunitySplit(
    Opportunity opp,
    Id userId,
    Default_Compensation__mdt defaultCompensation,
    Territory2 Territory
  ) {
    Opportunity_Split__c oppSplit = new Opportunity_Split__c();
    oppSplit.TeamMemberRole__c = defaultCompensation.Role_In_Territory__c;
    oppSplit.Percentage__c = defaultCompensation.Default_Percentage__c;
    oppSplit.User__c = userId;
    oppSplit.Opportunity__c = opp.Id;
    oppSplit.Territory_Reason__c = Territory.Name;
    return oppSplit;
  }

  private Opportunity_Split__c addOpportunitySplit(
    Opportunity opp,
    Id userId,
    String role,
    Decimal perc,
    Territory2 Territory
  ) {
    Opportunity_Split__c oppSplit = new Opportunity_Split__c();
    oppSplit.TeamMemberRole__c = role;
    oppSplit.Percentage__c = perc;
    oppSplit.User__c = userId;
    oppSplit.Opportunity__c = opp.Id;
    oppSplit.Territory_Reason__c = Territory.Name;
    return oppSplit;
  }

  private static List<String> KAPAccountClassification {
    get {
      if (KAPAccountClassification == null) {
        ETM_Setting__mdt metadata = [
          SELECT Label, DeveloperName, Value__c
          FROM ETM_Setting__mdt
          WHERE DeveloperName = 'Account_Classification'
        ];
        KAPAccountClassification = metadata.Value__c.split(',');
      }
      return KAPAccountClassification;
    }
    set;
  }

  private static List<Territory2> getdistributionPartnerTerritory(
    List<Partner_Involvement__c> oppallPartnInv,
    Map<Id, List<Territory2>> distributionpartnerAccountTerritoriesMap
  ) {
    List<Territory2> nonSalesTerritoryList = new List<Territory2>();

    for (Partner_Involvement__c partnerInvolvement : oppallPartnInv) {
      if (distributionpartnerAccountTerritoriesMap.containsKey(partnerInvolvement.Partner_Account_Name__c)) {
        nonSalesTerritoryList.addAll(
          distributionpartnerAccountTerritoriesMap.get(partnerInvolvement.Partner_Account_Name__c)
        );
      }
    }

    return nonSalesTerritoryList;
  }

  private static List<Territory2> getPartnerManagedTerritory(
    Opportunity opportunity,
    Partner_Involvement__c partnerInvolvement,
    Map<Id, List<Territory2>> accountTerritoryMap
  ) {
    List<Territory2> nonSalesTerritoryList = new List<Territory2>();
    if (
      opportunity.Deal_Type__c == ETMConstant.DEAL_TYPE_MANAGED_SERVICES &&
      opportunity.Account.RecordTypeId == PARTNER_RT &&
      opportunity.AccountId != null &&
      accountTerritoryMap.containsKey(opportunity.AccountId)
    ) {
      nonSalesTerritoryList.addAll(accountTerritoryMap.get(opportunity.AccountId));
    } else if (
      (opportunity.Deal_Type__c == ETMConstant.DEAL_TYPE_PARTNER_INTERNAL_INFRA ||
      opportunity.Deal_Type__c == ETMConstant.DEAL_TYPE_BPO) &&
      opportunity.Account.RecordTypeId == PARTNER_RT &&
      accountTerritoryMap.containsKey(opportunity.AccountId)
    ) {
      nonSalesTerritoryList.addAll(accountTerritoryMap.get(opportunity.AccountId));
    } else if (
      opportunity.Is_Partner_Sourced__c == true &&
      partnerInvolvement != null &&
      partnerInvolvement.Opportunity_Sourced__c == true &&
      accountTerritoryMap.containsKey(partnerInvolvement.Partner_Account_Name__c)
    ) {
      nonSalesTerritoryList.addAll(accountTerritoryMap.get(partnerInvolvement.Partner_Account_Name__c));
    }
    return nonSalesTerritoryList;
  }
}