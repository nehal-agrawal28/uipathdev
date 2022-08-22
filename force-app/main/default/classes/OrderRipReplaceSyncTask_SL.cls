public with sharing class OrderRipReplaceSyncTask_SL implements IAsyncTask_TS {
  public static final String SYNC_TASK_TYPE = 'RipReplace_OrderSync';

  /**
   * Create RipReplace_OppSync AsyncTask
   */
  public AsyncTask__c createTask(String inputJSON, AsyncTask__c prefilledObject) {
    AsyncTask__c newTask = prefilledObject != null ? prefilledObject : new AsyncTask__c();
    newTask.Type__c = SYNC_TASK_TYPE;
    newTask.InputJSON__c = inputJSON;
    return newTask;
  }

  /**
   * Parse input json and start AsyncTask task
   */
  public void doTask(AsyncTask__c asyncTask) {
    OrderRipReplaceSyncQueueableSerial_SL.TaskInputWrapper taskWrapper = (OrderRipReplaceSyncQueueableSerial_SL.TaskInputWrapper) JSON.deserialize(
      asyncTask.InputJSON__c,
      OrderRipReplaceSyncQueueableSerial_SL.TaskInputWrapper.class
    );
    //for error notifications, capture user detail in sync context
    Id initiatingUserId = UserInfo.getUserId();
    String initiatingUserTheme = UserInfo.getUiThemeDisplayed();

    Id jobId = System.enqueueJob(
      new OrderRipReplaceSyncQueueableSerial_SL(
        new List<Id>{ taskWrapper.record.Id },
        initiatingUserId,
        initiatingUserTheme
      )
    );

    asyncTask.Status__c = 'Inprogress';
    asyncTask.Error__c = null;
    update asyncTask;
  }
}