public class LeadTriggerAllHandler {
  public static boolean isFirstTime = true;
  public static boolean isFirstTimeInsertFunnel = true;
  public static boolean isFirstTimeUpdateFunnel = true;
  public static boolean isLeadAddedToOrchestrator = false;
  public static boolean isInsertedLeadAddedToOrchestrator = false;
  public static boolean skipLeadTriggerHandler = false;

  private static String LEAD_STATUS_RECYCLE = 'Recycle';
  private static String LEAD_STATUS_DISQUALIFIED = 'Disqualified';

  private static Id LEAD_RECORDTYPE_STANDARD = SObjectType.Lead.getRecordTypeInfosByDeveloperName()
    .get('Standard')
    .getRecordTypeId();

  /*
        Sebastiaan Verstraelen, Slalom Consulting
        Move status to New when Progressed_to_MQL is set
        This needs to happen on before insert trigger as it needs to be set
        before assignment rules fire
    */
  public static void moveLeadStatusToNew(List<Lead> newList) {
    Set<String> statusSetSPSRDD = new Set<String>{
      'Suspect',
      'Partner Suspect',
      'Recycle',
      'Declined',
      'Disqualified'
    };
    for (Lead lead : newList) {
      if (statusSetSPSRDD.contains(lead.Status) && lead.Progressed_to_MQL__c == true) {
        if (lead.RecordTypeId == LEAD_RECORDTYPE_STANDARD)
          lead.Status = 'MQL';
        else
          lead.Status = 'New';
      }
    }
  }

  public static void setDisableOwnerChange(List<Lead> leadList, Map<Id, Lead> oldMap) {
    Set<String> statusSetRDD = new Set<String>{ 'Recycle', 'Declined', 'Disqualified' };
    for (Lead l : leadList) {
      Lead oldLead = oldMap.get(l.Id);
      if (statusSetRDD.contains(l.Status) && l.Status != oldLead.Status) {
        l.Disable_Owner_Change__c = false;
        l.Progressed_to_MQL__c = false;
      }
    }
  }

  public static void setLeadOwnerOnStatusChange(List<Lead> leadList, Map<Id, Lead> oldMap) {
    for (Lead l : leadList) {
      Lead oldLead = oldMap.get(l.Id);
      if (
        l.Status != oldLead.Status &&
        ((l.Status == 'Sales Generated' && oldLead.Status == 'Suspect') ||
        (l.Status == 'Sales Generated' && (oldLead.Status == 'Disqualified' || oldLead.Status == 'Declined')))
      ) {
        l.OwnerId = UserInfo.getUserId();
      }
    }
  }

  public static void setOriginalMQLOwnerGroup(List<Lead> leadList, Map<Id, Lead> oldMap) {
    Map<Id, Lead> leadMap = new Map<Id, Lead>();
    for (Lead l : leadList) {
      Lead oldLead = oldMap.get(l.Id);
      if (l.Status != oldLead.Status && l.Status == 'MQL') {
        leadMap.put(l.Id, l);
      }
    }

    Map<Id, Lead> currentLeadsMap = new Map<Id, Lead>(
      [
        SELECT
          Id,
          OwnerId,
          Owner.ProfileId,
          Owner.Profile.Name,
          Owner.UserRoleId,
          Owner.UserRole.Name,
          Original_MQL_Owner_Group__c
        FROM Lead
        WHERE Id IN :leadMap.keySet()
      ]
    );
    if (currentLeadsMap.size() > 0) {
      for (Lead l : leadList) {
        Lead curentLead = currentLeadsMap.get(l.Id);
        if ((String.valueOf(curentLead.OwnerId)).substring(0, 3) == '00G') {
          l.Original_MQL_Owner_Group__c = 'Queue';
        } else {
          if (curentLead.Owner.Profile.Name == 'Lead Development' && curentLead.Owner.UserRole.Name != 'Operations') {
            l.Original_MQL_Owner_Group__c = 'BDR';
          } else {
            if (
              (curentLead.Owner.Profile.Name == 'Sales Representative CPQ' ||
              curentLead.Owner.Profile.Name == 'Sales Manager CPQ') && curentLead.Owner.UserRole.Name != 'Operations'
            ) {
              l.Original_MQL_Owner_Group__c = 'Sales';
            } else {
              l.Original_MQL_Owner_Group__c = 'Other';
            }
          }
        }
      }
    }
  }

  //Henry Cohen, Slalom Consulting
  //fire assignment rules manually
  public static void fireAssignmentRules(List<Lead> newList) {
    if (!isFirstTIme)
      return;

    List<Lead> leadsToUpdate = new List<Lead>();
    for (Lead l : newList) {
      if (l.Trigger_Assignment__c && !((String) l.OwnerId).startsWith('005') && l.Disable_Owner_Change__c == false) {
        Lead leadToUpdate = new Lead(Id = l.Id, Trigger_Assignment__c = false);
        Database.DMLOptions dmo = new Database.DMLOptions();
        dmo.assignmentRuleHeader.useDefaultRule = true;
        leadToUpdate.setOptions(dmo);
        leadsToUpdate.add(leadToUpdate);
      }
    }

    if (!leadsToUpdate.isEmpty()) {
      update leadsToUpdate;
    }
  }

