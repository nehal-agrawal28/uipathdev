public without sharing class OppRenewalFunction_SL implements SObjectToSObjectFunction {
  private Map<Id, Contract> contracts;

  public OppRenewalFunction_SL(List<Opportunity> records) {
    List<Id> contractIds = Collection.of(records).pluckIds(Opportunity.SBQQ__RenewedContract__c);
    this.contracts = new Map<Id, Contract>(
      [
        SELECT Id, SBQQ__Opportunity__c, SBQQ__Opportunity__r.Included_in_Partner_Community__c
        FROM Contract
        WHERE Id IN :contractIds
      ]
    );
  }

  private SObject apply(Opportunity record) {
    Contract contract = contracts.get(record.SBQQ__RenewedContract__c);
    if (contract != null) {
      record.Included_in_Partner_Community__c = contract.SBQQ__Opportunity__r.Included_in_Partner_Community__c;
    }
    return record;
  }

  public SObject apply(SObject record) {
    return apply((Opportunity) record);
  }

  public static void deriveIncludedInCommunity(List<Opportunity> records) {
    List<Opportunity> eligibleRecords = Collection.of(records)
      .filter(
        Match.field(Opportunity.SBQQ__Renewal__c)
          .hasValue()
          .also(Opportunity.SBQQ__Renewal__c)
          .equals(true)
          .also(Opportunity.SBQQ__RenewedContract__c)
          .hasValue()
      )
      .asList();
    if (!eligibleRecords.isEmpty()) {
      Collection.of(eligibleRecords).mapAll(new OppRenewalFunction_SL(eligibleRecords));
    }
  }
}