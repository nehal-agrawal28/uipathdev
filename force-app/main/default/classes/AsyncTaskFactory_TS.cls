public class AsyncTaskFactory_TS {
  private static Map<String, String> implementations = new Map<String, String>{
    'RipReplace_Cancellation' => 'CPQCreateCancellationQuoteTask_SL',
    'RipReplace_OppSync' => 'OppRipReplaceSyncTask_SL',
    'RipReplace_QuoteSync' => 'QuoteRipReplaceSyncTask_SL',
    'RipReplace_OrderSync' => 'OrderRipReplaceSyncTask_SL',
    'AbstractQueueable' => 'AbstractQueueableTask'
  };

  public static IAsyncTask_TS getInstance(String taskType) {
    IAsyncTask_TS taskInstance;
    if (implementations.containsKey(taskType)) {
      taskInstance = (IAsyncTask_TS) (Type.forName(implementations.get(taskType))).newInstance();
    } else {
      throw new AsyncTaskFactoryException('Implementation class for ' + taskType + ' is not registered');
    }
    return taskInstance;
  }

  public class AsyncTaskFactoryException extends Exception {
  }
}