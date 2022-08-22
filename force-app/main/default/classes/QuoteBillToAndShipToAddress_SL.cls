public with sharing class QuoteBillToAndShipToAddress_SL implements SObjectToSObjectFunction {
  private List<Address__c> addressList;
  private Map<Id, List<Address__c>> mapOfAccIdAndBillingAddressList = new Map<Id, List<Address__c>>();
  private Map<Id, List<Address__c>> mapOfAccIdAndShippingAddressList = new Map<Id, List<Address__c>>();

  public QuoteBillToAndShipToAddress_SL(List<SBQQ__Quote__c> records) {
    Set<Id> billToAccountIds = new Set<Id>(Collection.of(records).pluckIds(SBQQ__Quote__c.Bill_To_Account__c));

    addressList = new List<Address__c>(
      [
        SELECT Id, Account__c, Primary_Billing__c, Primary_Shipping__c
        FROM Address__c
        WHERE Account__c IN :billToAccountIds AND (Primary_Billing__c = TRUE OR Primary_Shipping__c = TRUE)
      ]
    );

    mapOfAccIdAndBillingAddressList = Collection.of(addressList)
      .filter(Match.field(Address__c.Account__c).notEquals(null).also(Address__c.Primary_Billing__c).equals(true))
      .groupByIds(Address__c.Account__c);

    mapOfAccIdAndShippingAddressList = Collection.of(addressList)
      .filter(Match.field(Address__c.Account__c).notEquals(null).also(Address__c.Primary_Shipping__c).equals(true))
      .groupByIds(Address__c.Account__c);
  }

  public SObject apply(SBQQ__Quote__c quote) {
    if (
      mapOfAccIdAndBillingAddressList != null &&
      mapOfAccIdAndBillingAddressList.size() > 0 &&
      mapOfAccIdAndBillingAddressList.containsKey(quote.Bill_To_Account__c)
    ) {
      quote.Bill_To_Address__c = mapOfAccIdAndBillingAddressList.get(quote.Bill_To_Account__c)[0].Id;
    }

    if (
      mapOfAccIdAndShippingAddressList != null &&
      mapOfAccIdAndShippingAddressList.size() > 0 &&
      mapOfAccIdAndShippingAddressList.containsKey(quote.Bill_To_Account__c)
    ) {
      quote.Ship_To_Address__c = mapOfAccIdAndShippingAddressList.get(quote.Bill_To_Account__c)[0].Id;
    }
    return quote;
  }

  public SObject apply(SObject record) {
    return apply((SBQQ__Quote__c) record);
  }

  public static void addBillToAndShipToAddress(List<SBQQ__Quote__c> quotes) {
    Collection.of(quotes)
      .filter(Match.field(SBQQ__Quote__c.Bill_To_Account__c).hasValue())
      .mapAll(new QuoteBillToAndShipToAddress_SL(quotes));
  }

  public static void addBillToAndShipToAddress(List<SObject> records, Map<Id, SObject> existingRecords) {
    SObjectPredicate hasBillToAccountChanged = new HasRecordChanged(
      new Set<SObjectField>{ SBQQ__Quote__c.Bill_To_Account__c },
      records,
      existingRecords
    );
    List<SBQQ__Quote__c> eligibleRecords = Collection.of(records).filter(hasBillToAccountChanged).asList();
    if (!eligibleRecords.isEmpty()) {
      Collection.of(eligibleRecords).mapAll(new QuoteBillToAndShipToAddress_SL(eligibleRecords));
    }
  }
}