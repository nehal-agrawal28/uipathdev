/**
 * Wrapper class to overcome asynchronous transaction limits (for example, from a batch Apex job), where you can add only one job to the queue with System.enqueueJob
 * We use this to have control over the flow and make sure that System.enqueueJob() is executed on our QueueableChain only once at the end of the transaction
 *.
 */
public class DefaultQueueableFinalizer implements Finalizer {
  private String jobName;
  private String className;
  //Only applicable for non-bulk contexts such as UI single CRUD transactions
  private Id primaryRecordId;
  private Id parentJobId;
  private AsyncDataWrapper asyncData { get; set; }
  private String queueableSnapshot { get; set; }
  private AsyncRetryConfig__c config {
    get {
      return AsyncRetryConfig__c.getInstance();
    }
    set;
  }

  public DefaultQueueableFinalizer(
    String jobName,
    Id primaryRecordId,
    AsyncDataWrapper asyncData,
    String queueableSnapshot
  ) {
    this.jobName = jobName;
    this.className = jobName.split('\\.')[0];
    this.primaryRecordId = primaryRecordId;
    this.asyncData = asyncData;
    this.queueableSnapshot = queueableSnapshot;
  }

  public void execute(FinalizerContext ctx) {
    this.parentJobId = ctx != null ? '' + ctx.getAsyncApexJobId() : '';

    if (ctx != null && ctx.getResult() == ParentJobResult.SUCCESS) {
      // SUCCESS
      jobSuccess();
    } else if (
      config != null &&
      config.Max_Retry_RealTime__c > 0 &&
      asyncData.retryCount < config.Max_Retry_RealTime__c
    ) {
      // RETRY
      jobRetry();
    } else {
      // FAILURE
      jobFailure(ctx.getException(), ctx.getException().getMessage());
    }
    Logger.saveLog();
  }

  @TestVisible
  private void jobSuccess() {
    logAsyncTask(true, null);
    LogMessage success = new LogMessage(
      'Queueable job {0} with Job Id {1} completed successfully ',
      jobName,
      this.parentJobId
    );
    if (primaryRecordId == null) {
      Logger.debug(success);
    } else {
      Logger.debug(success, primaryRecordId);
    }
  }

  @TestVisible
  private void jobRetry() {
    if (config != null && config.Disable_All__c) {
      return;
    }
    try {
      // Deserializing saved state
      AbstractQueueable retryQueueable = (AbstractQueueable) JSON.deserialize(
        queueableSnapshot,
        Type.forName(className)
      );
      if (!Test.isRunningTest()) {
        // Retry job
        System.enqueueJob(retryQueueable);
      }
    } catch (Exception e) {
      Logger.error('Exception in Retring ' + this.jobName, e);
      Logger.saveLog();
    }
  }

  @TestVisible
  private void jobFailure(Exception exp, String errorMessage) {
    logAsyncTask(false, errorMessage);
    LogMessage failMessage = new LogMessage('Queueable job {0} with Job Id {1} failed ', jobName, this.parentJobId);
    if (primaryRecordId == null) {
      Logger.error(failMessage, exp);
    } else {
      Logger.error(failMessage, primaryRecordId, exp);
    }
  }

  private void logAsyncTask(Boolean isSuccess, String error) {
    try {
      if (canLogAsyncTask(isSuccess, error)) {
        // Build task record
        String inputJSON = queueableSnapshot;
        AsyncTask__c prefilledTask;
        if (isSuccess) {
          prefilledTask = new AsyncTask__c(
            UIMessage__c = 'Queueable job ' + jobName + ' has completed',
            Status__c = 'Completed'
          );
        } else {
          prefilledTask = new AsyncTask__c(
            UIMessage__c = 'Queueable job ' + jobName + ' has failed',
            Status__c = 'Error',
            Error__c = error
          );
        }
        prefilledTask.SubType__c = this.className;
        prefilledTask.PrimaryRecordId__c = this.primaryRecordId;

        // Insert task record
        AsyncTaskManager_TS.createTask('AbstractQueueable', inputJSON, prefilledTask, true);
      }
    } catch (Exception e) {
      if (primaryRecordId == null) {
        Logger.error('AsyncTask logging failed', e);
      } else {
        Logger.error('AsyncTask logging failed', primaryRecordId, e);
      }
    }
  }

  private Boolean canLogAsyncTask(Boolean isSuccess, String error) {
    if (queueableSnapshot == null) {
      return false;
    }
    if (config != null && config.Disable_All__c) {
      return false;
    }
    if (isSuccess && config != null && config.Disable_Success_Log__c) {
      return false;
    }
    if (!isSuccess && config != null && String.isNotBlank(config.Error_List_To_Log__c)) {
      Boolean errorFound = false;
      List<String> eligibleErrors = config.Error_List_To_Log__c.split(',');
      for (String eligibleError : eligibleErrors) {
        if (error.contains(eligibleError)) {
          errorFound = true;
          break;
        }
      }
      if (!errorFound) {
        return false;
      }
    }
    return true;
  }

  public class AsyncDataWrapper {
    public Integer retryCount { get; set; }
    public AsyncDataWrapper() {
      this.retryCount = 0;
    }
  }
}