public with sharing class NetworksService_PP {
  public String getLoginURL(String name) {
    final NetworksSelector_PP networksSelector = (NetworksSelector_PP) Application_PP.Selector.newInstance(
      Network.SObjectType
    );
    final List<Network> networks = networksSelector.selectByName(new Set<String>{ name }, false);

    if (!networks.isEmpty()) {
      return Network.getLoginUrl(networks[0].Id);
    } else {
      return '';
    }
  }
}