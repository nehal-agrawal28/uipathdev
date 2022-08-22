public with sharing class RecRipReplaceUpdQueueableFinalizer_SL implements Finalizer, IRecRipReplaceUpdQueueableFinalizer_SL {
  public static final Integer MAX_RETRY = 2;
  public static final String LEX_THEME_NAME = 'Theme4d';
  public static final String RR_CUSTOM_NOTIF_TYPE = 'Rip_and_Replace';
  public static final Set<Object> ASYNC_TASKS_NON_TERMINAL_STATES = new Set<Object>{ 'Submitted', 'Inprogress' };
  private Map<Id, Map<String, String>> childIdToFieldUpdateMap { get; set; }
  private List<Id> childRecordIds { get; set; }
  List<String> retryJob { get; set; } //BUG: Primitive datatype not updating when finalizer run after failure
  private Id initiatingUserId { get; set; }
  private String initiatingUserTheme { get; set; }
  private String syncType { get; set; }
  private static AsyncTasksSelector_TS taskSelector = (AsyncTasksSelector_TS) Application_SL.Selector.newInstance(
    AsyncTask__c.SObjectType
  );

  public RecRipReplaceUpdQueueableFinalizer_SL(
    Map<Id, Map<String, String>> childIdToFieldUpdateMap,
    List<Id> childRecordIds,
    List<String> retryJob,
    Id initiatingUserId,
    String initiatingUserTheme,
    String syncType
  ) {
    this.childIdToFieldUpdateMap = childIdToFieldUpdateMap;
    this.childRecordIds = childRecordIds;
    this.retryJob = retryJob;
    this.initiatingUserId = initiatingUserId;
    this.initiatingUserTheme = initiatingUserTheme;
    this.syncType = syncType;
  }

  public void execute(FinalizerContext ctx) {
    String parentJobId = '' + ctx.getAsyncApexJobId();
    if (ctx.getResult() == ParentJobResult.SUCCESS) {
      // Success
      updateAsyncTask(parentJobId, childRecordIds.get(0), null);
      nextJob();
    } else {
      // Error
      Integer retryCount = retryJob.size();
      if (retryCount < MAX_RETRY) {
        // retry job
        retryJob.add(parentJobId);
        enqueueJob(childIdToFieldUpdateMap, childRecordIds, retryJob, initiatingUserId, initiatingUserTheme, syncType);
      } else {
        //final job close
        updateAsyncTask(parentJobId, childRecordIds.get(0), ctx.getException()); //failure
        nextJob(); //continue to next job
        sendInitUserErrorNotif(
          childRecordIds,
          ctx.getException(),
          parentJobId,
          initiatingUserTheme,
          initiatingUserId,
          syncType
        ); //send failure notif
      }
    }
  }

  // public to simulate operation in test context
  public void nextJob() {
    if (childRecordIds != null && childRecordIds.size() > 1) {
      // remove current record and start next job
      retryJob.clear();
      Id currentId = childRecordIds.remove(0);
      childIdToFieldUpdateMap.remove(currentId);
      enqueueJob(childIdToFieldUpdateMap, childRecordIds, retryJob, initiatingUserId, initiatingUserTheme, syncType);
    }
  }

  private void enqueueJob(
    Map<Id, Map<String, String>> recordIdFieldUpdateMap,
    List<Id> childIds,
    List<String> retryJob,
    Id initiatingUserId,
    String initiatingUserTheme,
    String syncType
  ) {
    IRipReplaceUpdater_SL job = RipReplaceUpdaterFactory_SL.getInstance(
      syncType,
      recordIdFieldUpdateMap,
      childIds,
      initiatingUserId,
      initiatingUserTheme,
      retryJob
    );
    //job.retryJob = retryJob;
    if (!Test.isRunningTest()) {
      Id newJob = System.enqueueJob(job);
    } else {
      job.work();
    }
  }

  public static void updateAsyncTask(String jobId, String recordId, Exception jobException) {
    try {
      List<SObject> currentTaskList = (List<AsyncTask__c>) taskSelector.selectByRecordId(recordId);
      //control to not update a task that has already been closed
      SObjectPredicate nonTerminalAsyncTasks = new FieldValueIsInSet(
        AsyncTask__c.Status__c,
        currentTaskList,
        ASYNC_TASKS_NON_TERMINAL_STATES
      );
      currentTaskList = (List<AsyncTask__c>) Collection.of(currentTaskList).filter(nonTerminalAsyncTasks).asList();

      if (currentTaskList.size() > 0) {
        AsyncTask__c currentTask = (AsyncTask__c) currentTaskList[0];
        currentTask.ApexJobId__c = jobId;
        if (jobException != null) {
          currentTask.Status__c = 'Error';
          currentTask.Error__c = jobException.getStackTraceString();
          currentTask.UIMessage__c = jobException.getMessage();
        } else {
          currentTask.Status__c = 'Completed';
          currentTask.Error__c = null;
        }
        update currentTask;
      }
    } catch (Exception e) {
      System.debug(LoggingLevel.ERROR, 'Error in updating AsyncTask' + e);
    }
  }

  public static string sendInitUserErrorNotif(
    List<Id> childRecordIds,
    Exception jobException,
    String parentJobId,
    String initiatingUserTheme,
    String initiatingUserId,
    String syncType
  ) {
    //TODO
    //support non-LEX notif
    String result;
    try {
      if (
        (childRecordIds == null ||
        childRecordIds.size() == 0) ||
        (initiatingUserTheme == null || String.isEmpty(initiatingUserTheme)) ||
        jobException == null ||
        (parentJobId == null || String.isEmpty(parentJobId)) ||
        (initiatingUserTheme == null || String.isEmpty(initiatingUserTheme)) ||
        (initiatingUserId == null || String.isEmpty(initiatingUserId))
      ) {
        throw new RecRipReplaceUpdQueueableFinalizerException('Missing params');
      }
      if (initiatingUserTheme == LEX_THEME_NAME) {
        //TODO - custom labels for notif string
        String notifBody = createNotifBody(jobException, parentJobId);
        result = CustomNotificationFromApex_SL.notifyUsers(
          new Set<String>{ initiatingUserId },
          childRecordIds.get(0),
          RR_CUSTOM_NOTIF_TYPE,
          syncType,
          notifBody
        );
      }
    } catch (Exception e) {
      result = 'Error';
      System.debug(LoggingLevel.ERROR, e.getMessage());
      System.debug(LoggingLevel.ERROR, e.getStackTraceString());
    }
    return result;
  }

  @TestVisible
  private static String createNotifBody(Exception jobException, String parentJobId) {
    fflib_StringBuilder stringBuilder = new fflib_StringBuilder();
    //TODO - custom labels for notif strings
    stringBuilder.add('Sync error - on attempting to synchronise your change, the following error occurred: \n');
    switch on jobException.getTypeName() {
      when 'System.DmlException' {
        stringBuilder.add('Record validation error: ' + jobException.getDmlMessage(0));
        stringBuilder.add(
          '.\n Please attempt to resolve the data issue with this record and re-apply your change to this record. \n'
        );
      }
      when else {
        stringBuilder.add('Error: ' + jobException.getMessage());
        stringBuilder.add('.\n System error - please contact UiPath Salesforce Support with the \'JobId\' below. \n');
      }
    }
    stringBuilder.add('(Ref JobId: ' + parentJobId + ')');
    return stringBuilder.getStringValue();
  }

  public class RecRipReplaceUpdQueueableFinalizerException extends Exception {
  }
}