public with sharing class OppPriceBookFunction_SL implements SObjectToSObjectFunction {
  private Map<Id, Account> japanAccountsMap;
  public OppPriceBookFunction_SL(List<Opportunity> records) {
    Set<Id> accountIds = new Set<Id>(Collection.of(records).pluckIds(Opportunity.AccountId));
    japanAccountsMap = new Map<Id, Account>([SELECT Id FROM Account WHERE Id IN :accountIds AND Area__c = 'Japan']);
  }

  private SObject apply(Opportunity opp) {
    if (opp.RecordTypeId != OpportunityMetadata_SL.StandardRecordType && !japanAccountsMap.containsKey(opp.AccountId)) {
      opp.Pricebook2Id = OpportunityMetadata_SL.DefaultPriceBookMap.get(Constants_SL.DEFAULT_PRICE_BOOK) != null
        ? OpportunityMetadata_SL.DefaultPriceBookMap.get(Constants_SL.DEFAULT_PRICE_BOOK)
        : opp.Pricebook2Id;
    }
    return opp;
  }

  public SObject apply(SObject record) {
    return apply((Opportunity) record);
  }

  public static void populatePricebookId(List<Opportunity> records) {
    List<Opportunity> eligibleRecords = Collection.of(records)
      .filter(
        Match.field(Opportunity.StageName)
          .notIn(new Set<String>{ OpportunityMetadata_SL.CLOSED_WON_PENDING, OpportunityMetadata_SL.CLOSED_WON_BOOKED })
          .also(Opportunity.RecordTypeId)
          .notIn(new Set<Id>{ OpportunityMetadata_SL.UiPathJapanPartnerStandardRecordType })
          .also(Opportunity.SBQQ__RenewedContract__c)
          .equals(null)
          .also(Opportunity.SBQQ__AmendedContract__c)
          .equals(null)
      )
      .asList();
    if (!eligibleRecords.isEmpty()) {
      Collection.of(eligibleRecords).mapAll(new OppPriceBookFunction_SL(eligibleRecords));
    }
  }
}