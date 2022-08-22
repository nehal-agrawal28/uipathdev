/**
 * Abstract base for Batch implementations that have issues with Queueable Async limits.
 * Forces a deferral of the queue to the very of each execute invocation - accumulating all Queueables and running them as a chain at the end.
 */
public abstract class BatchWithDeferredQueueableChain implements Database.Batchable<Object>, Database.Stateful, Database.AllowsCallouts {
  protected abstract Iterable<Object> start(Database.BatchableContext ctx);
  protected abstract void executeWork(Database.BatchableContext ctx, Iterable<Object> scope);
  protected abstract void finish(Database.BatchableContext ctx);

  public void execute(Database.BatchableContext ctx, Iterable<Object> scope) {
    AbstractQueueable.deferEnqueue();
    executeWork(ctx, scope);
    AbstractQueueable.commitChain();
  }
}