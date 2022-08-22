/**
 * File Name: ProductsSelector_PP
 *
 * @author: architect ir. Wilhelmus G.J. Velzeboer
 */
public virtual inherited sharing class ProductsSelector_PP extends fflib_SObjectSelector implements IProductsSelector_PP {
  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField>{ Product2.Id, Product2.PartnerDiscountCategory__c };
  }

  public ProductsSelector_PP() {
    super();
  }

  public ProductsSelector_PP(Boolean includeFieldSetFields, Boolean enforceCRUD, Boolean enforceFLS) {
    super(includeFieldSetFields, enforceCRUD, enforceFLS);
  }

  public static IProductsSelector_PP newInstance() {
    return (IProductsSelector_PP) Application_PP.Selector.newInstance(Product2.getSObjectType());
  }

  public static IProductsSelector_PP newElevatedInstance() {
    return (IProductsSelector_PP) Application_PP.ElevatedSelector.newInstance(Product2.getSObjectType());
  }

  public Schema.SObjectType getSObjectType() {
    return Product2.getSObjectType();
  }

  public virtual List<Product2> selectById(Set<Id> idSet) {
    return (List<Product2>) selectSObjectsById(idSet);
  }

  public with sharing class WithSharing extends ProductsSelector_PP {
    // Constructor that will enforce CRUD and FLS
    public WithSharing() {
      super(
        true, // Include field set felds
        true, // enforce CRUD
        true
      ); // enforce FLS
    }

    public override List<Product2> selectById(Set<Id> idSet) {
      return super.selectById(idSet);
    }
  }

  public without sharing class WithoutSharing extends ProductsSelector_PP {
    public WithoutSharing() {
      super(
        true, // Include field set felds
        false, // enforce CRUD
        false
      ); // enforce FLS
    }

    public override List<Product2> selectById(Set<Id> idSet) {
      return super.selectById(idSet);
    }
  }
}