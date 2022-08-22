public without sharing class LookupDistributorResellerController_PP {
  @AuraEnabled(Cacheable=true)
  public static List<LookupSearchResult_PP> searchDistributorsOrResellers(
    String searchTerm,
    String partnerType,
    Integer maxResults
  ) {
    List<LookupSearchResult_PP> results = new List<LookupSearchResult_PP>();

    String businessPartnerType = partnerType == 'Distributor' ? 'Distributor' : 'VAR';

    searchTerm += '*';

    List<List<SObject>> searchResults = [
      FIND :searchTerm
      IN NAME FIELDS
      RETURNING
        Account(
          Id,
          Name,
          BillingStreet,
          BillingCity,
          BillingState,
          BillingCountry
          WHERE Business_Partner_Type__c = :businessPartnerType)
      LIMIT :maxResults
    ];

    String accountIcon = 'standard:account';

    for (Account account : (List<Account>) searchResults[0]) {
      String subtitle =
        account.BillingStreet +
        ', ' +
        account.BillingCity +
        ', ' +
        account.BillingState +
        ', ' +
        account.BillingCountry;

      results.add(new LookupSearchResult_PP(account.Id, 'Account', accountIcon, account.Name, subtitle));
    }

    results.sort();

    return results;
  }

  @AuraEnabled(Cacheable=true)
  public static List<LookupSearchResult_PP> searchDistributorOrResellerAccounts(
    String searchTerm,
    Id partnerUserId,
    Integer maxResults
  ) {
    List<LookupSearchResult_PP> results = new List<LookupSearchResult_PP>();

    AccountsService_PP service = (AccountsService_PP) Application_PP.Service.newInstance(AccountsService_PP.class);

    Set<Id> accountIds = service.getDistributorOrResellerAccountIds(partnerUserId);

    if (accountIds.isEmpty())
      return results;

    searchTerm += '*';

    List<List<SObject>> searchResults = [
      FIND :searchTerm
      IN NAME FIELDS
      RETURNING Account(Id, Name, BillingStreet, BillingCity, BillingState, BillingCountry WHERE Id IN :accountIds)
      LIMIT :maxResults
    ];

    String accountIcon = 'standard:account';

    for (Account account : (List<Account>) searchResults[0]) {
      String subtitle =
        account.BillingStreet +
        ', ' +
        account.BillingCity +
        ', ' +
        account.BillingState +
        ', ' +
        account.BillingCountry;

      results.add(new LookupSearchResult_PP(account.Id, 'Account', accountIcon, account.Name, subtitle));
    }

    results.sort();

    return results;
  }

  @AuraEnabled(Cacheable=true)
  public static List<LookupSearchResult_PP> getInitialDistributorOrResellerAccounts(Id partnerUserId) {
    List<LookupSearchResult_PP> results = new List<LookupSearchResult_PP>();

    AccountsService_PP service = (AccountsService_PP) Application_PP.Service.newInstance(AccountsService_PP.class);

    Set<Id> accountIds = service.getDistributorOrResellerAccountIds(partnerUserId);

    if (accountIds.isEmpty())
      return results;

    AccountsSelector_PP selector = (AccountsSelector_PP) Application_PP.Selector.newInstance(Account.SObjectType);

    List<Account> accounts = selector.selectById(accountIds, false);

    String accountIcon = 'standard:account';

    for (Account account : accounts) {
      String subtitle =
        account.BillingStreet +
        ', ' +
        account.BillingCity +
        ', ' +
        account.BillingState +
        ', ' +
        account.BillingCountry;

      results.add(new LookupSearchResult_PP(account.Id, 'Account', accountIcon, account.Name, subtitle));
    }

    results.sort();

    return results;
  }

  @AuraEnabled(Cacheable=true)
  public static List<Account> getDistributorOrResellerAccounts(Id partnerUserId) {
    AccountsSelector_PP selector = (AccountsSelector_PP) Application_PP.Selector.newInstance(Account.SObjectType);
    AccountsService_PP service = (AccountsService_PP) Application_PP.Service.newInstance(AccountsService_PP.class);

    Set<Id> accountIds = service.getDistributorOrResellerAccountIds(partnerUserId);

    return accountIds.isEmpty() ? new List<Account>() : selector.selectById(accountIds, false);
  }

  @AuraEnabled(Cacheable=true)
  public static InitialData getInitialData(Id partnerUserId) {
    UsersSelector_PP selector = (UsersSelector_PP) Application_PP.Selector.newInstance(User.SObjectType);
    List<User> partnerUsers = selector.selectById(new Set<Id>{ partnerUserId }, false);

    AccountsService_PP service = (AccountsService_PP) Application_PP.Service.newInstance(AccountsService_PP.class);
    Set<Id> distributorOrResellerAccountIds = service.getDistributorOrResellerAccountIds(partnerUserId);

    return new InitialData(partnerUsers, distributorOrResellerAccountIds);
  }

  @AuraEnabled(Cacheable=true)
  public static Boolean hasDistributorAssociation(Id resellerUserId, Id distributorAccountId) {
    AccountsService_PP service = (AccountsService_PP) Application_PP.Service.newInstance(AccountsService_PP.class);
    Set<Id> distributorAccountIds = service.getDistributorOrResellerAccountIds(resellerUserId);

    if (!distributorAccountIds.contains(distributorAccountId))
      return false;

    AccountsSelector_PP selector = (AccountsSelector_PP) Application_PP.Selector.newInstance(Account.SObjectType);
    List<Account> accounts = selector.selectById(new Set<Id>{ distributorAccountId }, false);

    if (accounts.isEmpty())
      return false;

    return (accounts.get(0).Business_Partner_Type__c == 'Distributor');
  }

  public class InitialData {
    @AuraEnabled
    public Boolean isPartnerUserDistributor = false;

    @AuraEnabled
    public Boolean isPartnerUserReseller = false;

    @AuraEnabled
    public Boolean hasDistributorOrResellerAccounts = false;

    @AuraEnabled
    public Id distributorAccountId;

    @AuraEnabled
    public Id resellerAccountId;

    public InitialData(List<User> partnerUsers, Set<Id> distributorOrResellerAccountIds) {
      if (!partnerUsers.isEmpty() && String.isNotBlank(partnerUsers.get(0).ContactAccountBusinessPartnerType__c)) {
        isPartnerUserDistributor = partnerUsers.get(0).ContactAccountBusinessPartnerType__c == 'Distributor';
        isPartnerUserReseller =
          partnerUsers.get(0).ContactAccountBusinessPartnerType__c == 'VAR' ||
          partnerUsers.get(0).ContactAccountBusinessPartnerType__c == 'GSI' ||
          partnerUsers.get(0).ContactAccountBusinessPartnerType__c == 'LSP';
      }

      hasDistributorOrResellerAccounts = !distributorOrResellerAccountIds.isEmpty();

      if (isPartnerUserDistributor == true) {
        distributorAccountId = partnerUsers.get(0).Contact_Account_Id__c;
      }

      if (isPartnerUserReseller == true) {
        resellerAccountId = partnerUsers.get(0).Contact_Account_Id__c;
      }
    }
  }
}