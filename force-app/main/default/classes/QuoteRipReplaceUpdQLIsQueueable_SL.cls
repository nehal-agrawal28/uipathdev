public with sharing class QuoteRipReplaceUpdQLIsQueueable_SL extends AbstractQueueable implements Database.AllowsCallouts {
  private final String jsonRecords;
  private String originalTransactionId;

  public QuoteRipReplaceUpdQLIsQueueable_SL(String jsonRecords, String originalTransactionId) {
    super('QuoteRipReplaceUpdQLIsQueueable_SL');
    this.jsonRecords = jsonRecords;
    this.originalTransactionId = originalTransactionId;
  }

  public override void work() {
    try {
      execute(ctx, this.jsonRecords);
    } catch (Exception e) {
      System.debug(LoggingLevel.ERROR, 'R&R: QuoteRipReplaceUpdQLIsQueueable_SL: ' + e.getMessage());
      System.debug(LoggingLevel.ERROR, 'R&R: QuoteRipReplaceUpdQLIsQueueable_SL: ' + e.getStackTraceString());
      Logger.error('Failed deserializing/saving Lines into replacement quote', e.getMessage());
      Logger.saveLog();
    }
  }
  public void execute(QueueableContext ctx, String jsonRecords) {
    List<SBQQ__QuoteLine__c> updatedQLIs = (List<SBQQ__QuoteLine__c>) JSON.deserialize(
      jsonRecords,
      List<SBQQ__QuoteLine__c>.class
    );

    if (updatedQLIs.size() > 0) {
      //prevents a callout to pricing service occuring in the after update trigger
      SBQQ.TriggerControl.disable();
      upsert updatedQLIs;
      SBQQ.TriggerControl.enable();
      ////get the quote into a calculated state
      Id quoteId = updatedQLIs[0].SBQQ__Quote__c;
      if (!Test.isRunningTest()) {
        updateQlisAsync(quoteId);
      }
    }
  }

  public static void updateQuoteLines(String jsonRecords) {
    if (jsonRecords != null && String.isNotEmpty(jsonRecords)) {
      AbstractQueueable.enqueue(new QuoteRipReplaceUpdQLIsQueueable_SL(jsonRecords, Logger.getTransactionId()));
    }
  }

  @future(callout=true)
  private static void updateQlisAsync(Id quoteId) {
    QuoteLinesSelector_SL quoteLinesSelector_SL = (QuoteLinesSelector_SL) Application_SL.Selector.newInstance(
      SBQQ__QuoteLine__c.SObjectType
    );
    List<SBQQ__QuoteLine__c> qlis = quoteLinesSelector_SL.selectByParentQuoteId(quoteId);
    fflib_ISObjectUnitOfWork unitOfWork = Application_SL.UnitOfWork.newInstance();
    unitOfWork.registerDirty(qlis);
    unitOfWork.commitWork();
  }
}