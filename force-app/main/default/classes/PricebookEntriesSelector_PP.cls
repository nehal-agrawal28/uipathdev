public without sharing class PricebookEntriesSelector_PP extends fflib_SObjectSelector {
  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField>{
      PricebookEntry.Id,
      PricebookEntry.Pricebook2Id,
      PricebookEntry.Product2Id,
      PricebookEntry.Product2.Name,
      PricebookEntry.UnitPrice
    };
  }

  public Schema.SObjectType getSObjectType() {
    return PricebookEntry.sObjectType;
  }

  public List<PricebookEntry> selectById(Set<Id> ids, Boolean withSharing) {
    if (withSharing)
      return (List<PricebookEntry>) selectSObjectsById(ids);
    else
      return (List<PricebookEntry>) Database.query(
        newQueryFactory(false, false, true).setCondition('Id IN :ids').toSOQL()
      );
  }

  public List<PricebookEntry> selectByPricebookNameAndCurrency(
    Set<String> pricebookNames,
    String currencyIsoCode,
    Boolean withSharing
  ) {
    if (withSharing)
      return (List<PricebookEntry>) Database.query(
        newQueryFactory(true, true, true)
          .setCondition(
            'isActive = true AND Product2.External_Pricebook_Y_N__c = true AND Pricebook2.Name IN :pricebookNames AND CurrencyIsoCode = :currencyIsoCode'
          )
          .toSOQL()
      );
    else
      return (List<PricebookEntry>) Database.query(
        newQueryFactory(false, false, true)
          .setCondition(
            'isActive = true AND Product2.External_Pricebook_Y_N__c = true AND Pricebook2.Name IN :pricebookNames AND CurrencyIsoCode = :currencyIsoCode'
          )
          .toSOQL()
      );
  }
}