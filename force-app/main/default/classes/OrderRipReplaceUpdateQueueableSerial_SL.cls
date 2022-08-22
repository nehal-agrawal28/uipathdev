public with sharing class OrderRipReplaceUpdateQueueableSerial_SL extends AbstractQueueable implements IRipReplaceUpdater_SL {
  private Map<Id, Map<String, String>> recordIdToFieldUpdateMap { get; set; }
  private List<Id> childRecordIds { get; set; }
  private Id initiatingUserId { get; set; }
  private String initiatingUserTheme { get; set; }
  private static String ORDER_SYNC_TYPE = 'RipReplace_OrderSync';
  public List<String> retryJob {
    get {
      if (retryJob == null) {
        retryJob = new List<String>();
      }
      return retryJob;
    }
    set;
  }

  public OrderRipReplaceUpdateQueueableSerial_SL(
    Map<Id, Map<String, String>> recordIdToFieldUpdateMap,
    List<Id> childRecordIds,
    Id initiatingUserId,
    String initiatingUserTheme,
    List<String> retryJob
  ) {
    super('OrderRipReplaceUpdateQueueableSerial_SL');
    this.init(recordIdToFieldUpdateMap, childRecordIds, initiatingUserId, initiatingUserTheme, retryJob);
    //System.debug('OrderRipReplaceUpdateQueueableSerial_SL constructed: recordIdToFieldUpdateMap: ' + recordIdToFieldUpdateMap);
  }
  public OrderRipReplaceUpdateQueueableSerial_SL(
    Map<Id, Map<String, String>> recordIdToFieldUpdateMap,
    List<Id> childRecordIds,
    Id initiatingUserId,
    String initiatingUserTheme
  ) {
    super('OrderRipReplaceUpdateQueueableSerial_SL');
    this.init(recordIdToFieldUpdateMap, childRecordIds, initiatingUserId, initiatingUserTheme, new List<String>());
  }

  public OrderRipReplaceUpdateQueueableSerial_SL() {
    super('OrderRipReplaceUpdateQueueableSerial_SL');
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
      'RipReplace_OrderSync'
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
        Id childRecordId = childRecordIds.get(0);
        Map<String, String> fieldUpdateMap = recordIdToFieldUpdateMap.get(childRecordId);
        Order childRecord = new Order(Id = childRecordId);
        for (String fieldName : fieldUpdateMap.keySet()) {
          childRecord.put(fieldName, fieldUpdateMap.get(fieldName));
        }
        fflib_ISObjectUnitOfWork unitOfWork = Application_SL.UnitOfWork.newInstance();
        unitOfWork.registerDirty(childRecord);
        unitOfWork.commitWork();
      }
      //queueable job chaining test limitation, simulate finaliser operation
      if (Test.isRunningTest() && childRecordIds != null && childRecordIds.size() > 1) {
        IRecRipReplaceUpdQueueableFinalizer_SL finalizer = new RecRipReplaceUpdQueueableFinalizer_SL(
          recordIdToFieldUpdateMap,
          childRecordIds,
          retryJob,
          initiatingUserId,
          initiatingUserTheme,
          ORDER_SYNC_TYPE
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
        ORDER_SYNC_TYPE
      );
      //record failure in async task
      RecRipReplaceUpdQueueableFinalizer_SL.updateAsyncTask(jobId, childRecordIds[0], dml);
    } catch (Exception e) {
      throw new OrderRipReplaceUpdateException(e.getMessage(), e);
    }
  }

  public class OrderRipReplaceUpdateException extends Exception {
  }
}