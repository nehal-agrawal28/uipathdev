public without sharing class OpportunityTriggerHandlerAll {
  ///**TEMP** Temporary fix for stop looping of account and opportunity trigger handlers to unblock deployments. Issues is being investigated at the moment.
  public static integer opportunityTriggerHandlerBeforeUpdate = 1;
  public static integer opportunityTriggerHandlerAfterUpdateWithList = 1;

  public static Boolean setExistingAccountFirstRun = true;

  private list<opportunity> opps = new List<opportunity>();
  private map<string, CurrencyType> mapCurrencies = new Map<string, CurrencyType>();
  private list<opportunity> updateOpportunities = new List<opportunity>();

  map<Id, Opportunity> oldOppsMap = new Map<Id, Opportunity>();

  public OpportunityTriggerHandlerAll(list<Opportunity> opps) {
    this.opps = opps;
  }

  public OpportunityTriggerHandlerAll(list<Opportunity> newOpps, map<Id, Opportunity> oldOppsMap) {
    this.opps = newOpps;
    this.oldOppsMap = oldOppsMap;
  }

  // Public trigger methods
  // public void processBeforeInsert() {
  // setDefaultValue4JP(this.opps);
  //SetPartnerClosestToEndCustomer(this.opps);
  // }

  /*
        Because of the unusual implementation of this trigger framework, I had to create a new method
        to get access to the actual trigger opportunities without having to query them
    */
  public void processAfterUpdateWithList(list<Opportunity> newOpps, Map<Id, Opportunity> oldOpportunitiesMap) {
    ///**TEMP** Temporary fix for stop looping of account and opportunity trigger handlers to unblock deployments. Issues is being investigated at the moment.
    if (opportunityTriggerHandlerAfterUpdateWithList > 2) {
      return;
    }
    opportunityTriggerHandlerAfterUpdateWithList++;
    // CreateAssetOnClosedWonHandler.CreateAssetOnClosedWon(newOpps); // Pre-CPQ Code Not Needed any more : SLTECH-13611
    //Commented below code for SLTCHIN1383
    //OpportunityTeamMemberQueueable.updateOTM(newOpps, oldOpportunitiesMap);
    //OppRenewalSpecialistQueueable.updateRS(newOpps, oldOpportunitiesMap);
    //OpportunityRenewalCreation.createRenewalOpportunityWithProducts(newOpps, oldOpportunitiesMap);
    //CopyOpportunityType(newOpps, oldOpportunitiesMap);
  }

  public void processAfterInsert(list<Opportunity> newOpps) {
    //addEconomicBuyerAndChampionOCR('insert');
    //OpportunityTeamMemberQueueable.createOTM(newOpps);
    //OppRenewalSpecialistQueueable.createRS(newOpps);
  }

  // Private methods

  /*public void UpdateCloseDate(List<Opportunity> oppList, Map<Id, Opportunity> oldMap) {
        for(Opportunity opp: oppList) {
            Opportunity oldOpp = oldMap.get(opp.Id);
            if(opp.StageName == 'Closed Won Pending' && opp.StageName != oldOpp.StageName)    
                opp.Close_Won_Pending_Date__c = Date.Today(); 
            if((opp.StageName == 'Closed Won Booked' || opp.StageName == 'Closed Won Pending' || opp.StageName == 'Closed Lost') && opp.StageName != oldOpp.StageName)
                opp.CloseDate = Date.Today();
            
        }
    }*/

  // public void LastOppStageUpdate(List<Opportunity> oppList, Map<Id, Opportunity> oldMap, String triggerAction) {
  //   for (Opportunity opp : oppList) {
  //     if (triggerAction == 'insert') {
  //       opp.Last_Stage_Update_Date__c = Date.Today();
  //     }
  //     if (triggerAction == 'update') {
  //       Opportunity oldOpp = oldMap.get(opp.Id);
  //       if (opp.StageName != oldOpp.StageName)
  //         opp.Last_Stage_Update_Date__c = Date.Today();
  //     }
  //   }
  // }

  // Store Existing OpportunityTeamMembers (as string) in a field on Opportunity =================
  public void storeOppTeamMembers(map<Id, Opportunity> oldMap, map<Id, Opportunity> newMap) {
    List<Opportunity> oppIds = new List<Opportunity>();
    for (Opportunity Opp : newMap.values()) {
      if (oldMap.get(Opp.id).OwnerId != Opp.OwnerId) {
        oppIds.add(Opp);
      }
    }

    if (!oppIds.isEmpty()) {
      map<Id, list<OpportunityTeamMember>> mapOTMs = new Map<Id, list<OpportunityTeamMember>>();
      List<OpportunityTeamMember> allOTM = [
        SELECT UserId, TeamMemberRole, OpportunityId, OpportunityAccessLevel, Created_on_opportunity_insert__c
        FROM OpportunityTeamMember o
        WHERE OpportunityId IN :oppIds /*AND TeamMemberRole != 'Opportunity Owner'*/
      ];
      for (OpportunityTeamMember otm : allOTM) {
        if (!mapOTMs.containsKey(otm.OpportunityId)) {
          List<OpportunityTeamMember> newOTMList = new List<OpportunityTeamMember>();
          newOTMList.add(otm);
          mapOTMs.put(otm.OpportunityId, newOTMList);
        } else {
          List<OpportunityTeamMember> newOTMList = mapOTMs.get(otm.OpportunityId);
          newOTMList.add(otm);
          mapOTMs.put(otm.OpportunityId, newOTMList);
        }
      }
      for (Opportunity Opp : oppIds) {
        if (mapOTMs.containsKey(Opp.Id))
          Opp.OpportunityTeamMembers__c = String.valueOf(mapOTMs.get(Opp.Id));
      }
    }
  }

  public void setOppTeamMembers(map<Id, Opportunity> mapOppsOld, map<Id, Opportunity> mapOppsNew) {
    List<Opportunity> currentOpps = new List<Opportunity>();
    for (Opportunity Opp : mapOppsNew.values()) {
      if (mapOppsOld.get(Opp.id).OwnerId != Opp.OwnerId && !String.isEmpty(Opp.OpportunityTeamMembers__c)) {
        currentOpps.add(Opp);
      }
    }

    if (!currentOpps.isEmpty()) {
      Set<Id> lockedRecordIds = new Set<Id>{
        OpportunityMetadata_SL.CPQLockedRecordType,
        OpportunityMetadata_SL.UipathStandardLockedRecordType
      };
      /*list<OpportunityTeamMember> lstOTMs = parseStringToGetOTM(currentOpps, mapOppsOld, lockedRecordIds);
      //Insert old team members
      if (!lstOTMs.isEmpty()) {
        insert lstOTMs;
      }*/
    }
  }

  private static list<OpportunityTeamMember> parseStringToGetOTM(
    List<Opportunity> currentOpps,
    map<Id, Opportunity> mapOppsOld,
    Set<Id> lockedRecordIds
  ) {
    list<OpportunityTeamMember> allOTMs = new List<OpportunityTeamMember>();

    for (Opportunity Opp : currentOpps) {
      // Only if the record owner changed
      if (mapOppsOld.get(Opp.id).OwnerId != Opp.OwnerId) {
        // Get all the opp team members in a string
        String lstElements = Opp.OpportunityTeamMembers__c != null ? Opp.OpportunityTeamMembers__c : '';
        // Work on the string to keep only the pertinent info
        String regex = 'OpportunityTeamMember\\:\\{';
        String[] lstElementsTab = lstElements.split(regex);

        for (Integer j = 1; j < lstElementsTab.size(); j++) {
          // Create the new opp team member with the stored data
          OpportunityTeamMember otm = new OpportunityTeamMember();
          String[] elements = lstElementsTab[j].trim().split('\\,');
          otm = getOpportunityFromString(elements);
          if (
            (!lockedRecordIds.contains(Opp.RecordTypeId) && otm.TeamMemberRole != 'Opportunity Owner') ||
            lockedRecordIds.contains(Opp.RecordTypeId)
          )
            allOTMs.add(otm);
        }
      }
    }
    return allOTMs;
  }

  private static OpportunityTeamMember getOpportunityFromString(String[] elements) {
    OpportunityTeamMember otmem = new OpportunityTeamMember();
    for (Integer k = 0; k < elements.size(); k++) {
      if (elements[k].contains('OpportunityId')) {
        otmem.OpportunityId = (Id) elements[k].split('\\=')[1].trim();
      }
      if (elements[k].contains('UserId')) {
        otmem.UserId = (Id) elements[k].split('\\=')[1].trim().substring(0, 15);
      }
      if (elements[k].contains('TeamMemberRole')) {
        otmem.TeamMemberRole = (String) elements[k].split('\\=')[1].trim();
      }
      if (elements[k].contains('Created_on_opportunity_insert__c')) {
        otmem.Created_on_opportunity_insert__c = Boolean.valueOf(elements[k].split('\\=')[1].trim());
      }
      if (elements[k].contains('OpportunityAccessLevel')) {
        otmem.OpportunityAccessLevel = elements[k].split('\\=')[1].trim();
      }
    }
    otmem.Do_Not_Create_Split__c = true;
    return otmem;
  }

  /* public void setExistingAccount(List<Opportunity> oppList, Map<Id, Opportunity> oldMap)
    {
        // SLTECH-20917 Fix: Renewal Opportunity Creation Failing with SOQL 101
        if(!setExistingAccountFirstRun){
            return;
        }
        setExistingAccountFirstRun = false;

        List<String> companyNames = new List<String>();
        List<String> companyCountries = new List<String>();
        List<String> companyCities = new List<String>();
        for (Opportunity opp : oppList)
        {
            if(!string.isEmpty(opp.Account_Name__c))
            {
                companyNames.add('%' + opp.Account_Name__c + '%');
            }

            if(!string.isEmpty(opp.Account_Country__c))
            {
                companyCountries.add(opp.Account_Country__c);
            }

            if(!string.isEmpty(opp.Account_City__c))
            {
                companyCities.add(opp.Account_City__c);
            }

        }

        List<Account> matchingAccountNames = [SELECT Id, Name, BillingCountry, BillingCity, OwnerId
                                                FROM Account
                                                WHERE Owner.IsActive = true
                                                    AND (Name LIKE :companyNames AND BillingCountry LIKE :companyCountries)];*/
  /*Map<String, Account> accMap = new Map<String, Account>();
        for (Account acc : matchingAccountNames) {
            string key = acc.Name + '~' + acc.BillingCountry + '~' + acc.BillingCity;
            accMap.put(key, acc);
        }*/

  /*for (Opportunity opp : oppList)
        {

            if (string.isEmpty(opp.Account_Name__c) || string.isEmpty(opp.Account_Country__c))
                continue;

            for (Account match : matchingAccountNames) {
                boolean matching = false;
                if (match.Name.ToLowerCase().contains(opp.Account_Name__c.ToLowerCase()) && match.BillingCountry == opp.Account_Country__c) {
                    if (string.isEmpty(opp.Account_City__c)) {
                        matching = true;
                    } else {
                        if (match.BillingCity == opp.Account_City__c) {
                            matching = true;
                        }
                    }
                }

                if (matching) {
                    opp.Suggested_Account__c = match.Id;
                }
            }

        }

    }*/

  /*public void SetPartnerClosestToEndCustomer(List<Opportunity> opps) {
    for (Opportunity opp : opps) {
      opp.Partner_Closest_to_End_Customer__c = opp.Sold_To_Partner__c;
      if (opp.Tier_2_Partner__c != null)
        opp.Partner_Closest_to_End_Customer__c = opp.Tier_2_Partner__c;
      if (opp.Tier_3_Partner__c != null)
        opp.Partner_Closest_to_End_Customer__c = opp.Tier_3_Partner__c;
    }
  }*/

  // public void CopyOpportunityType(List<Opportunity> newList, Map<Id, Opportunity> oldMap) {
  //   Map<Id, Opportunity> eligibleMap = new Map<Id, Opportunity>();

  //   for (Opportunity newOpp : newList) {
  //     Opportunity oldOpp = oldmap.get(newOpp.Id);
  //     if (newOpp.Type != oldOpp.Type && (newOpp.Type == 'New Business' || newOpp.Type == 'Upsell')) {
  //       eligibleMap.put(newOpp.Id, newOpp);
  //     }
  //   }

  //   if (eligibleMap.size() > 0) {
  //     List<OpportunityLineItem> olis = [
  //       SELECT OpportunityId, Business_Type__c
  //       FROM OpportunityLineItem
  //       WHERE OpportunityId IN :eligiblemap.keySet() AND Business_Type__c != 'Renewal'
  //     ];
  //     if (olis.size() > 0) {
  //       List<OpportunityLineItem> toUpdate = new List<OpportunityLineItem>();

  //       for (OpportunityLineItem oli : olis) {
  //         if (eligibleMap.containsKey(oli.OpportunityId)) {
  //           if (oli.Business_Type__c != eligibleMap.get(oli.OpportunityId).Type) {
  //             oli.Business_Type__c = eligibleMap.get(oli.OpportunityId).Type;
  //             toUpdate.add(oli);
  //           }
  //         }
  //       }
  //       if (toUpdate.size() > 0) {
  //         update toUpdate;
  //       }
  //     }
  //   }
  // }

  /*public void addEconomicBuyerAndChampionOCR(string action) {
    String deleteQuery = 'SELECT Id FROM OpportunityContactRole WHERE ';
    string delimiter = '';
    if (action == 'update') {
      for (Opportunity opp : opps) {
        if (
          opp.Economic_Buyer__c != oldOppsMap.get(opp.Id).Economic_Buyer__c ||
          opp.Champion_Actual__c != oldOppsMap.get(opp.Id).Champion_Actual__c
        ) {
          deleteQuery =
            deleteQuery +
            delimiter +
            '(( Role = \'Champion\' OR Role = \'Economic Buyer\') AND OpportunityId = ' +
            '\'' +
            opp.Id +
            '\'' +
            ')';
          delimiter = ' OR ';
        }
      }

      if (delimiter != '') {
        List<sObject> results = Database.query(deleteQuery);
        delete results;
      }
    }

    //on insert and if any of them actually changed, we have to add new records.
    if (action == 'insert' || delimiter != '') {
      List<OpportunityContactRole> roles = new List<OpportunityContactRole>();
      for (Opportunity opp : opps) {
        if (opp.Economic_Buyer__c != null) {
          OpportunityContactRole role = new OpportunityContactRole();
          role.Role = 'Economic Buyer';
          role.OpportunityId = opp.Id;
          role.ContactId = opp.Economic_Buyer__c;
          roles.add(role);
        }

        if (opp.Champion_Actual__c != null) {
          OpportunityContactRole role = new OpportunityContactRole();
          role.Role = 'Champion';
          role.OpportunityId = opp.Id;
          role.ContactId = opp.Champion_Actual__c;
          roles.add(role);
        }
      }

      if (roles.size() > 0)
        insert roles;
    }
  }*/

  // public void setDefaultValue4JP(List<Opportunity> opps) {
  //   List<RecordType> rtList = [SELECT Id, DeveloperName FROM RecordType WHERE SObjectType = 'Opportunity'];
  //   ID rtId;
  //   for (RecordType rt : rtList) {
  //     if (rt.DeveloperName == 'UiPath_Japan_Partner_standard') {
  //       rtId = rt.Id;
  //     }
  //   }
  //   for (Opportunity opp : opps) {
  //     if (
  //       opp.RecordTypeId == rtId &&
  //       (opp.Deal_Type__c == 'Managed Service/BPO' ||
  //       opp.Deal_Type__c == 'Managed Services' ||
  //       opp.Deal_Type__c == 'BPO')
  //     ) {
  //       opp.Do_We_Know_End_Customer__c = 'No';
  //     }
  //   }
  // }
}