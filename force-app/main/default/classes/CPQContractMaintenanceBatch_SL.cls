/**
 * Batch job to keep renewal and amendment owners in sync with account owner
 *
 * @author Salestech
 * @date  01/12/2021
 *
 */
public without sharing class CPQContractMaintenanceBatch_SL implements Schedulable, Database.Batchable<sObject>, IGenericBatch, Database.Stateful {
  public static final Integer OPP_UPDATE_BATCH_SIZE = 1;

  private String originalTransactionId;
  private Set<Id> updatedContractIds = new Set<Id>();

  public Database.QueryLocator start(Database.BatchableContext context) {
    // Storing transaction Id for Logging purposes
    this.originalTransactionId = Logger.getTransactionId();
    Logger.info('Starting CPQContractMaintenanceBatch_SL Batch');
    Logger.saveLog();

    return this.getQueryLocator();
  }

  public void execute(Database.BatchableContext bc, List<Contract> contractList) {
    try {
      Logger.setParentLogTransactionId(this.originalTransactionId);
      Map<Id, Contract> contractsToUpdate = new Map<Id, Contract>();

      // CPQ  Owner fields syncing
      for (Contract con : contractList) {
        if (con.SBQQ__AmendmentOwner__c != con.Account.OwnerId || con.SBQQ__RenewalOwner__c != con.Account.OwnerId) {
          Logger.info(
            'Amendment Owner field updated from ' +
            con.SBQQ__AmendmentOwner__c +
            ' to ' +
            con.Account.OwnerId,
            con.Id
          );
          Logger.info(
            'Renewal Owner field updated from ' +
            con.SBQQ__RenewalOwner__c +
            ' to ' +
            con.Account.OwnerId,
            con.Id
          );

          con.SBQQ__AmendmentOwner__c = con.Account.OwnerId;
          con.SBQQ__RenewalOwner__c = con.Account.OwnerId;
          contractsToUpdate.put(con.Id, con);
        }
      }

      // Logging only when something was updated
      if (contractsToUpdate.size() > 0) {
        Database.update(contractsToUpdate.values(), false);
        updatedContractIds.addAll(contractsToUpdate.keySet());
        Logger.saveLog();
      }
    } catch (Exception e) {
      Logger.error('Error in CPQContractMaintenanceBatch_SL Batch', e);
      Logger.saveLog();
    }
  }

  public void finish(Database.BatchableContext BC) {
    Logger.setParentLogTransactionId(this.originalTransactionId);

    try {
      //Removing logic as part of SLTCHIN1375
      /*if (updatedContractIds.size() > 0) {
        // Execute batch job to update related amendment and renewal opportunity owner
        CPQUpdateOppOwnerBatch_SL oppUpdateBatch = new CPQUpdateOppOwnerBatch_SL(updatedContractIds);
        Database.executeBatch(oppUpdateBatch, OPP_UPDATE_BATCH_SIZE);

        Logger.info('Submitted CPQUpdateOppOwnerBatch_SL Batch');
      }*/
    } catch (Exception e) {
      Logger.error('Error in CPQContractMaintenanceBatch_SL Batch', e);
    }

    Logger.info('Finishing CPQContractMaintenanceBatch_SL Batch');
    Logger.saveLog();
  }

  public Database.QueryLocator getQueryLocator() {
    return Database.getQueryLocator(
      [
        SELECT Id, SBQQ__AmendmentOwner__c, SBQQ__RenewalOwner__c, AccountId, Account.OwnerId
        FROM Contract
        WHERE Status = 'Activated' AND EndDate > TODAY
      ]
    );
  }

  /**
   * @param context Schedule the batch
   */
  public void execute(SchedulableContext context) {
    Database.executeBatch(this, 500);
  }
}