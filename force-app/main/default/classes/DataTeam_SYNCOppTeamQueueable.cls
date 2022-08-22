public class DataTeam_SYNCOppTeamQueueable implements Queueable {
  private Map<String, List<String>> oppExistingTeamMembersMap = new Map<String, List<String>>();
  private Map<String, List<String>> oppShouldBeTeamMembersMap = new Map<String, List<String>>();
  private Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>();
  private Map<String, OpportunityTeamMember> allOTMMap = new Map<String, OpportunityTeamMember>();
  private Set<String> oppsToSync = new Set<String>();
  private Set<String> oppsTMToAdd = new Set<String>();
  private String contentCSVInsert;
  private String contentCSVDelete;

  public DataTeam_SYNCOppTeamQueueable(
    Map<String, List<String>> existingTeam,
    Map<String, List<String>> shouldbeBeTeam,
    Map<Id, Opportunity> opptyMap,
    Map<String, OpportunityTeamMember> allOTMMap,
    Set<String> oppsToSync,
    Set<String> oppsTMToAdd
  ) {
    this.oppExistingTeamMembersMap = existingTeam;
    this.oppShouldBeTeamMembersMap = shouldbeBeTeam;
    this.oppMap = opptyMap;
    this.allOTMMap = allOTMMap;
    this.oppsToSync = oppsToSync;
    this.oppsTMToAdd = oppsTMToAdd;
    this.contentCSVInsert = 'RECORD ID,OPPORTUNITY ID,USER ID,TEAM MEMBER ROLE,SUCCESS/FAILURE\r\n';
    this.contentCSVDelete = 'RECORD ID,OPPORTUNITY ID,USER ID,TEAM MEMBER ROLE,SUCCESS/FAILURE\r\n';
  }
  public void execute(QueueableContext context) {
    Set<String> exAccTeamMemberSet = new Set<String>();
    Set<String> oppAccTeamMemberSet = new Set<String>();
    for (Id oppId : oppMap.keySet()) {
      for (String s : oppExistingTeamMembersMap.get(String.valueOf(oppId))) {
        if (
          s.contains('Opportunity Owner') ||
          s.contains('Key Account Manager') ||
          s.contains('Partner Account Manager')
        )
          exAccTeamMemberSet.add(s);
      }
      for (String s : oppShouldBeTeamMembersMap.get(String.valueOf(oppId))) {
        if (
          s.contains('Opportunity Owner') ||
          s.contains('Key Account Manager') ||
          s.contains('Partner Account Manager')
        )
          oppAccTeamMemberSet.add(s);
      }
    }
    DataTeam_SyncTeamMemberSplits syncRec = new DataTeam_SyncTeamMemberSplits();
    Map<String, Set<String>> allRecordsMap = syncRec.compareSets(exAccTeamMemberSet, oppAccTeamMemberSet);

    List<OpportunityTeamMember> otmToDelete = new List<OpportunityTeamMember>();
    List<OpportunityTeamMember> otmToInsert = new List<OpportunityTeamMember>();

    for (String s : allRecordsMap.keySet()) {
      Set<String> str = allRecordsMap.get(s);
      if (s == 'ToInsert') {
        for (String sOs : str) {
          String[] recFields = sOs.split('-');
          OpportunityTeamMember newOTMRecord = new OpportunityTeamMember();
          newOTMRecord.OpportunityID = recFields[0];
          newOTMRecord.UserID = recFields[1];
          newOTMRecord.TeamMemberRole = recFields[2];
          newOTMRecord.Created_on_opportunity_insert__c = true;
          otmToInsert.add(newOTMRecord);
        }
      }

      if (s == 'ToDelete') {
        for (String sOs : str) {
          otmToDelete.add(allOTMMap.get(sOs));
        }
      }
    }

    if (otmToDelete.size() > 0) {
      DataBase.deleteResult[] srList = Database.delete(otmToDelete, false);
      for (Integer i = 0; i < srList.size(); i++) {
        Database.deleteResult sr = srList[i];
        String mapKey =
          otmToDelete[i].OpportunityId +
          '-' +
          otmToDelete[i].UserId +
          '-' +
          otmToDelete[i].TeamMemberRole;
        OpportunityTeamMember otm = allOTMMap.get(mapKey);
        if (sr.isSuccess()) {
          contentCSVDelete +=
            sr.getId() +
            ',' +
            otm.OpportunityId +
            ',' +
            otm.UserId +
            ',' +
            otm.TeamMemberRole +
            ',SUCCESS' +
            '\r\n';
        } else {
          contentCSVDelete +=
            otmToDelete[i].Id +
            ',' +
            otm.OpportunityId +
            +',' +
            otm.UserId +
            ',' +
            otm.TeamMemberRole +
            ',FAILURE' +
            '\r\n';
        }
      }
    }

    if (otmToInsert.size() > 0) {
      DataBase.saveResult[] srList = Database.insert(otmToInsert, false);
      for (Integer i = 0; i < srList.size(); i++) {
        Database.saveResult sr = srList[i];
        if (sr.isSuccess()) {
          contentCSVInsert +=
            sr.getId() +
            ',' +
            otmToInsert[i].OpportunityId +
            ',' +
            otmToInsert[i].UserId +
            ',' +
            otmToInsert[i].TeamMemberRole +
            ',' +
            'SUCCESS' +
            '\r\n';
        } else {
          contentCSVInsert +=
            otmToInsert[i].Id +
            ',' +
            otmToInsert[i].OpportunityId +
            ',' +
            otmToInsert[i].UserId +
            '-' +
            otmToInsert[i].TeamMemberRole +
            '-' +
            'FAILURE' +
            '\r\n';
        }
      }
    }

    Map<String, List<OpportunityTeamMember>> existingOTMMap = syncRec.populateOpportunityTeamList(oppsToSync);
    Map<String, List<Opportunity_Split__c>> existingOSMap = syncRec.populateOppSplitsList(oppsToSync);

    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
    mail.setToAddresses(new List<String>{ UserInfo.getUserEmail() });
    mail.setSubject('Sync Opp Related Team Members - Success/Error');
    mail.setHtmlBody('Sync Opp Related Team Members - Success/Error');

    Messaging.EmailFileAttachment attachmentInsert = new Messaging.EmailFileAttachment();
    attachmentInsert.setFileName('TeamMemberInsertResult.csv');
    attachmentInsert.setBody(Blob.valueOf(contentCSVInsert));

    Messaging.EmailFileAttachment attachmentDelete = new Messaging.EmailFileAttachment();
    attachmentDelete.setFileName('TeamMemberDeleteResult.csv');
    attachmentDelete.setBody(Blob.valueOf(contentCSVDelete));

    mail.setFileAttachments(new List<Messaging.EmailFileAttachment>{ attachmentInsert, attachmentDelete });
    Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });

    if (!Test.isRunningTest()) {
      Id jobId = System.enqueueJob(
        new DataTeam_SYNCOppSplitsQueueable(existingOTMMap, existingOSMap, oppMap, allOTMMap, oppsToSync, oppsTMToAdd)
      );
    }
  }
}