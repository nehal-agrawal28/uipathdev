global without sharing class AbstractQueueableRetryBatch implements Database.Batchable<SObject>, Database.Stateful, Schedulable {
  private static final String ERROR_TASK_STATUS = 'Error';
  private AsyncRetryConfig__c config {
    get {
      return AsyncRetryConfig__c.getOrgDefaults();
    }
    set;
  }

  global List<AsyncTask__c> start(Database.BatchableContext context) {
    if (config.Disable_All__c) {
      return new List<AsyncTask__c>();
    } else {
      return [
        SELECT Id
        FROM AsyncTask__c
        WHERE
          Status__c = :ERROR_TASK_STATUS
          AND (RetryCount__c = NULL
          OR RetryCount__c < :config.Max_Retry_Batch__c)
          AND CreatedDate = LAST_N_DAYS:1
      ];
    }
  }

  global void execute(Database.BatchableContext context, List<AsyncTask__c> asyncTasks) {
    for (AsyncTask__c task : asyncTasks) {
      AsyncTaskManager_TS.startTask(task.Id);
    }
  }

  global void finish(Database.BatchableContext context) {
  }

  /**
   * Schedule batch class and 1 record per execution
   */
  global void execute(SchedulableContext context) {
    Database.executeBatch(this, 1);
  }
}