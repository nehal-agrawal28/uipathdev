/**
 * File Name: DiscountTableItemsSelector_PP
 *
 * @author: architect ir. Wilhelmus G.J. Velzeboer
 */
public virtual inherited sharing class DiscountTableItemsSelector_PP extends fflib_SObjectSelector implements IDiscountTableItemsSelector_PP {
  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField>{
      DiscountTableItem__c.Id,
      DiscountTableItem__c.Category__c,
      DiscountTableItem__c.DiscountPercentage__c,
      DiscountTableItem__c.DiscountTable__c,
      DiscountTableItem__c.Product__c
    };
  }

  public DiscountTableItemsSelector_PP() {
    super();
  }

  public DiscountTableItemsSelector_PP(Boolean includeFieldSetFields, Boolean enforceCRUD, Boolean enforceFLS) {
    super(includeFieldSetFields, enforceCRUD, enforceFLS);
  }

  public static IDiscountTableItemsSelector_PP newInstance() {
    return (IDiscountTableItemsSelector_PP) Application_PP.Selector.newInstance(DiscountTableItem__c.SObjectType);
  }

  public static IDiscountTableItemsSelector_PP newElevatedInstance() {
    return (IDiscountTableItemsSelector_PP) Application_PP.ElevatedSelector.newInstance(
      DiscountTableItem__c.SObjectType
    );
  }

  public Schema.SObjectType getSObjectType() {
    return DiscountTableItem__c.SObjectType;
  }

  public virtual List<DiscountTableItem__c> selectById(Set<Id> idSet) {
    return (List<DiscountTableItem__c>) selectSObjectsById(idSet);
  }

  public without sharing class WithoutSharing extends DiscountTableItemsSelector_PP {
    public WithoutSharing() {
      super(
        true, // Include field set felds
        false, // enforce CRUD
        false
      ); // enforce FLS
    }

    public override List<DiscountTableItem__c> selectById(Set<Id> idSet) {
      return super.selectById(idSet);
    }
  }
}