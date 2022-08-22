public without sharing class DealRegistrationProductsService_PP {
  public Map<Id, List<DealRegistrationProduct__c>> getDealRegistrationProductsByDealRegistrationId(
    Set<Id> dealRegistrationIds
  ) {
    Map<Id, List<DealRegistrationProduct__c>> dealRegistrationProductsByDealRegistrationId = new Map<Id, List<DealRegistrationProduct__c>>();

    DealRegistrationProductsSelector_PP dealRegistrationProductsSelector = (DealRegistrationProductsSelector_PP) Application_PP.Selector
      .newInstance(DealRegistrationProduct__c.SObjectType);

    List<DealRegistrationProduct__c> dealRegistrationProducts = dealRegistrationProductsSelector.selectByDealRegistrationId(
      dealRegistrationIds,
      false
    );

    for (DealRegistrationProduct__c dealRegistrationProduct : dealRegistrationProducts) {
      if (!dealRegistrationProductsByDealRegistrationId.containsKey(dealRegistrationProduct.DealRegistration__c)) {
        dealRegistrationProductsByDealRegistrationId.put(
          dealRegistrationProduct.DealRegistration__c,
          new List<DealRegistrationProduct__c>()
        );
      }

      dealRegistrationProductsByDealRegistrationId.get(dealRegistrationProduct.DealRegistration__c)
        .add(dealRegistrationProduct);
    }

    return dealRegistrationProductsByDealRegistrationId;
  }
}