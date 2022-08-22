/*
 * Batch to resolve the Sync Issues between Opportunity and Quote
 * To Check the discrepancies of Amount between Opportunity & Quote
 * Sync Start and End dates between Quote Lines & Opportunity products
 */

global with sharing class CPQOpportunityMaintenanceBatch_SL implements Database.Batchable<sObject>, Database.Stateful, Schedulable {
  private String originalTransactionId;

  public CPQOpportunityMaintenanceBatch_SL() {
  }

  public Database.QueryLocator start(Database.BatchableContext context) {
    this.originalTransactionId = Logger.getTransactionId();
    Logger.info('Starting CPQOpportunityMaintenanceBatch_SL');
    Logger.saveLog();
    return this.getQueryLocator();
  }

  public void execute(Database.BatchableContext bc, List<SBQQ__Quote__c> quoteList) {
    try {
      AbstractQueueable.deferEnqueue();

      Set<Id> quoteIdSet = new Set<Id>();
      List<Id> OpportunityIdList = Collection.of(quoteList).pluckIds(SBQQ__Quote__c.SBQQ__Opportunity2__c);
      Map<Id, Opportunity> opportunityMap = new Map<Id, Opportunity>(
        [
          SELECT Id, Amount, (SELECT Id, ServiceDate, End_Date__c, SBQQ__QuoteLine__c FROM OpportunityLineItems)
          FROM Opportunity
          WHERE Id IN :OpportunityIdList
        ]
      );

      List<SBQQ__Quote__c> quoteUpdateList = new List<SBQQ__Quote__c>();
      for (SBQQ__Quote__c quote : quoteList) {
        Opportunity oppty = opportunityMap.get(quote.SBQQ__Opportunity2__c);
        Decimal oppAmount = oppty.Amount != null ? oppty.Amount.setScale(2, System.RoundingMode.HALF_UP) : null;
        Decimal quoteAmount = quote.SBQQ__NetAmount__c != null
          ? quote.SBQQ__NetAmount__c.setScale(2, System.RoundingMode.HALF_UP)
          : null;

        if (quoteAmount != oppAmount) {
          quoteUpdateList.add(quote);
          quoteIdSet.add(quote.Id);
          continue;
        }

        if (quote.Billing_Segments__r.size() == 0) {
          quoteUpdateList.add(quote);
          quoteIdSet.add(quote.Id);
          continue;
        }

        Map<Id, SBQQ__QuoteLine__c> quoteLineMap = new Map<Id, SBQQ__QuoteLine__c>();
        for (SBQQ__QuoteLine__c quoteLine : quote.SBQQ__LineItems__r) {
          quoteLineMap.put(quoteLine.Id, quoteLine);
        }

        for (OpportunityLineItem oli : oppty.OpportunityLineItems) {
          if (
            (oli.ServiceDate != quoteLineMap.get(oli.SBQQ__QuoteLine__c).SBQQ__EffectiveStartDate__c ||
            oli.End_Date__c != quoteLineMap.get(oli.SBQQ__QuoteLine__c).SBQQ__EffectiveEndDate__c) &&
            !quoteIdSet.contains(quoteLineMap.get(oli.SBQQ__QuoteLine__c).SBQQ__Quote__c)
          ) {
            quoteUpdateList.add(quote);
            break;
          }
        }
      }

      for (SBQQ__Quote__c quote : quoteUpdateList) {
        quote.SBQQ__Primary__c = false;
      }

      if (!quoteUpdateList.isEmpty() && quoteUpdateList.size() > 0) {
        update quoteUpdateList;
      }

      for (SBQQ__Quote__c quote : quoteUpdateList) {
        quote.SBQQ__Primary__c = true;
      }

      if (!quoteUpdateList.isEmpty() && quoteUpdateList.size() > 0) {
        update quoteUpdateList;
      }
      AbstractQueueable.commitChain();
    } catch (Exception e) {
      Logger.error('Error in CPQOpportunityMaintenanceBatch_SL', e);
      Logger.saveLog();
    }
  }

  public void finish(Database.BatchableContext BC) {
    Logger.setParentLogTransactionId(this.originalTransactionId);
    Logger.info('Finishing CPQOpportunityMaintenanceBatch_SL');
    Logger.saveLog();
  }

  public Database.QueryLocator getQueryLocator() {
    return Database.getQueryLocator(
      [
        SELECT
          Id,
          SBQQ__Primary__c,
          SBQQ__Opportunity2__c,
          SBQQ__NetAmount__c,
          (SELECT Id, SBQQ__EffectiveStartDate__c, SBQQ__EffectiveEndDate__c, SBQQ__Quote__c FROM SBQQ__LineItems__r),
          (SELECT Id, Quote__c FROM Billing_Segments__r)
        FROM SBQQ__Quote__c
        WHERE lastmodifieddate = LAST_N_DAYS:3 AND SBQQ__Primary__c = TRUE AND SBQQ__Opportunity2__r.IsClosed = FALSE
      ]
    );
  }

  global void execute(SchedulableContext context) {
    Database.executeBatch(this, 1);
  }
}