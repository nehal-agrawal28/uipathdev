public with sharing class SearchController_PP {
  @AuraEnabled(Cacheable=true)
  public static List<ContractSearchResult> getContractsList() {
    List<Contract> contracts = [
      SELECT Id, Name, Account.Name, AccountId, ContractNumber, EndDate, StartDate, Status, ContractTerm
      FROM Contract
      WHERE SBQQ__RenewalOpportunity__c IN (SELECT Id FROM Opportunity)
      LIMIT 100
    ];

    return getContractSearchResults(contracts);
  }

  @AuraEnabled(Cacheable=true)
  public static List<ContractSearchResult> findContracts(String searchKey) {
    String key = '%' + searchKey + '%';
    List<Contract> contracts = [
      SELECT Id, Name, Account.Name, AccountId, ContractNumber, EndDate, StartDate, Status, ContractTerm
      FROM Contract
      WHERE SBQQ__RenewalOpportunity__c IN (SELECT Id FROM Opportunity) AND ContractNumber LIKE :key
      LIMIT 100
    ];

    return getContractSearchResults(contracts);
  }

  @AuraEnabled(Cacheable=true)
  public static List<QuoteSearchResult> getQuoteList() {
    List<SBQQ__Quote__c> quotes = [
      SELECT
        Id,
        Name,
        SBQQ__Account__r.Name,
        SBQQ__Partner__r.Name,
        SBQQ__Opportunity2__r.Name,
        SBQQ__Account__c,
        SBQQ__Partner__c,
        SBQQ__Opportunity2__c
      FROM SBQQ__Quote__c
      WHERE SBQQ__Opportunity2__c IN (SELECT Id FROM Opportunity)
      LIMIT 100
    ];

    return getQuoteSearchResult(quotes);
  }

  @AuraEnabled(Cacheable=true)
  public static Boolean isQuoteAccessible(String quoteId) {
    List<SBQQ__Quote__c> quotes = new List<SBQQ__Quote__c>();
    quotes = [
      SELECT Id
      FROM SBQQ__Quote__c
      WHERE SBQQ__Opportunity2__c IN (SELECT Id FROM Opportunity) AND Id = :quoteId
    ];

    return !(quotes.isEmpty());
  }

  @AuraEnabled(Cacheable=true)
  public static List<QuoteSearchResult> findQuotes(String searchKey) {
    String key = '%' + searchKey + '%';
    List<SBQQ__Quote__c> quotes = [
      SELECT
        Id,
        Name,
        SBQQ__Account__r.Name,
        SBQQ__Partner__r.Name,
        SBQQ__Opportunity2__r.Name,
        SBQQ__Account__c,
        SBQQ__Partner__c,
        SBQQ__Opportunity2__c
      FROM SBQQ__Quote__c
      WHERE SBQQ__Opportunity2__c IN (SELECT Id FROM Opportunity) AND Name LIKE :key
      LIMIT 100
    ];

    return getQuoteSearchResult(quotes);
  }

  @AuraEnabled(Cacheable=true)
  public static List<Account> getAccountList() {
    return [
      SELECT
        Id,
        Name,
        BillingStreet,
        BillingCity,
        BillingState,
        BillingCountry,
        Business_Partner_Level__c,
        Resale_Discount_Tier__c,
        Indirect_Reseller_Signed__c,
        PartnerContributingStatus__c,
        Date_Joined_Program__c
      FROM Account
      WHERE Partner_Buys_Through_Disti__c = TRUE AND Business_Partner_Level__c != NULL
    ];
  }

  @AuraEnabled(Cacheable=true)
  public static List<Account> findAccounts(String searchKey) {
    String key = '%' + searchKey + '%';
    return [
      SELECT
        Id,
        Name,
        BillingStreet,
        BillingCity,
        BillingState,
        BillingCountry,
        Business_Partner_Level__c,
        Resale_Discount_Tier__c,
        Indirect_Reseller_Signed__c,
        PartnerContributingStatus__c,
        Date_Joined_Program__c
      FROM Account
      WHERE
        Name LIKE :key
        AND Partner_Buys_Through_Disti__c = TRUE
        AND Business_Partner_Level__c != NULL
        AND Resale_Discount_Tier__c != NULL
    ];
  }

  private static List<ContractSearchResult> getContractSearchResults(List<Contract> contracts) {
    List<ContractSearchResult> results = new List<ContractSearchResult>();

    for (Contract record : contracts) {
      ContractSearchResult result = new ContractSearchResult();
      result.AccountId = record.AccountId;
      result.AccountName = record.Account.Name;
      result.ContractNumber = record.ContractNumber;
      result.EndDate = record.EndDate.format();
      result.Id = record.Id;
      result.StartDate = record.StartDate.format();
      result.Status = record.Status;
      result.Term = String.valueOf(record.ContractTerm);
      results.add(result);
    }
    return results;
  }

  private static List<QuoteSearchResult> getQuoteSearchResult(List<SBQQ__Quote__c> quotes) {
    List<QuoteSearchResult> result = new List<QuoteSearchResult>();

    for (SBQQ__Quote__c quote : quotes) {
      QuoteSearchResult quoteResult = new QuoteSearchResult();
      quoteResult.AccountName = quote.SBQQ__Account__r.Name;
      quoteResult.PartnerName = quote.SBQQ__Partner__r.Name;
      quoteResult.OpportunityName = quote.SBQQ__Opportunity2__r.Name;
      quoteResult.Name = quote.Name;
      quoteResult.Id = quote.Id;
      quoteResult.AccountId = quote.SBQQ__Account__c;
      quoteResult.PartnerId = quote.SBQQ__Partner__c;
      quoteResult.OpportunityId = quote.SBQQ__Opportunity2__c;

      result.add(quoteResult);
    }
    return result;
  }

  public class ContractSearchResult {
    @AuraEnabled
    public String AccountId;
    @AuraEnabled
    public String AccountName;
    @AuraEnabled
    public String ContractNumber;
    @AuraEnabled
    public String EndDate;
    @AuraEnabled
    public String Id;
    @AuraEnabled
    public String StartDate;
    @AuraEnabled
    public String Status;
    @AuraEnabled
    public String Term;
  }

  public class QuoteSearchResult {
    @AuraEnabled
    public String AccountName;
    @AuraEnabled
    public String PartnerName;
    @AuraEnabled
    public String OpportunityName;
    @AuraEnabled
    public String Name;
    @AuraEnabled
    public String Id;
    @AuraEnabled
    public String AccountId;
    @AuraEnabled
    public String PartnerId;
    @AuraEnabled
    public String OpportunityId;
  }
}