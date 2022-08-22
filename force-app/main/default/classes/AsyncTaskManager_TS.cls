public without sharing class AsyncTaskManager_TS {
  private static final List<String> INVALID_STATUS = new List<String>{ 'Inprogress' , 'Completed' };
  private Id asyncTaskId;
  private AsyncTask__c asyncTask {
    get {
      if (asyncTask == null && asyncTaskId != null) {
        List<String> fields = new List<String>(AsyncTask__c.SObjectType.getDescribe().fields.getMap().keySet());
        String query = 'SELECT ' + String.join(fields, ',') + ' FROM AsyncTask__c ' + ' WHERE Id = :asyncTaskId';
        asyncTask = Database.query(query);
      }
      return asyncTask;
    }
    set;
  }

  private void processTask(Id asyncTaskId) {
    this.asyncTaskId = asyncTaskId;
    if (!INVALID_STATUS.contains(asyncTask.Status__c)) {
      IAsyncTask_TS taskInstance = AsyncTaskFactory_TS.getInstance(asyncTask.Type__c);
      taskInstance.doTask(asyncTask);
    }
  }

  public static void startTask(Id asyncTaskId) {
    AsyncTaskManager_TS manager = new AsyncTaskManager_TS();
    manager.processTask(asyncTaskId);
  }

  public static AsyncTask__c createTask(String type, String inputJSON, AsyncTask__c prefilledObject, Boolean isInsert) {
    IAsyncTask_TS taskInstance = AsyncTaskFactory_TS.getInstance(type);
    AsyncTask__c newTask = taskInstance.createTask(inputJSON, prefilledObject);
    if (isInsert) {
      insert newTask;
    }
    return newTask;
  }
}