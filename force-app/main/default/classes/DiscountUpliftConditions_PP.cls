/**
 * File Name: DiscountUpliftConditions_PP
 *
 * @author: architect ir. Wilhelmus G.J. Velzeboer
 */
public class DiscountUpliftConditions_PP extends ConditionsAbstract_PP implements IDiscountUpliftConditions_PP {
  public DiscountUpliftConditions_PP(List<DiscountUpliftCondition__c> records) {
    super(records, Schema.DiscountUpliftCondition__c.SObjectType);
  }

  public static IDiscountUpliftConditions_PP newInstance(List<DiscountUpliftCondition__c> records) {
    return (IDiscountUpliftConditions_PP) Application_PP.Domain.newInstance(
      records,
      Schema.DiscountUpliftCondition__c.SObjectType
    );
  }

  public DiscountUpliftConditions_PP selectByUpliftId(Id upliftId) {
    List<DiscountUpliftCondition__c> result = new List<DiscountUpliftCondition__c>();
    for (DiscountUpliftCondition__c condition : (List<DiscountUpliftCondition__c>) getRecords()) {
      if (condition.DiscountUplift__c == upliftId) {
        result.add(condition);
      }
    }
    return new DiscountUpliftConditions_PP(result);
  }

  public class Constructor implements fflib_SObjectDomain.IConstructable2 {
    public fflib_SObjectDomain construct(List<SObject> sObjectList) {
      return new DiscountUpliftConditions_PP(sObjectList);
    }

    public fflib_SObjectDomain construct(List<SObject> sObjectList, SObjectType sObjectType) {
      return new DiscountUpliftConditions_PP(sObjectList);
    }
  }
}