  public static void fireAssignmentRulesOnInsert(List<Lead> newList) {
    User integrationUser = [
      SELECT Id
      FROM User
      WHERE Name = 'Marketo Integration' OR Name = 'Integration Marketo'
      LIMIT 1
    ];
    List<Lead> leadsToUpdate = new List<Lead>();
    for (Lead l : newList) {
      if (l.Trigger_Assignment__c && l.CreatedById == integrationUser.Id) {
        Lead leadToUpdate = new Lead(Id = l.Id, Trigger_Assignment__c = false);
        Database.DMLOptions dmo = new Database.DMLOptions();
        dmo.assignmentRuleHeader.useDefaultRule = true;
        leadToUpdate.setOptions(dmo);
        leadsToUpdate.add(leadToUpdate);
      }
    }

    if (!leadsToUpdate.isEmpty()) {
      //LeadTriggerAllHandler.isFirstTime = false;
      update leadsToUpdate;
    }
  }

  public static void setCurrencyToEURO(List<Lead> leadList) {
    for (Lead l : leadList) {
      if (l.Region_Text__c == 'Southern Europe') {
        l.CurrencyIsoCode = 'EUR';
      }
    }
  }

  public static void setManuallyProgressed(List<Lead> leadList, Map<Id, Lead> oldMap) {
    for (Lead l : leadList) {
      Lead oldLead = oldMap.get(l.Id);
      if (l.Status == 'Sales Generated' && oldLead.Status == 'Suspect') {
        l.ManuallyProgressed__c = true;
      }
    }
  }

  public static void resetStatusWhenGettingTierValue(List<Lead> newList, Map<Id, Lead> oldMap) {
    Set<String> statusSet = new Set<String>{ 'Recycle', 'Declined', 'Disqualified' };
    User integrationUser = [
      SELECT Id
      FROM User
      WHERE Name = 'Marketo Integration' OR Name = 'Integration Marketo'
      LIMIT 1
    ];
    if (UserInfo.getUserId() == integrationUser.Id) {
      for (Lead newL : newList) {
        Lead oldL = oldMap.get(newL.Id);
        if (
          newL.Progressed_to_MQL__c == true &&
          newL.Progressed_to_MQL__c != oldL.Progressed_to_MQL__c &&
          statusSet.contains(newL.Status)
        ) {
          if (newL.RecordTypeId == LEAD_RECORDTYPE_STANDARD)
            newL.Status = 'MQL';
          else
            newL.Status = 'New';
          newL.Trigger_Assignment__c = true;
        }
      }
    }
  }

  public static void fireAssignmentRulesOnUpdate(List<Lead> newList, Map<Id, Lead> oldMap) {
    if (!LeadTriggerAllHandler.isFirstTime)
      return;
    Set<String> statusSet = new Set<String>{ 'Recycle', 'Declined', 'Disqualified', 'Suspect' };
    User integrationUser = [
      SELECT Id
      FROM User
      WHERE Name = 'Marketo Integration' OR Name = 'Integration Marketo'
      LIMIT 1
    ];
    List<Lead> leadsToUpdate = new List<Lead>();
    for (Lead l : newList) {
      if (l.Disable_Owner_Change__c == false) {
        Lead oldL = oldMap.get(l.Id);
        boolean runAssignmentRule = false;

        if (UserInfo.getUserId() == integrationUser.Id && !((String) l.OwnerId).startsWith('005')) {
          runAssignmentRule = true;
        } else if (
          (l.Status != oldL.Status || l.Stripe_Customer_Id__c != oldL.Stripe_Customer_Id__c) &&
          ((l.Account__c == null && (l.Status == 'MQL' || l.Status == 'New')) || statusSet.contains(l.Status))
        ) {
          runAssignmentRule = true;
        }

        if (runAssignmentRule) {
          Lead leadToUpdate = new Lead(Id = l.Id, Trigger_Assignment__c = false);
          Database.DMLOptions dmo = new Database.DMLOptions();
          dmo.assignmentRuleHeader.useDefaultRule = true;
          leadToUpdate.setOptions(dmo);
          leadsToUpdate.add(leadToUpdate);
        }
      }
    }

    if (!leadsToUpdate.isEmpty()) {
      LeadTriggerAllHandler.isFirstTime = false;
      update leadsToUpdate;
    }
  }

  private static Database.LeadConvert getLeadConvertInstance(Id leadId, Id accountId, String leadConvertStatus) {
    Database.LeadConvert lc = new database.LeadConvert();
    lc.setLeadId(leadId);
    lc.setAccountId(accountId);
    lc.setDoNotCreateOpportunity(true);
    lc.setConvertedStatus(leadConvertStatus);
    return lc;
  }
  // ===================================================================================
  // 1/10/2020 -  Converts Lead to an Existing account
  // Converts Lead to an Existing account when the lead is updated has an matching Account and status is changed to "New"
  // or has an account based on existing contact - (lead and contact are matched by email)

