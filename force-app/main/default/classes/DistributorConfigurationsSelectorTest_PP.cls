@IsTest
private class DistributorConfigurationsSelectorTest_PP {
  @IsTest
  static void itShouldSelectById() {
    // given
    DistributorConfiguration__c distributorConfiguration = new DistributorConfiguration__c(Country__c = 'Belgium');

    insert distributorConfiguration;

    Set<Id> distributorConfigurationIds = new Set<Id>{ distributorConfiguration.Id };

    DistributorConfigurationsSelector_PP selector = (DistributorConfigurationsSelector_PP) Application_PP.Selector.newInstance(
      DistributorConfiguration__c.SObjectType
    );

    // when
    List<DistributorConfiguration__c> recordsWithSharing = selector.selectById(distributorConfigurationIds, true);
    List<DistributorConfiguration__c> recordsWithoutSharing = selector.selectById(distributorConfigurationIds, false);

    // then
    System.assertEquals(false, recordsWithSharing.isEmpty());
    System.assertEquals(false, recordsWithoutSharing.isEmpty());

    System.assertEquals(distributorConfigurationIds.size(), recordsWithSharing.size());
    System.assertEquals(distributorConfigurationIds.size(), recordsWithoutSharing.size());
  }

  @IsTest
  static void itShouldSelectByBusinessPartnerTypesAndCountries() {
    // given
    TestFactory_PP.init();
    TestFactory_PP.initPortalUsers();

    List<Account> accounts = [SELECT Id FROM Account WHERE Business_Partner_Type__c = 'Distributor' LIMIT 1];

    String country = 'Belgium';
    String businessPartnerType = 'Distributor';

    DistributorConfiguration__c distributorConfiguration = new DistributorConfiguration__c(
      Account__c = accounts.get(0).Id,
      Country__c = country
    );

    insert distributorConfiguration;

    Set<String> businessPartnerTypes = new Set<String>{ businessPartnerType };
    Set<String> countries = new Set<String>{ country };

    DistributorConfigurationsSelector_PP selector = (DistributorConfigurationsSelector_PP) Application_PP.Selector.newInstance(
      DistributorConfiguration__c.SObjectType
    );

    // when
    List<DistributorConfiguration__c> recordsWithSharing = selector.selectByBusinessPartnerTypesAndCountries(
      businessPartnerTypes,
      countries,
      true
    );
    List<DistributorConfiguration__c> recordsWithoutSharing = selector.selectByBusinessPartnerTypesAndCountries(
      businessPartnerTypes,
      countries,
      false
    );

    // then
    System.assertEquals(false, recordsWithSharing.isEmpty());
    System.assertEquals(false, recordsWithoutSharing.isEmpty());

    System.assertEquals(1, recordsWithSharing.size());
    System.assertEquals(1, recordsWithoutSharing.size());
  }
}