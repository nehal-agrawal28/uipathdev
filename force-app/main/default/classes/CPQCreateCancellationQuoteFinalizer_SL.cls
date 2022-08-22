public without sharing class CPQCreateCancellationQuoteFinalizer_SL implements Finalizer {
  public static final Integer MAX_RETRY = 2;
  String contractId { get; set; }
  List<String> queueContracts { get; set; }
  Date startDate { get; set; }
  String quoteId { get; set; }
  List<String> retryJob { get; set; } //BUG: Primitive datatype not updating when finalizer run after failure
  private static QuotesSelector_SL quoteSelector {
    get {
      return (QuotesSelector_SL) Application_SL.Selector.newInstance(SBQQ__Quote__c.SObjectType);
    }
    set;
  }

  public CPQCreateCancellationQuoteFinalizer_SL(
    String contractId,
    Date startDate,
    String quoteId,
    List<String> queueContracts,
    List<String> retryJob
  ) {
    this.contractId = contractId;
    this.startDate = startDate;
    this.quoteId = quoteId;
    this.queueContracts = queueContracts;
    this.retryJob = retryJob;
  }

  // Finalizer implementation
  public void execute(FinalizerContext ctx) {
    String parentJobId = '' + ctx.getAsyncApexJobId();
    if (ctx.getResult() == ParentJobResult.SUCCESS) {
      // Success
      createEvent(parentJobId, quoteId, contractId, null); // success event for UI
      nextJob();
    } else {
      // Error
      Integer retryCount = retryJob.size();
      if (retryCount < MAX_RETRY) {
        // retry job
        retryJob.add(parentJobId);
        enqueueCancellationJob(contractId, startDate, quoteId, queueContracts, retryJob);
      } else {
        createEvent(parentJobId, quoteId, contractId, ctx.getException().getMessage()); // failure event for UI
        nextJob();
      }
    }
  }

  // Start next contract processing, consolidate, or set replacement transaction flag
  @TestVisible
  private void nextJob() {
    if (queueContracts != null && queueContracts.size() > 0) {
      // pop new contract and start job
      retryJob.clear();
      enqueueCancellationJob(queueContracts.remove(0), startDate, quoteId, queueContracts, retryJob);
    } else {
      SBQQ__Quote__c quote = (quoteSelector.selectById(new Set<Id>{ quoteId }, false))[0];
      // for a system created replacement quote, consolidate (clone) all cancellation lines into it
      if (quote.Replacement_Transaction__c) {
        enqueueConsolidationJob(quoteId);
      } else {
        // for a user created replacement quote, set replacement transaction flag only
        final fflib_ISObjectUnitOfWork unitOfWork = Application_SL.UnitOfWork.newInstance();
        quote.Replacement_Transaction__c = true;
        unitOfWork.registerDirty(quote);
        unitOfWork.commitWork();
      }
    }
  }

  private void enqueueCancellationJob(
    String contractId,
    Date startDate,
    String quoteId,
    List<String> queueContracts,
    List<String> retryJob
  ) {
    String sDateStr = String.valueOf(startDate);
    CPQCreateCancellationQuoteSerial_SL job = new CPQCreateCancellationQuoteSerial_SL(
      contractId,
      sDateStr,
      quoteId,
      queueContracts
    );
    job.retryJob = retryJob;
    System.enqueueJob(job);
  }

  private void enqueueConsolidationJob(String quoteId) {
    CPQConsolidateReplacementLines_SL quoteLineQueueable = new CPQConsolidateReplacementLines_SL(
      null,
      quoteId,
      Logger.getTransactionId()
    );
    // Test classes cannot chain queueables, we are just going to directly execute it
    if (Test.isRunningTest()) {
      quoteLineQueueable.execute();
    } else {
      AbstractQueueable.enqueue(quoteLineQueueable);
    }
  }

  // Creates an event with the jobId and the amended quote for the lwc can listen for when the job is done
  private void createEvent(String jobId, String quoteId, String contractId, String error) {
    ContractModEvent__e ripReplaceEvent = new ContractModEvent__e();
    ripReplaceEvent.JobId__c = jobId.substring(0, 18);
    ripReplaceEvent.QuoteId__c = quoteId.substring(0, 18);
    ripReplaceEvent.ContractId__c = contractId.substring(0, 18);
    ripReplaceEvent.Error__c = error?.substring(0, 254);

    Database.SaveResult sr = EventBus.publish(ripReplaceEvent);

    if (sr.isSuccess()) {
      // Logger.debug('Successfully published ContractModEvent for contract ' + contractId, quoteId);
    } else {
      for (Database.Error err : sr.getErrors()) {
        Logger.error('Failed Publishing ContractModEvent for contract ' + err.getMessage() + contractId, quoteId);
      }
    }
    Logger.saveLog();

    updateAsyncTask(jobId, contractId, quoteId, error);
  }

  private void updateAsyncTask(String jobId, String contractId, String replacementQuoteId, String error) {
    try {
      List<AsyncTask__c> currentTaskList = [
        SELECT Id, Status__c
        FROM AsyncTask__c
        WHERE Quote__c = :replacementQuoteId AND Contract__c = :contractId
        ORDER BY CreatedDate DESC
        LIMIT 1
      ];
      if (currentTaskList.size() > 0) {
        AsyncTask__c currentTask = currentTaskList[0];
        currentTask.ApexJobId__c = jobId;
        if (error != null) {
          currentTask.Status__c = 'Error';
          currentTask.Error__c = error;
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
}