  public static void autoConvertLeadToExistingAcc(List<Lead> leadList, Map<Id, Lead> oldMap) {
    Set<String> EmailSet = new Set<String>();
    for (Lead l : leadList) {
      if (l.Email != null && l.Account__c != null)
        EmailSet.add(l.Email);
    }
    List<Contact> relatedContacts = [SELECT Id, Email, AccountId FROM Contact WHERE Email IN :EmailSet];
    Map<String, Id> contactMap = new Map<String, Id>();
    Set<String> contactEmailSet = new Set<String>();
    for (Contact cnt : relatedContacts) {
      contactMap.put(String.valueOf(cnt.AccountId) + '-' + cnt.Email, cnt.Id);
      contactEmailSet.add(cnt.Email);
    }

    List<LeadStatus> convertStatus = [
      SELECT Id, MasterLabel
      FROM LeadStatus
      WHERE IsConverted = TRUE AND (MasterLabel = 'Partner Contact' OR MasterLabel = 'Qualified')
      ORDER BY MasterLabel ASC
    ];
    Id BusinessPartner = SObjectType.Lead.getRecordTypeInfosByDeveloperName()
      .get('Business_Partner_Onboarding')
      .getRecordTypeId();
    List<Database.LeadConvert> leadConvertList = new List<Database.LeadConvert>();
    for (Lead l : leadList) {
      if (!String.isEmpty(l.Stripe_Customer_ID__c) && l.IsConverted == false) {
        Database.LeadConvert lc = new database.LeadConvert();
        lc.setLeadId(l.id);
        if (l.RecordTypeId == BusinessPartner)
          lc.setConvertedStatus(convertStatus[0].MasterLabel);
        else
          lc.setConvertedStatus(convertStatus[1].MasterLabel);

        if (l.Account__c != null) {
          lc.setAccountId(l.Account__c); //converting  into existing account
        }
        lc.setDoNotCreateOpportunity(true); //mention weather to create a opportunity or not
        leadConvertList.add(lc);
      } else {
        if (
          ((!contactEmailSet.contains(l.Email) ||
          contactMap.containsKey(String.valueOf(l.Account__c) + '-' + l.Email)) &&
          ((String) l.OwnerId).startsWith('005') &&
          l.RecordTypeId == BusinessPartner &&
          l.Account_Record_Type__c == 'Partner' &&
          l.Account__c != null &&
          l.IsConverted == false &&
          l.Status != 'Suspect' &&
          l.Status != 'Partner Suspect' &&
          l.Area__c != 'Japan') || (!String.isEmpty(l.Duplicate_Contact__c) && l.IsConverted == false)
        ) {
          Database.LeadConvert lc = new database.LeadConvert();
          lc.setLeadId(l.id);
          lc.setAccountId(l.Account__c); //converting  into existing account
          if (contactMap.containsKey(String.valueOf(l.Account__c) + '-' + l.Email)) {
            Id cntId = contactMap.get(String.valueOf(l.Account__c) + '-' + l.Email);
            lc.setContactId(cntId); //converting  into existing contact
          }
          lc.setDoNotCreateOpportunity(true); //mention weather to create a opportunity or not
          if (l.RecordTypeId == BusinessPartner)
            lc.setConvertedStatus(convertStatus[0].MasterLabel);
          else
            lc.setConvertedStatus(convertStatus[1].MasterLabel);
          leadConvertList.add(lc);
        }
      }
    }

    if (!leadConvertList.isEmpty()) {
      for (Integer i = 0; i <= leadConvertList.size() / 100; i++) {
        list<Database.LeadConvert> tempList = new List<Database.LeadConvert>();
        Integer startIndex = i * 100;
        Integer endIndex = ((startIndex + 100) < leadConvertList.size()) ? startIndex + 100 : leadConvertList.size();
        for (Integer j = startIndex; j < endIndex; j++) {
          tempList.add(leadConvertList[j]);
        }
        Database.LeadConvertResult[] lcrList = Database.convertLead(tempList, false);

        for (Database.LeadConvertResult lcr : lcrList) {
          if (!lcr.isSuccess()) {
            String errorMessage = '';
            for (Database.Error err : lcr.getErrors()) {
              errorMessage += err.getMessage();
            }
            System.debug('Conversion Error Message =====> ' + errorMessage);
          }
        }
      }
    }
  }

  //Henry Cohen, Slalom Consulting
  //calculate the duration in business hours of how long the lead was in working status
  public static void setWorkingDuration(List<Lead> newList, Map<Id, Lead> oldMap) {
    string userTimezone = UserInfo.getTimeZone().getID();
    List<BusinessHours> bhList = [
      SELECT Id
      FROM BusinessHours
      WHERE IsActive = TRUE AND TimeZoneSidKey = :userTimezone
    ];
    if (bhList.size() == 0)
      return;
    BusinessHours bh = bhList[0];

    for (Lead l : newList) {
      DateTime oldWorkingDate = oldMap.get(l.Id).Working_Date_Time__c;
      DateTime oldOtherDate = oldMap.get(l.Id).Working_To_Other_Status_Date_Time__c;

      if (l.Working_To_Other_Status_Date_Time__c != oldOtherDate && l.Working_To_Other_Status_Date_Time__c != null) {
        decimal result = BusinessHours.diff(bh.Id, l.Working_Date_Time__c, l.Working_To_Other_Status_Date_Time__c);
        decimal hours = result / 3600000;
        l.Lead_Working_Duration_Business_Hours__c = hours;
      } else if (l.Working_To_Other_Status_Date_Time__c == null) {
        l.Lead_Working_Duration_Business_Hours__c = null;
      }

      if (l.New_Date_Time__c != null && l.Working_Date_Time__c != oldWorkingDate && l.Working_Date_Time__c != null) {
        decimal result = BusinessHours.diff(bh.Id, l.New_Date_Time__c, l.Working_Date_Time__c);
        decimal hours = result / 3600000;
        l.Lead_New_To_Working_Duration_Hours__c = hours;
      } else if (l.Working_Date_Time__c == null) {
        l.Lead_New_To_Working_Duration_Hours__c = null;
      }
    }
  }

  // ===================================================================================
  // Mirela Chituc - 9/27/2019 -  Set up date when Status is changing
  // Used with a formula field to show how many days a field is in a certain status

