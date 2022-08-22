/**
 * Allows Approval Rule generation to be triggere Async via the Schedulable and Batchable interfaces
 * 1.0 Girish Lakshmanan 23/08/2019 Initial Version
 *
 * @author Girish Lakshmanan
 * @date 23/08/2019
 *
 */

global with sharing class CreateApprovalRulesJob implements System.Schedulable, Database.Batchable<SObject>, Database.Stateful {
  Boolean includeProcessedRecords = false;

  public CreateApprovalRulesJob(Boolean includeProcessedRecords) {
    this.includeProcessedRecords = includeProcessedRecords;
  }

  public CreateApprovalRulesJob() {
  }

  // Simple job log for errors
  private List<JobError> jobErrors = new List<JobError>();

  global void execute(SchedulableContext sc) {
    // Start the job once the scheduled time has arrived
    Database.executeBatch(new CreateApprovalRulesJob());
  }

  public Database.QueryLocator start(Database.BatchableContext context) {
    if (includeProcessedRecords) {
      return ApprovalMatrix.getQueryLocator(new List<String>{ 'Pending', 'Processed', 'Error' });
    } else {
      return ApprovalMatrix.getQueryLocator(new List<String>{ 'Pending', 'Error' });
    }
  }

  public void execute(Database.BatchableContext context, List<ApprovalRuleMatrix__c> matrixRecords) {
    try {
      Set<Id> matrixRecordIds = new Map<Id, SObject>(matrixRecords).keySet();

      ApprovalRuleServiceFactory.generate(new List<Id>(matrixRecordIds));

      for (ApprovalRuleMatrix__c matrixRecord : matrixRecords) {
        matrixRecord.SyncStatus__c = 'Processed';
      }

      update matrixRecords;
    } catch (Exception e) {
      // Capture context and error for reporting once job complete
      JobError jobError = new JobError();
      jobError.records = matrixRecords;
      jobError.message = e.getMessage();
      jobErrors.add(jobError);
    }
  }

  public void finish(Database.BatchableContext context) {
    for (JobError jobError : jobErrors) {
      for (ApprovalRuleMatrix__c matrixRecord : jobError.records) {
        matrixRecord.SyncStatus__c = 'Error';
      }
      update jobError.records;
    }

    // Simple notifiation of any errors received via email
    if (jobErrors.size() > 0) {
      // Email address from user
      Map<Id, User> user = new Map<Id, User>([SELECT Id, email FROM user WHERE Id = :UserInFo.getUserId()]);

      // Construct email body
      String emailBody = '';
      for (JobError jobError : jobErrors) {
        List<String> failedMatrixRecords = new List<String>();
        for (ApprovalRuleMatrix__c matrixRecord : jobError.records)
          failedMatrixRecords.add(matrixRecord.Name);
        emailBody += String.format(
          '<p>Error {0} occured during the processing of Matrix Records {1}</p>',
          new List<String>{ jobError.message, String.join(failedMatrixRecords, ',') }
        );
      }
      // Send email
      Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
      mail.setToAddresses(new List<String>{ user.get(UserInfo.getUserId()).Email });
      mail.setReplyTo(user.get(UserInfo.getUserId()).Email);
      mail.setSenderDisplayName(userInfo.getUserName());
      mail.setSubject('Create Approval Rule Job Failures');
      mail.setHtmlBody(emailBody);

      try {
        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });
      } catch (Exception e) {
        System.debug('CreateApprovalRulesJob finish exception ==> ' + e);
      }
    }
  }

  /**
   * Simple wrapper class containing the error message and the records in scope at the time
   **/
  public class JobError {
    public String message;
    public List<ApprovalRuleMatrix__c> records;
  }
}