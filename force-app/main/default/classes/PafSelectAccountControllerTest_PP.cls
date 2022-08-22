@IsTest
private class PafSelectAccountControllerTest_PP {
  @TestSetup
  static void setup() {
    TestFactory_PP.init();
    TestFactory_PP.initPortalUsers();
  }

  @IsTest
  static void itShouldGetRecentlyViewedAccounts() {
    // given
    Integer maxResults = 5;

    // when
    List<LookupSearchResult_PP> results = PafSelectAccountController_PP.getRecentlyViewedAccounts(maxResults);

    // then
    System.assertEquals(false, results.isEmpty());
  }

  @IsTest
  static void itShouldGetRecentlyViewedContactsForAccount() {
    // given
    Account distributorAccount = [SELECT Id FROM Account WHERE Name LIKE 'distributoraccount%' LIMIT 1];

    Id accountId = distributorAccount.Id;
    Integer maxResults = 5;

    // when
    List<LookupSearchResult_PP> results = PafSelectAccountController_PP.getRecentlyViewedContactsForAccount(
      accountId,
      maxResults
    );

    // then
    System.assertEquals(false, results.isEmpty());
  }

  @IsTest
  static void itShouldSearchAccounts() {
    // given
    String searchTerm = 'dist';
    Integer maxResults = 5;

    // when
    List<LookupSearchResult_PP> results = PafSelectAccountController_PP.searchAccounts(searchTerm, maxResults);

    // then
    System.assertEquals(false, results.isEmpty());
  }

  @IsTest
  static void itShouldSearchContactsForAccount() {
    // given
    Account distributorAccount = [SELECT Id FROM Account WHERE Name LIKE 'distributoraccount%' LIMIT 1];

    String searchTerm = 'dist';
    Id accountId = distributorAccount.Id;
    Integer maxResults = 5;

    // when
    List<LookupSearchResult_PP> results = PafSelectAccountController_PP.searchContactsForAccount(
      searchTerm,
      accountId,
      maxResults
    );

    // then
    System.assertEquals(false, results.isEmpty());
  }
}