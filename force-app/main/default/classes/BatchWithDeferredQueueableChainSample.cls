/**
 * Test Class Support for testing BatchWithDeferredQueueableChain
 */
public class BatchWithDeferredQueueableChainSample extends BatchWithDeferredQueueableChain {
  public override Iterable<Object> start(Database.BatchableContext ctx) {
    BatchWithDeferredQueueableChainTest.started = true;
    return (Iterable<Object>) [SELECT Phone FROM Account];
  }

  public override void executeWork(Database.BatchableContext ctx, Iterable<Object> scope) {
    System.debug('Performing some very hard work!');
    BatchWithDeferredQueueableChainTest.workDone = true;
  }

  public override void finish(Database.BatchableContext ctx) {
    BatchWithDeferredQueueableChainTest.finished = true;
  }
}