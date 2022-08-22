public with sharing class QuoteRipReplaceUpdateQueueableOrdered_SL implements Queueable, Database.AllowsCallouts, IRipReplaceUpdater_SL {
  private SBQQ__Quote__c quoteToUpdate;
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

  public QuoteRipReplaceUpdateQueueableOrdered_SL() {
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
  }

  public void execute(System.QueueableContext ctx) {
    IRecRipReplaceUpdQueueableFinalizer_SL finalizer = new RecRipReplaceUpdQueueableFinalizer_SL(
      this.recordIdToFieldUpdateMap,
      this.childRecordIds,
      this.retryJob,
      this.initiatingUserId,
      this.initiatingUserTheme,
      'RipReplace_QuoteSyncOrdered'
    );
    System.attachFinalizer(finalizer);

    work();
  }

  public void work() {
    try {
      SBQQ__Quote__c quoteToUpdate = new SBQQ__Quote__c(Id = childRecordIds.get(0));
      quoteToUpdate.put('SBQQ__Ordered__c', true);
      fflib_ISObjectUnitOfWork unitOfWork = Application_SL.UnitOfWork.newInstance();
      unitOfWork.registerDirty(quoteToUpdate);
      unitOfWork.commitWork();
    } catch (DmlException dml) {
      throw new QuoteRipReplaceUpdateQueueableOrderedException('Record validation error: ' + dml.getDmlMessage(0), dml);
    } catch (Exception e) {
      throw new QuoteRipReplaceUpdateQueueableOrderedException(e.getMessage(), e);
    }
  }

  public class QuoteRipReplaceUpdateQueueableOrderedException extends Exception {
  }
}