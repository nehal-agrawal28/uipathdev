public class DataTeam_UpdateOwnerLeadQueueable implements Queueable {
  private Map<Id, Id> opps;
  private Map<Id, Id> leads;
  private String contentCSV;
  public DataTeam_UpdateOwnerLeadQueueable(Map<Id, Id> opps, Map<Id, Id> leads) {
    this.opps = opps;
    this.leads = leads;
    this.contentCSV = 'LEAD ID,NEW OWNER,SUCCESS/FAILURE\r\n';
  }
  public void execute(QueueableContext context) {
    List<Lead> leadList = [SELECT Id, OwnerId FROM Lead WHERE Id IN :leads.keySet()];
    List<Lead> leadToUpdate = new List<Lead>();
    for (Lead l : leadList) {
      if (l.OwnerId != leads.get(l.Id)) {
        l.OwnerId = leads.get(l.Id);
        leadToUpdate.add(l);
      }
    }

    DataBase.SaveResult[] srList = Database.update(leadToUpdate, false);
    for (Integer i = 0; i < srList.size(); i++) {
      Database.saveResult sr = srList[i];
      String newOwnerId = leads.get(sr.getId());
      if (sr.isSuccess()) {
        contentCSV += sr.getId() + ',' + newOwnerId + ',' + 'SUCCESS' + '\r\n';
      } else {
        contentCSV += leadToUpdate[i].Id + ',' + leads.get(leadToUpdate[i].Id) + ',' + 'FAILURE' + '\r\n';
      }
    }
    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
    mail.setToAddresses(new List<String>{ UserInfo.getUserEmail() });
    mail.setSubject('Lead Owner Update - Success/Error');
    mail.setHtmlBody('Lead Owner Update - Success/Error');

    Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
    attachment.setFileName('LeadsUpdateOwnerResult.csv');
    attachment.setBody(Blob.valueOf(contentCSV));
    mail.setFileAttachments(new List<Messaging.EmailFileAttachment>{ attachment });
    Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });

    if (opps != null && !opps.isEmpty())
      Id jobId = System.enqueueJob(new DataTeam_ReturnResultsQueueable(null, opps, null));
  }
}