public with sharing class QuoteRipReplaceSyncQueueableSerial_SL extends AbstractQueueable implements IRipReplaceSync_SL {
  private static final Set<Id> PROCESSEDRECORDS = new Set<Id>();
  List<Id> parentRecordIds { get; set; }
  private Id initiatingUserId { get; set; }
  private String initiatingUserTheme { get; set; }

  private final IQuoteService_SL quoteService = (IQuoteService_SL) Application_SL.Service.newInstance(
    IQuoteService_SL.class
  );

  public QuoteRipReplaceSyncQueueableSerial_SL(
    List<Id> parentRecordIds,
    Id initiatingUserId,
    String initiatingUserTheme
  ) {
    super('QuoteRipReplaceSyncQueueableSerial_SL');
    this.init(parentRecordIds, initiatingUserId, initiatingUserTheme);
  }

  public QuoteRipReplaceSyncQueueableSerial_SL() {
    super('QuoteRipReplaceSyncQueueableSerial_SL');
  }

  public void init(List<Id> parentRecordIds, Id initiatingUserId, String initiatingUserTheme) {
    this.parentRecordIds = parentRecordIds;
    this.initiatingUserId = initiatingUserId;
    this.initiatingUserTheme = initiatingUserTheme;
  }

  public override void work() {
    if (!Test.isRunningTest()) {
      execute(ctx.getJobId());
    } else {
      execute('TEST');
    }
  }

  public void execute(String jobId) {
    //System.debug('### QuoteRipReplaceSyncQueueableSerial_SL.work()');
    if (parentRecordIds != null && parentRecordIds.size() > 0) {
      //for each quote id, map field name to new field value
      Map<Id, Map<String, String>> quoteIdToFieldUpdateMap = new Map<Id, Map<String, String>>();

      //get the sync changes by field
      Map<Id, SBQQ__Quote__c> updatedStartDateQuotes = quoteService.syncFieldOnCancelledQuotes(
        new Set<Id>(parentRecordIds),
        SBQQ__Quote__c.SBQQ__StartDate__c
      );
      Map<Id, SBQQ__Quote__c> updatedOrderedQuotes = quoteService.syncFieldOnCancelledQuotes(
        new Set<Id>(parentRecordIds),
        SBQQ__Quote__c.SBQQ__Ordered__c
      );
      //represents the desired endstate for given quotes
      Map<Id, SBQQ__Quote__c> finalStateUpdateQuotes = new Map<Id, SBQQ__Quote__c>();

      //consolidate the changes down into a single update - Start Date field
      for (Id qId : updatedStartDateQuotes.keySet()) {
        Map<String, String> fieldNameMap = new Map<String, String>();
        if (quoteIdToFieldUpdateMap.containsKey(qId)) {
          fieldNameMap = quoteIdToFieldUpdateMap.get(qId);
        }
        SBQQ__Quote__c q = updatedStartDateQuotes.get(qId);
        fieldNameMap.put('SBQQ__StartDate__c', String.valueOf(q.SBQQ__StartDate__c));
        quoteIdToFieldUpdateMap.put(qid, fieldNameMap);
        finalStateUpdateQuotes.put(
          q.Id,
          new SBQQ__Quote__c(
            Id = q.Id,
            SBQQ__Account__c = q.SBQQ__Account__c,
            SBQQ__Opportunity2__c = q.SBQQ__Opportunity2__c,
            SBQQ__StartDate__c = q.SBQQ__StartDate__c
          )
        );
      }

      //consolidate the changes down into a single update - Ordered field
      for (Id qId : updatedOrderedQuotes.keySet()) {
        Map<String, String> fieldNameMap = new Map<String, String>();
        if (quoteIdToFieldUpdateMap.containsKey(qId)) {
          fieldNameMap = quoteIdToFieldUpdateMap.get(qId);
        }
        SBQQ__Quote__c q = updatedOrderedQuotes.get(qId);
        fieldNameMap.put('SBQQ__Ordered__c', String.valueOf(q.SBQQ__Ordered__c));
        quoteIdToFieldUpdateMap.put(qid, fieldNameMap);
        if (finalStateUpdateQuotes.containsKey(qid)) {
          SBQQ__Quote__c finalQuote = finalStateUpdateQuotes.get(qid);
          finalQuote.put('SBQQ__Ordered__c', q.SBQQ__Ordered__c);
        } else {
          finalStateUpdateQuotes.put(
            q.Id,
            new SBQQ__Quote__c(
              Id = q.Id,
              SBQQ__Account__c = q.SBQQ__Account__c,
              SBQQ__Opportunity2__c = q.SBQQ__Opportunity2__c,
              SBQQ__Ordered__c = q.SBQQ__Ordered__c
            )
          );
        }
      }

      //2. create async tasks for all the quotes to update
      createAsyncTasks(finalStateUpdateQuotes.values());
      //System.debug('### QuoteRipReplaceSyncQueueableSerial_SL.quoteIdToFieldUpdateMap.keySet(): ' + quoteIdToFieldUpdateMap.keySet());

      //3. delegate the update process to queueable w/ finalizer
      AbstractQueueable job = (AbstractQueueable) RipReplaceUpdaterFactory_SL.getInstance(
        'RipReplace_QuoteSync',
        quoteIdToFieldUpdateMap,
        new List<Id>(quoteIdToFieldUpdateMap.keySet()),
        initiatingUserId,
        initiatingUserTheme
      );

      if (!Test.isRunningTest()) {
        AbstractQueueable.enqueue(job);
      } else {
        job.work();
      }
    }
  }

  public static void syncCancelledRecordsWithReplacementRecord(
    List<SObject> records,
    Map<Id, SObject> existingRecords
  ) {
    syncCancelledQuotesWithReplacementQuote(records, existingRecords);
  }

  public static void syncCancelledQuotesWithReplacementQuote(
    List<SBQQ__Quote__c> quotes,
    Map<Id, SObject> existingQuotes
  ) {
    //Feature Toggle
    List<CPQ_RR_Sync_Feature__mdt> featureControls = new List<CPQ_RR_Sync_Feature__mdt>();
    try {
      featureControls = [
        SELECT Is_Active__c
        FROM CPQ_RR_Sync_Feature__mdt
        WHERE Sync_Target_Object__c = 'SBQQ__Quote__c' AND Is_Active__c = TRUE
      ];
    } catch (Exception e) {
      System.debug(
        LoggingLevel.ERROR,
        'Rip and Replace feature activation metadata is missing - feature defaults to off'
      );
    }

    if (featureControls == null || featureControls.isEmpty()) {
      return;
    }
    //

    SObjectPredicate hasChanged = new HasRecordChanged(
      new Set<SObjectField>{ SBQQ__Quote__c.SBQQ__StartDate__c, SBQQ__Quote__c.SBQQ__Ordered__c },
      quotes,
      existingQuotes
    );

    SObjectPredicate isStillNotProcessed = new IsRecordNotProcessedYet(PROCESSEDRECORDS);

    List<SBQQ__Quote__c> eligibleQuotes = Collection.of(quotes)
      .filter(
        Match.field(SBQQ__Quote__c.Replacement_Quote__c)
          .equals(null)
          .also(SBQQ__Quote__c.Replacement_Transaction__c)
          .hasValue()
          .also(SBQQ__Quote__c.Replacement_Transaction__c)
          .equals(true)
      )
      .filter(isStillNotProcessed)
      .filter(hasChanged)
      .asList();

    if (!eligibleQuotes.isEmpty()) {
      List<Id> eligibleQuoteIds = Collection.of(eligibleQuotes).pluckIds();
      PROCESSEDRECORDS.addAll(eligibleQuoteIds);

      //move into async context for subsequent processing
      //for error notifications, capture user details in sync context
      Id initiatingUserId = UserInfo.getUserId();
      String initiatingUserTheme = UserInfo.getUiThemeDisplayed();
      //System.debug('### QuoteRipReplaceSyncQueueableSerial_SL eligibleQuoteIds: ' + eligibleQuoteIds);
      AbstractQueueable job = (AbstractQueueable) RipReplaceSyncFactory_SL.getInstance(
        'RipReplace_QuoteSync',
        eligibleQuoteIds,
        initiatingUserId,
        initiatingUserTheme
      );
      if (!Test.isRunningTest()) {
        AbstractQueueable.enqueue(job);
      } else {
        job.work();
      }
    }
  }

  public static void createAsyncTasks(List<SBQQ__Quote__c> quotes) {
    List<AsyncTask__c> taskList = new List<AsyncTask__c>();
    for (SBQQ__Quote__c quote : quotes) {
      TaskInputWrapper inputs = new TaskInputWrapper(quote);
      AsyncTask__c prefilledTask = new AsyncTask__c(
        Account__c = quote.SBQQ__Account__c,
        Opportunity__c = quote.SBQQ__Opportunity2__c,
        Quote__c = quote.Id,
        Status__c = 'Inprogress',
        Type__c = OppRipReplaceSyncTask_SL.SYNC_TASK_TYPE
      );
      AsyncTask__c newTask = AsyncTaskManager_TS.createTask(
        'RipReplace_QuoteSync',
        JSON.serialize(inputs),
        prefilledTask,
        false
      );
      taskList.add(newTask);
    }
    insert taskList;
  }

  public class TaskInputWrapper {
    public SBQQ__Quote__c quote;
    public TaskInputWrapper(SBQQ__Quote__c quote) {
      this.quote = quote;
    }
  }
}