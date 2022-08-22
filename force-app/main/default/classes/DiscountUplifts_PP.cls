/**
 * File Name: DiscountUplifts_PP
 *
 * @author: architect ir. Wilhelmus G.J. Velzeboer
 */
public class DiscountUplifts_PP extends fflib_SObjectDomain implements IDiscountUplifts_PP {
  public DiscountUplifts_PP(List<DiscountUplift__c> records) {
    super(records, Schema.DiscountUplift__c.SObjectType);
  }

  public static IDiscountUplifts_PP newInstance(List<DiscountUplift__c> records) {
    return (IDiscountUplifts_PP) Application_PP.Domain.newInstance(records, Schema.DiscountUplift__c.SObjectType);
  }

  public static IDiscountUplifts_PP newInstance(Set<Id> ids) {
    return (IDiscountUplifts_PP) Application_PP.Domain.newInstance(ids);
  }

  public IDiscountUpliftConditions_PP getConditions() {
    List<DiscountUpliftCondition__c> result = new List<DiscountUpliftCondition__c>();
    for (DiscountUplift__c record : getDiscountUplifts()) {
      if (record.DiscountUpliftConditions__r?.isEmpty())
        continue;

      result.addAll(record.DiscountUpliftConditions__r);
    }
    return DiscountUpliftConditions_PP.newInstance(result);
  }

  public Set<Id> getDiscountTableIds() {
    Set<Id> result = new Set<Id>();
    for (DiscountUplift__c record : getDiscountUplifts()) {
      result.add(record.DiscountTable__c);
    }
    return result;
  }

  public List<Id> getDiscountTableIdList() {
    List<Id> result = new List<Id>();
    for (DiscountUplift__c record : getDiscountUplifts()) {
      result.add(record.DiscountTable__c);
    }
    return result;
  }

  public List<DiscountUplift__c> getDiscountUplifts() {
    return (List<DiscountUplift__c>) getRecords();
  }

  public IDiscountUplifts_PP selectByAccountId(Set<Id> ids) {
    List<DiscountUplift__c> result = new List<DiscountUplift__c>();
    for (DiscountUplift__c record : getDiscountUplifts()) {
      if (ids.contains(record.Account__c)) {
        result.add(record);
      }
    }
    return DiscountUplifts_PP.newInstance(result);
  }

  public IDiscountUplifts_PP selectByAccountId(Id id) {
    return selectByAccountId(new Set<Id>{ id, null });
  }

  public class Constructor implements fflib_SObjectDomain.IConstructable2 {
    public fflib_SObjectDomain construct(List<SObject> sObjectList) {
      return new DiscountUplifts_PP(sObjectList);
    }

    public fflib_SObjectDomain construct(List<SObject> sObjectList, SObjectType sObjectType) {
      return new DiscountUplifts_PP(sObjectList);
    }
  }
}