public with sharing class OppDefaultTypeFunction_SL implements SObjectToSObjectFunction {
  private AccountsSelector_SL accountSelector {
    get {
      if (accountSelector == null) {
        accountSelector = (AccountsSelector_SL) Application_SL.Selector.newInstance(Account.getSObjectType());
      }
      return accountSelector;
    }
    set {
    }
  }
  private Map<Id, Account> accountsWithWonOpps;
  public OppDefaultTypeFunction_SL(List<Opportunity> records) {
    List<Id> accountIds = Collection.of(records).pluckIds(Opportunity.AccountId);
    this.accountsWithWonOpps = new Map<Id, Account>(
      accountSelector.getAccountsWithWonOppsById(new Set<Id>(accountIds), false)
    );
  }

  private SObject apply(Opportunity record) {
    record.Type = (record.SBQQ__Renewal__c)
      ? Constants_SL.OPPORTUNITY_TYPE_RENEWAL
      : (record.Replacement_Transaction__c || this.accountsWithWonOpps.containsKey(record.AccountId))
          ? Constants_SL.OPPORTUNITY_TYPE_UPSELL
          : Constants_SL.OPPORTUNITY_TYPE_NEW_BUSINESS;

    return record;
  }

  public SObject apply(SObject record) {
    return apply((Opportunity) record);
  }

  public static void deriveType(List<Opportunity> records) {
    if (records == null || records.isEmpty()) {
      return;
    }
    List<Opportunity> eligibleRecords = Collection.of(records)
      .filter(Match.field(Opportunity.Type).notEquals('Renewal'))
      .asList();

    if (!eligibleRecords.isEmpty()) {
      Collection.of(eligibleRecords).mapAll(new OppDefaultTypeFunction_SL(eligibleRecords));
    }
  }
}