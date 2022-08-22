public class DataTeam_SYNCAddTeamMembersQueueable implements Queueable {
  private Set<String> oppsTMToAdd = new Set<String>();
  private Map<String, OpportunityTeamMember> allOTMMap = new Map<String, OpportunityTeamMember>();
  private String contentCSVInsert;

  public DataTeam_SYNCAddTeamMembersQueueable(Set<String> oppsTMToAdd, Map<String, OpportunityTeamMember> allOTMMap) {
    this.oppsTMToAdd = oppsTMToAdd;
    this.allOTMMap = allOTMMap;
    this.contentCSVInsert = 'RECORD ID,OPPORTUNITY ID,USER ID,TEAM MEMBER ROLE,SUCCESS/FAILURE\r\n';
  }
  public void execute(QueueableContext context) {
    List<OpportunityTeamMember> otmToInsert = new List<OpportunityTeamMember>();
    for (String s : oppsTMToAdd) {
      List<String> newTM = s.split('-');
      if (newTM.size() == 3) {
        OpportunityTeamMember otm = new OpportunityTeamMember();
        otm.OpportunityId = newTM[0];
        otm.UserId = newTM[1];
        otm.TeamMemberRole = newTM[2];
        otmToInsert.add(otm);
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
            ',' +
            otmToInsert[i].OpportunityId +
            ',' +
            otmToInsert[i].UserId +
            ',' +
            otmToInsert[i].TeamMemberRole +
            '-' +
            'FAILURE' +
            '\r\n';
        }
      }
    }

    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
    mail.setToAddresses(new List<String>{ UserInfo.getUserEmail() });
    mail.setSubject('Add New Team Members - Success/Error');
    mail.setHtmlBody('Add New Team Members - Success/Error');

    Messaging.EmailFileAttachment attachmentInsert = new Messaging.EmailFileAttachment();
    attachmentInsert.setFileName('OppTeamMembersInsertResult.csv');
    attachmentInsert.setBody(Blob.valueOf(contentCSVInsert));
    mail.setFileAttachments(new List<Messaging.EmailFileAttachment>{ attachmentInsert });
    Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });
  }
}