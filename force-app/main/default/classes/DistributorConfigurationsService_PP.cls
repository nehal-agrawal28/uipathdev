public without sharing class DistributorConfigurationsService_PP {
  public static Map<Id, Set<String>> buildCountriesByAccountId(Set<String> countries) {
    DistributorConfigurationsSelector_PP selector = (DistributorConfigurationsSelector_PP) Application_PP.Selector.newInstance(
      DistributorConfiguration__c.SObjectType
    );

    List<DistributorConfiguration__c> configurations = selector.selectByBusinessPartnerTypesAndCountries(
      new Set<String>{ 'Distributor' },
      countries,
      false
    );

    Map<Id, Set<String>> countriesByAccountId = new Map<Id, Set<String>>();

    for (DistributorConfiguration__c configuration : configurations) {
      if (String.isBlank(configuration.Country__c))
        continue;

      String country = configuration.Country__c.toUpperCase();

      if (!countriesByAccountId.containsKey(configuration.Account__c)) {
        countriesByAccountId.put(configuration.Account__c, new Set<String>());
      }

      countriesByAccountId.get(configuration.Account__c).add(country);
    }

    return countriesByAccountId;
  }
}