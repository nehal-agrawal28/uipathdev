public without sharing class CPQCreateCancellationQuoteTask_SL implements IAsyncTask_TS {
  /**
   * Create RipReplace_Cancellation AsyncTask
   */
  public AsyncTask__c createTask(String inputJSON, AsyncTask__c prefilledObject) {
    AsyncTask__c newTask = prefilledObject != null ? prefilledObject : new AsyncTask__c();
    newTask.Type__c = 'RipReplace_Cancellation';
    newTask.InputJSON__c = inputJSON;
    return newTask;
  }

  /**
   * Parse input json and start AsyncTask task
   */
  public void doTask(AsyncTask__c asyncTask) {
    CPQCreateCancellationQuoteSerial_SL.TaskInputWrapper inputs = (CPQCreateCancellationQuoteSerial_SL.TaskInputWrapper) JSON.deserialize(
      asyncTask.InputJSON__c,
      CPQCreateCancellationQuoteSerial_SL.TaskInputWrapper.class
    );

    Id jobId = System.enqueueJob(
      new CPQCreateCancellationQuoteSerial_SL(inputs.contractId, inputs.startDate, inputs.quoteId, null)
    );

    asyncTask.Status__c = 'Inprogress';
    asyncTask.Error__c = null;
    update asyncTask;
  }
}