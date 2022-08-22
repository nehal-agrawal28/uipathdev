/**
 * Batch job to force Quote Re-Calculation
 * 1.0 -- 23/03/2020 Initial Version
 *
 * --
 * @date  23/03/2020
 *
 */

global with sharing class CPQTriggerQuoteRecalculationJob implements Database.Batchable<SObject>, Database.Stateful {
  private List<String> statusesToInclude;
  private Date fromDate;
  private Date toDate;
  // Simple job log for errors
  private List<JobError> batchErrors = new List<JobError>();

  public CPQTriggerQuoteRecalculationJob(List<String> statusesToInclude, Date fromDate, Date toDate) {
    this.statusesToInclude = statusesToInclude;
    this.fromDate = fromDate;
    this.toDate = toDate;
  }

  public CPQTriggerQuoteRecalculationJob() {
  }

  public Database.QueryLocator start(Database.BatchableContext context) {
    return this.getQueryLocator(statusesToInclude, fromDate, toDate);
  }

  public void execute(Database.BatchableContext context, List<SBQQ__Quote__c> quoteRecords) {
    try {
      Set<Id> quoteRecordIds = new Map<Id, SObject>(quoteRecords).keySet();

      for (SBQQ__Quote__c quoteRecord : quoteRecords) {
        quoteRecord.Forced_Recalc_Date__c = System.now();
      }

      update quoteRecords;
    } catch (Exception e) {
      // Capture context and error for reporting once job complete
      JobError batchError = new JobError();
      batchError.records = quoteRecords;
      batchError.message = e.getMessage();
      batchErrors.add(batchError);
    }
  }

  public void finish(Database.BatchableContext context) {
    // Simple notifiation of any errors received via email
    if (batchErrors.size() > 0) {
      this.processErrors(batchErrors);
    }
  }

  /**
   * Send an Email with a list of all the errors during processing
   *
   * @param jobErrors
   */
  public void processErrors(List<JobError> jobErrors) {
    // Simple notifiation of any errors received via email
    if (jobErrors.size() > 0) {
      // Email address from user
      Map<Id, User> user = new Map<Id, User>([SELECT Id, Email FROM User WHERE Id = :UserInFo.getUserId()]);

      // Construct email body
      String emailBody = '';
      for (JobError jobError : jobErrors) {
        List<String> failedQuoteRecords = new List<String>();
        for (SBQQ__Quote__c quoteRecord : jobError.records)
          failedQuoteRecords.add(quoteRecord.Name);
        emailBody += String.format(
          '<p>Error {0} occured while attempting to re-trigger  Recalculation of Quote Records {1}</p>',
          new List<String>{ jobError.message, String.join(failedQuoteRecords, ',') }
        );
      }
      // Send email
      Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
      mail.setToAddresses(new List<String>{ user.get(UserInfo.getUserId()).Email });
      mail.setReplyTo(user.get(UserInfo.getUserId()).Email);
      mail.setSenderDisplayName(userInfo.getUserName());
      mail.setSubject('Quote Re-calculation Failures');
      mail.setHtmlBody(emailBody);
      try {
        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });
      } catch (EmailException e) {
        System.debug(LoggingLevel.ERROR, 'EmailException: ' + e.getMessage());
      }
    }
  }

  /**
   * Get Query Locator for picking up eligible Quotes for triggering recalculation
   *
   * @return
   */
  public Database.QueryLocator getQueryLocator(List<String> statuses, Date fromDate, Date toDate) {
    String query = 'SELECT ';
    query +=
      'Id, ' +
      'Forced_Recalc_Date__c ' +
      'FROM SBQQ__Quote__c ' +
      'WHERE SBQQ__Opportunity2__r.StageName in :statuses' +
      ' AND SBQQ__Opportunity2__r.CloseDate >= :fromDate ' +
      ' AND SBQQ__Opportunity2__r.CloseDate <= :toDate';

    return Database.getQueryLocator(query);
  }

  /**
   * Simple wrapper class containing the error message and the records in scope at the time
   **/
  public class JobError {
    public String message;
    public List<SBQQ__Quote__c> records;
    public JobError() {
    }
    public JobError(String message, List<SBQQ__Quote__c> records) {
      this.message = message;
      this.records = records;
    }
  }

  public void setBatchErrors(List<JobError> jobErrors) {
    this.batchErrors = jobErrors;
  }
}