  public static void setLastStatusChangeDate(List<Lead> leadList, Map<Id, Lead> oldMap) {
    for (Lead l : leadList) {
      if (oldMap == null) {
        l.Last_Change_Status_Date__c = Date.today();
      } else {
        if (l.Status == 'New' && l.New_Date_Time__c == null)
          l.New_Date_Time__c = DateTime.Now();
        if (l.Status == 'MQL' && l.MQL_Date_Time__c == null)
          l.MQL_Date_Time__c = DateTime.Now();
        if (l.Status == 'Sales Generated' && l.Sales_Generated_Date_Time__c == null)
          l.Sales_Generated_Date_Time__c = DateTime.Now();
        Lead oldLead = oldMap.get(l.Id);
        if (l.Status != oldLead.Status) {
          l.Last_Change_Status_Date__c = Date.today();

          if (l.Status == 'New')
            l.New_Date_Time__c = DateTime.Now();
          if (l.Status == 'Working') {
            l.Working_Date_Time__c = DateTime.Now();
            if (l.New_Date_Time__c == null)
              l.New_Date_Time__c = l.Working_Date_Time__c;
          }
          if (l.Status == 'Recycle')
            l.Recycle_Date_Time__c = DateTime.Now();

          if (l.Status == 'MQL')
            l.MQL_Date_Time__c = DateTime.Now();
          if (l.Status == 'Sales Generated')
            l.Sales_Generated_Date_Time__c = DateTime.Now();
          if (l.Status == 'Accepted')
            l.Accepted_Date_Time__c = DateTime.Now();
          if (l.Status == 'Declined')
            l.Declined_Date_Time__c = DateTime.Now();

          if (l.Status == 'Disqualified')
            l.Disqualified_Date_Time__c = DateTime.Now();
          if (l.Status == 'Qualified') {
            l.Qualified_Date_Time__c = DateTime.Now();
            if (l.Working_Date_Time__c == null && l.RecordTypeId != LEAD_RECORDTYPE_STANDARD)
              l.Working_Date_Time__c = DateTime.Now();
          }
        }
      }
    }
  }

  // ===================================================================================
  // 9/17/2019 -  Domain / Country Account Matching
  // Look for an existing account using the Lead DUNS_Number, Website/Email Domain/s, Country
  // updated 8/26/2020

