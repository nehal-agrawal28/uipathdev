/**
 * File Name: DiscountTables_PP
 *
 * @author: architect ir. Wilhelmus G.J. Velzeboer
 */
public class DiscountTables_PP extends fflib_SObjectDomain implements IDiscountTables_PP {
  public DiscountTables_PP(List<DiscountTable__c> records) {
    super(records, Schema.DiscountTable__c.SObjectType);
  }

  public static IDiscountTables_PP newInstance(Set<Id> ids) {
    return (IDiscountTables_PP) Application_PP.Domain.newInstance(ids);
  }

  public static IDiscountTables_PP newInstance(List<DiscountTable__c> records) {
    return (IDiscountTables_PP) Application_PP.Domain.newInstance(records, Schema.DiscountTable__c.SObjectType);
  }

  public List<DiscountTable__c> getDiscountTables() {
    return (List<DiscountTable__c>) getRecords();
  }

  public Map<Id, DiscountTable__c> getRecordsById() {
    return new Map<Id, DiscountTable__c>(getDiscountTables());
  }

  public IDiscountTables_PP orderById(List<Id> ids) {
    Map<Id, DiscountTable__c> discountTableById = getRecordsById();
    List<DiscountTable__c> result = new List<DiscountTable__c>();
    for (Id id : ids) {
      result.add(discountTableById.get(id));
    }
    return new DiscountTables_PP(result);
  }

  public IDiscountTables_PP selectById(Set<Id> ids) {
    List<DiscountTable__c> result = new List<DiscountTable__c>();
    for (DiscountTable__c record : getDiscountTables()) {
      if (ids.contains(record.Id)) {
        result.add(record);
      }
    }
    return new DiscountTables_PP(result);
  }

  public class Constructor implements fflib_SObjectDomain.IConstructable2 {
    public fflib_SObjectDomain construct(List<SObject> sObjectList) {
      return new DiscountTables_PP(sObjectList);
    }

    public fflib_SObjectDomain construct(List<SObject> sObjectList, SObjectType sObjectType) {
      return new DiscountTables_PP(sObjectList);
    }
  }
}