public interface IAsyncTask_TS {
  AsyncTask__c createTask(String inputJSON, AsyncTask__c prefilledObject);
  void doTask(AsyncTask__c asyncTask);
}