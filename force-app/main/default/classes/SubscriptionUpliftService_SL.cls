/**
 * CPQ renewal uplift service implementation
 */
public with sharing class SubscriptionUpliftService_SL implements ISubscriptionUpliftService_SL {
  private SubscriptionSelector_SL subscriptionSelector {
    get {
      return (SubscriptionSelector_SL) Application_SL.Selector.newInstance(SBQQ__Subscription__c.SObjectType);
    }
    set;
  }

  private fflib_ISObjectUnitOfWork unitOfWork = Application_SL.UnitOfWork.newInstance();

  /**
   * @description fetch contract related subscriptions and evaluate uplift
   * @param  contracts      list of contract
   */
  public void evaluateSubscriptionUplifts(Set<Id> contractIds) {
    List<SBQQ__Subscription__c> subscriptions = subscriptionSelector.selectSubscriptionsFromContractForUplift(
      contractIds
    );

    // Fetch potential contracted prices
    Map<Id, SBQQ__ContractedPrice__c> eligiblePricesMap = new Map<Id, SBQQ__ContractedPrice__c>();
    List<Id> quotelineIds = Collection.of(subscriptions).pluckIds(SBQQ__Subscription__c.SBQQ__QuoteLine__c);
    fflib_QueryFactory queryPrices = new fflib_QueryFactory(SBQQ__ContractedPrice__c.SObjectType);
    queryPrices.selectField('Id');
    queryPrices.selectField('SBQQ__OriginalQuoteLine__c');
    queryPrices.selectField('SBQQ__ExpirationDate__c');
    queryPrices.selectField('SBQQ__Product__c');
    queryPrices.setCondition('SBQQ__OriginalQuoteLine__c != null AND SBQQ__OriginalQuoteLine__c IN :quotelineIds');
    for (SBQQ__ContractedPrice__c cp : Database.query(queryPrices.toSOQL())) {
      if (cp.SBQQ__ExpirationDate__c >= System.Today() || cp.SBQQ__ExpirationDate__c == null) {
        eligiblePricesMap.put(cp.SBQQ__OriginalQuoteLine__c, cp);
      }
    }

    for (SBQQ__Subscription__c sub : subscriptions) {
      CPQ_Renewal_Uplift__mdt configMetadata = ContractRenewalService_SL.getUpliftGeoConfig(
        sub.SBQQ__Account__r.Geo__c + sub.SBQQ__Account__r.Area__c,
        sub.SBQQ__Account__r.Geo__c
      );

      Boolean hasContractedPrice =
        sub.SBQQ__QuoteLine__r.SBQQ__ContractedPrice__c != null &&
        (sub.SBQQ__QuoteLine__r.SBQQ__ContractedPrice__r.SBQQ__ExpirationDate__c >= System.today() ||
        sub.SBQQ__QuoteLine__r.SBQQ__ContractedPrice__r.SBQQ__ExpirationDate__c == null);

      if (sub.SBQQ__Product__r.Uplift_Exempt__c) {
        // Excluded: Product exempted
        excludeSubscription(sub, 'Product Uplift Exempt');
      } else if (hasContractedPrice || eligiblePricesMap.containsKey(sub.SBQQ__QuoteLine__c)) {
        // Excluded: Contracted price
        excludeSubscription(sub, 'Contracted Price');
      } else {
        // Included: Apply uplift
        includeSubscription(sub, configMetadata.UpliftRate__c);

        if (sub.SBQQ__ProrateMultiplier__c < 1) {
          Decimal annualisedNetPrice = sub.SBQQ__ProrateMultiplier__c != 0
            ? sub.SBQQ__NetPrice__c / sub.SBQQ__ProrateMultiplier__c
            : 0;
          Decimal upliftPrice = annualisedNetPrice * (1 + configMetadata.UpliftRate__c / 100);

          if (upliftPrice > sub.SBQQ__QuoteLine__r.SBQQ__ListPrice__c) {
            // Prevent uplift to exceed list price
            sub.SBQQ__RenewalPrice__c = sub.SBQQ__QuoteLine__r.SBQQ__ListPrice__c;
            excludeSubscription(sub, 'Uplift can not exceed list price');
          } else {
            // Set correct annualised price when contract duration is less than one year
            sub.SBQQ__RenewalPrice__c = upliftPrice;
          }
        } else {
          Decimal upliftPrice = sub.SBQQ__NetPrice__c * (1 + configMetadata.UpliftRate__c / 100);

          if (upliftPrice > sub.SBQQ__ListPrice__c) {
            // Prevent uplift to exceed list price
            sub.SBQQ__RenewalPrice__c = sub.SBQQ__ListPrice__c;
            excludeSubscription(sub, 'Uplift can not exceed list price');
          }
        }
      }
    }

    unitOfWork.registerDirty(subscriptions);
    unitOfWork.commitWork();
  }

  /**
   * @description fetch contract related subscriptions and remove uplift
   * @param  contracts      list of contract
   */
  public void removeSubscriptionUplifts(Set<Id> contractIds) {
    List<SBQQ__Subscription__c> subscriptions = subscriptionSelector.selectSubscriptionsFromContractForUplift(
      contractIds
    );

    for (SBQQ__Subscription__c sub : subscriptions) {
      sub.SBQQ__RenewalPrice__c = null;
      sub.SBQQ__RenewalUpliftRate__c = null;
      sub.Uplift_Exception_Reason__c = null;
    }

    unitOfWork.registerDirty(subscriptions);
    unitOfWork.commitWork();
  }

  private void excludeSubscription(SBQQ__Subscription__c sub, String reason) {
    sub.Uplift_Exception_Reason__c = reason;
    sub.SBQQ__RenewalUpliftRate__c = 0;
  }

  private void includeSubscription(SBQQ__Subscription__c sub, Decimal rate) {
    sub.Uplift_Exception_Reason__c = null;
    sub.SBQQ__RenewalUpliftRate__c = rate;
    sub.SBQQ__RenewalPrice__c = null;
  }
}