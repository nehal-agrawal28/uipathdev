/**
 * File Name: DiscountConditions_PP
 *
 * @author : architect ir. Wilhelmus G.J. Velzeboer
 */
public class DiscountConditions_PP extends ConditionsAbstract_PP implements IDiscountConditions_PP {
  public DiscountConditions_PP(List<DiscountCondition__c> records) {
    super(records, Schema.DiscountCondition__c.SObjectType);
  }

  public static IDiscountConditions_PP newInstance(Set<Id> ids) {
    return (IDiscountConditions_PP) Application_PP.Domain.newInstance(ids);
  }

  public static IDiscountConditions_PP newInstance(List<DiscountCondition__c> records) {
    return (IDiscountConditions_PP) Application_PP.Domain.newInstance(records, DiscountCondition__c.SObjectType);
  }

  public List<DiscountCondition__c> getDiscountConditions() {
    return (List<DiscountCondition__c>) getRecords();
  }

  public IDiscountConditions_PP selectByScheduleId(Id scheduleId) {
    List<DiscountCondition__c> result = new List<DiscountCondition__c>();
    for (DiscountCondition__c condition : getDiscountConditions()) {
      if (condition.DiscountSchedule__c == scheduleId) {
        result.add(condition);
      }
    }
    return new DiscountConditions_PP(result);
  }

  public class Constructor implements fflib_SObjectDomain.IConstructable2 {
    public fflib_SObjectDomain construct(List<SObject> sObjectList) {
      return new DiscountConditions_PP(sObjectList);
    }

    public fflib_SObjectDomain construct(List<SObject> sObjectList, SObjectType sObjectType) {
      return new DiscountConditions_PP(sObjectList);
    }
  }
}