  public static void setExistingAccount(List<Lead> leadList, Map<Id, Lead> oldMap) {
    Set<String> emailexceptions = getAccountDomainExceptions();
    Set<String> DUNSNumbers = new Set<String>();
    Set<String> domains = new Set<String>();
    Set<String> emaildomains = new Set<String>();
    Set<String> companyName = new Set<String>();
    List<Lead> leadsToBeProcess = new List<Lead>();
    // Go through all the leads to populate domains lists
    for (Lead lead : leadList) {
      Lead oldLead = new Lead();
      if (oldMap != null)
        oldLead = oldMap.get(lead.Id);

      if (
        (lead.Account__c == null ||
        lead.Country != oldLead.Country ||
        lead.Website != oldLead.Website ||
        lead.Disable_Owner_Change__c != oldLead.Disable_Owner_Change__c ||
        lead.DNBoptimizer__DNB_D_U_N_S_Number__c != oldLead.DNBoptimizer__DNB_D_U_N_S_Number__c ||
        lead.Email != oldLead.Email ||
        lead.Public_email__c != oldLead.Public_email__c ||
        lead.Company != oldLead.Company ||
        (lead.Status != oldLead.Status && (lead.Status == 'New' || lead.Status == 'MQL'))) &&
        !string.isEmpty(lead.CountryCode) &&
        lead.Overwrite_Account_Match__c == false
      ) {
        String webDomain = getWebDomain(lead.Website);
        String shortWebDomain = (webDomain).contains('/') ? webDomain.substring(0, webDomain.indexOf('/')) : '';
        if (!String.isEmpty(webDomain)) {
          domains.add('%' + webDomain + '%');
          if (!String.isEmpty(shortWebDomain))
            domains.add('%' + shortWebDomain + '%');
        }

        if (!String.isEmpty(lead.DNBoptimizer__DNB_D_U_N_S_Number__c))
          DUNSNumbers.add(lead.DNBoptimizer__DNB_D_U_N_S_Number__c);

        if (lead.Public_email__c == false) {
          String emailDomain = getEmailDomain(lead.Email);
          if (!String.isEmpty(emailDomain) && !emailexceptions.contains(emailDomain))
            emaildomains.add('%' + emailDomain + '%');
        } else {
          if (!String.isEmpty(lead.Company))
            companyName.add(lead.Company);
        }
        leadsToBeProcess.add(lead);
      }
    }

    // run the matching Account code only if we have values
    if (leadsToBeProcess.size() > 0) {
      List<Account> matchingAccountNames = [
        SELECT
          Id,
          Name,
          Website,
          Email_Domain__c,
          DNBoptimizer__DNB_D_U_N_S_Number__c,
          BillingCountry,
          BillingCountryCode,
          OwnerId,
          EDR__c,
          Owner.UserRole.Name,
          Geo__c,
          Area__c,
          Territory__c,
          Region__c,
          RecordTypeId,
          RecordType.Name,
          Classification__c
        FROM Account
        WHERE
          Owner.IsActive = TRUE
          AND (DNBoptimizer__DNB_D_U_N_S_Number__c IN :DUNSNumbers
          OR Website LIKE :domains
          OR Email_Domain__c LIKE :emaildomains
          OR Name IN :companyName)
      ];
      Id BusinessPartner = SObjectType.Lead.getRecordTypeInfosByDeveloperName()
        .get('Business_Partner_Onboarding')
        .getRecordTypeId();
      // Go through all the accounts and populate three maps with company, domain and companyname***domain as keys
      // and corresponding account as a value

      // Daniel Edwards (Slalom)
      // Collect the Ids of the Account records returned from the query so that
      // they can be used to retrieve related Territory2 information
      Set<Id> accountIds = new Set<Id>();

      Map<String, List<Account>> domainAccMap = new Map<String, List<Account>>();
      for (Account acc : matchingAccountNames) {
        accountIds.add(acc.Id);
        // populate map: Map key - AccountDomanin***AcountBillingCountry
        String accDomain = getWebDomain(acc.Website);
        String shortAccDomain = (accDomain).contains('/') ? accDomain.substring(0, accDomain.indexOf('/')) : '';
        String dunsNumber = acc.DNBoptimizer__DNB_D_U_N_S_Number__c; /*+ '-' + acc.BillingCountryCode;*/
        String company = acc.Name + '-' + acc.BillingCountryCode;

        domainAccMap = populateDomainAccountMap(
          company,
          dunsNumber,
          accDomain,
          shortAccDomain,
          acc.Email_Domain__c,
          acc,
          domainAccMap
        );
      }

      // Return related Territory info from the collected Ids from the Account__c field
      Type accTerritoryTypeInstance = Type.forName('AccountsService_ET');
      IAccountTerritory accountTerritoryService = (IAccountTerritory) accTerritoryTypeInstance.newInstance();
      Map<Id, Territory2> account_RelatedTerritories = accountTerritoryService.getAccountPrimarySalesTerritory(
        accountIds
      );
      Set<Id> territoryIds = new Set<Id>();
      for (Territory2 tr : account_RelatedTerritories.values())
        territoryIds.add(tr.Id);

      List<String> territoryRolesForOwnership = new List<String>{
        'Enterprise Development Rep',
        'Sales Development Rep'
      };

      Map<Id, Id> territoryId_userId = new Map<Id, Id>();
      if (!territoryIds.isEmpty())
        for (UserTerritory2Association recordContext : [
          SELECT Id, Territory2Id, UserId
          FROM UserTerritory2Association
          WHERE Territory2Id IN :territoryIds AND RoleInTerritory2 IN :territoryRolesForOwnership
        ])
          if (!territoryId_userId.containsKey(recordContext.Territory2Id))
            territoryId_userId.put(recordContext.Territory2Id, recordContext.UserId);

      // Go through all the leads and find the match
      for (Lead lead : leadsToBeProcess) {
        //    In case of an update, we will force the assignment rules to run if the lead moves from Suspect to New
        //    We run the assignment rules by setting Trigger_Assignment__c to true, this is used by fireAssignmentRules()
        //    In case of inserts, whether the assignment rules run depends on the source of lead and if
        //    they user / source system indicated that lead assignment should run.
        if (lead.Overwrite_Account_Match__c == false) {
          if (oldMap != null) {
            lead.Trigger_Assignment__c = false;
            Lead oldLead = oldMap.get(lead.Id);
            if (oldLead.Status == 'Suspect' && (lead.Status == 'New' || lead.Status == 'MQL')) {
              lead.Trigger_Assignment__c = true;
            } else if ((lead.Status == 'New' || lead.Status == 'MQL') && oldLead.Territory__c != lead.Territory__c) {
              lead.Trigger_Assignment__c = true;
            }
          }

          String currentLeadDomain = getWebDomain(lead.Website);
          String shortCurrentLeadDomain = (currentLeadDomain).contains('/')
            ? currentLeadDomain.substring(0, currentLeadDomain.indexOf('/'))
            : '';
          String currentEmailDomain = getEmailDomain(lead.Email);
          String dunsNumber = lead.DNBoptimizer__DNB_D_U_N_S_Number__c; /* + '-' + lead.CountryCode;*/
          String companyNameLead = lead.Company + '-' + lead.CountryCode;
          List<Account> currentAccounts = new List<Account>();
          // filter accounts by duns, website, company name / email domain
          currentAccounts = getAllLeadMatchedAccounts(
            lead.Public_Email__c,
            companyNameLead,
            dunsNumber,
            currentLeadDomain,
            shortCurrentLeadDomain,
            currentEmailDomain,
            domainAccMap
          );

          // Match lead with an existing account
          Boolean foundMatch = false;

          if (currentAccounts.size() > 0) {
            for (Account ca : currentAccounts) {
              // if DUNS number is a match being unique we don't need a country match for it
              // if the match is made with the website, company name or email domain we filter the accounts by country code
              if (ca.BillingCountryCode == lead.CountryCode) {
                lead.Account__c = ca.Id;

                if (account_RelatedTerritories.containsKey(lead.Account__c)) {
                  Territory2 accountTerritory = account_RelatedTerritories.get(lead.Account__c);
                  // Assign territory info
                  lead.Territory_Id__c = accountTerritory.Id;
                  lead.Territory_Name__c = accountTerritory.Name;
                  lead.Geo__c = accountTerritory.Ultimate_Geo__c;
                  lead.Area__c = accountTerritory.Area__c;
                  lead.Region_Text__c = accountTerritory.Region__c;
                }

                if (
                  new List<String>{ 'New', 'MQL' }.contains(lead.Status) &&
                  !lead.Exclude_from_account_owner_assignment__c &&
                  lead.Disable_Owner_Change__c == false
                ) {
                  // Assign new Lead Owner
                  if (territoryId_userId.containsKey(lead.Territory_Id__c)) {
                    lead.OwnerId = territoryId_userId.get(lead.Territory_Id__c);
                  } else if (account_RelatedTerritories.containsKey(lead.Account__c)) {
                    Territory2 territory = account_RelatedTerritories.get(lead.Account__c);
                    if (territory.Primary_Account_Manager_Id__c != null) {
                      lead.OwnerId = territory.Primary_Account_Manager_Id__c;
                    } else if (territory.Interim_Account_Manager_Id__c != null) {
                      lead.OwnerId = territory.Interim_Account_Manager_Id__c;
                    }
                  }

                  if (ca.EDR__c != null)
                    lead.OwnerId = ca.EDR__c;
                  else {
                    if (ca.Owner.UserRole.Name != 'Operations')
                      lead.OwnerId = ca.OwnerId;
                  }
                  lead.Trigger_Assignment__c = false;
                }

                lead.Account_Record_Type__c = ca.RecordType.Name;
                if (ca.RecordType.Name == 'Partner')
                  lead.RecordTypeId = BusinessPartner;
                /*if(lead.Status == 'New' && !lead.Exclude_from_account_owner_assignment__c && lead.Disable_Owner_Change__c == false)  {
                                    System.debug('Lead Status is:' + lead.Status);
                                    System.debug('Lead Exclude from acc owner ass is: ' + lead.Exclude_from_account_owner_assignment__c);
                                    System.debug('lead.Disable_Owner_Change__c is: ' + lead.Disable_Owner_Change__c);
                                    System.debug('ca.EDR__c is: ' + ca.EDR__c);
                                    if(ca.EDR__c != null)
                                        lead.OwnerId = ca.EDR__c;
                                    else
                                        lead.OwnerId = ca.OwnerId
                                    lead.Trigger_Assignment__c = false;
                                }
                                */
                foundMatch = true;
                break;
              }
            }
          }
          System.debug('foundMatch   =====>' + foundMatch);
          // If not a match found reset matching fields
          System.debug('foundMatch   =====>' + lead.CountryCode);
          if ((!foundMatch || String.isEmpty(lead.CountryCode)) && lead.Ignore_Territory_Assignment__c == false) {
            lead.Account__c = null;
            lead.Account_Record_Type__c = null;
            lead.Geo__c = null;
            lead.Area__c = null;
            lead.Territory__c = null;
            lead.Region_Text__c = null;
          }
        }
      }
    }
  }

