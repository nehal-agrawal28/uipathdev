@IsTest
public class DefaultQueueableFinalizerTest {
  @isTest
  public static void attachFinalizerTest() {
    TestSupportObject__c testSupportObject = new TestSupportObject__c(Name = 'Queueable test');
    insert testSupportObject;

    TestQueueable first = new TestQueueable();
    first.getDefaultFinalizer();
  }

  @isTest
  public static void defaultQueueableFinalizerTest() {
    CustomException cExp = new CustomException('Test');
    DefaultQueueableFinalizer.AsyncDataWrapper asyncData = new DefaultQueueableFinalizer.AsyncDataWrapper();
    DefaultQueueableFinalizer d = new DefaultQueueableFinalizer('TestQueueable', null, asyncData, 'queueableSnapshot');
    try {
      d.execute(null);
    } catch (Exception e) {
    }
    d.jobSuccess();
    d.jobRetry();
    d.jobFailure(cExp, 'Error');
    System.assertEquals(1, [SELECT Id FROM AsyncTask__c WHERE Status__c = 'Error'].size());
    System.assertEquals(1, [SELECT Id FROM AsyncTask__c WHERE Status__c = 'Completed'].size());
  }

  public class TestQueueable extends AbstractQueueable {
    public String state = 'initial state';

    public TestQueueable() {
      super('TestQueueable');
    }

    public override void work() {
      System.debug('*******Working on TestQueueable **********' + this.name);
      this.state = 'modified state';
      AbstractQueueable.enqueue(new TestQueueable());
    }
  }

  public class CustomException extends Exception {
  }
}