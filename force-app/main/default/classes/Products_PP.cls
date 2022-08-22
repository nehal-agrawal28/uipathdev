/**
 * File Name: Products_PP
 *
 * @author: architect ir. Wilhelmus G.J. Velzeboer
 */
public class Products_PP extends fflib_SObjectDomain implements IProducts_PP {
  public Products_PP(List<Product2> records) {
    super(records, Schema.Product2.SObjectType);
  }

  public static IProducts_PP newInstance(Set<Id> ids) {
    return (IProducts_PP) Application_PP.Domain.newInstance(ids, Schema.Product2.SObjectType);
  }

  public static IProducts_PP newInstance(List<Product2> records) {
    return (IProducts_PP) Application_PP.Domain.newInstance(records, Schema.Product2.SObjectType);
  }

  public Map<Id, String> getDiscountCategoryById() {
    Map<Id, String> result = new Map<Id, String>();
    for (Product2 record : getProducts()) {
      result.put(record.Id, record.PartnerDiscountCategory__c);
    }
    return result;
  }

  public List<Product2> getProducts() {
    return (List<Product2>) getRecords();
  }

  public Map<Id, Product2> getRecordById() {
    return new Map<Id, Product2>(getProducts());
  }

  public IProducts_PP selectById(Set<Id> productIds) {
    List<Product2> result = new List<Product2>();
    for (Product2 product : getProducts()) {
      if (productIds.contains(product.Id)) {
        result.add(product);
      }
    }
    return new Products_PP(result);
  }

  public class Constructor implements fflib_SObjectDomain.IConstructable2 {
    public fflib_SObjectDomain construct(List<SObject> sObjectList) {
      return new Products_PP(sObjectList);
    }

    public fflib_SObjectDomain construct(List<SObject> sObjectList, SObjectType sObjectType) {
      return new Products_PP(sObjectList);
    }
  }
}