  private static Map<String, List<Account>> populateDomainAccountMap(
    String Company_Name,
    String DUNS_Number,
    String accDomain,
    String shortAccDomain,
    String emailDomain,
    Account acc,
    Map<String, List<Account>> domainAccMap
  ) {
    if (!String.isEmpty(DUNS_Number) && DUNS_Number.substring(0, 4) != 'null') {
      domainAccMap = populateAccountMap(DUNS_Number, acc, domainAccMap);
    }

    if (!String.isEmpty(Company_Name) && Company_Name.substring(0, 4) != 'null') {
      domainAccMap = populateAccountMap(Company_Name, acc, domainAccMap);
    }

    if (!String.isEmpty(accDomain))
      domainAccMap = populateAccountMap(accDomain, acc, domainAccMap);

    if (!String.isEmpty(shortAccDomain) && shortAccDomain != accDomain)
      domainAccMap = populateAccountMap(shortAccDomain, acc, domainAccMap);

    if (!String.isEmpty(emailDomain) && emailDomain != accDomain && emailDomain != shortAccDomain)
      domainAccMap = populateAccountMap(emailDomain, acc, domainAccMap);

    return domainAccMap;
  }

  private static List<Account> getAllLeadMatchedAccounts(
    Boolean publicEmail,
    String Company_Name,
    String DUNS_Number,
    String fullDomain,
    String shortDomain,
    String emailDomain,
    Map<String, List<Account>> domainAccMap
  ) {
    List<Account> currentAccounts = new List<Account>();
    // filter accounts by unique DUNS number
    if (!string.isEmpty(DUNS_Number) && domainAccMap.containsKey(DUNS_Number))
      currentAccounts = domainAccMap.get(DUNS_Number);
    else {
      // filter accounts by website
      if (!string.isEmpty(fullDomain) && domainAccMap.containsKey(fullDomain))
        currentAccounts.addAll(domainAccMap.get(fullDomain));
      if (!string.isEmpty(shortDomain) && domainAccMap.containsKey(shortDomain))
        currentAccounts.addAll(domainAccMap.get(shortDomain));
      // if we don't have results for website match filter by company name or email domain
      if (currentAccounts.size() == 0) {
        if (publicEmail == true) {
          // if Public_Email__c = true filter accounts by company name
          if (Company_Name != null && domainAccMap.containsKey(Company_Name))
            currentAccounts = domainAccMap.get(Company_Name);
        } else {
          // if Public_Email__c = false filter accounts by email domain
          if (!string.isEmpty(emailDomain) && domainAccMap.containsKey(emailDomain))
            currentAccounts = domainAccMap.get(emailDomain);
        }
      }
    }
    return currentAccounts;
  }

  private static Set<String> getAccountDomainExceptions() {
    List<Account_Email_Domain_Exceptions__mdt> domainExceptions = [
      SELECT Excluded_Email_Domain__c
      FROM Account_Email_Domain_Exceptions__mdt
      WHERE Active__c = TRUE
    ];

    Set<String> emailexceptions = new Set<String>{};
    for (Account_Email_Domain_Exceptions__mdt dom : domainExceptions) {
      emailexceptions.add(dom.Excluded_Email_Domain__c);
    }
    return emailexceptions;
  }

