@IsTest
private class DistributorConfigurationsServiceTest_PP {
  @IsTest
  static void itShouldBuildCountriesByAccountId() {
    // given
    TestFactory_PP.init();

    List<Account> accounts = [SELECT Id FROM Account WHERE Business_Partner_Type__c = 'Distributor'];

    System.assertEquals(false, accounts.isEmpty());

    Id accountId = accounts.get(0).Id;
    String country = 'Belgium';

    DistributorConfiguration__c distributorConfiguration = new DistributorConfiguration__c(
      Account__c = accountId,
      Country__c = country
    );

    insert distributorConfiguration;

    // when
    Map<Id, Set<String>> countriesByAccountId = DistributorConfigurationsService_PP.buildCountriesByAccountId(
      new Set<String>{ country }
    );

    // then
    System.assertEquals(false, countriesByAccountId.isEmpty());
    System.assertEquals(true, countriesByAccountId.containsKey(accountId));
    System.assertEquals(true, countriesByAccountId.get(accountId).contains(country.toUpperCase()));
  }
}