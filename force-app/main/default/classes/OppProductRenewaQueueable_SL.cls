public with sharing class OppProductRenewaQueueable_SL {
  //extends AbstractQueueable
  // private final List<SObject> records;
  // public OppProductRenewaQueueable_SL(List<SObject> records) {
  //   super('OppProductRenewaQueueable_SL');
  //   this.records = records;
  //   if (records != null && records.size() == 1) {
  //     this.setPrimaryRecordId(records.get(0).Id);
  //   }
  // }

  // public override void work() {
  //   this.updateOpportunities(this.records);
  // }

  // private void updateOpportunities(List<OpportunityLineItem> records) {
  //   List<Id> opportunityIds = Collection.of(records).pluckIds(OpportunityLineItem.OpportunityId);
  //   List<Opportunity> opportunities = [
  //     SELECT
  //       Id,
  //       Product_Renewal_Date__c,
  //       (
  //         SELECT End_Date__c, OpportunityId
  //         FROM OpportunityLineItems
  //         WHERE (NOT Name LIKE '%training, professional%') AND Opportunity.Number_of_Products__c >= 1
  //         ORDER BY End_Date__c DESC NULLS LAST
  //         LIMIT 1
  //       )
  //     FROM Opportunity
  //     WHERE Id IN :opportunityIds
  //   ];
  //   List<Opportunity> oppsToUpdate = new List<Opportunity>();
  //   for (Opportunity opp : opportunities) {
  //     if (
  //       !opp.OpportunityLineItems.isEmpty() &&
  //       opp.Product_Renewal_Date__c != opp.OpportunityLineItems.get(0).End_Date__c
  //     ) {
  //       opp.Product_Renewal_Date__c = opp.OpportunityLineItems.get(0).End_Date__c;
  //       oppsToUpdate.add(opp);
  //     } else if (opp.Product_Renewal_Date__c != null) {
  //       opp.Product_Renewal_Date__c = null;
  //       oppsToUpdate.add(opp);
  //     }
  //   }

  //   update oppsToUpdate;
  // }

  // public static void updateRenewalDateOnOpp(List<OpportunityLineItem> records, Map<Id, SObject> existingRecords) {
  //   SObjectPredicate hasChanged = new HasRecordChanged(
  //     new Set<SObjectField>{ OpportunityLineItem.End_Date__c },
  //     records,
  //     existingRecords
  //   );
  //   List<OpportunityLineItem> eligibleRecords = Collection.of(records).filter(hasChanged).asList();
  //   if (eligibleRecords.isEmpty()) {
  //     return;
  //   }

  //   updateRenewalDateOnOpp(eligibleRecords);
  // }

  // public static void updateRenewalDateOnOpp(List<OpportunityLineItem> records) {
  //   AbstractQueueable.enqueue(new OppProductRenewaQueueable_SL(records));
  // }
}