@isTest
public class RelatedAsyncTasksControllerTest {
  @TestSetup
  private static void makeData() {
    AsyncTask__c prefilledTask = new AsyncTask__c();
    prefilledTask.Status__c = 'Error';
    prefilledTask.Error__c = 'Error Test';
    prefilledTask.PrimaryRecordId__c = 'FakeId';
    AsyncTask__c aTask = AsyncTaskManager_TS.createTask('AbstractQueueable', '', prefilledTask, true);
  }

  @isTest
  private static void controllerTest() {
    Test.startTest();
    RelatedAsyncTasksController.RelatedAsyncTasksWrapper wrapper = RelatedAsyncTasksController.getAsyncTasksData(
      'FakeId'
    );
    System.assertEquals(true, wrapper.asyncTasks.size() > 0);

    RelatedAsyncTasksController.retryAsyncTask(wrapper.asyncTasks[0].Id);

    Test.stopTest();
  }
}