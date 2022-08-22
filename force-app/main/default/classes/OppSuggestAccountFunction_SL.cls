public with sharing class OppSuggestAccountFunction_SL implements SObjectToSObjectFunction {
  List<Account> matchingAccountNames;
  public OppSuggestAccountFunction_SL(List<Opportunity> opps) {
    List<String> companyNames = new List<String>();
    List<String> companyCountries = Collection.of(opps).pluckStrings(Opportunity.Account_Country__c);
    List<String> companyCities = Collection.of(opps).pluckStrings(Opportunity.Account_City__c);
    for (Opportunity opp : opps) {
      if (!String.isEmpty(opp.Account_Name__c)) {
        companyNames.add('%' + opp.Account_Name__c + '%');
      }
    }

    matchingAccountNames = [
      SELECT Id, Name, BillingCountry, BillingCity, OwnerId
      FROM Account
      WHERE Owner.IsActive = TRUE AND Name LIKE :companyNames AND BillingCountry LIKE :companyCountries
    ];
  }

  private SObject apply(Opportunity record) {
    for (Account match : matchingAccountNames) {
      boolean matching = false;
      if (
        match.Name.ToLowerCase().contains(record.Account_Name__c.ToLowerCase()) &&
        match.BillingCountry == record.Account_Country__c
      ) {
        if (String.isEmpty(record.Account_City__c)) {
          matching = true;
        } else if (match.BillingCity == record.Account_City__c) {
          matching = true;
        }
      }

      if (matching) {
        record.Suggested_Account__c = match.Id;
      }
    }
    return record;
  }

  public SObject apply(SObject record) {
    return apply((Opportunity) record);
  }

  public static void setExistingAccount(List<Opportunity> records) {
    List<Opportunity> eligibleRecords = Collection.of(records)
      .filter(Match.field(Opportunity.Account_Name__c).hasValue().also(Opportunity.Account_Country__c).hasValue())
      .asList();

    if (!eligibleRecords.isEmpty()) {
      Collection.of(eligibleRecords).mapAll(new OppSuggestAccountFunction_SL(eligibleRecords));
    }
  }
}