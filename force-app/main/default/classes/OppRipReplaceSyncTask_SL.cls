public without sharing class OppRipReplaceSyncTask_SL implements IAsyncTask_TS {
  public static final String SYNC_TASK_TYPE = 'RipReplace_OppSync';

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
    OppRipReplaceSyncQueueableSerial_SL.TaskInputWrapper taskWrapper = (OppRipReplaceSyncQueueableSerial_SL.TaskInputWrapper) JSON.deserialize(
      asyncTask.InputJSON__c,
      OppRipReplaceSyncQueueableSerial_SL.TaskInputWrapper.class
    );
    //for error notifications, capture user details in sync context
    Id initiatingUserId = UserInfo.getUserId();
    String initiatingUserTheme = UserInfo.getUiThemeDisplayed();

    Id jobId = System.enqueueJob(
      new OppRipReplaceSyncQueueableSerial_SL(new List<Id>{ taskWrapper.opp.Id }, initiatingUserId, initiatingUserTheme)
    );

    asyncTask.Status__c = 'Inprogress';
    asyncTask.Error__c = null;
    update asyncTask;
  }
}