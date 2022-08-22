public class CPQContractRenewalBatch_SL implements Database.Batchable<sObject>, Database.Stateful {
  private final Integer maxRetryAttempts = 3;
  private final Integer retryBatchSize = 1;
  private String originalTransactionId;
  private final Set<Id> retryIds;
  private final Integer renewalAttempt;

  public CpqContractRenewalBatch_SL() {
    this.renewalAttempt = 1;
    this.retryIds = new Set<Id>();
  }
  public CpqContractRenewalBatch_SL(Set<Id> retryIds, Integer renewalAttempt) {
    this.retryIds = retryIds;
    this.renewalAttempt = renewalAttempt;
  }

  public Database.QueryLocator start(Database.BatchableContext BC) {
    this.originalTransactionId = Logger.getTransactionId();
    Logger.info('Starting CpqContractRenewalBatch_SL Batch');
    Logger.saveLog();
    System.debug('*** Starting Renewal Batch');
    return this.getQueryLocator();
  }

  public void execute(Database.BatchableContext BC, List<Contract> scope) {
    Set<Id> contractsToReforecast = new Set<Id>();
    for (Contract con : scope) {
      List<Opportunity> renOps = con.SBQQ__RenewalOpportunities__r;
      if (renOps.size() > 0 && renOps[0].isClosed) {
        //branch 1
        con.SBQQ__RenewalOpportunity__c = renOps[0].Id;
      } else if (renOps.size() > 0) {
        //branch 2
        con.SBQQ__RenewalOpportunity__c = renOps[0].Id;
        con.SBQQ__RenewalForecast__c = false;
        contractsToReforecast.add(con.Id);
      } else if (renOps.isEmpty()) {
        //branch 3
        con.SBQQ__RenewalForecast__c = false;
        contractsToReforecast.add(con.Id);
      }
      //apply tidying to all contracts
      con.SBQQ__DefaultRenewalContactRoles__c = false;
    }
    Database.SaveResult[] srList;
    SBQQ.TriggerControl.disable();
    fflib_SObjectDomain.getTriggerEvent(Contracts_SL.class).disableAll();
    Database.DMLOptions dml = new Database.DMLOptions();
    dml.OptAllOrNone = false;
    srList = Database.update(scope, dml);
    fflib_SObjectDomain.getTriggerEvent(Contracts_SL.class).enableAll();
    SBQQ.TriggerControl.enable();

    for (Database.SaveResult sr : srList) {
      if (!sr.isSuccess()) {
        contractsToReforecast.remove(sr.getId());
        retryIds.add(sr.getId());
      } else if (retryIds.contains(sr.getId())) {
        retryIds.remove(sr.getId());
      }
    }

    if (!contractsToReforecast.isEmpty()) {
      //set SBQQ__RenewalForecast__c for relevant records
      AbstractQueueable.enqueue(new RenewalForecaster(contractsToReforecast));
    }
  }

  public void finish(Database.BatchableContext BC) {
    Logger.setParentLogTransactionId(this.originalTransactionId);
    Logger.info('Finishing CpqContractRenewalBatch_SL Batch');
    Logger.saveLog();
    if (!retryIds.isEmpty() && renewalAttempt < maxRetryAttempts && !Test.isRunningTest()) {
      CpqContractRenewalBatch_SL retryBatchJob = new CpqContractRenewalBatch_SL(this.retryIds, this.renewalAttempt + 1);
      Database.executeBatch(retryBatchJob, 1);
    }
    System.debug('*** Finishing Renewal Batch');
  }

  @TestVisible
  private class RenewalForecaster extends AbstractQueueable {
    Set<Id> recordids;
    public RenewalForecaster(Set<Id> recordIds) {
      super('CpqContractRenewalBatch_SL.RenewalForecaster');
      this.recordIds = recordIds;
    }

    public override void work() {
      if (!Test.isRunningTest()) {
        execute(ctx.getJobId());
      } else {
        execute('TEST');
      }
    }

    public void execute(String jobId) {
      List<Contract> contracts = new List<Contract>();
      for (Id conId : recordIds) {
        contracts.add(new Contract(Id = conId, SBQQ__RenewalForecast__c = true));
      }
      if (!contracts.isEmpty()) {
        update contracts;
      }
    }
  }

  private Database.QueryLocator getQueryLocator() {
    return Database.getQueryLocator(
      [
        SELECT Id, (SELECT Id, IsClosed, StageName FROM SBQQ__RenewalOpportunities__r ORDER BY CreatedDate DESC)
        FROM Contract
        WHERE
          (ActivatedDate = LAST_N_DAYS:4
          AND SBQQ__RenewalForecast__c = TRUE
          AND SBQQ__RenewalOpportunity__c = NULL)
          OR Id IN :retryIds
      ]
    );
  }
}