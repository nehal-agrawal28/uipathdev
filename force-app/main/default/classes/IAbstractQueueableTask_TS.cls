public interface IAbstractQueueableTask_TS {
  Boolean isRetryValid(AsyncTask__c asyncTask);
  void doTask(AsyncTask__c asyncTask);
}