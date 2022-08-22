/**
 * @AUTHOR: UIPath
 * @DATE: 03/30/2022
 * @DESCRIPTION: PartnerInvolvementsService_ET for ETM project.
 * syncPartnerTerritoriesOnCustomer method execute when Partner Involvement record create, update or delete
 * All the partner territories available under partner account copied to customer account when create Partner Involvement record
 * All the partner territories availale under Partner account delete from customer account when delete Partner Involvement record
 * All the partner territories available under new Partner account copied to customer account and all the partner territories available under old Partner account delete from customer account
 */
public without sharing class PartnerInvolvementsService_ET {
  public static List<ObjectTerritory2Association> listOfPartnerToCustomerOTAs = new List<ObjectTerritory2Association>();

  private static Map<Id, Id> buildOppIdToAccountIdMap(Set<Id> setOfCustomerOpportunityIds) {
    Map<Id, Id> mapOfOppIdToAccountId = new Map<Id, Id>();
    OpportunitiesSelector_ET oppSelector = (OpportunitiesSelector_ET) Application_ET.Selector.newInstance(
      Opportunity.SObjectType
    );
    if (setOfCustomerOpportunityIds != null && setOfCustomerOpportunityIds.size() > 0) {
      for (Opportunity opp : oppSelector.selectOppById(setOfCustomerOpportunityIds)) {
        if (
          opp.AccountId != null &&
          !mapOfOppIdToAccountId.containsKey(opp.Id) &&
          opp.Account.RecordType.DeveloperName.Contains(ETMConstant.CUSTOMER)
        ) {
          mapOfOppIdToAccountId.put(opp.Id, opp.AccountId);
        }
      }
    }
    return mapOfOppIdToAccountId;
  }

  private static Map<Id, List<ObjectTerritory2Association>> buildCustomerAccountIdToOTAsMap(
    Map<Id, Id> mapOfOppIdToAccountId
  ) {
    ObjectTerritory2AssociationsSelector_ET objAssociationSelector = (ObjectTerritory2AssociationsSelector_ET) Application_ET.Selector.newInstance(
      ObjectTerritory2Association.getSObjectType()
    );
    Map<Id, List<ObjectTerritory2Association>> mapOfCustomerAccountIdToOTAs = new Map<Id, List<ObjectTerritory2Association>>();
    if (mapOfOppIdToAccountId != null && mapOfOppIdToAccountId.KeySet().size() > 0) {
      for (
        ObjectTerritory2Association OTA : objAssociationSelector.selectByObjectId(
          new Set<Id>(mapOfOppIdToAccountId.values())
        )
      ) {
        if (!mapOfCustomerAccountIdToOTAs.containsKey(OTA.ObjectId)) {
          mapOfCustomerAccountIdToOTAs.put(OTA.ObjectId, new List<ObjectTerritory2Association>{ OTA });
        } else {
          mapOfCustomerAccountIdToOTAs.get(OTA.ObjectId).add(OTA);
        }
      }
    }
    return mapOfCustomerAccountIdToOTAs;
  }

  private static Map<Id, List<ObjectTerritory2Association>> buildPartnerAccountIdToOTAsMap(
    Set<Id> setOfPartnerAccountIds
  ) {
    Map<Id, List<ObjectTerritory2Association>> mapOfPartnerAccountIdToOTAs = new Map<Id, List<ObjectTerritory2Association>>();
    ObjectTerritory2AssociationsSelector_ET objAssociationSelector = (ObjectTerritory2AssociationsSelector_ET) Application_ET.Selector.newInstance(
      ObjectTerritory2Association.getSObjectType()
    );
    if (setOfPartnerAccountIds != null && setOfPartnerAccountIds.size() > 0) {
      for (
        ObjectTerritory2Association OTA : objAssociationSelector.selectByObjectIdAndNonSalesTerritory(
          setOfPartnerAccountIds,
          new Set<String>{ ETMConstant.PARTNER_MANAGEMENT }
        )
      ) {
        if (!mapOfPartnerAccountIdToOTAs.containsKey(OTA.ObjectId)) {
          mapOfPartnerAccountIdToOTAs.put(OTA.ObjectId, new List<ObjectTerritory2Association>{ OTA });
        } else {
          mapOfPartnerAccountIdToOTAs.get(OTA.ObjectId).add(OTA);
        }
      }
    }
    return mapOfPartnerAccountIdToOTAs;
  }

  private static void clonePartnerOTAToCustomer(Id territory2Id, Id accountId) {
    listOfPartnerToCustomerOTAs.add(
      new ObjectTerritory2Association(
        ObjectId = accountId,
        AssociationCause = ETMConstant.TERRITORY2MANUAL,
        Territory2Id = territory2Id
      )
    );
  }

  private static void prepareOTAsToCreate(
    List<Partner_Involvement__c> listOfPartnerInvolements,
    Map<Id, Id> mapOfOppIdToAccountId,
    Map<Id, List<ObjectTerritory2Association>> mapOfPartnerAccountIdToOTAs,
    Map<Id, List<ObjectTerritory2Association>> mapOfCustomerAccountIdToOTAs
  ) {
    AccountsSelector_ET accountSelector = (AccountsSelector_ET) Application_ET.Selector.newInstance(
      Account.SObjectType
    );

    Map<Id, Account> mapOfAccountIdToRecord = new Map<Id, Account>(
      accountSelector.selectById(mapOfPartnerAccountIdToOTAs.KeySet())
    );

    for (Partner_Involvement__c partner : listOfPartnerInvolements) {
      if (mapOfPartnerAccountIdToOTAs.containsKey(partner.Partner_Account_Name__c)) {
        for (
          ObjectTerritory2Association partnerOTA : mapOfPartnerAccountIdToOTAs.get(partner.Partner_Account_Name__c)
        ) {
          Boolean isPartnerTerritoryExistOnCustomer = false;
          String partnerNamedListAssignment = mapOfAccountIdToRecord.get(partnerOTA.ObjectId)
            .Partner_Named_List_Assignment__c;

          if (partnerNamedListAssignment != null && partnerNamedListAssignment.contains(partnerOTA.Territory2.Name)) {
            if (
              mapOfOppIdToAccountId.containsKey(partner.PartnerOpp_Name__c) &&
              mapOfCustomerAccountIdToOTAs.containsKey(mapOfOppIdToAccountId.get(partner.PartnerOpp_Name__c))
            ) {
              for (
                ObjectTerritory2Association customerOTA : mapOfCustomerAccountIdToOTAs.get(
                  mapOfOppIdToAccountId.get(partner.PartnerOpp_Name__c)
                )
              ) {
                if (partnerOTA.Territory2Id == customerOTA.Territory2Id) {
                  isPartnerTerritoryExistOnCustomer = true;
                }
              }
              // If Territories on Partner Account with TerritoryType = 'Partner Management'
              // doesn't exist on Customer Account then clone Territories on Parnter Account -> Customer Account
              if (!isPartnerTerritoryExistOnCustomer) {
                clonePartnerOTAToCustomer(
                  partnerOTA.Territory2Id,
                  mapOfOppIdToAccountId.get(partner.PartnerOpp_Name__c)
                );
              }
            } else {
              if (mapOfOppIdToAccountId.containsKey(partner.PartnerOpp_Name__c)) {
                // If Customer Account has no Territories then clone all Territories on
                // Partner Account with TerritoryType = "Partner Management" to Customer Account
                clonePartnerOTAToCustomer(
                  partnerOTA.Territory2Id,
                  mapOfOppIdToAccountId.get(partner.PartnerOpp_Name__c)
                );
              }
            }
          }
        }
      }
    }
    try {
      List<Database.SaveResult> results = Database.insert(listOfPartnerToCustomerOTAs, false);
      Logger.debug(new LogMessage('Create Object Territory Association Result', ''), results);
    } catch (Exception ex) {
      Logger.debug(
        new LogMessage('Create Object Territory Association Result failed', ex.getLineNumber() + ex.getMessage())
      );
    } finally {
      logger.saveLog();
    }
  }

  private static void prepareOTAsToDelete(
    List<Partner_Involvement__c> listOfPartnerInvolements,
    Map<Id, Id> mapOfOppIdToAccountId,
    Map<Id, List<ObjectTerritory2Association>> mapOfPartnerAccountIdToOTAs,
    Map<Id, List<ObjectTerritory2Association>> mapOfCustomerAccountIdToOTAs,
    Map<Id, Partner_Involvement__c> existingRecords
  ) {
    Set<Id> setOfCustomerOTAIds = new Set<Id>();
    for (Partner_Involvement__c partner : listOfPartnerInvolements) {
      Partner_Involvement__c oldPartnerInvolvement;
      if (existingRecords != null && existingRecords.containsKey(partner.Id)) {
        oldPartnerInvolvement = existingRecords.get(partner.Id);
      }
      List<ObjectTerritory2Association> OTAs = new List<ObjectTerritory2Association>();
      if (oldPartnerInvolvement == null && mapOfPartnerAccountIdToOTAs.containsKey(partner.Partner_Account_Name__c)) {
        OTAs = mapOfPartnerAccountIdToOTAs.get(partner.Partner_Account_Name__c);
      } else if (
        oldPartnerInvolvement != null &&
        mapOfPartnerAccountIdToOTAs.containsKey(oldPartnerInvolvement.Partner_Account_Name__c)
      ) {
        OTAs = mapOfPartnerAccountIdToOTAs.get(oldPartnerInvolvement.Partner_Account_Name__c);
      }
      if (OTAs != null && OTAs.size() > 0) {
        for (ObjectTerritory2Association partnerOTA : OTAs) {
          if (
            mapOfOppIdToAccountId.containsKey(partner.PartnerOpp_Name__c) &&
            mapOfCustomerAccountIdToOTAs.containsKey(mapOfOppIdToAccountId.get(partner.PartnerOpp_Name__c))
          ) {
            for (
              ObjectTerritory2Association customerOTA : mapOfCustomerAccountIdToOTAs.get(
                mapOfOppIdToAccountId.get(partner.PartnerOpp_Name__c)
              )
            ) {
              if (partnerOTA.Territory2Id == customerOTA.Territory2Id) {
                setOfCustomerOTAIds.add(customerOTA.Id);
              }
            }
          }
        }
      }
    }
    try {
      ObjectTerritory2AssociationsSelector_ET objAssociationSelector = (ObjectTerritory2AssociationsSelector_ET) Application_ET.Selector.newInstance(
        ObjectTerritory2Association.getSObjectType()
      );
      List<ObjectTerritory2Association> listOfCustomerOTAsToDelete = objAssociationSelector.selectById(
        setOfCustomerOTAIds
      );
      List<Database.DeleteResult> results = Database.delete(listOfCustomerOTAsToDelete, false);
      Logger.debug(new LogMessage('Delete Object Territory Association Result', ''), results);
    } catch (Exception ex) {
      Logger.debug(
        new LogMessage('Delete Object Territory Association Result failed', ex.getLineNumber() + ex.getMessage())
      );
    } finally {
      logger.saveLog();
    }
  }

  public void syncPartnerTerritoriesOnCustomer(
    String action,
    List<Partner_Involvement__c> listOfPartnerInvolements,
    Map<Id, Partner_Involvement__c> existingRecords
  ) {
    Set<Id> setOfPartnerAccountIds = new Set<Id>();
    Set<Id> setOfCustomerOpportunityIds = new Set<Id>();
    Set<Id> setOfOldPartnerAccountIds = new Set<Id>();
    Map<Id, Id> mapOfOppIdToAccountId = new Map<Id, Id>();
    Map<Id, List<ObjectTerritory2Association>> mapOfOldPartnerAccountIdToOTAs = new Map<Id, List<ObjectTerritory2Association>>();
    Map<Id, List<ObjectTerritory2Association>> mapOfPartnerAccountIdToOTAs = new Map<Id, List<ObjectTerritory2Association>>();
    Map<Id, List<ObjectTerritory2Association>> mapOfCustomerAccountIdToOTAs = new Map<Id, List<ObjectTerritory2Association>>();

    for (Partner_Involvement__c partner : listOfPartnerInvolements) {
      Partner_Involvement__c oldPartnerInvolement;
      if (existingRecords != null && existingRecords.containsKey(partner.Id)) {
        oldPartnerInvolement = existingRecords.get(partner.Id);
      }
      if (partner.Partner_Account_Name__c != null) {
        setOfPartnerAccountIds.add(partner.Partner_Account_Name__c);
      }
      if (partner.PartnerOpp_Name__c != null) {
        setOfCustomerOpportunityIds.add(partner.PartnerOpp_Name__c);
      }
      if (oldPartnerInvolement != null && oldPartnerInvolement.Partner_Account_Name__c != null) {
        setOfOldPartnerAccountIds.add(oldPartnerInvolement.Partner_Account_Name__c);
      }
    }
    mapOfOppIdToAccountId = buildOppIdToAccountIdMap(setOfCustomerOpportunityIds);
    mapOfCustomerAccountIdToOTAs = buildCustomerAccountIdToOTAsMap(mapOfOppIdToAccountId);
    mapOfPartnerAccountIdToOTAs = buildPartnerAccountIdToOTAsMap(setOfPartnerAccountIds);
    mapOfOldPartnerAccountIdToOTAs = buildPartnerAccountIdToOTAsMap(setOfOldPartnerAccountIds);
    if (action == 'create') {
      prepareOTAsToCreate(
        listOfPartnerInvolements,
        mapOfOppIdToAccountId,
        mapOfPartnerAccountIdToOTAs,
        mapOfCustomerAccountIdToOTAs
      );
    } else if (action == 'update') {
      prepareOTAsToDelete(
        listOfPartnerInvolements,
        mapOfOppIdToAccountId,
        mapOfOldPartnerAccountIdToOTAs,
        mapOfCustomerAccountIdToOTAs,
        existingRecords
      );
      prepareOTAsToCreate(
        listOfPartnerInvolements,
        mapOfOppIdToAccountId,
        mapOfPartnerAccountIdToOTAs,
        mapOfCustomerAccountIdToOTAs
      );
    } else if (action == 'delete') {
      prepareOTAsToDelete(
        listOfPartnerInvolements,
        mapOfOppIdToAccountId,
        mapOfPartnerAccountIdToOTAs,
        mapOfCustomerAccountIdToOTAs,
        null
      );
    }
  }
}