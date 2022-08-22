/**
 * @AUTHOR: UIPath
 * @DATE: 01/10/2021
 * @DESCRIPTION: This is Account object service class
 */
public without sharing class AccountsService_ET implements IAccountTerritory {
  public Map<String, List<String>> countryCodesGroupMap;
  public Set<Id> accountTerritoryIds = new Set<Id>(); // gets populate on getAccountTerritories method
  public Map<Id, Territory2> accountSalesTerritoryMap = new Map<Id, Territory2>(); // gets populate on getAccountSalesTerritories method

  /* When an account ParentId has changed, set Recalculate Compensation flag to ture to recalculate Opportunity Splits */
  public void setRecalculateCompensationFlag(List<Account> accountsList, Map<Id, Account> existingAccountsMap) {
    for (Account acc : accountsList) {
      Account oldAcc;
      if (existingAccountsMap != null) {
        oldAcc = existingAccountsMap.get(acc.Id);
      }
      if (
        oldAcc != null &&
        acc.ParentId != null &&
        oldAcc.ParentId != acc.ParentId &&
        !acc.Recalculate_Compensation__c
      ) {
        acc.Recalculate_Compensation__c = true;
      }
    }
  }

  public void runTerritoryRules(List<Account> accountList, Map<Id, Account> oldAccountMap) {
    List<Account> listOfAccountToRunRules = new List<Account>();
    for (Account newAccount : accountList) {
      Account oldAccount;
      if (oldAccountMap != null && oldAccountMap.containsKey(newAccount.Id)) {
        oldAccount = oldAccountMap.get(newAccount.Id);
      }

      if (
        (newAccount.Named_List_Assignment__c == null ||
        newAccount.Named_List_Assignment__c == ETMConstant.UNABLE_TO_DEFAULT_NAMED_LIST_ASSIGNMENT) &&
        newAccount.Partner_Named_List_Assignment__c == null &&
        ((oldAccount == null &&
        (newAccount.BillingCountryCode != null ||
        newAccount.BillingStateCode != null ||
        newAccount.BillingPostalCode != null)) ||
        (oldAccount != null &&
        (oldAccount.BillingCountryCode != newAccount.BillingCountryCode &&
        newAccount.BillingCountryCode != null) ||
        (oldAccount.BillingStateCode != newAccount.BillingStateCode &&
        newAccount.BillingStateCode != null) ||
        (oldAccount.BillingPostalCode != newAccount.BillingPostalCode &&
        newAccount.BillingPostalCode != null)))
      ) {
        listOfAccountToRunRules.add(newAccount);
      }
    }
    if (!listOfAccountToRunRules.isEmpty() && listOfAccountToRunRules.size() > 0) {
      AbstractQueueable.enqueue(new RunTerritoryRules(null, listOfAccountToRunRules));
    }
  }

  /**
   * Case 1: When BillingPostalCode changed and ParentId == null, run for all children
   * Case 2: When BillingPostalCode changed and ParentId != null, run for changed account
   * Case 3: When ParentId changed and ParentId == null, run for all children
   * Case 4: When ParentId changed and ParentId != null, run for all children
   * This method populates below account fields
   *   - Territory Postalcode Mapping
   *   - Is Domestic Child?
   */
  public void populateTerritoryZipcodeMapping(
    List<Account> accountList,
    Map<Id, Account> oldAccountMap,
    Boolean syncStaticField,
    Boolean isInsert
  ) {
    Set<String> postalCodes = new Set<String>();
    Set<Id> ultimateParentIds = new Set<Id>();
    Map<Id, Account> ultimateParentMap = new Map<Id, Account>();

    for (Account account : accountList) {
      Account existingAccount;
      if (oldAccountMap != null) {
        existingAccount = (Account) oldAccountMap.get(account.Id);
      }

      // Populate Static Fields
      if (
        syncStaticField ||
        existingAccount == null ||
        AddressTriggerHandler.syncAddressFromObject == true ||
        (existingAccount != null &&
        account.Sync_Static_Fields__c &&
        account.Sync_Static_Fields__c != existingAccount.Sync_Static_Fields__c)
      ) {
        account.Annual_Revenue_Static__c = account.AnnualRevenue;
        account.Billing_Country_Code_Static__c = account.BillingCountryCode;
        account.Billing_State_Code_Static__c = account.BillingStateCode;
        account.Billing_Postal_Code_Static__c = account.BillingPostalCode;
        account.Owner_Sync_Status__c = ETMConstant.OWNER_STATUS_OUT_OF_SYNC;
        if (account.Billing_Postal_Code_Static__c != null) {
          String uniqueKey = generateUniqueKey(account);
          if (uniqueKey != null) {
            postalCodes.add(uniqueKey);
          }
        }
        if (account.Ultimate_Parent_Id__c != null) {
          ultimateParentIds.add(Id.valueOf(account.Ultimate_Parent_Id__c));
        }
      }
    }
    AccountsSelector_ET accountSelector = (AccountsSelector_ET) Application_ET.Selector.newInstance(
      Account.SObjectType
    );
    if (!ultimateParentIds.isEmpty()) {
      Map<Id, Account> accountMap = new Map<Id, Account>();
      if (accountList != null) {
        accountMap.putall(accountMap);
      }
      for (Account acc : accountSelector.selectById(ultimateParentIds)) {
        String ultimateParentUniquekey = generateUniqueKey(acc);
        if (ultimateParentUniquekey != null) {
          postalCodes.add(ultimateParentUniquekey);
        }
        // If ultimate parent is present in the account list then consider the new billing country code static
        if (accountMap.containsKey(acc.id)) {
          acc.Billing_Country_Code_Static__c = accountMap.get(acc.id).Billing_Country_Code_Static__c;
        }
        ultimateParentMap.put(acc.Id, acc);
      }
    }
    Map<String, Territory_Postal_Code_Mapping__c> postalCodeTerrMapping = new Map<String, Territory_Postal_Code_Mapping__c>();
    if (postalCodes.size() > 0) {
      TerritoryPostalCodeMappingsSelector_ET terrZipcodeSelector = (TerritoryPostalCodeMappingsSelector_ET) Application_ET.Selector.newInstance(
        Territory_Postal_Code_Mapping__c.SObjectType
      );
      postalCodeTerrMapping = TerrZipcodeSelector.selectMapByPostalCode(postalCodes);
    }

    // This is required to populate default named list assignment
    List<Territory2> creatorTerritories = new List<Territory2>();
    UserTerritory2AssociationsSelector_ET userAssSelector = (UserTerritory2AssociationsSelector_ET) Application_ET.Selector.newInstance(
      UserTerritory2Association.SObjectType
    );
    for (UserTerritory2Association userAss : userAssSelector.selectByUserIds(new Set<Id>{ UserInfo.getUserId() })) {
      if (!creatorTerritories.contains(userAss.Territory2)) {
        creatorTerritories.add(userAss.Territory2);
      }
    }

    for (Account account : accountList) {
      Account existingAccount;
      if (oldAccountMap != null) {
        existingAccount = (Account) oldAccountMap.get(account.Id);
      }
      if (
        syncStaticField ||
        existingAccount == null ||
        AddressTriggerHandler.syncAddressFromObject == true ||
        (existingAccount != null &&
        account.Sync_Static_Fields__c &&
        account.Sync_Static_Fields__c != existingAccount.Sync_Static_Fields__c)
      ) {
        if (account.Sync_Static_Fields__c)
          account.Sync_Static_Fields__c = false;
        String uniquekey = generateUniqueKey(account);
        if (uniquekey != null && postalCodeTerrMapping.containsKey(uniquekey)) {
          account.Territory_Postal_Code_Mapping__c = postalCodeTerrMapping.get(uniquekey).Id;
        } else {
          account.Territory_Postal_Code_Mapping__c = null;
        }
        if (
          account.ParentId != null &&
          account.Ultimate_Parent_Id__c != null &&
          ultimateParentMap.containsKey(Id.valueof(account.Ultimate_Parent_Id__c))
        ) {
          Account UltimateParent = ultimateParentMap.get(Id.valueof(account.Ultimate_Parent_Id__c));
          String ultimateParentGroup = getCountryGroup(UltimateParent);
          String childGroup = getCountryGroup(account);
          if (ultimateParentGroup != null && childGroup != null && ultimateParentGroup == childGroup) {
            account.Is_Domestic_Child__c = true;
            String externalId = generateUniqueKey(UltimateParent);
            if (postalCodeTerrMapping.containsKey(externalId)) {
              account.Territory_Postal_Code_Mapping__c = postalCodeTerrMapping.get(externalId).Id;
            }
          } else {
            account.Is_Domestic_Child__c = false;
          }
        }
      }
      if (isInsert) {
        populateDefaultNamedListAssignment(
          account,
          creatorTerritories,
          ultimateParentMap.get(account.Ultimate_Parent_Id__c)
        );
      }
    }
    if (syncStaticField == true) {
      List<Database.SaveResult> result = Database.update(accountList, false);
      Logger.debug(new LogMessage('Updated Account Result', ''), result);
    }
  }

  public Set<Id> populateCSMTerritory(List<Account> changedRecords) {
    Set<Id> CSMUserIds = new Set<Id>();
    Set<Id> exceptionAccIds = new Set<Id>();
    Set<Id> accountIds = new Set<Id>();
    List<ObjectTerritory2Association> CSMobjList = new List<ObjectTerritory2Association>();
    List<ObjectTerritory2Association> delCSMobjList = new List<ObjectTerritory2Association>();
    Map<Id, List<UserTerritory2Association>> mapOfCSMTerrUTARecord = new Map<Id, List<UserTerritory2Association>>();
    Map<Id, List<ObjectTerritory2Association>> mapOfCSMTerrOTARecord = new Map<Id, List<ObjectTerritory2Association>>();

    try {
      //get Account CSM Ids.
      for (Account ac : changedRecords) {
        if (!CSMUserIds.contains(ac.CSM__c))
          CSMUserIds.add(ac.CSM__c);
        accountIds.add(ac.Id);
      }

      //get account's existing OTA
      ObjectTerritory2AssociationsSelector_ET objAssociationSelector = (ObjectTerritory2AssociationsSelector_ET) Application_ET.Selector.newInstance(
        ObjectTerritory2Association.getSObjectType()
      );
      List<ObjectTerritory2Association> objAssociationList = objAssociationSelector.selectByObjectIdAndTerritoryType(
        accountIds,
        new Set<String>{ ETMConstant.CUSTOMER_SUCCESS }
      );

      for (ObjectTerritory2Association otaAss : objAssociationList) {
        if (!mapOfCSMTerrOTARecord.containsKey(otaAss.ObjectId))
          mapOfCSMTerrOTARecord.put(otaAss.ObjectId, new List<ObjectTerritory2Association>{ otaAss });
        else
          mapOfCSMTerrOTARecord.get(otaAss.ObjectId).add(otaAss);
      }

      //get account's CSM UTA
      UserTerritory2AssociationsSelector_ET userAssSelector = (UserTerritory2AssociationsSelector_ET) Application_ET.Selector.newInstance(
        UserTerritory2Association.SObjectType
      );

      List<UserTerritory2Association> CSMUTAList = userAssSelector.selectByRoleAndTypeInTerritory(
        CSMUserIds,
        new Set<String>{ ETMConstant.CUSTOMER_SUCCESS_MANAGER },
        new Set<String>{ ETMConstant.CUSTOMER_SUCCESS }
      );

      for (UserTerritory2Association userAss : CSMUTAList) {
        if (!mapOfCSMTerrUTARecord.containsKey(userAss.UserId))
          mapOfCSMTerrUTARecord.put(userAss.UserId, new List<UserTerritory2Association>{ userAss });
        else
          mapOfCSMTerrUTARecord.get(userAss.UserId).add(userAss);
      }

      for (Account acToUpdate : changedRecords) {
        Boolean addToCSMObj = false;

        List<UserTerritory2Association> accCSMList = mapOfCSMTerrUTARecord.get(acToUpdate.CSM__c);

        //delete existing CSM association
        if (mapOfCSMTerrOTARecord.containsKey(acToUpdate.Id))
          delCSMobjList.addall(mapOfCSMTerrOTARecord.get(acToUpdate.Id));

        //Create ObjectTerritory2Association where user is same as account’s CSM
        if (accCSMList != null && accCSMList.size() == 1) {
          ObjectTerritory2Association csmObj = new ObjectTerritory2Association();
          csmObj.Territory2Id = accCSMList[0].Territory2Id;
          csmObj.ObjectId = acToUpdate.Id;
          csmObj.AssociationCause = 'Territory2Manual';
          CSMobjList.add(csmObj);
        } else {
          //If multiple territories found or no territory found then send exception email
          exceptionAccIds.add(acToUpdate.Id);
        }
      }
      AccountsSelector_ET accountSelector = (AccountsSelector_ET) Application_ET.Selector.newInstance(
        Account.SObjectType
      );

      Database.DeleteResult[] deleteCSMLst = Database.delete(delCSMobjList, false);
      Database.SaveResult[] updateCSMLst = Database.insert(CSMobjList, false);
    } catch (Exception e) {
      Logger.error(new LogMessage('Exception: {0}', e.getLineNumber() + e.getMessage()));
      throw e;
    } finally {
      Logger.saveLog();
    }

    return exceptionAccIds;
  }

  public void populateDefaultNamedListAssignment(
    Account account,
    List<Territory2> creatorTerritories,
    Account ultimateParent
  ) {
    if (creatorTerritories != null) {
      Integer creatorTerritoriesCount = creatorTerritories.size();
      if (creatorTerritoriesCount == 1) {
        Territory2 creatorTerritory = creatorTerritories[0];
        // If domestic child and parent territory override is true Or not domestic child
        if (
          ((account.Is_Domestic_Child__c == true && account.Parent_Territory_Override__c == true) ||
          account.Is_Domestic_Child__c == false) &&
          String.isBlank(account.Named_List_Assignment__c) &&
          (creatorTerritory.Named_List_Assignment__c == true ||
          account.Territory_Postal_Code_Mapping__c == null)
        ) {
          account.Named_List_Assignment__c = creatorTerritory.Name;
        } else if (
          account.Is_Domestic_Child__c == true &&
          account.Parent_Territory_Override__c == false &&
          creatorTerritory.Named_List_Assignment__c == true &&
          ultimateParent != null &&
          (String.isBlank(ultimateParent.Named_List_Assignment__c) ||
          ultimateParent.Named_List_Assignment__c == ETMConstant.UNABLE_TO_DEFAULT_NAMED_LIST_ASSIGNMENT) &&
          ultimateParent.OwnerId == Userinfo.getUserId()
        ) {
          account.Named_List_Assignment__c = creatorTerritory.Name;
        } else if (
          account.Is_Domestic_Child__c == true &&
          account.Parent_Territory_Override__c == false &&
          ultimateParent != null &&
          ((creatorTerritory.Named_List_Assignment__c == false &&
          ultimateParent.Territory_Postal_Code_Mapping__c == null) ||
          (creatorTerritory.Named_List_Assignment__c == true &&
          ultimateParent.Named_List_Assignment__c == null &&
          ultimateParent.OwnerId != Userinfo.getUserId()))
        ) {
          account.Named_List_Assignment__c = ETMConstant.UNABLE_TO_DEFAULT_NAMED_LIST_ASSIGNMENT;
        }
      } else if (creatorTerritoriesCount > 1 || creatorTerritoriesCount == 0) {
        if (
          ((account.Is_Domestic_Child__c == true && account.Parent_Territory_Override__c == true) ||
          account.Is_Domestic_Child__c == false) &&
          String.isBlank(account.Named_List_Assignment__c) &&
          account.Territory_Postal_Code_Mapping__c == null
        ) {
          account.Named_List_Assignment__c = ETMConstant.UNABLE_TO_DEFAULT_NAMED_LIST_ASSIGNMENT;
        } else if (
          account.Is_Domestic_Child__c == true &&
          account.Parent_Territory_Override__c == false &&
          ultimateParent != null &&
          ((String.isBlank(ultimateParent.Named_List_Assignment__c) ||
          ultimateParent.Named_List_Assignment__c == ETMConstant.UNABLE_TO_DEFAULT_NAMED_LIST_ASSIGNMENT)) &&
          ultimateParent.Territory_Postal_Code_Mapping__c == null
        ) {
          account.Named_List_Assignment__c = ETMConstant.UNABLE_TO_DEFAULT_NAMED_LIST_ASSIGNMENT;
        }
      }
    }
  }
  public List<Account> syncAccountOwner(Set<Id> accountIds) {
    Map<Id, Territory2> accountIdTerritoryMap = getAccountTerritory(accountIds);

    // Defer Queueable
    AbstractQueueable.deferEnqueue();
    List<Account> updatedAccounts = syncAccountTerritoryFields(accountIdTerritoryMap);

    ETM_Setting__mdt setting = Utility_ET.getSetting(ETMConstant.SKIP_OPP_REALIGNMENT_SETTING);
    Logger.debug(new LogMessage('Skip Opp Realignment Setting', ''), setting);
    if (setting == null || setting.value__c != 'true') {
      OpportunitiesService_ET oppService = (OpportunitiesService_ET) Application_ET.Service.newInstance(
        OpportunitiesService_ET.class
      );
      List<Opportunity> updatedOpportunities = oppService.realignOpportunities(accountIdTerritoryMap);
      Logger.debug(new LogMessage('Updated opportunities', ''), updatedOpportunities);
    }
    return updatedAccounts;
  }
  public List<Account> syncAccountTerritoryFields(Map<Id, Territory2> accountTerritoryMap) {
    List<Account> accountList = new List<Account>();
    Set<String> roleSet = new Set<String>{ ETMConstant.SALES_DEVELOPMENT_REP, ETMConstant.PRIMARY_ACCOUNT_MANAGER };

    Set<Id> territoryIds = new Set<Id>();

    for (Territory2 territory : accountTerritoryMap.values()) {
      territoryIds.add(territory.Id);
    }

    UserTerritory2AssociationsService_ET userTerritoryAssService = (UserTerritory2AssociationsService_ET) Application_ET.Service.newInstance(
      UserTerritory2AssociationsService_ET.class
    );

    Map<Id, List<UserTerritory2Association>> territoryUserAssListMap = userTerritoryAssService.getMapofTerritoryIdAndUserAssociations(
      territoryIds,
      roleSet
    );

    for (Id accountId : accountTerritoryMap.keySet()) {
      Account account = new Account(Id = accountId);

      Territory2 territory = accountTerritoryMap.get(accountId);

      boolean isPrimaryPresent = false;
      if (territoryUserAssListMap.containsKey(territory.Id)) {
        account.EDR__c = null;
        for (UserTerritory2Association userAssociation : territoryUserAssListMap.get(territory.Id)) {
          if (userAssociation.RoleInTerritory2 == ETMConstant.SALES_DEVELOPMENT_REP) {
            account.EDR__c = userAssociation.UserId;
          } else if (userAssociation.RoleInTerritory2 == ETMConstant.PRIMARY_ACCOUNT_MANAGER) {
            isPrimaryPresent = true;
          }
        }
      }
      if (
        String.isBlank(territory.Primary_Account_Manager_Id__c) &&
        String.isBlank(territory.Interim_Account_Manager_Id__c)
      ) {
        account.Owner_Sync_Status__c = ETMConstant.OWNER_STATUS_EXCEPTION;
      } else {
        if (isPrimaryPresent) {
          account.OwnerId = territory.Primary_Account_Manager_Id__c;
        } else if (String.isNotBlank(territory.Interim_Account_Manager_Id__c)) {
          account.OwnerId = territory.Interim_Account_Manager_Id__c;
        }
        account.Owner_Updated_On__c = System.now();
        account.Owner_Sync_Status__c = ETMConstant.OWNER_STATUS_SYNCHED;
      }
      account.Geo__c = territory.Ultimate_Geo__c;
      account.Area__c = territory.Area__c;
      account.Region__c = territory.Region__c;
      account.Subregion__c = territory.Sub_Region_Text__c;
      accountList.add(account);
    }
    if (!accountList.isEmpty()) {
      //final fflib_ISObjectUnitOfWork unitOfWork = Application_ET.UnitOfWork.newInstance();
      //unitOfWork.registerDirty(accountList);
      //unitOfWork.commitWork();
      List<Database.SaveResult> result = Database.update(accountList, false);
      Logger.debug(new LogMessage('Update Account Owner Result', ''), result);
      Logger.saveLog();
    }
    return accountList;
  }

  private string getCountryGroup(Account account) {
    if (countryCodesGroupMap == null) {
      countryCodesGroupMap = new Map<String, List<String>>();
      if (
        Schema.SObjectType.ETM_Country_Group__mdt.fields.Label.isAccessible() &&
        Schema.SObjectType.ETM_Country_Group__mdt.fields.Country_Codes__c.isAccessible()
      ) {
        for (ETM_Country_Group__mdt countryGroup : [
          SELECT Label, Country_Codes__c
          FROM ETM_Country_Group__mdt
          WITH SECURITY_ENFORCED
        ]) {
          countryCodesGroupMap.put(countryGroup.Label, countryGroup.Country_Codes__c.split(','));
        }
      }
    }

    if (countryCodesGroupMap.keySet().size() > 0) {
      for (String groupName : countryCodesGroupMap.KeySet()) {
        if (countryCodesGroupMap.get(groupName).contains(account.Billing_Country_Code_Static__c)) {
          return groupName;
        }
      }
    }
    return null;
  }

  // This method return newly associated sales territory to account
  public Map<Id, Territory2> getAccountTerritory(Set<id> accountIds) {
    Map<Id, Territory2> accountIdTerritoryMap = new Map<Id, Territory2>();
    // Query ObjectTerritory2Association related to account
    ObjectTerritory2AssociationsSelector_ET objAssociationSelector = (ObjectTerritory2AssociationsSelector_ET) Application_ET.Selector.newInstance(
      ObjectTerritory2Association.getSObjectType()
    );

    // Order by SystemModStamp is not working as expected. Selector is applying ID ASC order first then systemModStamp.
    // Account Ownership is based on sales territory only
    List<ObjectTerritory2Association> objAssociationList = objAssociationSelector.selectByObjectIdAndSalesTerritory(
      accountIds
    );

    Map<Id, ObjectTerritory2Association> accountIdObjectAssociationMap = new Map<Id, ObjectTerritory2Association>();

    for (ObjectTerritory2Association objAssociation : objAssociationList) {
      if (accountIdObjectAssociationMap.containsKey(objAssociation.ObjectId)) {
        ObjectTerritory2Association existingObjAssociation = accountIdObjectAssociationMap.get(objAssociation.ObjectId);

        // If objAssociation SystemModStamp is greater than existingObjAssociation that means its the new association.
        if (objAssociation.SystemModStamp > existingObjAssociation.SystemModStamp) {
          accountIdObjectAssociationMap.put(objAssociation.ObjectId, objAssociation);
          accountIdTerritoryMap.put(objAssociation.ObjectId, objAssociation.Territory2);
        }
      } else {
        accountIdObjectAssociationMap.put(objAssociation.ObjectId, objAssociation);
        accountIdTerritoryMap.put(objAssociation.ObjectId, objAssociation.Territory2);
      }
    }
    return accountIdTerritoryMap;
  }

  // This method return all account territories of any type
  public Map<Id, List<Territory2>> getAccountTerritories(Set<Id> accountIds) {
    Map<Id, List<Territory2>> accountTerritoryMap = new Map<Id, List<Territory2>>();
    ObjectTerritory2AssociationsSelector_ET objAssociationSelector = (ObjectTerritory2AssociationsSelector_ET) Application_ET.Selector.newInstance(
      ObjectTerritory2Association.getSObjectType()
    );
    for (ObjectTerritory2Association accountObjAssociation : objAssociationSelector.selectByObjectId(accountIds)) {
      accountTerritoryIds.add(accountObjAssociation.Territory2Id);
      if (accountTerritoryMap.containsKey(accountObjAssociation.ObjectId)) {
        accountTerritoryMap.get(accountObjAssociation.ObjectId).add(accountObjAssociation.Territory2);
      } else {
        accountTerritoryMap.put(
          accountObjAssociation.ObjectId,
          new List<Territory2>{ accountObjAssociation.Territory2 }
        );
      }
    }
    return accountTerritoryMap;
  }

  public Map<Id, List<Territory2>> getAccountSalesTerritories(Set<Id> accountIds) {
    Map<Id, List<Territory2>> accountTerritoryMap = new Map<Id, List<Territory2>>();
    ObjectTerritory2AssociationsSelector_ET objAssociationSelector = (ObjectTerritory2AssociationsSelector_ET) Application_ET.Selector.newInstance(
      ObjectTerritory2Association.getSObjectType()
    );
    for (
      ObjectTerritory2Association accountObjAssociation : objAssociationSelector.selectByObjectIdAndSalesTerritory(
        accountIds
      )
    ) {
      accountSalesTerritoryMap.put(accountObjAssociation.Territory2Id, accountObjAssociation.Territory2);
      if (accountTerritoryMap.containsKey(accountObjAssociation.ObjectId)) {
        accountTerritoryMap.get(accountObjAssociation.ObjectId).add(accountObjAssociation.Territory2);
      } else {
        accountTerritoryMap.put(
          accountObjAssociation.ObjectId,
          new List<Territory2>{ accountObjAssociation.Territory2 }
        );
      }
    }
    return accountTerritoryMap;
  }

  // this method returns primary associated territory based on territory assignment rule
  public Map<Id, Territory2> getAccountPrimarySalesTerritory(Set<Id> accountIds) {
    Map<Id, Territory2> accountTerritoryMap = new Map<Id, Territory2>();
    ObjectTerritory2AssociationsSelector_ET objAssociationSelector = (ObjectTerritory2AssociationsSelector_ET) Application_ET.Selector.newInstance(
      ObjectTerritory2Association.getSObjectType()
    );
    for (
      ObjectTerritory2Association accountObjAssociation : objAssociationSelector.selectByObjectIdAndSalesTerritory(
        accountIds
      )
    ) {
      if (
        (!accountTerritoryMap.containsKey(accountObjAssociation.ObjectId) &&
        accountObjAssociation.AssociationCause == ETMConstant.TERRITORY_ASSIGNMENT_RULE) || Test.isRunningTest()
      ) {
        accountTerritoryMap.put(accountObjAssociation.ObjectId, accountObjAssociation.Territory2);
      }
    }
    return accountTerritoryMap;
  }

  // This method return the valid territory.
  // If only one sales territory then return that else secondary territory
  public Map<Id, ObjectTerritory2Association> getValidAccountTerritory(Set<Id> accountIds) {
    Set<Id> setofTerritory2Ids = new Set<Id>();
    Set<String> interimRoles = UserTerritory2AssociationsService_ET.getInterimManagerRole();
    Map<Id, ObjectTerritory2Association> mapOfAccountIdToValidTerritory = new Map<Id, ObjectTerritory2Association>();
    Map<Id, List<UserTerritory2Association>> mapOfTerritory2IdToUserTerritories = new Map<Id, List<UserTerritory2Association>>();

    ObjectTerritory2AssociationsSelector_ET objAssociationSelector = (ObjectTerritory2AssociationsSelector_ET) Application_ET.Selector.newInstance(
      ObjectTerritory2Association.getSObjectType()
    );
    UserTerritory2AssociationsSelector_ET userAssociationSelector = (UserTerritory2AssociationsSelector_ET) Application_ET.Selector.newInstance(
      UserTerritory2Association.getSObjectType()
    );

    for (
      ObjectTerritory2Association objTerrAss : objAssociationSelector.selectByObjectIdAndSalesTerritory(accountIds)
    ) {
      setofTerritory2Ids.add(objTerrAss.Territory2Id);
    }

    for (
      UserTerritory2Association userTerrAss : userAssociationSelector.selectByTerritoryIdsAndDescRoles(
        setOfTerritory2Ids
      )
    ) {
      if (!mapOfTerritory2IdToUserTerritories.containsKey(userTerrAss.Territory2Id)) {
        mapOfTerritory2IdToUserTerritories.put(
          userTerrAss.Territory2Id,
          new List<UserTerritory2Association>{ userTerrAss }
        );
      } else {
        mapOfTerritory2IdToUserTerritories.get(userTerrAss.Territory2Id).add(userTerrAss);
      }
    }

    for (
      ObjectTerritory2Association objTerrAss : objAssociationSelector.selectByObjectIdAndSalesTerritory(accountIds)
    ) {
      if (mapOfTerritory2IdToUserTerritories.containsKey(objTerrAss.Territory2Id)) {
        for (UserTerritory2Association userTerrAss : mapOfTerritory2IdToUserTerritories.get(objTerrAss.Territory2Id)) {
          if (userTerrAss.RoleInTerritory2 == ETMConstant.PRIMARY_ACCOUNT_MANAGER) {
            if (!mapOfAccountIdToValidTerritory.containsKey(objTerrAss.ObjectId)) {
              mapOfAccountIdToValidTerritory.put(objTerrAss.ObjectId, objTerrAss);
            }
            break;
          }
          if (interimRoles.contains(userTerrAss.RoleInTerritory2)) {
            if (!mapOfAccountIdToValidTerritory.containsKey(objTerrAss.ObjectId)) {
              mapOfAccountIdToValidTerritory.put(objTerrAss.ObjectId, objTerrAss);
            }
            break;
          }
        }
      }
    }
    return mapOfAccountIdToValidTerritory;
  }

  public string generateUniqueKey(Account account) {
    String externalId;
    if (account.Billing_Postal_Code_Static__c != null && account.Billing_Country_Code_Static__c != null) {
      String billingPostalCode = account.Billing_Postal_Code_Static__c;
      if (account.Billing_Country_Code_Static__c == ETMConstant.COUNTRY_CODE_US) {
        if (StatesWithSpecialPostcodes.contains(account.Billing_State_Code_Static__c)) {
          billingPostalCode = account.Billing_Postal_Code_Static__c.split('-')
            .get(0)
            .replaceAll('[^a-zA-Z0-9\\s+]', '')
            .deleteWhitespace()
            .leftPad(5, '0');
        } else {
          billingPostalCode = account.Billing_Postal_Code_Static__c.replaceAll('[^a-zA-Z0-9\\s+]', '')
            .deleteWhitespace();
          billingPostalCode = billingPostalCode.length() > 5 ? billingPostalCode.substring(0, 5) : billingPostalCode;
        }
      }
      externalId = account.Billing_Country_Code_Static__c + '-' + billingPostalCode;
    }
    return externalId;
  }

  private static List<String> StatesWithSpecialPostcodes {
    get {
      if (StatesWithSpecialPostcodes == null) {
        ETM_Setting__mdt metadata = Utility_ET.getSetting('USA_States_With_Special_Postcodes');
        StatesWithSpecialPostcodes = metadata.Value__c.split(',');
      }
      return StatesWithSpecialPostcodes;
    }
    set;
  }
}