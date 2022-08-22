public with sharing class OpportunityLineItemFunction_SL implements SObjectToSObjectFunction {
  private Map<Id, PriceBookEntry> priceBookEntryMap;

  public OpportunityLineItemFunction_SL(List<OpportunityLineItem> records) {
    Set<Id> pbeIds = new Set<Id>(Collection.of(records).pluckIds(OpportunityLineItem.PricebookEntryId));
    priceBookEntryMap = new Map<Id, PricebookEntry>(
      [SELECT Id, Product2.Family FROM PriceBookEntry WHERE Id IN :pbeIds]
    );
  }

  private SObject apply(OpportunityLineItem record) {
    if (priceBookEntryMap.containsKey(record.PricebookEntryId)) {
      record.Product_Family_T__c = priceBookEntryMap.get(record.PricebookEntryId).Product2.Family;
    }
    if (record.ServiceDate == null) {
      record.ServiceDate = record.Effective_Start_Date__c;
    }
    return record;
  }

  public SObject apply(SObject record) {
    return apply((OpportunityLineItem) record);
  }

  public static void setDefaultValues(List<OpportunityLineItem> records) {
    Collection.of(records).mapAll(new OpportunityLineItemFunction_SL(records));
  }
}