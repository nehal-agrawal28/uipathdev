public class DataTeam_SyncTeamMemberSplits {
  public String activeTab { get; set; }
  public String activeTitle { get; set; }
  
  public Set<String> oppsToSync {get; set;}
  public Set<String> oppsTMToAdd {get; set;}
  public Map<String, List<String>> oppsTMToAddMap {get; set;}
  public Map<String, List<OpportunityTeamMember>> existingOTMMap {get; set;}
  public Map<String, List<Opportunity_Split__c>> existingOSMap {get; set;}
  public Map<Id, Opportunity> oppMap {get; set;}
  public Boolean showbatchcomponent {get; set;}
  private Map<String, Decimal> AvailableRoles;
  
  public Blob csvFileBody { get; set; }
  public string csvAsString { get; set; }
  
  public DataTeam_SyncTeamMemberSplits() {
    activeTab = '0';
    activeTitle = 'OPPORTUNITY TEAM MEMBERS / SPLITS';
    AvailableRoles = AvailableTeamMemberRoles();
  }

  // =============================================================================================
  // =============================== READ DATA FROM CSV FILE =====================================
  // =============================== DISPLAY DATA IN VF TABLES ===================================
  public void readCSVData() {
    oppsToSync = new Set<String>();
    oppsTMToAdd = new Set<String>();
    existingOTMMap = new Map<String, List<OpportunityTeamMember>>();
    existingOSMap = new Map<String, List<Opportunity_Split__c>>();
    oppsTMToAddMap = new Map<String,List<String>>();
    try {
      csvAsString = csvFileBody.toString();
      String[] csvFileLines = csvAsString.split('\r\n');
      for (Integer i = 1; i < csvFileLines.size(); i++) {
        string[] csvOppData = csvFileLines[i].split(',');
        oppsToSync.add(csvOppData[0].trim());
        if(csvOppData.size() > 1) {
            oppsTMToAdd.add(csvOppData[0].trim() + '-' + csvOppData[1].trim() + '-' + csvOppData[2].trim());
            if(!oppsTMToAddMap.containsKey(csvOppData[0])) {
              List<String> newList = new List<String>();
              newList.add(csvOppData[0] + '-' + csvOppData[1] + '-' + csvOppData[2]);
              oppsTMToAddMap.put(csvOppData[0], newList);
            } else {
              List<String> exList = oppsTMToAddMap.get(csvOppData[0]);
              exList.add(csvOppData[0] + '-' + csvOppData[1] + '-' + csvOppData[2]);
              oppsTMToAddMap.put(csvOppData[0], exList);
            }
         } else {
           oppsTMToAddMap.put(csvOppData[0].trim(), new List<String>());
         }
      }
      existingOTMMap = populateOpportunityTeamList(oppsToSync);
      existingOSMap = populateOppSplitsList(oppsToSync);
      oppMap = getOpportunitiesByIDMap(oppsToSync);
    } catch (Exception e) {
      ApexPages.Message errorMessage = new ApexPages.Message(
        ApexPages.severity.ERROR,
        e.getMessage() + ' Please make sure input csv file is correct'
      );
      ApexPages.addMessage(errorMessage);
    }
  }
  // =============================================================================================

  // =============================================================================================
  // ========================= BUTTONS ACTIONS ===================================================
  
  // =============================================================================================
  // SYNC OPPORTUNITY TEAM MEMBERS ===============================================================
  // =============================================================================================
  public void setOpportunityTeamMember() {
    Boolean isError = false;
    Map<String, List<String>> oppExistingTeamMembersMap = getOppTeamMembersAsStringMap(oppMap);
    Map<String, List<String>> oppShouldBeTeamMembersMap = getTeamMembersFromOppMap(oppMap);
    showbatchcomponent = true;
    Id jobIdTeam = System.enqueueJob(new DataTeam_SYNCOppTeamQueueable(oppExistingTeamMembersMap, oppShouldBeTeamMembersMap, oppMap, allOTMMap, oppsToSync, oppsTMToAdd));
    if (Test.isRunningTest()) {
      Id jobIdSplit = System.enqueueJob(new DataTeam_SYNCOppSplitsQueueable(existingOTMMap, existingOSMap, oppMap, allOTMMap, oppsToSync, oppsTMToAdd));
      Id jobIdNewTM = System.enqueueJob(new DataTeam_SYNCAddTeamMembersQueueable(oppsTMToAdd, allOTMMap));
    }
  }
  // =============================================================================================
  // END SYNC OPPORTUNITY TEAM MEMBERS ===========================================================
  // =============================================================================================
  
  public void Cancel() {
    showbatchcomponent = false;
    existingOTMMap = null;
    existingOSMap = null;
    oppsToSync = null;
  }

  // ========================= END BUTTONS ACTIONS ===============================================
  // =============================================================================================
  
  private Map<Id, Opportunity> getOpportunitiesByIDMap(Set<String> oppIds) {
    return new Map<Id, Opportunity>([SELECT Id, OwnerId, AccountId, Account.OwnerId, Account.KAM_Id__c, Account.KAM_GSI__c, Account.Geo__c, Account.Area__c, Sold_To_Partner__c,  Sold_To_Partner__r.OwnerId, Tier_2_Partner__c, Tier_2_Partner__r.OwnerId, Influencers__c, (SELECT Id, OpportunityId, UserId, TeamMemberRole FROM OpportunityTeamMembers) FROM Opportunity WHERE Id IN: oppIds]);
  }

  private Map<String, List<String>> getTeamMembersFromOppMap(Map<Id, Opportunity> oppMap) {
     Map<String, List<String>> returnMap = new Map<String, List<String>>();
     Set<String> accountIds = new Set<String>();
     for(Id oppId: oppMap.keySet()) {
         Opportunity currentOpp = oppMap.get(oppId);
         if(!String.isEmpty(currentOpp.Influencers__c)) {
           for(String s: (currentOpp.Influencers__c).split(';'))
             accountIds.add(s);
         }
     }
     
     Map<Id, Account> mapAccounts = new Map<Id, Account>([SELECT Id, OwnerId FROM Account WHERE Id IN: accountIds]);
     for(Id oppId: oppMap.keySet()) {
         Opportunity currentOpp = oppMap.get(oppId);
         List<String> newList = new List<String>();
         newList.add(String.valueOf(currentOpp.Id) + '-' + String.valueOf(currentOpp.OwnerId) + '-Opportunity Owner');
         if(currentOpp.Account.KAM_Id__c != null && currentOpp.Account.KAM_GSI__c != currentOpp.Account.OwnerId)
             newList.add(String.valueOf(currentOpp.Id) + '-' + currentOpp.Account.KAM_Id__c + '-Key Account Manager');
         if(currentOpp.Account.KAM_GSI__c != null && currentOpp.Account.KAM_GSI__c != currentOpp.Account.OwnerId)
             newList.add(String.valueOf(currentOpp.Id) + '-' + String.valueOf(currentOpp.Account.KAM_GSI__c) + '-Key Account Manager');
         if(currentOpp.Sold_To_Partner__c != null)
             newList.add(String.valueOf(currentOpp.Id) + '-' + String.valueOf(currentOpp.Sold_To_Partner__r.OwnerId) + '-Partner Account Manager');
         if(currentOpp.Tier_2_Partner__c != null)
             newList.add(String.valueOf(currentOpp.Id) + '-' + String.valueOf(currentOpp.Tier_2_Partner__r.OwnerId) + '-Partner Account Manager');
         if(!String.isEmpty(currentOpp.Influencers__c)) {
           for(String s: (currentOpp.Influencers__c).split(';')) {
               if(mapAccounts.containsKey(Id.valueOf(s))) { 
                   Account currentAcc = mapAccounts.get(Id.valueOf(s));
                   newList.add(String.valueOf(currentOpp.Id) + '-' + String.valueOf(currentAcc.OwnerId) + '-Partner Account Manager');
               }
           }
         }       
         returnMap.put(String.valueOf(currentOpp.Id), newList);
     }
     return returnMap;
  }
  private Map<String, OpportunityTeamMember> allOTMMap;
  private Map<String, List<String>> getOppTeamMembersAsStringMap(Map<Id, Opportunity> oppMap) {
     Map<String, List<String>> returnMap = new Map<String, List<String>>();
     allOTMMap = new Map<String, OpportunityTeamMember>();
     for(Id oppId: oppMap.keySet()) {
         List<OpportunityTeamMember> currentotms = oppMap.get(oppId).OpportunityTeamMembers;
         for(OpportunityTeamMember otm: currentotms) {
             allOTMMap.put(String.valueOf(otm.OpportunityId) + '-' + String.valueOf(otm.UserId) + '-' + otm.TeamMemberRole, otm);
             if(!returnMap.containskey(String.valueOf(oppId))) {
               List<String> newList = new List<String>();
               newList.add(String.valueOf(otm.OpportunityId) + '-' + String.valueOf(otm.UserId) + '-' + otm.TeamMemberRole);
               returnMap.put(String.valueOf(otm.OpportunityId), newList);
             } else {
               List<String> newList = returnMap.get(String.valueOf(oppId));
               newList.add(String.valueOf(otm.OpportunityId) + '-' + String.valueOf(otm.UserId) + '-' + otm.TeamMemberRole);
               returnMap.put(String.valueOf(otm.OpportunityId), newList);
             }
         }
     }
     return returnMap;
  }
  
  private Map<String, Set<String>> getOTMAsMap(Map<String, List<OpportunityTeamMember>> otmSentMap) {
    Map<String, Set<String>> otmMap = new Map<String, Set<String>>();
    for (String oppId : otmSentMap.keySet()) {
      List<OpportunityTeamMember> existingOTMforCurrentOpp = otmSentMap.get(oppId);
      for (OpportunityTeamMember otm : existingOTMforCurrentOpp) {
        String otmString = otm.OpportunityId + '-' + otm.UserId + '-' + otm.TeamMemberRole;
        String sId = String.valueOf(otm.Id);
        if (!otmMap.containsKey(sId)) {
          Set<String> newSet = new Set<String>();
          newSet.add(otmString);
          otmMap.put(sId, newSet);
        } else {
          Set<String> exSet = otmMap.get(sId);
          exSet.add(otmString);
          otmMap.put(sId, exSet);
        }
      }
    }
    return otmMap;
  }
  
  private Map<String, Set<String>> getOSAsMap(Map<String, List<Opportunity_Split__c>> osSentMap) {
    Map<String, Set<String>> osMap = new Map<String, Set<String>>();
    for (String oppId : osSentMap.keySet()) {
      List<Opportunity_Split__c> existingOSforCurrentOpp = osSentMap.get(oppId);
      for (Opportunity_Split__c os : existingOSforCurrentOpp) {
        String osString = os.Opportunity__c + '-' + os.User__c + '-' + os.Role__c;
        String sId = String.valueOf(os.Id);
        if (!osMap.containsKey(sId)) {
          Set<String> newSet = new Set<String>();
          newSet.add(osString);
          osMap.put(sId, newSet);
        } else {
          Set<String> exSet = osMap.get(sId);
          exSet.add(osString);
          osMap.put(sId, exSet);
        }
      }
    }
    return osMap;
  }
  
  public Set<String> getOTMRecordsAsSet(Map<String, List<OpportunityTeamMember>> otmSentMap, Map<Id, Opportunity> opptyMap) {
    Set<String> otmSet = new Set<String>();
    for (String oppId : otmSentMap.keySet()) {
      List<OpportunityTeamMember> existingOTMforCurrentOpp = otmSentMap.get(oppId);
      for (OpportunityTeamMember otm : existingOTMforCurrentOpp) {
        if(opptyMap.containsKey(otm.OpportunityId)){
          Opportunity opp = opptyMap.get(otm.OpportunityId);
          if(otm.TeamMemberRole != 'Partner Account Manager') {
            otmSet.add(otm.OpportunityId + '-' + otm.UserId + '-' + otm.TeamMemberRole);
          } else {
           if(opp.Account.Geo__c != 'AMER' && opp.Account.Geo__c != 'EMEA' && opp.Account.Area__c != 'Japan') {
             otmSet.add(otm.OpportunityId + '-' + otm.UserId + '-' + otm.TeamMemberRole);
           }
         }
         }
       }
    }
    return otmSet;
  }
  
  public Map<String, Opportunity_Split__c> getOSRecordAsMap(Map<String, List<Opportunity_Split__c>> osSentMap) {
    Map<String, Opportunity_Split__c> osMap = new Map<String, Opportunity_Split__c>();
    for (String oppId : osSentMap.keySet()) {
    if(osSentMap.containsKey(oppId)){
      List<Opportunity_Split__c> existingOSforCurrentOpp = osSentMap.get(oppId);
      for (Opportunity_Split__c os : existingOSforCurrentOpp) {
        String osString = os.Opportunity__c + '-' + os.User__c + '-' + os.Role__c;
        if (!osMap.containsKey(osString)) {
          osMap.put(osString, os);
        }
      }
      }
    }
    return osMap;
  }

  
  public Map<String, Set<String>> compareSets(Set<String> os, Set<String> otm) {
    Map<String, Set<String>> returnMap = new Map<String, Set<String>>();
    for (String s : os) {
      if (!otm.contains(s)) {
        if (!returnMap.containsKey('ToDelete')) {
          returnMap.put('ToDelete', new Set<String>{ s });
        } else {
          Set<String> addRec = returnMap.get('ToDelete');
          addRec.add(s);
          returnMap.put('ToDelete', addRec);
        }
        
      } else {
        if (!returnMap.containsKey('ToUpdate')) {
          returnMap.put('ToUpdate', new Set<String>{ s });
        } else {
          Set<String> addRec = returnMap.get('ToUpdate');
          addRec.add(s);
          returnMap.put('ToUpdate', addRec);
        }
      }
    }

    for (String s : otm) {
      if (!os.contains(s)) {
        if (!returnMap.containsKey('ToInsert')) {
          returnMap.put('ToInsert', new Set<String>{ s });
        } else {
          Set<String> addRec = returnMap.get('ToInsert');
          addRec.add(s);
          returnMap.put('ToInsert', addRec);
        }
      } else {
        if (!returnMap.containsKey('ToUpdate')) {
          returnMap.put('ToUpdate', new Set<String>{ s });
        } else {
          Set<String> addRec = returnMap.get('ToUpdate');
          addRec.add(s);
          returnMap.put('ToUpdate', addRec);
        }
      }
    }

    return returnMap;
  }
  
  // ===============================================================================================
  // GET EXISTING RECORDS ==========================================================================
  // ===============================================================================================
  public Map<String, List<OpportunityTeamMember>> populateOpportunityTeamList(Set<String> oppIds) {
    Map<String, List<OpportunityTeamMember>> otmMap = new Map<String, List<OpportunityTeamMember>>();
    for (String s : oppIds) {
      otmMap.put(s, new List<OpportunityTeamMember>());
    }
    for (OpportunityTeamMember otm : [
      SELECT Id, UserId, User.Name, OpportunityId, TeamMemberRole
      FROM OpportunityTeamMember
      WHERE OpportunityId IN :oppIds AND TeamMemberRole IN :AvailableRoles.keySet() ORDER BY TeamMemberRole ASC
    ]) {
      String oppId = String.valueOf(otm.OpportunityId);
      List<OpportunityTeamMember> exList = otmMap.get(oppId);
      exList.add(otm);
      otmMap.put(oppId, exList);
    }
    return otmMap;
  }
  
  public Map<String, List<Opportunity_Split__c>> populateOppSplitsList(Set<String> oppIds) {
    Map<String, List<Opportunity_Split__c>> osMap = new Map<String, List<Opportunity_Split__c>>();
    for (String s : oppIds) {
      osMap.put(s, new List<Opportunity_Split__c>());
    }
    for (Opportunity_Split__c os : [
      SELECT Id, User__c, Opportunity__c, Role__c, Percentage__c, Included_in_Compensation__c
      FROM Opportunity_Split__c
      WHERE Opportunity__c IN :oppIds ORDER BY Role__c ASC
    ]) {
      String oppId = String.valueOf(os.Opportunity__c);
      List<Opportunity_Split__c> exList = osMap.get(oppId);
      exList.add(os);
      osMap.put(oppId, exList);
    }
    return osMap;
  }
  
  public Map<String, Decimal> AvailableTeamMemberRoles() {
    List<AvailableTeamMemberRole__mdt> availableRoles = [
      SELECT Id, Role__c, Percentage__c
      FROM AvailableTeamMemberRole__mdt
    ];
    Map<String, Decimal> AvailableTeamMemberRolesCached = new Map<String, Decimal>();
    for (AvailableTeamMemberRole__mdt role : availableRoles) {
      AvailableTeamMemberRolesCached.put(role.Role__c, role.Percentage__c);
    }
    return AvailableTeamMemberRolesCached;
  }
}