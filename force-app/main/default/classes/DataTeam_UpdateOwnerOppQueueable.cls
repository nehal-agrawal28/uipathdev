public class DataTeam_UpdateOwnerOppQueueable implements Queueable {
  private Map<Id, Id> opps = new Map<Id, Id>();
  private Map<Id, Id> leads = new Map<Id, Id>();
  private Boolean leadUpdate;
  private String contentCSV;
  public DataTeam_UpdateOwnerOppQueueable(Map<Id, Id> opps, Map<Id, Id> leads, Boolean l) {
    this.opps = opps;
    this.leads = leads;
    this.leadUpdate = l;
    this.contentCSV = 'OPPORTUNITY ID,NEW OWNER,SUCCESS/FAILURE\r\n';
  }
  public void execute(QueueableContext context) {
    System.debug('Start CPU Time===>' + Limits.getCpuTime());
    List<Opportunity> oppsToUpdate = new List<Opportunity>();

    for (Opportunity opp : [SELECT Id, OwnerId FROM Opportunity WHERE Id IN :opps.keySet() LIMIT 2000]) {
      if (opp.OwnerId != opps.get(opp.Id)) {
        opp.OwnerId = opps.get(opp.Id);
        oppsToUpdate.add(opp);
      }
    }
    if (oppsToUpdate.size() > 0) {
      update oppsToUpdate;

      /*DataBase.SaveResult[] srList = Database.update(oppsToUpdate, false);
      for (Integer i = 0; i < srList.size(); i++) {
        Database.saveResult sr = srList[i];
        String newOwnerId = opps.get(sr.getId());
        if (sr.isSuccess()) {
          contentCSV += sr.getId() + ',' + newOwnerId + ',' + 'SUCCESS' + '\r\n';
        } else {
          contentCSV += oppsToUpdate[i].Id + ',' + opps.get(oppsToUpdate[i].Id) + ',' + 'FAILURE' + '\r\n';
        }
      }
      system.debug(contentCSV);
      Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
      mail.setToAddresses(new List<String>{ UserInfo.getUserEmail() });
      mail.setSubject('Opportunity Owner Update - Success/Error');
      mail.setHtmlBody('Opportunity Owner Update - Success/Error');

      Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
      attachment.setFileName('OpportunitiesUpdateOwnerResult.csv');
      attachment.setBody(Blob.valueOf(contentCSV));
      mail.setFileAttachments(new List<Messaging.EmailFileAttachment>{ attachment });
      Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });*/
    }
    if (!Test.isRunningTest()) {
      Id jobId = System.enqueueJob(new DataTeam_AddOppOwnerTeamMemberQueueable(opps, leads, leadUpdate));
    }
  }
}