public with sharing class QuoteRipReplaceUpdateQueueableSerial_SL extends AbstractQueueable implements Database.AllowsCallouts, IRipReplaceUpdater_SL {
  private Map<Id, Map<String, String>> recordIdToFieldUpdateMap { get; set; }
  private List<Id> childRecordIds { get; set; }
  public List<String> retryJob {
    get {
      if (retryJob == null) {
        retryJob = new List<String>();
      }
      return retryJob;
    }
    set;
  }
  private Id initiatingUserId { get; set; }
  private String initiatingUserTheme { get; set; }
  public static final string QUOTE_SYNC_TYPE = 'RipReplace_QuoteSync';
  public static final string QUOTE_ORDERED_SYNC_TYPE = 'RipReplace_QuoteSyncOrdered';

  public QuoteRipReplaceUpdateQueueableSerial_SL(
    Map<Id, Map<String, String>> recordIdToFieldUpdateMap,
    List<Id> childRecordIds,
    Id initiatingUserId,
    String initiatingUserTheme,
    List<String> retryJob
  ) {
    super('QuoteRipReplaceUpdateQueueableSerial_SL');
    this.init(recordIdToFieldUpdateMap, childRecordIds, initiatingUserId, initiatingUserTheme, retryJob);
  }

  public QuoteRipReplaceUpdateQueueableSerial_SL(
    Map<Id, Map<String, String>> recordIdToFieldUpdateMap,
    List<Id> childRecordIds,
    Id initiatingUserId,
    String initiatingUserTheme
  ) {
    super('QuoteRipReplaceUpdateQueueableSerial_SL');
    this.init(recordIdToFieldUpdateMap, childRecordIds, initiatingUserId, initiatingUserTheme, new List<String>());
  }

  public QuoteRipReplaceUpdateQueueableSerial_SL() {
    super('QuoteRipReplaceUpdateQueueableSerial_SL');
  }

  public void init(
    Map<Id, Map<String, String>> recordIdToFieldUpdateMap,
    List<Id> childRecordIds,
    Id initiatingUserId,
    String initiatingUserTheme,
    List<String> retryJob
  ) {
    this.recordIdToFieldUpdateMap = recordIdToFieldUpdateMap;
    this.childRecordIds = childRecordIds;
    this.initiatingUserId = initiatingUserId;
    this.initiatingUserTheme = initiatingUserTheme;
    this.retryJob = retryJob;
    this.baseFinalizer = new RecRipReplaceUpdQueueableFinalizer_SL(
      this.recordIdToFieldUpdateMap,
      this.childRecordIds,
      this.retryJob,
      this.initiatingUserId,
      this.initiatingUserTheme,
      QUOTE_SYNC_TYPE
    );
  }

  public override void work() {
    if (!Test.isRunningTest()) {
      execute(ctx.getJobId());
    } else {
      execute('TEST');
    }
  }

  public void execute(String jobId) {
    //do work
    try {
      if (
        recordIdToFieldUpdateMap != null &&
        recordIdToFieldUpdateMap.size() > 0 &&
        childRecordIds != null &&
        childRecordIds.size() > 0 &&
        childRecordIds.size() == recordIdToFieldUpdateMap.keySet().size() &&
        recordIdToFieldUpdateMap.containsKey(childRecordIds.get(0))
      ) {
        Id childQuoteId = childRecordIds.get(0);
        Map<String, String> fieldUpdateMap = recordIdToFieldUpdateMap.get(childQuoteId);
        SBQQ__Quote__c childQuote = new SBQQ__Quote__c(Id = childQuoteId);
        for (String fieldName : fieldUpdateMap.keySet()) {
          //TODO - this can be much improved
          switch on fieldName {
            when 'SBQQ__StartDate__c' {
              childQuote.put(fieldName, Date.valueOf(fieldUpdateMap.get(fieldName)));
            }
            when 'SBQQ__Ordered__c' {
              childQuote.put(fieldName, Boolean.valueOf(fieldUpdateMap.get(fieldName)));
            }
            when else {
              childQuote.put(fieldName, fieldUpdateMap.get(fieldName));
            }
          }
        }

        if (childQuote.get('SBQQ__StartDate__c') != null) {
          /*SBQQ gymnastics to get quote in valid state
          - if the start date is being set, SBQQ triggers must be disabled
          - else a callout in trigger context exception is thrown
          */
          SBQQ.TriggerControl.disable();
          fflib_ISObjectUnitOfWork unitOfWork = Application_SL.UnitOfWork.newInstance();
          unitOfWork.registerDirty(childQuote);
          unitOfWork.commitWork();
          SBQQ.TriggerControl.enable();

          asyncForceQuoteUpdate(childQuote.Id);
        } else if (childQuote.get('SBQQ__Ordered__c') != null) {
          /*SBQQ gymnastics to get the child orders to generate
          - if the quote is being ordered, a fresh execution context
          is needed to allow SBQQ queueable to execute
          */
          QuoteRipReplaceSyncQueueableSerial_SL.TaskInputWrapper taskWrapper = new QuoteRipReplaceSyncQueueableSerial_SL.TaskInputWrapper(
            childQuote
          );
          String taskWrapperJson = JSON.serialize(taskWrapper);
          asyncUpdateQuoteSimple(taskWrapperJson, initiatingUserId, initiatingUserTheme);
        } else {
          //assume other cases are simple...
          fflib_ISObjectUnitOfWork unitOfWork = Application_SL.UnitOfWork.newInstance();
          unitOfWork.registerDirty(childQuote);
          unitOfWork.commitWork();
        }
      }
      //queueable job chaining test limitation, simulate finalizer operation
      if (Test.isRunningTest() && childRecordIds != null && childRecordIds.size() > 1) {
        IRecRipReplaceUpdQueueableFinalizer_SL finalizer = new RecRipReplaceUpdQueueableFinalizer_SL(
          recordIdToFieldUpdateMap,
          childRecordIds,
          retryJob,
          initiatingUserId,
          initiatingUserTheme,
          QUOTE_SYNC_TYPE
        );
        finalizer.nextJob();
      }
    } catch (DmlException dml) {
      //send validation notif to requesting user
      RecRipReplaceUpdQueueableFinalizer_SL.sendInitUserErrorNotif(
        childRecordIds,
        dml,
        jobId,
        initiatingUserTheme,
        initiatingUserId,
        QUOTE_SYNC_TYPE
      );
      //record failure in async task
      RecRipReplaceUpdQueueableFinalizer_SL.updateAsyncTask(jobId, childRecordIds[0], dml);
    } catch (Exception e) {
      throw new QuoteRipReplaceUpdateException(e.getMessage(), e);
    }
  }

  /**
   * Used to massage a Quote into a valid state after Start Date change
   */
  @future(callout=true)
  public static void asyncForceQuoteUpdate(Id childQuoteId) {
    IQuoteService_SL quoteService = (IQuoteService_SL) Application_SL.Service.newInstance(IQuoteService_SL.class);
    quoteService.quoteUpdater(childQuoteId);
  }

  /**
   * Used to massage a Quote into producing an order when ordered
   */
  @future(callout=true)
  public static void asyncUpdateQuoteSimple(String recordJson, Id initiatingUserId, String initiatingUserTheme) {
    QuoteRipReplaceSyncQueueableSerial_SL.TaskInputWrapper taskWrapper = (QuoteRipReplaceSyncQueueableSerial_SL.TaskInputWrapper) JSON.deserialize(
      recordJson,
      QuoteRipReplaceSyncQueueableSerial_SL.TaskInputWrapper.class
    );
    SBQQ__Quote__c quoteToUpdate = taskWrapper.quote;

    //QuoteRipReplaceUpdateQueueableOrdered_SL job = new QuoteRipReplaceUpdateQueueableOrdered_SL(quoteToUpdate);

    Map<Id, Map<String, String>> recordIdToFieldUpdateMap = new Map<Id, Map<String, String>>();
    Map<String, String> fieldUpdateMap = new Map<String, String>();
    fieldUpdateMap.put('SBQQ__Ordered__c', 'true');
    recordIdToFieldUpdateMap.put(quoteToUpdate.Id, fieldUpdateMap);
    IRipReplaceUpdater_SL job = RipReplaceUpdaterFactory_SL.getInstance(
      QuoteRipReplaceUpdateQueueableSerial_SL.QUOTE_ORDERED_SYNC_TYPE,
      recordIdToFieldUpdateMap,
      new List<Id>{ quoteToUpdate.Id },
      initiatingUserId,
      initiatingUserTheme
    );
    System.enqueueJob(job);
  }

  public class QuoteRipReplaceUpdateException extends Exception {
  }
}