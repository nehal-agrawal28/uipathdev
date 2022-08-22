@IsTest
private class LookupDistResellControllerTest_PP {
  @TestSetup
  static void setup() {
    TestFactory_PP.init();
    TestFactory_PP.initPortalUsers();
  }

  @IsTest
  static void itShouldGetInitialData() {
    // given
    User distributorUser = [SELECT Id, Contact_Account_Id__c FROM User WHERE Name LIKE 'distributoruser%' LIMIT 1];
    User resellerUser = [SELECT Id, Contact_Account_Id__c FROM User WHERE Name LIKE 'reselleruser%' LIMIT 1];

    // when
    LookupDistributorResellerController_PP.InitialData distributorInitialData = LookupDistributorResellerController_PP.getInitialData(
      distributorUser.Id
    );

    LookupDistributorResellerController_PP.InitialData resellerInitialData = LookupDistributorResellerController_PP.getInitialData(
      resellerUser.Id
    );

    // then
    System.assertEquals(true, distributorInitialData.hasDistributorOrResellerAccounts);
    System.assertEquals(true, distributorInitialData.isPartnerUserDistributor);
    System.assertEquals(false, distributorInitialData.isPartnerUserReseller);
    System.assertEquals(distributorUser.Contact_Account_Id__c, distributorInitialData.distributorAccountId);
    System.assertEquals(null, distributorInitialData.resellerAccountId);

    System.assertEquals(true, resellerInitialData.hasDistributorOrResellerAccounts);
    System.assertEquals(false, resellerInitialData.isPartnerUserDistributor);
    System.assertEquals(true, resellerInitialData.isPartnerUserReseller);
    System.assertEquals(null, resellerInitialData.distributorAccountId);
    System.assertEquals(resellerUser.Contact_Account_Id__c, resellerInitialData.resellerAccountId);
  }

  @IsTest
  static void itShouldSearchDistributorOrResellerAccounts() {
    // given
    User resellerUser = [SELECT Id FROM User WHERE Name LIKE 'reselleruser%' LIMIT 1];
    User distributorUser = [SELECT Id FROM User WHERE Name LIKE 'distributoruser%' LIMIT 1];
    Account distributorAccount = [SELECT Id FROM Account WHERE Name LIKE 'distributoraccount%' LIMIT 1];

    Test.setFixedSearchResults(new List<Id>{ distributorAccount.Id });

    // when
    List<LookupSearchResult_PP> results = LookupDistributorResellerController_PP.searchDistributorOrResellerAccounts(
      'dist',
      resellerUser.Id,
      5
    );

    // then
    System.assertEquals(false, results.isEmpty());
    System.assertEquals(distributorAccount.Id, results.get(0).getId());
  }

  @IsTest
  static void itShouldGetInitialDistributorOrResellerAccounts() {
    // given
    User resellerUser = [SELECT Id FROM User WHERE Name LIKE 'reselleruser%' LIMIT 1];
    User distributorUser = [SELECT Id FROM User WHERE Name LIKE 'distributoruser%' LIMIT 1];
    Account distributorAccount = [SELECT Id FROM Account WHERE Name LIKE 'distributoraccount%' LIMIT 1];

    Test.setFixedSearchResults(new List<Id>{ distributorAccount.Id });

    // when
    List<LookupSearchResult_PP> results = LookupDistributorResellerController_PP.getInitialDistributorOrResellerAccounts(
      resellerUser.Id
    );

    // then
    System.assertEquals(false, results.isEmpty());
    System.assertEquals(distributorAccount.Id, results.get(0).getId());
  }

  @IsTest
  static void itShouldGetDistributorOrResellerAccounts() {
    // given
    User resellerUser = [SELECT Id FROM User WHERE Name LIKE 'reselleruser%' LIMIT 1];
    Account distributorAccount = [SELECT Id FROM Account WHERE Name LIKE 'distributoraccount%' LIMIT 1];

    // when
    List<Account> accounts = LookupDistributorResellerController_PP.getDistributorOrResellerAccounts(resellerUser.Id);

    // then
    System.assertEquals(false, accounts.isEmpty());
    System.assertEquals(distributorAccount.Id, accounts.get(0).Id);
  }

  @IsTest
  static void itShouldReturnCorrectValueWhenHasDistributorAssociationIsCalled() {
    // given
    User resellerUser = [SELECT Id FROM User WHERE Name LIKE 'reselleruser%' LIMIT 1];
    Account distributorAccount = [SELECT Id FROM Account WHERE Name LIKE 'distributoraccount%' LIMIT 1];
    Account resellerAccount = [SELECT Id FROM Account WHERE Name LIKE 'reselleraccount%' LIMIT 1];

    // when
    Boolean hasDistributorAssociationToDistributor = LookupDistributorResellerController_PP.hasDistributorAssociation(
      resellerUser.Id,
      distributorAccount.Id
    );

    Boolean hasDistributorAssociationToReseller = LookupDistributorResellerController_PP.hasDistributorAssociation(
      resellerUser.Id,
      resellerAccount.Id
    );

    // then
    System.assertEquals(true, hasDistributorAssociationToDistributor);
    System.assertEquals(false, hasDistributorAssociationToReseller);
  }
}