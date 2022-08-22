public class ContractSubscriptionController {
  @AuraEnabled(cacheable=true)
  public static Contract getContractDetail(String contractId) {
    return [SELECT Id, ContractNumber, CurrencyIsoCode FROM Contract WHERE id = :contractId];
  }

  @AuraEnabled(cacheable=true)
  public static List<SubscriptionProduct> getSubscription(String contractId) {
    List<SubscriptionProduct> subscriptionProductList = new List<SubscriptionProduct>();
    Map<Id, List<SBQQ__Subscription__c>> subscriptionMap = new Map<Id, List<SBQQ__Subscription__c>>();
    List<String> elaProductCode = new List<String>();
    elaProductCode = Label.ELA_Product_Codes.split(',');
    List<SBQQ__Subscription__c> sbList = [
      SELECT
        Id,
        Name,
        SBQQ__Quantity__c,
        SBQQ__Product__c,
        ELA_End_Date__c,
        qtc_Current_Cap_Quantity__c,
        SBQQ__Number__c,
        SBQQ__StartDate__c,
        qtc_Above_the_Cap_Price__c,
        SBQQ__NetPrice__c,
        SBQQ__Product__r.Name,
        SBQQ__Product__r.ProductCode,
        qtc_Cap_Quantity__c,
        SBQQ__RenewalQuantity__c,
        SBQQ__SegmentQuantity__c
      FROM SBQQ__Subscription__c
      WHERE
        SBQQ__Contract__c = :contractId
        AND SBQQ__Product__r.productCode IN :elaProductCode
        AND ELA_End_Date__c > today
        AND SBQQ__TerminatedDate__c = null 
      ORDER BY SBQQ__StartDate__c, SBQQ__RequiredByProduct__c
    ];

    for (SBQQ__Subscription__c sb : sbList) {
      List<SBQQ__Subscription__c> subscriptionList = new List<SBQQ__Subscription__c>();
      if (subscriptionMap.containskey(sb.SBQQ__Product__c)) {
        subscriptionList = subscriptionMap.get(sb.SBQQ__Product__c);
      }
      subscriptionList.add(sb);
      subscriptionMap.put(sb.SBQQ__Product__c, subscriptionList);
    }

    for (Id productId : subscriptionMap.keyset()) {
      SubscriptionProduct sp = new SubscriptionProduct();
      sp.productId = productId;
      List<SBQQ__Subscription__c> subscriptionList = subscriptionMap.get(productId);
      sp.name = subscriptionList[0].SBQQ__Product__r.Name;
      sp.productCode = subscriptionList[0].SBQQ__Product__r.ProductCode;
      List<SubscriptionData> subscriptions = new List<SubscriptionData>();
      for (SBQQ__Subscription__c sb : subscriptionList) {
        subscriptions.add(new SubscriptionData(sb));
      }
      subscriptions[0].isFirst = true;
      subscriptions[0].firstClassName = 'firstRow';
      sp.subscriptions = subscriptions;
      subscriptionProductList.add(sp);
    }

    return subscriptionProductList;
  }

  @AuraEnabled
  public static String saveSubscription(String updatedListStr) {
    List<SubscriptionProduct> updatedList = (List<SubscriptionProduct>) JSON.deserialize(
      updatedListStr,
      List<SubscriptionProduct>.class
    );
    List<SBQQ__Subscription__c> subscriptionList = new List<SBQQ__Subscription__c>();
    for (SubscriptionProduct sp : updatedList) {
      for (SubscriptionData sub : sp.subscriptions) {
        subscriptionList.add(sub.subscription);
      }
    }

    if (!subscriptionList.isEmpty() && subscriptionList.size() > 0) {
      update subscriptionList;
    }
    return 'Success';
  }

  public class SubscriptionProduct {
    @AuraEnabled
    public String productId;
    @AuraEnabled
    public String name;
    @AuraEnabled
    public String productCode;
    @AuraEnabled
    public List<SubscriptionData> subscriptions;
  }
  public class SubscriptionData {
    @AuraEnabled
    public SBQQ__Subscription__c subscription;
    @AuraEnabled
    public Boolean isFirst;
    @AuraEnabled
    public String firstClassName;
    @AuraEnabled
    public Integer swapRequest;
    @AuraEnabled
    public Integer accum;
    @AuraEnabled
    public Boolean isDisabled;
    @AuraEnabled
    public Integer originalCapQuantity;

    public SubscriptionData(SBQQ__Subscription__c subscription) {
      this.swapRequest = 0;
      this.accum = 0;
      this.isFirst = false;
      this.isDisabled = false; //(Integer.valueof(subscription.qtc_Cap_Quantity__c)==0 || Integer.valueof(subscription.qtc_Cap_Quantity__c)==null) ? true : false;
      if (subscription.qtc_Cap_Quantity__c == null) {
        subscription.qtc_Cap_Quantity__c = 0;
      }
      this.originalCapQuantity = Integer.valueof(subscription.qtc_Cap_Quantity__c);
      this.subscription = subscription;
    }
  }
}