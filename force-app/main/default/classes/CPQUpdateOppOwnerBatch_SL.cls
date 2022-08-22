/**
 * Batch job to update amendment and renewal opportunity's owner
 *
 * @author Salestech
 * @date  01/12/2021
 *
 */
public without sharing class CPQUpdateOppOwnerBatch_SL implements Database.Batchable<sObject>, Database.Stateful {
  private final Integer OPP_PROBABILITY = 70; // Negotiation : max probability to consider

  private String originalTransactionId;
  private Set<Id> contractIds = new Set<Id>();

  public CPQUpdateOppOwnerBatch_SL(Set<Id> contractIds) {
    this.contractIds = contractIds;
  }

  public Database.QueryLocator start(Database.BatchableContext context) {
    // Storing transaction Id for Logging purposes
    this.originalTransactionId = Logger.getTransactionId();
    Logger.info('Starting CPQUpdateOppOwnerBatch_SL Batch');
    Logger.saveLog();

    return this.getQueryLocator();
  }

  public void execute(Database.BatchableContext bc, List<Opportunity> oppList) {
    try {
      Logger.setParentLogTransactionId(this.originalTransactionId);
      Map<Id, Opportunity> oppsToUpdate = new Map<Id, Opportunity>();

      // CPQ  Owner fields syncing
      for (Opportunity opp : oppList) {
        if (opp.OwnerId != opp.Account.OwnerId) {
          Logger.info('Opportunity owner updated from ' + opp.OwnerId + ' to ' + opp.Account.OwnerId, opp.Id);

          opp.OwnerId = opp.Account.OwnerId;
          oppsToUpdate.put(opp.Id, opp);
        }
      }

      // Logging only when something was updated
      if (oppsToUpdate.size() > 0) {
        Database.update(oppsToUpdate.values(), false);
        Logger.saveLog();
      }
    } catch (Exception e) {
      Logger.error('Error in CPQContractMaintenanceBatch_SL Batch', e);
      Logger.saveLog();
    }
  }

  public void finish(Database.BatchableContext BC) {
    Logger.setParentLogTransactionId(this.originalTransactionId);
    Logger.info('Finishing CPQUpdateOppOwnerBatch_SL Batch');
    Logger.saveLog();
  }

  public Database.QueryLocator getQueryLocator() {
    return this.contractIds != null &&
      this.contractIds.size() > 0
      ? Database.getQueryLocator(
          [
            SELECT Id, OwnerId, AccountId, Account.OwnerId
            FROM Opportunity
            WHERE
              (SBQQ__RenewedContract__c IN :contractIds
              OR SBQQ__AmendedContract__c IN :contractIds)
              AND IsClosed = FALSE
              AND Probability <= :OPP_PROBABILITY
              AND CloseDate > TODAY
          ]
        )
      : null;
  }
}