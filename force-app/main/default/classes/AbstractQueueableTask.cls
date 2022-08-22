public with sharing class AbstractQueueableTask implements IAsyncTask_TS {
  private static final String INPROGRESS_TASK_STATUS = 'Inprogress';
  private static final String ERROR_TASK_STATUS = 'Error';
  private static final String SUCCESS_TASK_STATUS = 'Completed';

  // Override default queueable retry by defining an IAbstractQueueableTask_TS implementation
  public static Map<String, String> subImplementations = new Map<String, String>{
    // 'SampleQueueableClassName' => 'SampleQueueableTaskImplementationClassName'
  };

  public AsyncTask__c createTask(String inputJSON, AsyncTask__c prefilledObject) {
    AsyncTask__c newTask = prefilledObject != null ? prefilledObject : new AsyncTask__c();
    newTask.Type__c = 'AbstractQueueable';
    newTask.InputJSON__c = inputJSON;
    return newTask;
  }

  public void doTask(AsyncTask__c asyncTask) {
    if (subImplementations.containsKey(asyncTask.SubType__c)) {
      // Queueable specific retry
      IAbstractQueueableTask_TS taskInstance = getSubImplementationInstance(asyncTask.SubType__c);
      if (taskInstance.isRetryValid(asyncTask)) {
        taskInstance.doTask(asyncTask);
      }
    } else {
      // Default retry
      defaultRetry(asyncTask);
    }
  }

  private void defaultRetry(AsyncTask__c asyncTask) {
    // Inprogress
    asyncTask.Status__c = INPROGRESS_TASK_STATUS;
    asyncTask.UIMessage__c = 'Job ' + asyncTask.SubType__c + ' is inprogress';
    update asyncTask;

    try {
      String className = asyncTask.SubType__c;
      AbstractQueueable retryQueueable = (AbstractQueueable) JSON.deserialize(
        asyncTask.InputJSON__c,
        Type.forName(className)
      );
      retryQueueable.executeSynchronously(null);

      // Success
      asyncTask.Status__c = SUCCESS_TASK_STATUS;
      asyncTask.Error__c = null;
      asyncTask.RetryCount__c = asyncTask.RetryCount__c > 0 ? asyncTask.RetryCount__c + 1 : 1;
      asyncTask.UIMessage__c = 'Job ' + asyncTask.SubType__c + ' completed successfully';
      update asyncTask;
    } catch (Exception e) {
      // Error
      asyncTask.Status__c = ERROR_TASK_STATUS;
      asyncTask.Error__c = e.getMessage() + ' ' + e.getStackTraceString();
      asyncTask.RetryCount__c = asyncTask.RetryCount__c > 0 ? asyncTask.RetryCount__c + 1 : 1;
      asyncTask.UIMessage__c = 'Error in retrying job ' + asyncTask.SubType__c;
      update asyncTask;
    }
  }

  public IAbstractQueueableTask_TS getSubImplementationInstance(String subType) {
    IAbstractQueueableTask_TS taskInstance;
    taskInstance = (IAbstractQueueableTask_TS) (Type.forName(subImplementations.get(subType))).newInstance();
    return taskInstance;
  }
}