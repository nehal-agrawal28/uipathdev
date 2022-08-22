public class DataTeam_SYNCOppSplitsQueueable implements Queueable {
  private Map<String, List<OpportunityTeamMember>> existingOTMMap = new Map<String, List<OpportunityTeamMember>>();
  private Map<String, List<Opportunity_Split__c>> existingOSMap = new Map<String, List<Opportunity_Split__c>>();
  private Map<String, OpportunityTeamMember> allOTMMap = new Map<String, OpportunityTeamMember>();
  private Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>();
  private Set<String> oppsToSync = new Set<String>();
  private Set<String> oppsTMToAdd = new Set<String>();
  private String contentCSVInsert;
  private String contentCSVDelete;

  public DataTeam_SYNCOppSplitsQueueable(
    Map<String, List<OpportunityTeamMember>> existingOTMMap,
    Map<String, List<Opportunity_Split__c>> existingOSMap,
    Map<Id, Opportunity> opptyMap,
    Map<String, OpportunityTeamMember> allOTMMap,
    Set<String> oppsToSync,
    Set<String> oppsTMToAdd
  ) {
    this.existingOTMMap = existingOTMMap;
    this.existingOSMap = existingOSMap;
    this.oppMap = opptyMap;
    this.oppsToSync = oppsToSync;
    this.oppsTMToAdd = oppsTMToAdd;
    this.allOTMMap = allOTMMap;
    this.contentCSVInsert = 'OPP SPLIT ID,OPPORTUNITY ID,USER ID,TEAM MEMBER ROLE,SUCCESS/FAILURE\r\n';
    this.contentCSVDelete = 'OPP SPLIT ID,OPPORTUNITY ID,USER ID,TEAM MEMBER ROLE,SUCCESS/FAILURE\r\n';
  }
  public void execute(QueueableContext context) {
    DataTeam_SyncTeamMemberSplits syncRec = new DataTeam_SyncTeamMemberSplits();
    Map<String, Opportunity_Split__c> osRecordMap = syncRec.getOSRecordAsMap(existingOSMap);
    Set<String> OpportunityTeamMemberSet = syncRec.getOTMRecordsAsSet(existingOTMMap, oppMap);

    List<Opportunity_Split__c> osToInsert = new List<Opportunity_Split__c>();
    List<Opportunity_Split__c> osToDelete = new List<Opportunity_Split__c>();

    Map<String, Set<String>> allRecordsMap = syncRec.compareSets(osRecordMap.keySet(), OpportunityTeamMemberSet);
    Map<String, Decimal> AvailableRoles = syncRec.AvailableTeamMemberRoles();
    for (String s : allRecordsMap.keySet()) {
      Set<String> str = allRecordsMap.get(s);
      if (s == 'ToInsert') {
        for (String sOs : str) {
          String[] recFields = sOs.split('-');
          Opportunity o = oppMap.get(recFields[0]);
          if (recFields[2] != 'Partner Account Manager') {
            Opportunity_Split__c newOSRecord = new Opportunity_Split__c();
            newOSRecord.Opportunity__c = recFields[0];
            newOSRecord.User__c = recFields[1];
            newOSRecord.Role__c = recFields[2];
            newOSRecord.Percentage__c = AvailableRoles.get(recFields[2]);
            osToInsert.add(newOSRecord);
          } else {
            if (o.Account.Geo__c != 'EMEA' && o.Account.Geo__c != 'AMER' && o.Account.Area__c != 'Japan') {
              Opportunity_Split__c newOSRecord = new Opportunity_Split__c();
              newOSRecord.Opportunity__c = recFields[0];
              newOSRecord.User__c = recFields[1];
              newOSRecord.Role__c = recFields[2];
              newOSRecord.Percentage__c = AvailableRoles.get(recFields[2]);
              osToInsert.add(newOSRecord);
            }
          }
        }
      }

      if (s == 'ToDelete') {
        for (String osStr : allRecordsMap.get(s))
          osToDelete.add(osRecordMap.get(osStr));
      }
    }
    if (osToInsert.size() > 0) {
      DataBase.saveResult[] srList = Database.insert(osToInsert, false);
      for (Integer i = 0; i < srList.size(); i++) {
        Database.saveResult sr = srList[i];
        Opportunity_Split__c os = osRecordMap.get(sr.getId());
        if (sr.isSuccess()) {
          contentCSVInsert += sr.getId() + ',,,,' + 'SUCCESS' + '\r\n';
        } else {
          contentCSVInsert +=
            osRecordMap.get(osToInsert[i].Id).Opportunity__c +
            ',' +
            osRecordMap.get(osToInsert[i].Id).User__c +
            ',' +
            osRecordMap.get(osToInsert[i].Id).Role__c +
            '-' +
            'FAILURE' +
            '\r\n';
        }
      }
    }

    if (osToDelete.size() > 0) {
      DataBase.deleteResult[] srList = Database.delete(osToDelete, false);
      for (Integer i = 0; i < srList.size(); i++) {
        Database.deleteResult sr = srList[i];
        String mapKey = osToDelete[i].Opportunity__c + '-' + osToDelete[i].User__c + '-' + osToDelete[i].Role__c;
        Opportunity_Split__c os = osRecordMap.get(mapKey);
        if (sr.isSuccess()) {
          contentCSVDelete +=
            sr.getId() +
            ',' +
            os.Opportunity__c +
            ',' +
            os.User__c +
            ',' +
            os.Role__c +
            ',' +
            'SUCCESS' +
            '\r\n';
        } else {
          contentCSVDelete +=
            osToDelete[i].Id +
            ',' +
            osToDelete[i].Opportunity__c +
            ',' +
            osToDelete[i].User__c +
            '-' +
            osToDelete[i].Role__c +
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
    mail.setSubject('Sync Opp Related Splits - Success/Error');
    mail.setHtmlBody('Sync Opp Related Splits - Success/Error');

    Messaging.EmailFileAttachment attachmentInsert = new Messaging.EmailFileAttachment();
    attachmentInsert.setFileName('OppSplitsInsertResult.csv');
    attachmentInsert.setBody(Blob.valueOf(contentCSVInsert));

    Messaging.EmailFileAttachment attachmentDelete = new Messaging.EmailFileAttachment();
    attachmentDelete.setFileName('OppSplitsDeleteResult.csv');
    attachmentDelete.setBody(Blob.valueOf(contentCSVDelete));

    mail.setFileAttachments(new List<Messaging.EmailFileAttachment>{ attachmentInsert, attachmentDelete });
    Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });

    if (oppsTMToAdd.size() > 0 && !Test.isRunningTest()) {
      Id jobId = System.enqueueJob(new DataTeam_SYNCAddTeamMembersQueueable(oppsTMToAdd, allOTMMap));
    }
  }
}