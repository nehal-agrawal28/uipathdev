public abstract class AbstractChain {
  private AbstractChain previous;
  private AbstractChain next;

  private Map<String, Object> sharedVariables = new Map<String, Object>();

  protected abstract void executeAsynchronously();
  protected abstract void executeSynchronously(Context ctx);
  protected abstract Boolean isSync();

  public AbstractChain then(AbstractChain successor) {
    if (next != null) {
      next.then(successor);
    } else {
      next = successor;
      next.previous = this;
      next.sharedVariables = sharedVariables;
    }

    return this;
  }

  public AbstractChain execute() {
    if (isSync()) {
      executeSynchronously(new Context());
      executeNext();
    } else {
      executeAsynchronously();
    }

    return this;
  }

  public AbstractChain setShared(String key, Object value) {
    sharedVariables.put(key, value);
    return this;
  }

  public Object getShared(String key) {
    return sharedVariables.get(key);
  }

  protected void executeNext() {
    if (next != null) {
      next.execute();
    }
  }

  public class Context {
    private Object originalContext;

    public Context() {
    }

    public Context(Database.BatchableContext ctx) {
      originalContext = ctx;
    }

    public Context(QueueableContext ctx) {
      originalContext = ctx;
    }

    public Context(SchedulableContext ctx) {
      originalContext = ctx;
    }

    public Object get() {
      return originalContext;
    }
  }
}