public with sharing class OppRipReplaceUpdateQueueableSerial_SL extends AbstractQueueable implements IRipReplaceUpdater_SL {
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
  public string OPP_SYNC_TYPE = 'RipReplace_OppSync';

  public OppRipReplaceUpdateQueueableSerial_SL(
    Map<Id, Map<String, String>> recordIdToFieldUpdateMap,
    List<Id> childRecordIds,
    Id initiatingUserId,
    String initiatingUserTheme,
    List<String> retryJob
  ) {
    super('OppRipReplaceUpdateQueueableSerial_SL');
    this.init(recordIdToFieldUpdateMap, childRecordIds, initiatingUserId, initiatingUserTheme, retryJob);
  }

  public OppRipReplaceUpdateQueueableSerial_SL(
    Map<Id, Map<String, String>> recordIdToFieldUpdateMap,
    List<Id> childRecordIds,
    Id initiatingUserId,
    String initiatingUserTheme
  ) {
    super('OppRipReplaceUpdateQueueableSerial_SL');
    this.init(recordIdToFieldUpdateMap, childRecordIds, initiatingUserId, initiatingUserTheme, new List<String>());
  }

  public OppRipReplaceUpdateQueueableSerial_SL() {
    super('OppRipReplaceUpdateQueueableSerial_SL');
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
      OPP_SYNC_TYPE
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
        Id childOppId = childRecordIds.get(0);
        Map<String, String> fieldUpdateMap = recordIdToFieldUpdateMap.get(childOppId);
        Opportunity childOpp = new Opportunity(Id = childOppId);
        for (String fieldName : fieldUpdateMap.keySet()) {
          childOpp.put(fieldName, fieldUpdateMap.get(fieldName));
        }
        fflib_ISObjectUnitOfWork unitOfWork = Application_SL.UnitOfWork.newInstance();
        unitOfWork.registerDirty(childOpp);
        unitOfWork.commitWork();
      }
      //queueable job chaining test limitation, simulate finalizer operation
      if (Test.isRunningTest() && childRecordIds != null && childRecordIds.size() > 1) {
        IRecRipReplaceUpdQueueableFinalizer_SL finalizer = new RecRipReplaceUpdQueueableFinalizer_SL(
          recordIdToFieldUpdateMap,
          childRecordIds,
          retryJob,
          initiatingUserId,
          initiatingUserTheme,
          OPP_SYNC_TYPE
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
        OPP_SYNC_TYPE
      );
      //record failure in async task
      RecRipReplaceUpdQueueableFinalizer_SL.updateAsyncTask(jobId, childRecordIds[0], dml);
    } catch (Exception e) {
      throw new OppRipReplaceUpdateException(e.getMessage(), e);
    }
  }

  public class OppRipReplaceUpdateException extends Exception {
  }
}