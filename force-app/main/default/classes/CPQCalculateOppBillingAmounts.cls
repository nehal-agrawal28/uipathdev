/**
 * This is a Temp workaround batch job to populate Period1_Amount on Opp to allow for reporting on year 1 billings
 * This will eventually be replaced by a more strategic solutiom
 * 1.0 Salestech 11/12/2020 Initial Version
 *
 * @author Salestech
 * @date  11/12/2020
 *
 */

global with sharing class CPQCalculateOppBillingAmounts implements Database.Batchable<SObject>, Database.Stateful, Schedulable {
  private String originalTransactionId;
  // Simple job log for errors
  private List<JobError> batchErrors = new List<JobError>();
  public enum CalculationType {
    HAS_SEGMENT,
    NO_SEGMENT
  }
  private CalculationType calcType;
  public Boolean errorEmailSent = false;

  //Optional Custom SOQL selecting from Opportunity and must have Id,Amount,SBQQ__PrimaryQuote__c in the Select List
  //If none is provided, the batch processes all Opps updated in the last 1 day processes
  public String customOppSOQL;

  public CPQCalculateOppBillingAmounts(CalculationType calcType) {
    this.calcType = calcType;
  }

  public CPQCalculateOppBillingAmounts() {
  }

  public Database.QueryLocator start(Database.BatchableContext context) {
    // Storing transaction Id for Logging purposes
    this.originalTransactionId = Logger.getTransactionId();
    Logger.info('Starting CPQCalculateOppBillingAmounts Batch');
    Logger.saveLog();

    if (customOppSOQL != null) {
      return Database.getQueryLocator(customOppSOQL);
    }

    return this.getQueryLocator(calcType);
  }

  public void execute(Database.BatchableContext context, List<Opportunity> opportunities) {
    try {
      Logger.setParentLogTransactionId(this.originalTransactionId);
      List<Opportunity> updatedOpps = new List<Opportunity>();
      List<Billing_Segment__c> updatedSegments = new List<Billing_Segment__c>();

      switch on calcType {
        when NO_SEGMENT {
          for (Opportunity opp : opportunities) {
            Decimal oppAmount = opp.Amount != null ? opp.Amount.setScale(2, System.RoundingMode.HALF_UP) : null;
            if (opp.Period1_Billing_Amount__c != oppAmount) {
              Logger.info(
                'Period1BillingAmount updated from ' +
                opp.Period1_Billing_Amount__c +
                ' to ' +
                opp.Amount,
                opp.Id
              );
              opp.Period1_Billing_Amount__c = opp.Amount;
              updatedOpps.add(opp);
            }
          }
        }
        /**
         * when the Primary Quote has segments, then the Period 1 Amount is taken from the 1st segment
         */
        when HAS_SEGMENT {
          List<Id> quoteIds = Collection.of(opportunities).pluckIds(Opportunity.SBQQ__PrimaryQuote__c);
          List<Billing_Segment__c> firstBillingSegments = getFirstBillingSegments(quoteIds);

          Map<Id, List<SObject>> segmentsByQuotes = Collection.of(firstBillingSegments)
            .groupByIds(Billing_Segment__c.Quote__c);

          for (Opportunity opp : opportunities) {
            if (segmentsByQuotes.get(opp.SBQQ__PrimaryQuote__c) != null) {
              Billing_Segment__c firstPeriodSegment = (Billing_Segment__c) segmentsByQuotes.get(
                  opp.SBQQ__PrimaryQuote__c
                )
                .get(0);

              Decimal firstSegAmount = firstPeriodSegment.Total_Amount__c != null
                ? firstPeriodSegment.Total_Amount__c.setScale(2, System.RoundingMode.HALF_UP)
                : null;
              if (opp.Period1_Billing_Amount__c != firstSegAmount) {
                Logger.info(
                  'Period1BillingAmount updated from ' +
                  opp.Period1_Billing_Amount__c +
                  ' to ' +
                  firstPeriodSegment.Total_Amount__c,
                  opp.Id
                );
                opp.Period1_Billing_Amount__c = firstPeriodSegment.Total_Amount__c;
                updatedOpps.add(opp);
              }
              if (opp.CloseDate != firstPeriodSegment.Reporting_Date__c) {
                Logger.info(
                  'First Billing Segment ' +
                  firstPeriodSegment.Id +
                  ' ReportingDate updated from ' +
                  firstPeriodSegment.Reporting_Date__c +
                  ' to ' +
                  opp.CloseDate,
                  opp.Id
                );
                firstPeriodSegment.Reporting_Date__c = opp.CloseDate;
                updatedSegments.add(firstPeriodSegment);
              }
            }
          }
          update updatedSegments;
        }
      }
      update updatedOpps;

      // Logging only when something was updated
      if (updatedSegments.size() > 0 || updatedOpps.size() > 0) {
        Logger.saveLog();
      }
    } catch (Exception e) {
      // Capture context and error for reporting once job complete
      errorEmailSent = false;
      System.debug(LoggingLevel.ERROR, 'ERROR: CPQCalculateOppBillingAmountsException' + e.getMessage());
      JobError batchError = new JobError();
      batchError.records = opportunities;
      batchError.message = e.getMessage();
      batchErrors.add(batchError);

      // Logging exceptions against records
      for (Opportunity opp : opportunities) {
        Logger.error('Error in CPQCalculateOppBillingAmounts Batch', opp.Id, e);
      }
      Logger.saveLog();
    }
  }

  private List<Billing_Segment__c> getFirstBillingSegments(List<Id> quoteIds) {
    List<Billing_Segment__c> firstBillingSegments = [
      SELECT Id, Quote__c, Total_Amount__c, Reporting_Date__c
      FROM Billing_Segment__c
      WHERE Segment_No__c = 1.0 AND Quote__c != NULL AND Quote__c IN :quoteIds
    ];
    return firstBillingSegments;
  }

  public void finish(Database.BatchableContext context) {
    Logger.setParentLogTransactionId(this.originalTransactionId);
    Logger.info('Finishing CPQCalculateOppBillingAmounts Batch');
    // Simple notifiation of any errors received via email
    if (batchErrors.size() > 0) {
      this.processErrors(batchErrors);
    }
    Logger.saveLog();
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
        List<String> failedOppRecords = new List<String>();
        for (Opportunity opp : jobError.records) {
          failedOppRecords.add(opp.Name + '(' + opp.Id + ')');
        }
        emailBody += String.format(
          '<p>Error {0} occured while calculating billing amounts for Opp {1}</p>',
          new List<String>{ jobError.message, String.join(failedOppRecords, ',') }
        );
      }

      // Send email
      Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
      mail.setToAddresses(new List<String>{ user.get(UserInfo.getUserId()).Email });
      mail.setReplyTo(user.get(UserInfo.getUserId()).Email);
      mail.setSenderDisplayName(userInfo.getUserName());
      mail.setSubject('Opportunity Periodic amount calculation failures');
      mail.setHtmlBody(emailBody);
      try {
        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });
        errorEmailSent = true;
      } catch (EmailException e) {
        Logger.error('Error in sending Email from CPQCalculateOppBillingAmounts.processErrors', e);
        System.debug(LoggingLevel.ERROR, 'EmailException: ' + e.getMessage());
      }
    }
  }

  /**
   * Get Query Locator for picking up eligible Opps
   *
   * @return
   */
  public Database.QueryLocator getQueryLocator(CalculationType calcType) {
    // Salesforce stores date in GMT
    String Last5Hours = System.now().addHours(-5).formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
    String query =
      'SELECT Id,Name,CloseDate,Amount,SBQQ__PrimaryQuote__c,Period1_Billing_Amount__c\n' +
      'FROM Opportunity\n' +
      'WHERE Period1_Billing_Amount_Override__c = false \n' +
      'AND (LastModifiedDate > ' +
      Last5Hours +
      ' OR SBQQ__PrimaryQuote__r.LastModifiedDate > ' +
      Last5Hours +
      ') \n';

    switch on calcType {
      when NO_SEGMENT {
        query = query + ' AND SBQQ__PrimaryQuote__c NOT IN (SELECT Quote__c FROM Billing_Segment__c)';
      }
      when HAS_SEGMENT {
        query = query + ' AND SBQQ__PrimaryQuote__c IN (SELECT Quote__c FROM Billing_Segment__c)';
      }
    }
    return Database.getQueryLocator(query);
  }

  /**
   * Simple wrapper class containing the error message and the records in scope at the time
   **/
  public class JobError {
    public String message;
    public List<Opportunity> records;
    public JobError() {
    }
    public JobError(String message, List<Opportunity> records) {
      this.message = message;
      this.records = records;
    }
  }

  public void setBatchErrors(List<JobError> jobErrors) {
    this.batchErrors = jobErrors;
  }

  public static CPQCalculateOppBillingAmounts schedule(CalculationType calculationType) {
    return new CPQCalculateOppBillingAmounts(calculationType);
  }

  /**
   * @param context Schedule the batch with a size of 1
   */
  global void execute(SchedulableContext context) {
    // Database.executeBatch(this,1);
    Database.executeBatch(this, 2);
  }
}