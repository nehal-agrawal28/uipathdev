public with sharing class PricebookEntrySelector_SL extends fflib_SObjectSelector {
  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField>{
      PricebookEntry.CurrencyIsoCode,
      PricebookEntry.IsActive,
      PricebookEntry.Pricebook2Id,
      PricebookEntry.ProductCode
    };
  }

  public Schema.SObjectType getSObjectType() {
    return PricebookEntry.sObjectType;
  }

  public List<PricebookEntry> selectById(Set<Id> ids, Boolean enforceSecurity) {
    if (enforceSecurity) {
      return (List<PricebookEntry>) selectSObjectsById(ids);
    } else {
      return (List<PricebookEntry>) Database.query(
        newQueryFactory(false, false, true).setCondition('Id IN :ids').toSOQL()
      );
    }
  }
}