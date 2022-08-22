public without sharing class RelatedAsyncTasksController {
  public class RelatedAsyncTasksWrapper {
    @AuraEnabled
    public List<AsyncTask__c> asyncTasks { get; set; }
  }

  @AuraEnabled
  public static RelatedAsyncTasksWrapper getAsyncTasksData(String recordId) {
    RelatedAsyncTasksWrapper wrapper = new RelatedAsyncTasksWrapper();
    wrapper.asyncTasks = [
      SELECT Id, Name, Status__c, UIMessage__c, Error__c, Type__c, SubType__c, RetryCount__c
      FROM AsyncTask__c
      WHERE PrimaryRecordId__c = :recordId
      ORDER BY CreatedDate DESC
    ];
    return wrapper;
  }

  @AuraEnabled
  public static void retryAsyncTask(String asyncTaskId) {
    AsyncTaskManager_TS.startTask(asyncTaskId);
  }
}