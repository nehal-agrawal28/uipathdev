public class DataTeam_UpdateOwnerAccountQueueable implements Queueable {
  private Map<Id, Id> accounts;
  private Map<Id, Id> opps;
  private Map<Id, Id> leads;
  private Boolean oppUpdate;
  private Boolean leadUpdate;
  private String contentCSV;

  public DataTeam_UpdateOwnerAccountQueueable(
    Map<Id, Id> accounts,
    Map<Id, Id> opps,
    Map<Id, Id> leads,
    Boolean o,
    Boolean l
  ) {
    this.accounts = accounts;
    this.opps = opps;
    this.leads = leads;
    this.oppUpdate = o;
    this.leadUpdate = l;
    this.contentCSV = 'ACCOUNT ID,NEW OWNER,SUCCESS/FAILURE\r\n';
  }

  public void execute(QueueableContext context) {
    List<Account> accountList = [SELECT Id, OwnerId FROM Account WHERE Id IN :accounts.keyset()];
    List<Account> accToUpdate = new List<Account>();
    for (Account a : accountList) {
      if (a.OwnerId != accounts.get(a.Id)) {
        a.OwnerId = accounts.get(a.Id);
        accToUpdate.add(a);
      }
    }

    DataBase.SaveResult[] srList = Database.update(accToUpdate, false);
    for (Integer i = 0; i < srList.size(); i++) {
      Database.saveResult sr = srList[i];
      String newOwnerId = accounts.get(sr.getId());
      if (sr.isSuccess()) {
        contentCSV += sr.getId() + ',' + newOwnerId + ',' + 'SUCCESS' + '\r\n';
      } else {
        contentCSV += accToUpdate[i].Id + ',' + accounts.get(accToUpdate[i].Id) + ',' + 'FAILURE' + '\r\n';
      }
    }
    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
    mail.setToAddresses(new List<String>{ UserInfo.getUserEmail() });
    mail.setSubject('Account Owner Update - Success/Error');
    mail.setHtmlBody('Account Owner Update - Success/Error');

    Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
    attachment.setFileName('AccountsUpdateOwnerResult.csv');
    attachment.setBody(Blob.valueOf(contentCSV));
    mail.setFileAttachments(new List<Messaging.EmailFileAttachment>{ attachment });
    Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });

    if (oppUpdate == true && !Test.isRunningTest()) {
      System.enqueueJob(new DataTeam_DeleteTMOSQueueable(accounts, opps, leads, oppUpdate, leadUpdate));
    }

    if (oppUpdate == false && leadUpdate == true && !Test.isRunningTest()) {
      System.enqueueJob(new DataTeam_UpdateOwnerLeadQueueable(null, leads));
    }
  }
}