/**
 * Controller for the LWC component used in the Partner Application Form approval flow
 */
public without sharing class PafSelectAccountController_PP {
  @AuraEnabled(Cacheable=true)
  public static List<LookupSearchResult_PP> getRecentlyViewedAccounts(Integer maxResults) {
    List<LookupSearchResult_PP> results = new List<LookupSearchResult_PP>();

    Map<String, Schema.RecordTypeInfo> recordTypeInfoByDeveloperName = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName();

    Set<Id> recordTypeIds = new Set<Id>{
      recordTypeInfoByDeveloperName.get('Partner').getRecordTypeId(),
      recordTypeInfoByDeveloperName.get('Partner_Prospect').getRecordTypeId()
    };

    AccountsSelector_PP selector = (AccountsSelector_PP) Application_PP.Selector.newInstance(Account.SObjectType);

    List<Account> accounts = selector.selectRecentlyViewedByRecordTypeIds(recordTypeIds, maxResults, false);

    String icon = 'standard:account';

    for (Account account : accounts) {
      String subtitle =
        account.BillingStreet +
        ', ' +
        account.BillingCity +
        ', ' +
        account.BillingState +
        ', ' +
        account.BillingCountry;

      results.add(new LookupSearchResult_PP(account.Id, 'Account', icon, account.Name, subtitle));
    }

    return results;
  }

  @AuraEnabled(Cacheable=true)
  public static List<LookupSearchResult_PP> getRecentlyViewedContactsForAccount(Id accountId, Integer maxResults) {
    List<LookupSearchResult_PP> results = new List<LookupSearchResult_PP>();

    ContactsSelector_PP selector = (ContactsSelector_PP) Application_PP.Selector.newInstance(Contact.SObjectType);

    Set<Id> accountIds = new Set<Id>{ accountId };

    List<Contact> contacts = selector.selectRecentlyViewedByAccountIds(accountIds, maxResults, false);

    String icon = 'standard:contact';

    for (Contact contact : contacts) {
      results.add(new LookupSearchResult_PP(contact.Id, 'Contact', icon, contact.Name, contact.Email));
    }

    return results;
  }

  @AuraEnabled(Cacheable=true)
  public static List<LookupSearchResult_PP> searchAccounts(String searchTerm, Integer maxResults) {
    List<LookupSearchResult_PP> results = new List<LookupSearchResult_PP>();

    Map<String, Schema.RecordTypeInfo> recordTypeInfoByDeveloperName = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName();

    Set<Id> recordTypeIds = new Set<Id>{
      recordTypeInfoByDeveloperName.get('Partner').getRecordTypeId(),
      recordTypeInfoByDeveloperName.get('Partner_Prospect').getRecordTypeId()
    };

    AccountsSelector_PP selector = (AccountsSelector_PP) Application_PP.Selector.newInstance(Account.SObjectType);

    List<Account> accounts = selector.selectBySearchTermAndRecordTypeIds(searchTerm, recordTypeIds, maxResults, false);

    String icon = 'standard:account';

    for (Account account : accounts) {
      String subtitle =
        account.BillingStreet +
        ', ' +
        account.BillingCity +
        ', ' +
        account.BillingState +
        ', ' +
        account.BillingCountry;

      results.add(new LookupSearchResult_PP(account.Id, 'Account', icon, account.Name, subtitle));
    }

    return results;
  }

  @AuraEnabled(Cacheable=true)
  public static List<LookupSearchResult_PP> searchContactsForAccount(
    String searchTerm,
    Id accountId,
    Integer maxResults
  ) {
    List<LookupSearchResult_PP> results = new List<LookupSearchResult_PP>();

    ContactsSelector_PP selector = (ContactsSelector_PP) Application_PP.Selector.newInstance(Contact.SObjectType);

    Set<Id> accountIds = new Set<Id>{ accountId };

    List<Contact> contacts = selector.selectBySearchTermAndAccountIds(searchTerm, accountIds, maxResults, false);

    String icon = 'standard:contact';

    for (Contact contact : contacts) {
      results.add(new LookupSearchResult_PP(contact.Id, 'Contact', icon, contact.Name, contact.Email));
    }

    return results;
  }
}