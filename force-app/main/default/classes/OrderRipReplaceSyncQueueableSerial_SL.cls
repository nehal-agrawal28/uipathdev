public with sharing class OrderRipReplaceSyncQueueableSerial_SL extends AbstractQueueable implements IRipReplaceSync_SL {
  private static final Set<Id> PROCESSEDRECORDS = new Set<Id>();
  List<Id> parentRecordIds { get; set; }
  private Id initiatingUserId { get; set; }
  private String initiatingUserTheme { get; set; }

  private final IOrdersService_SL recordService = (IOrdersService_SL) Application_SL.Service.newInstance(
    IOrdersService_SL.class
  );

  public OrderRipReplaceSyncQueueableSerial_SL() {
    super('OrderRipReplaceSyncQueueableSerial_SL');
  }

  public OrderRipReplaceSyncQueueableSerial_SL(
    List<Id> parentRecordIds,
    Id initiatingUserId,
    String initiatingUserTheme
  ) {
    super('OrderRipReplaceSyncQueueableSerial_SL');
    this.init(parentRecordIds, initiatingUserId, initiatingUserTheme);
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
    //System.debug('### OrderRipReplaceSyncQueueableSerial_SL.work()');
    if (parentRecordIds != null && parentRecordIds.size() > 0) {
      //for each order id, map field name to new field value
      Map<Id, Map<String, String>> recordIdToFieldUpdateMap = new Map<Id, Map<String, String>>();

      //get the sync changes by field
      Map<Id, Order> updatedStatusOrders = recordService.syncFieldOnCancelledOrders(
        new Set<Id>(parentRecordIds),
        Order.Status
      );

      //consolidate the changes down into a single update - Start Date field
      for (Id oId : updatedStatusOrders.keySet()) {
        Map<String, String> fieldNameMap = new Map<String, String>();
        if (recordIdToFieldUpdateMap.containsKey(oId)) {
          fieldNameMap = recordIdToFieldUpdateMap.get(oId);
        }
        Order o = updatedStatusOrders.get(oId);
        fieldNameMap.put('Status', String.valueOf(o.Status));
        recordIdToFieldUpdateMap.put(oId, fieldNameMap);
      }

      //2. create async tasks for all the records to update
      createAsyncTasks(updatedStatusOrders.values());
      //System.debug('### OrderRipReplaceSyncQueueableSerial_SL.recordIdToFieldUpdateMap.keySet(): ' + recordIdToFieldUpdateMap.keySet());

      //3. delegate the update process to queueable w/ finaliser
      AbstractQueueable job = (AbstractQueueable) RipReplaceUpdaterFactory_SL.getInstance(
        'RipReplace_OrderSync',
        recordIdToFieldUpdateMap,
        new List<Id>(recordIdToFieldUpdateMap.keySet()),
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

  public static void syncCancelledRecordsWithReplacementRecord(List<Order> records, Map<Id, SObject> existingRecords) {
    //Feature Toggle
    List<CPQ_RR_Sync_Feature__mdt> featureControls = new List<CPQ_RR_Sync_Feature__mdt>();
    try {
      featureControls = [
        SELECT Is_Active__c
        FROM CPQ_RR_Sync_Feature__mdt
        WHERE Sync_Target_Object__c = 'Order' AND Is_Active__c = TRUE
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

    SObjectPredicate hasChanged = new HasRecordChanged(new Set<SObjectField>{ Order.Status }, records, existingRecords);

    SObjectPredicate isStillNotProcessed = new IsRecordNotProcessedYet(PROCESSEDRECORDS);

    List<Order> eligibleRecords = Collection.of(records)
      .filter(
        Match.field(Order.Replacement_Order__c)
          .equals(null)
          .also(Order.Replacement_Transaction__c)
          .hasValue()
          .also(Order.Replacement_Transaction__c)
          .equals(true)
      )
      .filter(isStillNotProcessed)
      .filter(hasChanged)
      .asList();

    if (!eligibleRecords.isEmpty()) {
      List<Id> eligibleRecordIds = Collection.of(eligibleRecords).pluckIds();
      PROCESSEDRECORDS.addAll(eligibleRecordIds);

      //move into async context for subsequent processing
      //for error notifications, capture user details in sync context
      Id initiatingUserId = UserInfo.getUserId();
      String initiatingUserTheme = UserInfo.getUiThemeDisplayed();
      //System.debug('### OrderRipReplaceSyncQueueableSerial_SL eligibleRecordIds: ' + eligibleRecordIds);
      AbstractQueueable job = (AbstractQueueable) RipReplaceSyncFactory_SL.getInstance(
        'RipReplace_OrderSync',
        eligibleRecordIds,
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

  public static void createAsyncTasks(List<Order> records) {
    List<AsyncTask__c> taskList = new List<AsyncTask__c>();
    for (Order record : records) {
      TaskInputWrapper inputs = new TaskInputWrapper(record);
      AsyncTask__c prefilledTask = new AsyncTask__c(
        Account__c = record.AccountId,
        Opportunity__c = record.OpportunityId,
        Order__c = record.Id,
        Status__c = 'Inprogress',
        Type__c = OrderRipReplaceSyncTask_SL.SYNC_TASK_TYPE
      );
      AsyncTask__c newTask = AsyncTaskManager_TS.createTask(
        'RipReplace_OrderSync',
        JSON.serialize(inputs),
        prefilledTask,
        false
      );
      taskList.add(newTask);
    }
    insert taskList;
  }

  public class TaskInputWrapper {
    public Order record;
    public TaskInputWrapper(Order record) {
      this.record = record;
    }
  }
}