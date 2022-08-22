/**
 * File Name: DiscountTablesSelector_PP
 *
 * @author: architect ir. Wilhelmus G.J. Velzeboer
 */
public virtual inherited sharing class DiscountTablesSelector_PP extends fflib_SObjectSelector implements IDiscountTablesSelector_PP {
  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField>{ DiscountTable__c.Id, DiscountTable__c.Name };
  }

  public DiscountTablesSelector_PP() {
    super();
  }

  public DiscountTablesSelector_PP(Boolean includeFieldSetFields, Boolean enforceCRUD, Boolean enforceFLS) {
    super(includeFieldSetFields, enforceCRUD, enforceFLS);
  }

  public static IDiscountTablesSelector_PP newInstance() {
    return (IDiscountTablesSelector_PP) Application_PP.Selector.newInstance(DiscountTable__c.SObjectType);
  }

  public static IDiscountTablesSelector_PP newElevatedInstance() {
    return (IDiscountTablesSelector_PP) Application_PP.ElevatedSelector.newInstance(DiscountTable__c.SObjectType);
  }

  public Schema.SObjectType getSObjectType() {
    return DiscountTable__c.SObjectType;
  }

  public virtual List<DiscountTable__c> selectByIdWithItems(Set<Id> ids) {
    fflib_QueryFactory queryFactory = newQueryFactory();

    new DiscountTableItemsSelector_PP().addQueryFactorySubselect(queryFactory);

    return (List<DiscountTable__c>) Database.query(queryFactory.setCondition('Id IN :ids').toSOQL());
  }

  public virtual List<DiscountTable__c> selectById(Set<Id> idSet) {
    return (List<DiscountTable__c>) selectSObjectsById(idSet);
  }

  public without sharing class WithoutSharing extends DiscountTablesSelector_PP {
    public WithoutSharing() {
      super(
        true, // Include field set felds
        false, // enforce CRUD
        false
      ); // enforce FLS
    }

    public override List<DiscountTable__c> selectById(Set<Id> idSet) {
      return super.selectById(idSet);
    }

    public override List<DiscountTable__c> selectByIdWithItems(Set<Id> ids) {
      return super.selectByIdWithItems(ids);
    }
  }
}