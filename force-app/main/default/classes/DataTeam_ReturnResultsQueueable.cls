public class DataTeam_ReturnResultsQueueable implements Queueable {
  private Map<Id, Id> accounts;
  private Map<Id, Id> opps;
  private Map<Id, Id> leads;

  public DataTeam_ReturnResultsQueueable(Map<Id, Id> accounts, Map<Id, Id> opps, Map<Id, Id> leads) {
    this.accounts = accounts;
    this.opps = opps;
    this.leads = leads;
  }

  public void execute(QueueableContext context) {
    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
    mail.setToAddresses(new List<String>{ UserInfo.getUserEmail() });
    mail.setSubject('DataTeam App Owner Update - Success/Error');
    mail.setHtmlBody('DataTeam App Owner Update - Success/Error');

    List<Messaging.EmailFileAttachment> attachments = new List<Messaging.EmailFileAttachment>();

    String contentCSVAccounts = '';
    if (accounts != null && !accounts.isEmpty()) {
      contentCSVAccounts = 'ACCOUNT ID,NEW OWNER,SUCCESS/FAILURE\r\n';
      for (Account a : [SELECT Id, OwnerId FROM Account WHERE Id IN :accounts.keyset()]) {
        if (a.OwnerId != accounts.get(a.Id)) {
          contentCSVAccounts += a.Id + ',' + accounts.get(a.Id) + ',' + 'FAILURE' + '\r\n';
        }
      }
      Messaging.EmailFileAttachment attachmentAccount = new Messaging.EmailFileAttachment();
      attachmentAccount.setFileName('AccountsUpdateOwnerResult.csv');
      attachmentAccount.setBody(Blob.valueOf(contentCSVAccounts));
      attachments.add(attachmentAccount);
    }

    String contentCSVOpportunities = '';
    if (opps != null && !opps.isEmpty()) {
      contentCSVOpportunities = 'OPPORTUNITY ID,NEW OWNER,SUCCESS/FAILURE\r\n';
      for (Opportunity o : [
        SELECT Id, OwnerId, (SELECT Id FROM OpportunityTeamMembers WHERE TeamMemberRole = 'Opportunity Owner')
        FROM Opportunity
        WHERE Id IN :opps.keyset()
      ]) {
        if (o.OwnerId != opps.get(o.Id)) {
          contentCSVOpportunities += o.Id + ',' + opps.get(o.Id) + ',' + 'Owner was not updated' + '\r\n';
        } else {
          if ((o.OpportunityTeamMembers).isEmpty()) {
            contentCSVOpportunities +=
              o.Id +
              ',' +
              opps.get(o.Id) +
              ',' +
              'Opportunity Owner was not added as a Team Member' +
              '\r\n';
          } else {
            contentCSVOpportunities += o.Id + ',' + o.OwnerId + ',' + 'Owner was successfully updated' + '\r\n';
          }
        }
      }
      Messaging.EmailFileAttachment attachmentOpportunities = new Messaging.EmailFileAttachment();
      attachmentOpportunities.setFileName('OpportunitiesUpdateOwnerResults.csv');
      attachmentOpportunities.setBody(Blob.valueOf(contentCSVOpportunities));
      attachments.add(attachmentOpportunities);
    }

    String contentCSVLeads = '';
    if (leads != null && !leads.isEmpty()) {
      contentCSVLeads = 'LEAD ID,NEW OWNER,SUCCESS/FAILURE\r\n';
      for (Lead l : [SELECT Id, OwnerId FROM Lead WHERE Id IN :leads.keyset()]) {
        if (l.OwnerId != leads.get(l.Id)) {
          contentCSVLeads += l.Id + ',' + leads.get(l.Id) + ',' + 'FAILURE' + '\r\n';
        }
      }
      Messaging.EmailFileAttachment attachmentLeads = new Messaging.EmailFileAttachment();
      attachmentLeads.setFileName('LeadsUpdateOwnerResult.csv');
      attachmentLeads.setBody(Blob.valueOf(contentCSVLeads));
      attachments.add(attachmentLeads);
    }

    if (attachments.size() > 0) {
      mail.setFileAttachments(attachments);
      Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });
    }
  }
}