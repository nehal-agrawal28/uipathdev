public with sharing class QuoteKAMFieldFunction_SL implements SObjectToSObjectFunction {
  private Map<Id, Account> accounts;

  public QuoteKAMFieldFunction_SL(List<SBQQ__Quote__c> records) {
    Set<Id> accountIds = new Set<Id>(Collection.of(records).pluckIds(SBQQ__Quote__c.SBQQ__Account__c));

    accounts = new Map<Id, Account>(
      [SELECT Id, Classification__c, KAM_Id__c, KAM_GSI__c FROM Account WHERE Id IN :accountIds]
    );
  }

  public SObject apply(SBQQ__Quote__c quote) {
    if (accounts.get(quote.SBQQ__Account__c) != null) {
      if (accounts.get(quote.SBQQ__Account__c).Classification__c != null) {
        if (accounts.get(quote.SBQQ__Account__c).Classification__c == 'KAP') {
          quote.KAM__c = accounts.get(quote.SBQQ__Account__c).KAM_Id__c;
        } else if (accounts.get(quote.SBQQ__Account__c).Classification__c == 'KAP-GSI') {
          quote.KAM__c = accounts.get(quote.SBQQ__Account__c).KAM_GSI__c;
        }
      }
    }
    return quote;
  }

  public SObject apply(SObject record) {
    return apply((SBQQ__Quote__c) record);
  }

  /**
   * Set Quote KAM Field
   */
  public static void deriveKAMFields(List<SBQQ__Quote__c> records) {
    Collection.of(records).mapAll(new QuoteKAMFieldFunction_SL(records));
  }
}