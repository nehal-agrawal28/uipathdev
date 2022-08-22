public with sharing class DealBuilderAccountController {
  private final static Integer MAX_RESULTS = 5;

  @AuraEnabled(Cacheable=true)
  public static List<LookupSearchResult_SL> search(String searchTerm, List<String> selectedIds) {
    // Prepare query paramters
    searchTerm += '*';

    // Execute search query
    List<List<SObject>> searchResults = [
      FIND :searchTerm
      IN ALL FIELDS
      RETURNING Account(Id, Name, BillingCountry WHERE id NOT IN :selectedIds)
      LIMIT :MAX_RESULTS
    ];

    // Prepare results
    List<LookupSearchResult_SL> results = new List<LookupSearchResult_SL>();

    // Extract Accounts & convert them into LookupSearchResult_SL
    String accountIcon = 'standard:account';
    Account[] accounts = (List<Account>) searchResults[0];
    for (Account account : accounts) {
      String subtitle = 'Account' + account.BillingCountry == null ? '' : ' • ' + account.BillingCountry;
      results.add(new LookupSearchResult_SL(account.Id, 'Account', accountIcon, account.Name, subtitle));
    }

    // Optionnaly sort all results on title
    results.sort();

    return results;
  }

  @AuraEnabled(Cacheable=true)
  public static List<LookupSearchResult_SL> getRecentlyViewed() {
    List<LookupSearchResult_SL> results = new List<LookupSearchResult_SL>();
    String accountIcon = 'standard:account';
    // Get recently viewed records of type Account or Opportunity
    List<Account> recentRecords = [
      SELECT Name, BillingCountry
      FROM Account
      WHERE LastViewedDate != NULL
      ORDER BY LastViewedDate DESC
      LIMIT 5
    ];

    // Convert recent records into LookupSearchResult_SL
    for (Account account : recentRecords) {
      String subtitle = 'Account' + account.BillingCountry == null ? '' : ' • ' + account.BillingCountry;
      results.add(new LookupSearchResult_SL(account.Id, 'Account', accountIcon, account.Name, subtitle));
    }
    return results;
  }
}