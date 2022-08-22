/* run batch =============================================================
   inserts, updates and deletes Team Members and Splits
==========================================================================*/

global class DataTeam_UpsertDeleteTeamAndSplitsBatch implements Database.Batchable<sObject>, Database.Stateful {
  private List<sObject> teamMembersOrSplits = new List<sObject>();
  private String SelectedOption;
  global String contentCSV;
  private String emailSubject;
  private String emailBody;
  private String fileName;

  global DataTeam_UpsertDeleteTeamAndSplitsBatch(
    String selOption,
    List<sObject> otmos,
    String emailSub,
    String emailBdy,
    String emailFileName
  ) {
    this.SelectedOption = selOption;
    this.emailSubject = emailSub;
    this.emailBody = emailBdy;
    this.fileName = emailFileName;
    this.teamMembersOrSplits = otmos;

    this.contentCSV = 'RECORD ID,OPPORTUNITY ID,USER ID, ROLE, PERCENTAGE, SUCCESS/FAILURE\r\n';
  }

  global Iterable<sObject> start(Database.BatchableContext BC) {
    return teamMembersOrSplits;
  }

  global void execute(Database.BatchableContext BC, List<sObject> scope) {
    if (SelectedOption == 'OpportunityTeamMembers') {
      List<OpportunityTeamMember> otmToUpsert = (List<OpportunityTeamMember>) scope;
      DataBase.UpsertResult[] srList = Database.upsert(otmToUpsert, false);
      for (Integer i = 0; i < srList.size(); i++) {
        Database.UpsertResult sr = srList[i];
        if (sr.isSuccess()) {
          contentCSV +=
            sr.getId() +
            ',' +
            otmToUpsert[i].OpportunityId +
            ',' +
            otmToUpsert[i].UserId +
            ',' +
            otmToUpsert[i].TeamMemberRole +
            ',' +
            ',SUCCESS' +
            '\r\n';
        } else {
          contentCSV +=
            otmToUpsert[i].Id +
            ',' +
            otmToUpsert[i].OpportunityId +
            ',' +
            otmToUpsert[i].UserId +
            ',' +
            otmToUpsert[i].TeamMemberRole +
            ',' +
            ',FAILURE' +
            '\r\n';
        }
      }
    }
    if (SelectedOption == 'OpportunityTeamMembersDelete' || SelectedOption == 'OpportunitysplitsDelete') {
      if (SelectedOption == 'OpportunityTeamMembersDelete') {
        List<OpportunityTeamMember> otmToDelete = (List<OpportunityTeamMember>) scope;
        DataBase.DeleteResult[] srList = Database.delete(otmToDelete, false);
        for (Integer i = 0; i < srList.size(); i++) {
          Database.DeleteResult sr = srList[i];
          if (sr.isSuccess()) {
            contentCSV +=
              sr.getId() +
              ',' +
              otmToDelete[i].OpportunityId +
              ',' +
              otmToDelete[i].UserId +
              ',' +
              otmToDelete[i].TeamMemberRole +
              ',' +
              ',SUCCESS' +
              '\r\n';
          } else {
            contentCSV +=
              otmToDelete[i].Id +
              ',' +
              otmToDelete[i].OpportunityId +
              ',' +
              otmToDelete[i].UserId +
              ',' +
              otmToDelete[i].TeamMemberRole +
              ',' +
              ',FAILURE' +
              '\r\n';
          }
        }
      }
    }

    if (SelectedOption == 'OpportunitysplitsDelete') {
      List<Opportunity_Split__c> osToDelete = (List<Opportunity_Split__c>) scope;
      DataBase.DeleteResult[] srList = Database.delete(osToDelete, false);
      for (Integer i = 0; i < srList.size(); i++) {
        Database.DeleteResult sr = srList[i];
        if (sr.isSuccess()) {
          contentCSV +=
            sr.getId() +
            ',' +
            osToDelete[i].Opportunity__c +
            ',' +
            osToDelete[i].User__c +
            ',' +
            osToDelete[i].Role__c +
            ',' +
            osToDelete[i].Percentage__c +
            ',SUCCESS' +
            '\r\n';
        } else {
          contentCSV +=
            ',' +
            osToDelete[i].Opportunity__c +
            ',' +
            osToDelete[i].User__c +
            ',' +
            osToDelete[i].Role__c +
            ',' +
            osToDelete[i].Percentage__c +
            ',FAILURE' +
            '\r\n';
        }
      }
    }
    if (SelectedOption == 'OpportunitysplitsInsert') {
      List<Opportunity_Split__c> osToInsert = (List<Opportunity_Split__c>) scope;
      DataBase.SaveResult[] srList = Database.insert(osToInsert, false);
      for (Integer i = 0; i < srList.size(); i++) {
        Database.SaveResult sr = srList[i];
        if (sr.isSuccess()) {
          contentCSV +=
            sr.getId() +
            ',' +
            osToInsert[i].Opportunity__c +
            ',' +
            osToInsert[i].User__c +
            ',' +
            osToInsert[i].Role__c +
            ',' +
            osToInsert[i].Percentage__c +
            ',SUCCESS' +
            '\r\n';
        } else {
          contentCSV +=
            ',' +
            osToInsert[i].Opportunity__c +
            ',' +
            osToInsert[i].User__c +
            ',' +
            osToInsert[i].Role__c +
            ',' +
            osToInsert[i].Percentage__c +
            ',FAILURE' +
            '\r\n';
        }
      }
    }
    if (SelectedOption == 'OpportunitysplitsUpdate') {
      List<Opportunity_Split__c> osToUpdate = (List<Opportunity_Split__c>) scope;
      DataBase.SaveResult[] srList = Database.update(osToUpdate, false);
      for (Integer i = 0; i < srList.size(); i++) {
        Database.saveResult sr = srList[i];
        if (sr.isSuccess()) {
          contentCSV +=
            sr.getId() +
            ',' +
            osToUpdate[i].Opportunity__c +
            ',' +
            osToUpdate[i].User__c +
            ',' +
            osToUpdate[i].Role__c +
            ',' +
            osToUpdate[i].Percentage__c +
            ',SUCCESS' +
            '\r\n';
        } else {
          contentCSV +=
            ',' +
            osToUpdate[i].Opportunity__c +
            ',' +
            osToUpdate[i].User__c +
            ',' +
            osToUpdate[i].Role__c +
            ',' +
            osToUpdate[i].Percentage__c +
            ',FAILURE' +
            '\r\n';
        }
      }
    }
  }

  global void finish(Database.BatchableContext BC) {
    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
    mail.setToAddresses(new List<String>{ UserInfo.getUserEmail() });
    mail.setSubject(emailSubject);
    mail.setHtmlBody(emailBody);

    Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
    attachment.setFileName(fileName);
    attachment.setBody(Blob.valueOf(contentCSV));
    mail.setFileAttachments(new List<Messaging.EmailFileAttachment>{ attachment });
    Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });
  }
}