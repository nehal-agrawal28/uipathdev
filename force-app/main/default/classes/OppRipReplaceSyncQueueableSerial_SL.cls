public with sharing class OppRipReplaceSyncQueueableSerial_SL extends AbstractQueueable implements IRipReplaceSync_SL {
  private static final Set<Id> PROCESSEDRECORDS = new Set<Id>();
  List<Id> parentRecordIds { get; set; }
  private Id initiatingUserId { get; set; }
  private String initiatingUserTheme { get; set; }
  public final static string OPP_SYNC_TYPE = 'RipReplace_OppSync';

  private final IOpportunitiesService_SL oppService = (IOpportunitiesService_SL) Application_SL.Service.newInstance(
    IOpportunitiesService_SL.class
  );

  public OppRipReplaceSyncQueueableSerial_SL(
    List<Id> parentRecordIds,
    Id initiatingUserId,
    String initiatingUserTheme
  ) {
    super('OppRipReplaceSyncQueueableSerial_SL');
    this.init(parentRecordIds, initiatingUserId, initiatingUserTheme);
    //System.debug('OppRipReplaceSyncQueueableSerial_SL constructed: parentRecordIds: ' + parentRecordIds);
  }

  public OppRipReplaceSyncQueueableSerial_SL() {
    super('OppRipReplaceSyncQueueableSerial_SL');
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
    //System.debug('OppRipReplaceSyncQueueableSerial_SL.work()');

    Map<Id, Map<String, String>> oppIdToFieldUpdateMap = new Map<Id, Map<String, String>>();

    if (parentRecordIds != null && parentRecordIds.size() > 0) {
      //1. get child opp in correct state
      List<Opportunity> oppsToUpdate = oppService.syncFieldOnCancelledOpps(
        new Set<Id>(parentRecordIds),
        Opportunity.StageName
      );
      for (Opportunity opp : oppsToUpdate) {
        Map<String, String> fieldNameMap = new Map<String, String>();
        fieldNameMap.put('StageName', opp.StageName);
        oppIdToFieldUpdateMap.put(opp.Id, fieldNameMap);
      }
      //2. create async tasks for all the opps to update
      createAsyncTasks(oppsToUpdate);

      //3. delegate the update process to queueable w/ finalizer
      AbstractQueueable job = (AbstractQueueable) RipReplaceUpdaterFactory_SL.getInstance(
        OPP_SYNC_TYPE,
        oppIdToFieldUpdateMap,
        new List<Id>(oppIdToFieldUpdateMap.keySet()),
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
    List<Opportunity> records,
    Map<Id, SObject> existingRecords
  ) {
    //System.debug('OppRipReplaceSyncQueueableSerial_SL.syncCancelledOppsWithReplacementOpp()' );

    //Feature Toggle
    List<CPQ_RR_Sync_Feature__mdt> featureControls = new List<CPQ_RR_Sync_Feature__mdt>();
    try {
      featureControls = [
        SELECT Is_Active__c
        FROM CPQ_RR_Sync_Feature__mdt
        WHERE Sync_Target_Object__c = 'Opportunity' AND Is_Active__c = TRUE
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

    OpportunitiesSelector_SL oppsSelectorSL = (OpportunitiesSelector_SL) Application_SL.Selector.newInstance(
      Opportunity.SObjectType
    );

    SObjectPredicate hasChanged = new HasRecordChanged(
      new Set<SObjectField>{ Opportunity.StageName },
      records,
      existingRecords
    );

    SObjectPredicate isStillNotProcessed = new IsRecordNotProcessedYet(PROCESSEDRECORDS);

    List<Opportunity> stageChangeOpps = Collection.of(records)
      .filter(
        Match.field(Opportunity.Replacement_Transaction__c)
          .hasValue()
          .also(Opportunity.Replacement_Transaction__c)
          .equals(true)
      )
      .filter(isStillNotProcessed)
      .filter(hasChanged)
      .asList();

    if (!stageChangeOpps.isEmpty()) {
      Set<Id> stageChangeOppIds = new Set<Id>(Collection.of(stageChangeOpps).pluckIds());

      //requery to get state change replacement opp only
      List<Opportunity> eligibleOpps = oppsSelectorSL.getEligibleReplacementOpps(stageChangeOppIds);

      if (!eligibleOpps.isEmpty()) {
        List<Id> eligibleRecordIds = Collection.of(eligibleOpps).pluckIds();
        PROCESSEDRECORDS.addAll(eligibleRecordIds);

        //move into async context for subsequent processing
        //for error notifications, capture user details in sync context
        Id initiatingUserId = UserInfo.getUserId();
        String initiatingUserTheme = UserInfo.getUiThemeDisplayed();
        AbstractQueueable job = (AbstractQueueable) RipReplaceSyncFactory_SL.getInstance(
          OppRipReplaceSyncQueueableSerial_SL.OPP_SYNC_TYPE,
          eligibleRecordIds,
          initiatingUserId,
          initiatingUserTheme
        );
        if (!Test.isRunningTest()) {
          System.debug(LoggingLevel.ERROR, '^^^ attempting to enqueue OppRipReplaceSyncQueueableSerial_SL');
          AbstractQueueable.enqueue(job);
        } else {
          job.work();
        }
      }
    }
  }

  public static void createAsyncTasks(List<Opportunity> opps) {
    List<AsyncTask__c> taskList = new List<AsyncTask__c>();
    for (Opportunity opp : opps) {
      TaskInputWrapper inputs = new TaskInputWrapper(opp);
      AsyncTask__c prefilledTask = new AsyncTask__c(
        Account__c = opp.AccountId,
        Opportunity__c = opp.Id, // Replacement opp id
        Status__c = 'Inprogress',
        Type__c = OppRipReplaceSyncTask_SL.SYNC_TASK_TYPE
      );
      AsyncTask__c newTask = AsyncTaskManager_TS.createTask(
        OppRipReplaceSyncQueueableSerial_SL.OPP_SYNC_TYPE,
        JSON.serialize(inputs),
        prefilledTask,
        false
      );
      taskList.add(newTask);
    }
    insert taskList;
  }

  public class TaskInputWrapper {
    public Opportunity opp;
    public TaskInputWrapper(Opportunity opp) {
      this.opp = opp;
    }
  }

  public class OppRipReplaceSyncException extends Exception {
  }
}