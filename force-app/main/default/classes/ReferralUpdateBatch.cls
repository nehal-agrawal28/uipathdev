public without sharing class ReferralUpdateBatch implements Database.Batchable<sObject>, Schedulable, Database.Stateful {
  private String originalTransactionId;

  public ReferralUpdateBatch() {
  }

  public Database.QueryLocator start(Database.BatchableContext context) {
    this.originalTransactionId = Logger.getTransactionId();
    Logger.info('Starting ReferralUpdateBatch Batch');
    Logger.saveLog();

    return this.getQueryLocator();
  }

  public void execute(Database.BatchableContext bc, List<workspan__Referral__c> records) {
    try {
      Logger.setParentLogTransactionId(this.originalTransactionId);
      List<workspan__Referral__c> recordsToUpdate = new List<workspan__Referral__c>();

      for (workspan__Referral__c record : records) {
        record.workspan__SalesStage__c = record.workspan__Opportunity__r.StageName;
        record.workspan__CloseDate__c = record.workspan__Opportunity__r.CloseDate;
        recordsToUpdate.add(record);
      }

      update recordsToUpdate;
      Logger.saveLog();
    } catch (Exception e) {
      Logger.error('Error in ReferralUpdateBatch Batch', e);
      Logger.saveLog();
    }
  }

  public void finish(Database.BatchableContext BC) {
    Logger.setParentLogTransactionId(this.originalTransactionId);
    Logger.info('Finishing ReferralUpdateBatch Batch');
    Logger.saveLog();
  }

  private Database.QueryLocator getQueryLocator() {
    return Database.getQueryLocator(
      [
        SELECT
          Id,
          workspan__SalesStage__c,
          workspan__CloseDate__c,
          workspan__Opportunity__r.StageName,
          workspan__Opportunity__r.CloseDate
        FROM workspan__Referral__c
        WHERE
          workspan__Opportunity__c != NULL
          AND workspan__Opportunity__r.StageName NOT IN (
            :OpportunityMetadata_SL.CLOSED_WON_PENDING,
            :OpportunityMetadata_SL.CLOSED_WON_BOOKED
          )
          AND workspan__ReferralStatus__c NOT IN ('Decline', 'Discontinued')
          AND OpportunitySyncFlag__c = FALSE
      ]
    );
  }

  public void execute(SchedulableContext context) {
    Database.executeBatch(this, 2000);
  }
}