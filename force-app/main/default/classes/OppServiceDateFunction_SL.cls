public with sharing class OppServiceDateFunction_SL implements SObjectToSObjectFunction {
  private Map<Id, Opportunity> opportunities;
  public OppServiceDateFunction_SL(List<Opportunity> records) {
    List<Id> opportunityIds = Collection.of(records).pluckIds();
    this.opportunities = new Map<Id, Opportunity>(
      [
        SELECT
          Id,
          Product_Start_Date__c,
          StageName,
          (SELECT Id, ServiceDate FROM OpportunityLineItems WHERE ServiceDate != NULL ORDER BY ServiceDate ASC LIMIT 1)
        FROM Opportunity
        WHERE Id IN :opportunityIds
      ]
    );
  }

  private SObject apply(Opportunity record) {
    record.Product_Start_Date__c = null;
    if (!opportunities.containsKey(record.Id)) {
      return record;
    }
    List<OpportunityLineItem> lineItems = opportunities.get(record.Id).OpportunityLineItems;
    if (!lineItems.isEmpty()) {
      record.Product_Start_Date__c = lineItems.get(0).ServiceDate;
    }
    return record;
  }

  public SObject apply(SObject record) {
    return apply((Opportunity) record);
  }

  public static void deriveProductStartDate(List<Opportunity> records, Map<Id, SObject> existingRecords) {
    SObjectPredicate hasChanged = new HasRecordChanged(
      new Set<SObjectField>{ Opportunity.StageName },
      records,
      existingRecords
    );

    List<Opportunity> eligibleRecords = Collection.of(records)
      .filter(hasChanged)
      .filter(
        Match.field(Opportunity.StageName)
          .isIn(new Set<String>{ OpportunityMetadata_SL.CLOSED_WON_PENDING, OpportunityMetadata_SL.CLOSED_WON_BOOKED })
      )
      .asList();
    if (!eligibleRecords.isEmpty()) {
      Collection.of(eligibleRecords).mapAll(new OppServiceDateFunction_SL(eligibleRecords));
    }
  }
}