  private static String getWebDomain(String leadWebDomain) {
    String webDomain = '';
    if (!string.isEmpty(leadWebDomain)) {
      if ((leadWebDomain).contains('://'))
        webDomain = (leadWebDomain).substring((leadWebDomain).indexOf('://') + 3, (leadWebDomain).length());
      else
        webDomain = leadWebDomain;

      if ((webDomain).contains('www.'))
        webDomain = webDomain.substring(webDomain.indexOf('.') + 1, webDomain.length());
    }
    return webDomain;
  }

  private static String getEmailDomain(String leadEmailDomain) {
    String emailDomain = '';
    if (!string.isEmpty(leadEmailDomain) && (leadEmailDomain).contains('@')) {
      emailDomain = (leadEmailDomain).substring((leadEmailDomain).indexOf('@') + 1, (leadEmailDomain).length());
    }
    return emailDomain;
  }

  private static Map<String, List<Account>> populateAccountMap(
    String domain,
    Account currentAccount,
    Map<String, List<Account>> currentDomainsMap
  ) {
    if (!currentDomainsMap.containsKey(domain)) {
      List<Account> newAccList = new List<Account>();
      newAccList.add(currentAccount);
      currentDomainsMap.put(domain, newAccList);
    } else {
      List<Account> exAccList = currentDomainsMap.get(domain);
      exAccList.add(currentAccount);
      currentDomainsMap.put(domain, exAccList);
    }

    return currentDomainsMap;
  }

  // End DUNS_Number / Domain / Country Lead Matching
  // ===================================================================================

  public static void setRegion(List<Lead> leadList) {
    //Retrieve Country Codes
    Schema.DescribeFieldResult countryCodeResult = User.Countrycode.getDescribe();
    List<Schema.PicklistEntry> countryPLE = countryCodeResult.getPicklistValues();
    Map<String, String> countryAndCodeMap = new Map<String, String>();
    for (Schema.PicklistEntry entry : countryPLE) {
      countryAndCodeMap.put(entry.getLabel(), entry.getValue());
    }

    //Retrieve State Codes
    Schema.DescribeFieldResult stateCodeResult = User.StateCode.getDescribe();
    List<Schema.PicklistEntry> statePLE = stateCodeResult.getPicklistValues();
    Map<String, String> stateAndCodeMap = new Map<String, String>();
    for (Schema.PicklistEntry entry : statePLE) {
      stateAndCodeMap.put(entry.getLabel(), entry.getValue());
    }

    //generate maps of metadata
    list<USA_Industry__mdt> uimList = [SELECT Region__c, Industry__c, Area__c, Territory__c FROM USA_Industry__mdt];
    map<string, USA_Industry__mdt> uimMap = new Map<string, USA_Industry__mdt>();

    for (USA_Industry__mdt uimTmp : uimList) {
      uimMap.put(uimTmp.Industry__c, uimTmp);
    }

    list<USA_States__mdt> usmList = [
      SELECT Label, DeveloperName, Region__c, Billing_State_Code__c, US_State__c, Area__c, Territory__c, Country__c
      FROM USA_States__mdt
    ];
    map<string, USA_States__mdt> usmMap = new Map<string, USA_States__mdt>();

    for (USA_States__mdt usmTmp : usmList) {
      usmMap.put(usmTmp.Billing_State_Code__c + '-' + usmTmp.Country__c, usmTmp);
    }

    list<String> zipCodeList = new List<String>();

    for (Lead leadTmp : leadList) {
      if (string.isNotBlank(leadTmp.PostalCode)) {
        zipCodeList.add(leadTmp.PostalCode);
      }
    }

    list<UsaZipCodes__mdt> uzmList = [
      SELECT Postal_Code__c, Region__c, Area__c, Territory__c
      FROM UsaZipCodes__mdt
      WHERE Postal_Code__c IN :zipCodeList
    ];
    map<string, UsaZipCodes__mdt> uzmMap = new Map<string, UsaZipCodes__mdt>();

    for (UsaZipCodes__mdt uzmTmp : uzmList) {
      uzmMap.put(uzmTmp.Postal_Code__c, uzmTmp);
    }

    list<ROW_Country__mdt> rcmList = [SELECT Country_Code__c, Region__c, Area__c, Territory__c FROM ROW_Country__mdt];
    map<string, ROW_Country__mdt> rcmMap = new Map<string, ROW_Country__mdt>();

    for (ROW_Country__mdt rcmTmp : rcmList) {
      rcmMap.put(rcmTmp.Country_Code__c, rcmTmp);
    }
    Set<Id> accIds = new Set<Id>();
    for (Lead leadTmp : leadList) {
      if (leadTmp.Account__c != null && !(String.valueOf(leadTmp.OwnerId).startsWith('005'))) {
        accIds.add(leadTmp.Account__c);
      }
    }

    Map<Id, Account> allAccounts = getAllAccounts(accIds);

    //set Lead fields
    for (Lead leadTmp : leadList) {
      // start - Set currency to EUR for CE countries
      Set<String> CECountryCodeToEUR = new Set<String>{ 'DE', 'AT', 'CHEF', 'CH' };
      if (CECountryCodeToEUR.contains(leadTmp.CountryCode)) {
        leadTmp.CurrencyIsoCode = 'EUR';
      }
      // end - Set currency to EUR for CE countries
      if (!leadTmp.Ignore_Territory_Assignment__c) {
        if (leadTmp.Account__c == null) {
          if (leadTmp.CountryCode == null && leadTmp.Country != null) {
            leadTmp.CountryCode = countryAndCodeMap.get(leadTmp.Country);
          }

          if (leadTmp.StateCode == null && leadTmp.State != null) {
            leadTmp.StateCode = stateAndCodeMap.get(leadTmp.State);
          }

          String stateKey = leadTmp.StateCode + '-' + leadTmp.CountryCode;
          if (leadTmp.CountryCode != null) {
            if (leadTmp.CountryCode == 'US') {
              if (uimMap.containsKey(leadTmp.Industry)) {
                leadTmp.Geo__c = uimMap.get(leadTmp.Industry).Region__c;
                leadTmp.Region_Text__c = uimMap.get(leadTmp.Industry).Territory__c;
                leadTmp.Territory__c = uimMap.get(leadTmp.Industry).Territory__c;
                leadTmp.Area__c = uimMap.get(leadTmp.Industry).Area__c;
              } else if (usmMap.containsKey(stateKey)) {
                leadTmp.Geo__c = usmMap.get(stateKey).Region__c;
                leadTmp.Region_Text__c = usmMap.get(stateKey).Territory__c;
                leadTmp.Territory__c = usmMap.get(stateKey).Territory__c;
                leadTmp.Area__c = usmMap.get(stateKey).Area__c;
              } else if (uzmMap.containsKey(leadTmp.PostalCode)) {
                leadTmp.Geo__c = uzmMap.get(leadTmp.PostalCode).Region__c;
                leadTmp.Region_Text__c = uzmMap.get(leadTmp.PostalCode).Territory__c;
                leadTmp.Territory__c = uzmMap.get(leadTmp.PostalCode).Territory__c;
                leadTmp.Area__c = uzmMap.get(leadTmp.PostalCode).Area__c;
              } else {
                leadTmp.Geo__c = 'AMER';
                leadTmp.Region_Text__c = 'Territory Unknown';
                leadTmp.Territory__c = 'Territory Unknown';
                leadTmp.Area__c = null;
              }
            } else {
              if (leadTmp.CountryCode == 'IN' || leadTmp.CountryCode == 'JP') {
                if (usmMap.containsKey(stateKey)) {
                  leadTmp.Geo__c = usmMap.get(stateKey).Region__c;
                  leadTmp.Region_Text__c = usmMap.get(stateKey).Territory__c;
                  leadTmp.Territory__c = usmMap.get(stateKey).Territory__c;
                  leadTmp.Area__c = usmMap.get(leadTmp.CountryCode).Area__c;
                } else {
                  leadTmp.Geo__c = rcmMap.get(leadTmp.CountryCode).Region__c;
                  leadTmp.Region_Text__c = 'Territory Unknown';
                  leadTmp.Territory__c = 'Territory Unknown';
                  leadTmp.Area__c = null;
                }
              } else {
                if (rcmMap.containsKey(leadTmp.CountryCode)) {
                  leadTmp.Geo__c = rcmMap.get(leadTmp.CountryCode).Region__c;
                  leadTmp.Region_Text__c = rcmMap.get(leadTmp.CountryCode).Territory__c;
                  leadTmp.Territory__c = rcmMap.get(leadTmp.CountryCode).Territory__c;
                  leadTmp.Area__c = rcmMap.get(leadTmp.CountryCode).Area__c;
                }
              }
            }
          }
        } else {
          if (!(String.valueOf(leadTmp.OwnerId).startsWith('005')) && allAccounts.containsKey(leadTmp.Account__c)) {
            leadTmp.Geo__c = allAccounts.get(leadTmp.Account__c).Geo__c;
            leadTmp.Region_Text__c = allAccounts.get(leadTmp.Account__c).Region__c;
            leadTmp.Territory__c = allAccounts.get(leadTmp.Account__c).Territory__c;
            leadTmp.Area__c = allAccounts.get(leadTmp.Account__c).Area__c;
          }
        }
        if (leadTmp.Area__c == 'Southern Europe') {
          leadTmp.CurrencyIsoCode = 'EUR';
        }
      }
    }
  }

