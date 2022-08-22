public with sharing class QuoteSalesRepFunction_SL implements SObjectToSObjectFunction {
  private Map<Id, Opportunity> opportunities;

  public QuoteSalesRepFunction_SL(List<SBQQ__Quote__c> records) {
    Set<Id> opportunityIds = new Set<Id>(Collection.of(records).pluckIds(SBQQ__Quote__c.SBQQ__Opportunity2__c));
    opportunities = new Map<Id, Opportunity>(
      [SELECT Id, OwnerId, Owner.ManagerId FROM Opportunity WHERE Id IN :opportunityIds AND Owner.ManagerId != NULL]
    );
  }

  public SObject apply(SBQQ__Quote__c quote) {
    if (opportunities.get(quote.SBQQ__Opportunity2__c) <> null) {
      quote.SBQQ__SalesRep__c = opportunities.get(quote.SBQQ__Opportunity2__c).OwnerId;
      quote.Sales_Rep_s_Manager__c = opportunities.get(quote.SBQQ__Opportunity2__c).Owner.ManagerId;
    }
    return quote;
  }

  public SObject apply(SObject record) {
    return apply((SBQQ__Quote__c) record);
  }

  /**
   * Set Quote Sales Rep Fields
   */
  public static void deriveSalesRepFields(List<SBQQ__Quote__c> records) {
    Collection.of(records)
      .filter(Match.field(SBQQ__Quote__c.SBQQ__Opportunity2__c).hasValue())
      .mapAll(new QuoteSalesRepFunction_SL(records));
  }

  /**
   * Set Quote Sales Rep Fields
   */
  public static void deriveSalesRepFields(List<SObject> records, Map<Id, SObject> existingRecords) {
    SObjectPredicate hasChanged = new HasRecordChanged(
      new Set<SObjectField>{ SBQQ__Quote__c.SBQQ__Opportunity2__c },
      records,
      existingRecords
    );

    List<SBQQ__Quote__c> eligibleRecords = Collection.of(records)
      .filter(hasChanged)
      .filter(Match.field(SBQQ__Quote__c.SBQQ__Opportunity2__c).hasValue())
      .asList();

    if (!eligibleRecords.isEmpty()) {
      Collection.of(eligibleRecords).mapAll(new QuoteSalesRepFunction_SL(eligibleRecords));
    }
  }
}