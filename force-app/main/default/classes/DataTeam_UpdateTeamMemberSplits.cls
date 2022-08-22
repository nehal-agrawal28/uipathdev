public class DataTeam_UpdateTeamMemberSplits {
  public String activeTab { get; set; }
  public String activeTitle { get; set; }
  public Boolean showbatchcomponent { get; set; }

  public List<opportunitywrapperotm> allOpportunitiesOTM { get; set; }
  public List<opportunitywrapperos> allOpportunitiesOS { get; set; }
  public List<opportunityteammember> allotmtodelete { get; set; }
  public List<opportunity_split__c> allostodelete { get; set; }

  public DataTeam_UpdateTeamMemberSplits() {
    activeTab = '0';
    activeTitle = '';
    showbatchcomponent = false;
  }

  public List<SelectOption> objectOption { set; }
  public String selectedOption { get; set; }

  public List<SelectOption> getObjectOption() {
    List<SelectOption> options = new List<SelectOption>();
    options.add(new SelectOption('', ' -- SELECT ACTION -- '));
    options.add(new SelectOption('OpportunityTeamMembers', 'INSERT TEAM MEMBERS'));
    options.add(new SelectOption('OpportunityTeamMembersDelete', 'DELETE TEAM MEMBERS'));
    options.add(new SelectOption('OpportunitysplitsInsert', 'INSERT OPPORTUNITY SPLITS'));
    options.add(new SelectOption('OpportunitysplitsUpdate', 'UPDATE OPPORTUNITY SPLITS'));
    options.add(new SelectOption('OpportunitysplitsDelete', 'DELETE OPPORTUNITY SPLITS'));
    return options;
  }

  public Blob csvFileBody { get; set; }
  public string csvAsString { get; set; }
  private Map<String, Set<String>> dataMap;
  private Map<String, String> dataMapUpdate;
  private Set<String> dataSet;

  // =============================================================================================
  // =============================== READ DATA FROM CSV FILE =====================================
  // =============================== DISPLAY DATA IN VF TABLES ===================================
  public void readCSVData() {
    allOpportunitiesOTM = new List<opportunitywrapperotm>();
    allOpportunitiesOS = new List<opportunitywrapperos>();
    allotmtodelete = new List<opportunityteammember>();
    allostodelete = new List<opportunity_split__c>();
    try {
      csvAsString = csvFileBody.toString();

      String[] csvFileLines = csvAsString.split('\r\n');
      Set<String> toDeleteSetIds = new Set<String>();
      dataSet = new Set<String>();
      dataMap = new Map<String, Set<String>>();
      dataMapUpdate = new Map<String, String>();
      for (Integer i = 1; i < csvFileLines.size(); i++) {
        List<string> csvOppData = new List<string>();

        if (csvFileLines[i].contains(','))
          csvOppData = csvFileLines[i].split(',');
        else
          csvOppData.add(csvFileLines[i]);

        if (!String.isEmpty(csvOppData[0]) || !String.isEmpty(csvOppData[1])) {
          String s = '';
          if (selectedOption == 'OpportunityTeamMembers') {
            s = csvOppData[1].trim() + '-' + csvOppData[2].trim() + '-' + csvOppData[3].trim();
          } else {
            if (selectedOption == 'OpportunityTeamMembersDelete' || selectedOption == 'OpportunitysplitsDelete') {
              s = csvOppData[0].trim();
              toDeleteSetIds.add(csvOppData[0].trim());
            } else {
              if (selectedOption == 'OpportunitysplitsInsert') {
                s =
                  csvOppData[1].trim() +
                  '-' +
                  csvOppData[2].trim() +
                  '-' +
                  csvOppData[3].trim() +
                  '-' +
                  csvOppData[4].trim() +
                  '-' +
                  csvOppData[5].trim();
              } else {
                if (selectedOption == 'OpportunitysplitsUpdate') {
                  s =
                    csvOppData[0].trim() +
                    '-' +
                    csvOppData[1].trim() +
                    '-' +
                    csvOppData[2].trim() +
                    '-' +
                    csvOppData[3].trim() +
                    '-' +
                    csvOppData[4].trim() +
                    '-' +
                    csvOppData[5].trim();

                  dataSet.add(csvOppData[0]);
                }
              }
            }
          }

          if (String.isEmpty(csvOppData[0]) && !String.isEmpty(csvOppData[1])) {
            if (!dataMap.containsKey(csvOppData[1])) {
              Set<String> otmosList = new Set<String>();
              otmosList.add(s);
              dataMap.put(csvOppData[1], otmosList);
            } else {
              Set<String> otmosList = dataMap.get(csvOppData[1]);
              otmosList.add(s);
              dataMap.put(csvOppData[1], otmosList);
            }
          }
          system.debug('dataMap =====> ' + dataMap);
          if (!String.isEmpty(csvOppData[0])) {
            if (!dataMapUpdate.containsKey(csvOppData[0])) {
              dataMapUpdate.put(csvOppData[0], s);
            }
          }
        }
        system.debug('dataMapUpdate =====> ' + dataMapUpdate);
      }
      if (selectedOption == 'OpportunityTeamMembers') {
        Map<String, Set<String>> exotm = populateOpportunityTeamMap(dataMap.keySet());
        allOpportunitiesOTM = populateOpportunityWrappersOTM(dataMap, exotm);
        activeTab = '0';
        activeTitle = 'INSERT TEAM MEMBERS';
      } else {
        if (selectedOption == 'OpportunityTeamMembersDelete' || selectedOption == 'OpportunitysplitsDelete') {
          if (selectedOption == 'OpportunityTeamMembersDelete') {
            allotmtodelete = populateOTMtoDeleteList(toDeleteSetIds);
            activeTitle = 'DELETE OPPORTUNITY TEAM MEMBERS';
          } else {
            if (selectedOption == 'OpportunitysplitsDelete') {
              allostodelete = populateOStoDeleteList(toDeleteSetIds);
              activeTitle = 'DELETE OPPORTUNITY SPLITS';
            }
          }
          activeTab = '2';
        } else {
          if (selectedOption == 'OpportunitysplitsInsert') {
            Map<String, Set<String>> exos = populateInsertOppSplitsMap(dataMap.keySet());
            allOpportunitiesOS = populateOpportunityWrappersOS(dataMap, exos);
            activeTitle = 'INSERT OPPORTUNITY SPLITS';
          } else {
            if (selectedOption == 'OpportunitysplitsUpdate') {
              Map<Id, Opportunity_Split__c> exos = populateUpdateOppSplitsMap(dataSet);
              allOpportunitiesOS = populateOppUpdateWrappersOS(dataMapUpdate, exos);
              activeTitle = 'UPDATE OPPORTUNITY SPLITS';
            }
          }
          activeTab = '1';
        }
      }
    } catch (Exception e) {
      ApexPages.Message errorMessage = new ApexPages.Message(
        ApexPages.severity.ERROR,
        e.getMessage() + ' Please make sure input csv file is correct'
      );
      ApexPages.addMessage(errorMessage);
    }
  }

  // =============================================================================================
  // ========================= BUTTONS ACTIONS ===================================================

  // =============================================================================================
  // UPDATE OPPORTUNITY TEAM MEMBERS =============================================================
  // =============================================================================================
  public void updateOpportunityTeamMember() {
    List<OpportunityTeamMember> otmToUpsert = new List<OpportunityTeamMember>();
    for (opportunitywrapperotm otm : allOpportunitiesOTM) {
      for (String newotm : otm.newOTM) {
        Set<String> sString = otm.existingotm;
        if (sString == null || !sString.contains(newotm)) {
          String[] otmValues = (newotm).split('-');
          OpportunityTeamMember otmNewRecord = new OpportunityTeamMember();
          otmNewRecord.OpportunityId = otmValues[0];
          otmNewRecord.UserId = otmValues[1];
          otmNewRecord.TeamMemberRole = otmValues[2];
          otmToUpsert.add(otmNewRecord);
        }
      }
    }
    if (otmToUpsert.size() > 0) {
      DataTeam_UpsertDeleteTeamAndSplitsBatch dmlTMSplits = new DataTeam_UpsertDeleteTeamAndSplitsBatch(
        'OpportunityTeamMembers',
        otmToUpsert,
        'Upsert Team Members Result',
        'Upsert Team Members Result',
        'UpsertTeamMembersResult.csv'
      );
      database.executeBatch(dmlTMSplits, 50);
      showbatchcomponent = true;
    }
  }

  // =========================================================================================
  // INSERT OPPORTUNITY SPLITS ===============================================================
  // =========================================================================================
  public void insertOpportunitySplits() {
    List<Opportunity_Split__c> osToInsert = new List<Opportunity_Split__c>();
    for (opportunitywrapperos os : allOpportunitiesOS) {
      for (String nos : os.newOS) {
        Set<String> sString = os.existingos;
        if (sString == null || !sString.contains(nos)) {
          String[] osValues = (nos).split('-');
          system.debug('osValues ======>' + osValues);
          Opportunity_Split__c osNewRecord = new Opportunity_Split__c();
          osNewRecord.Opportunity__c = osValues[0].trim();
          osNewRecord.User__c = osValues[1].trim();
          osNewRecord.Role__c = osValues[2].trim();
          osNewRecord.Percentage__c = Decimal.valueOf(osValues[3].trim());
          osNewRecord.Included_in_Compensation__c = osValues[4].trim();
          osToInsert.add(osNewRecord);
        }
      }
    }
    if (osToInsert.size() > 0) {
      //insert osToInsert;
      DataTeam_UpsertDeleteTeamAndSplitsBatch dmlTMSplits = new DataTeam_UpsertDeleteTeamAndSplitsBatch(
        'OpportunitysplitsInsert',
        osToInsert,
        'Insert Opportunity Splits Result',
        'Insert Opportunity Splits Result',
        'InsertSplitsRecords.csv'
      );
      database.executeBatch(dmlTMSplits, 50);
      showbatchcomponent = true;
    }
  }

  // =========================================================================================
  // UPDATE OPPORTUNITY SPLITS ===============================================================
  // =========================================================================================

  public void updateOpportunitySplits() {
    List<Opportunity_Split__c> osToUpdate = new List<Opportunity_Split__c>();
    Map<String, Opportunity_Split__c> osRecordMap = populateOppSplitsUpdateMap(dataSet);
    for (opportunitywrapperos os : allOpportunitiesOS) {
      for (String newos : os.newOS) {
        String[] recordList = newos.split('-');
        Opportunity_Split__c osNewRecord = new Opportunity_Split__c();
        if (osRecordMap.containsKey(recordList[0])) {
          osNewRecord = osRecordMap.get(recordList[0]);
          osNewRecord.Role__c = recordList[3].trim();
          osNewRecord.Percentage__c = Decimal.valueOf(recordList[4].trim());
          osNewRecord.Included_in_Compensation__c = recordList[5].trim();
          osToUpdate.add(osNewRecord);
        }
      }
    }
    if (osToUpdate.size() > 0) {
      // update osToUpdate;
      DataTeam_UpsertDeleteTeamAndSplitsBatch dmlTMSplits = new DataTeam_UpsertDeleteTeamAndSplitsBatch(
        'OpportunitysplitsUpdate',
        osToUpdate,
        'Update Opportunity Splits Result',
        'Update Opportunity Splits Result',
        'UpdateSplitsRecords.csv'
      );
      database.executeBatch(dmlTMSplits, 50);
      showbatchcomponent = true;
    }
  }

  // ===========================================================================================
  // DELETE OPPORTUNITY TEAM MEMBERS / SPLITS ==================================================
  // ===========================================================================================
  public void deleteAllRecords() {
    String contentCSV = 'RECORD ID,SUCCESS/FAILURE,ERROR MESSAGE\r\n';

    if (allotmtodelete.size() > 0) {
      DataTeam_UpsertDeleteTeamAndSplitsBatch dmlTMSplits = new DataTeam_UpsertDeleteTeamAndSplitsBatch(
        'OpportunityTeamMembersDelete',
        allotmtodelete,
        'Delete Opportunity Team Member',
        'Delete Opportunity Team Member',
        'DeleteTeamMemberResult.csv'
      );
      database.executeBatch(dmlTMSplits, 50);
      showbatchcomponent = true;
    }
    if (allostodelete.size() > 0) {
      DataTeam_UpsertDeleteTeamAndSplitsBatch dmlTMSplits = new DataTeam_UpsertDeleteTeamAndSplitsBatch(
        'OpportunitysplitsDelete',
        allostodelete,
        'Delete Opportunity Splits',
        'Delete Opportunity Splits',
        'DeleteOppSplitsResult.csv'
      );
      database.executeBatch(dmlTMSplits, 50);
      showbatchcomponent = true;
    }
  }

  // ===========================================================================================
  // CANCEL ====================================================================================
  // ===========================================================================================
  public void Cancel() {
    selectedOption = '';
    activeTitle = '';
    allOpportunitiesOTM = null;
    allOpportunitiesOS = null;
    showbatchcomponent = false;
  }
  // ========================= END BUTTONS ACTIONS ===============================================
  // =============================================================================================

  // ========================= POPULATE WRAPPERS =================================================
  private List<opportunitywrapperotm> populateOpportunityWrappersOTM(
    Map<String, Set<String>> dataMap,
    Map<String, Set<String>> exOTM
  ) {
    List<opportunitywrapperotm> owrapper = new List<opportunitywrapperotm>();
    Map<Id, Opportunity> allOpps = getOpportunitiesByID(dataMap.keySet());
    for (String d : dataMap.keySet()) {
      Opportunity o = allOpps.get(Id.valueOf(d));
      owrapper.add(new opportunitywrapperotm(o, exOTM.get(d), dataMap.get(d)));
    }
    return owrapper;
  }

  private List<opportunitywrapperos> populateOppUpdateWrappersOS(
    Map<String, String> dataMap,
    Map<Id, Opportunity_Split__c> exOS
  ) {
    List<opportunitywrapperos> owrapper = new List<opportunitywrapperos>();
    Map<Id, Opportunity> allOpps = getOpportunitiesByID(dataMap.keySet());
    for (String d : dataMap.keySet()) {
      Opportunity o = allOpps.get(Id.valueOf(d));
      Opportunity_Split__c os = exOS.get(Id.valueOf(d));
      String es =
        String.valueOf(os.Id) +
        '-' +
        String.valueOf(os.Opportunity__c) +
        '-' +
        String.valueOf(os.User__c) +
        '-' +
        String.valueOf(os.Role__c) +
        '-' +
        String.valueOf(os.Percentage__c) +
        '-' +
        String.valueOf(os.Included_in_Compensation__c);
      owrapper.add(new opportunitywrapperos(o, new Set<String>{ es }, new Set<String>{ dataMap.get(d) }));
    }
    return owrapper;
  }

  private List<opportunitywrapperos> populateOpportunityWrappersOS(
    Map<String, Set<String>> dataMap,
    Map<String, Set<String>> exOS
  ) {
    List<opportunitywrapperos> owrapper = new List<opportunitywrapperos>();
    Map<Id, Opportunity> allOpps = getOpportunitiesByID(dataMap.keySet());
    for (String d : dataMap.keySet()) {
      Opportunity o = allOpps.get(Id.valueOf(d));
      owrapper.add(new opportunitywrapperos(o, exOS.get(d), dataMap.get(d)));
    }
    return owrapper;
  }
  // ========================= END POPULATE WRAPPERS =============================================
  // =============================================================================================

  // =============================================================================================
  // ========================= SELECT EXISTING RECORDS ===========================================
  private List<OpportunityTeamMember> populateOTMtoDeleteList(Set<String> otmSetIds) {
    return [
      SELECT Id, OpportunityId, Opportunity.Name, UserId, User.Name, TeamMemberRole
      FROM OpportunityTeamMember
      WHERE Id IN :otmSetIds
    ];
  }

  private List<Opportunity_Split__c> populateOStoDeleteList(Set<String> osSetIds) {
    return [
      SELECT Id, Opportunity__c, Opportunity__r.Name, User__c, User__r.Name, Role__c, Percentage__c
      FROM Opportunity_Split__c
      WHERE Id IN :osSetIds
    ];
  }

  private Map<String, Set<String>> populateOpportunityTeamMap(Set<String> oppIds) {
    Map<String, Set<String>> otmMap = new Map<String, Set<String>>();
    for (OpportunityTeamMember otm : [
      SELECT Id, UserId, User.Name, OpportunityId, TeamMemberRole
      FROM OpportunityTeamMember
      WHERE OpportunityId IN :oppIds
    ]) {
      if (!otmMap.containsKey(otm.OpportunityId)) {
        Set<String> otmList = new Set<String>();
        otmList.add(otm.OpportunityId + '-' + otm.UserId + '-' + otm.TeamMemberRole);
        otmMap.put(otm.OpportunityId, otmList);
      } else {
        Set<String> otmList = otmMap.get(otm.OpportunityId);
        otmList.add(otm.OpportunityId + '-' + otm.UserId + '-' + otm.TeamMemberRole);
        otmMap.put(otm.OpportunityId, otmList);
      }
    }
    return otmMap;
  }

  private Map<String, Set<String>> populateInsertOppSplitsMap(Set<String> oppIds) {
    Map<String, Set<String>> osMap = new Map<String, Set<String>>();
    for (Opportunity_Split__c os : [
      SELECT Id, User__c, Opportunity__c, Role__c, Percentage__c, Included_in_Compensation__c
      FROM Opportunity_Split__c
      WHERE Opportunity__c IN :oppIds
    ]) {
      if (!osMap.containsKey(os.Opportunity__c)) {
        Set<String> osList = new Set<String>();
        osList.add(
          os.Id +
          '-' +
          os.Opportunity__c +
          '-' +
          os.User__c +
          '-' +
          os.Role__c +
          '-' +
          os.Percentage__c +
          '-' +
          os.Included_in_Compensation__c
        );
        osMap.put(os.Opportunity__c, osList);
      } else {
        Set<String> osList = osMap.get(os.Opportunity__c);
        osList.add(
          os.Id +
          '-' +
          os.Opportunity__c +
          '-' +
          os.User__c +
          '-' +
          os.Role__c +
          '-' +
          os.Percentage__c +
          '-' +
          os.Included_in_Compensation__c
        );
        osMap.put(os.Opportunity__c, osList);
      }
    }
    return osMap;
  }

  private Map<Id, Opportunity_Split__c> populateUpdateOppSplitsMap(Set<String> oppSplitIds) {
    return new Map<Id, Opportunity_Split__c>(
      [
        SELECT Id, User__c, Opportunity__c, Role__c, Percentage__c, Included_in_Compensation__c
        FROM Opportunity_Split__c
        WHERE Id IN :oppSplitIds
      ]
    );
  }

  private Map<String, Opportunity_Split__c> populateOppSplitsUpdateMap(Set<String> recIds) {
    Map<String, Opportunity_Split__c> osRecordMap = new Map<String, Opportunity_Split__c>();
    for (Opportunity_Split__c os : [
      SELECT Id, User__c, Opportunity__c, Role__c, Percentage__c, Included_in_Compensation__c
      FROM Opportunity_Split__c
      WHERE Id IN :recIds
    ]) {
      if (!osRecordMap.containsKey(os.Id))
        osRecordMap.put(os.Id, os);
    }
    return osRecordMap;
  }
  // ========================= SELECT EXISTING RECORDS ===========================================
  // =============================================================================================

  // get opportunities by id
  private Map<Id, Opportunity> getOpportunitiesByID(Set<String> oppIds) {
    return new Map<Id, Opportunity>(
      [
        SELECT Id, Name, AccountId, Account.Name, OwnerId, Owner.Name
        FROM Opportunity
        WHERE ID IN :oppIds AND IsClosed = FALSE
      ]
    );
  }

  // =============================================================================================
  // ========================= WRAPPER CLASSES ===================================================
  public class opportunitywrapperotm {
    public Opportunity opp { get; set; }
    public Set<String> existingotm { get; set; }
    public Set<String> newOTM { get; set; }
    public opportunitywrapperotm(Opportunity currentOpp, Set<String> eotm, Set<String> notm) {
      this.opp = currentOpp;
      this.existingotm = eotm;
      this.newOTM = notm;
    }
  }

  public class opportunitywrapperos {
    public Opportunity opp { get; set; }
    public Set<String> existingos { get; set; }
    public Set<String> newOS { get; set; }
    public opportunitywrapperos(Opportunity currentOpp, Set<String> eos, Set<String> nos) {
      this.opp = currentOpp;
      this.existingos = eos;
      this.newOS = nos;
    }
  }
  // ========================= END WRAPPER CLASSES ===============================================
  // =============================================================================================
}