@IsTest
public class AbstractQueueableRetryBatchTest implements IAbstractQueueableTask_TS {
  @IsTest
  private static void RetryBatchTest() {
    AsyncTask__c prefilledTask = new AsyncTask__c();
    prefilledTask.Status__c = 'Error';
    prefilledTask.Error__c = 'Error Test';
    AsyncTask__c aTask = AsyncTaskManager_TS.createTask('AbstractQueueable', '', prefilledTask, true);

    Test.startTest();
    AbstractQueueableRetryBatch batch = new AbstractQueueableRetryBatch();
    Database.executeBatch(batch);
    Test.stopTest();

    System.assertEquals(
      true,
      [SELECT Id, RetryCount__c FROM AsyncTask__c WHERE Id = :aTask.Id].RetryCount__c > 0,
      'Retry batch did not work'
    );
  }

  @IsTest
  private static void RetryBatchSubImplementationTest() {
    AbstractQueueableTask.subImplementations = new Map<String, String>{
      'SampleQueueableClassName' => 'AbstractQueueableRetryBatchTest'
    };

    AsyncTask__c prefilledTask = new AsyncTask__c();
    prefilledTask.Status__c = 'Error';
    prefilledTask.Error__c = 'Error Test';
    prefilledTask.SubType__c = 'SampleQueueableClassName';
    AsyncTask__c aTask = AsyncTaskManager_TS.createTask('AbstractQueueable', '', prefilledTask, true);

    Test.startTest();
    AbstractQueueableRetryBatch batch = new AbstractQueueableRetryBatch();
    Database.executeBatch(batch);
    Test.stopTest();
  }

  @IsTest
  private static void RetryScheduleTest() {
    Test.startTest();
    AbstractQueueableRetryBatch batch = new AbstractQueueableRetryBatch();
    String sch = '0 0 23 * * ?';
    System.schedule('AbstractQueueableRetryScheduleTest', sch, batch);
    Test.stopTest();
  }

  public Boolean isRetryValid(AsyncTask__c asyncTask) {
    return true;
  }
  public void doTask(AsyncTask__c asyncTask) {
  }
}