  public static Map<Id, Account> getAllAccounts(Set<Id> aIds) {
    return new Map<Id, Account>([SELECT Id, Geo__c, Region__c, Territory__c, Area__c FROM Account WHERE Id IN :aIds]);
  }

  public static void onAfterInsert(List<Lead> newList) {
    if (!isInsertedLeadAddedToOrchestrator) {
      isInsertedLeadAddedToOrchestrator = true;
      LeadIntegrationService.publishNewLeadToOrchestrator(newList);
    }
  }

  public static void onAfterUpdate(List<Lead> newList, Map<Id, Lead> oldMAp) {
    if (!isLeadAddedToOrchestrator) {
      isLeadAddedToOrchestrator = true;
      LeadIntegrationService.publishLeadOwnerUpdatesToOrchestrator(newList, oldMap);
    }
  }

  public static void setTerritoryRelatedFields(List<Lead> leadList) {
    Set<Id> accIds = new Set<Id>();
    for (Lead l : leadList) {
      accIds.add(l.Account__c);
    }
    Map<Id, Account> accsMap = new Map<Id, Account>(
      [SELECT Id, Geo__c, Area__c, Region__c, Territory__c FROM Account WHERE Id IN :accIds]
    );
    for (Lead l : leadList) {
      if (l.Account__c != null) {
        l.Geo__c = accsMap.get(l.Account__c).Geo__c;
        l.Area__c = accsMap.get(l.Account__c).Area__c;
        l.Region_Text__c = accsMap.get(l.Account__c).Region__c;
        l.Territory__c = accsMap.get(l.Account__c).Territory__c;
      }
    }
  }
}