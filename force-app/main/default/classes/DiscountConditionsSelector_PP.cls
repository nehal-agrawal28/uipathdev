/**
 * File Name: DiscountConditionsSelector_PP
 *
 * @author : architect ir. Wilhelmus G.J. Velzeboer
 */
public virtual inherited sharing class DiscountConditionsSelector_PP extends fflib_SObjectSelector implements IDiscountConditionsSelector_PP {
  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField>{
      DiscountCondition__c.Id,
      DiscountCondition__c.DiscountSchedule__c,
      DiscountCondition__c.Field__c,
      DiscountCondition__c.Operator__c,
      DiscountCondition__c.Sequence__c,
      DiscountCondition__c.Value__c
    };
  }

  public DiscountConditionsSelector_PP() {
    super();
  }

  public DiscountConditionsSelector_PP(Boolean includeFieldSetFields, Boolean enforceCRUD, Boolean enforceFLS) {
    super(includeFieldSetFields, enforceCRUD, enforceFLS);
  }

  public static IDiscountConditionsSelector_PP newInstance() {
    return (IDiscountConditionsSelector_PP) Application_PP.Selector.newInstance(DiscountCondition__c.SObjectType);
  }

  public static IDiscountConditionsSelector_PP newElevatedInstance() {
    return (IDiscountConditionsSelector_PP) Application_PP.ElevatedSelector.newInstance(
      DiscountCondition__c.SObjectType
    );
  }

  public virtual List<DiscountCondition__c> selectByScheduleId(Set<Id> discountSchedulesIds) {
    return (List<DiscountCondition__c>) Database.query(
      newQueryFactory().setCondition('DiscountSchedule__c IN :discountSchedulesIds').toSOQL()
    );
  }

  public Schema.SObjectType getSObjectType() {
    return DiscountCondition__c.SObjectType;
  }

  public without sharing class WithoutSharing extends DiscountConditionsSelector_PP {
    public WithoutSharing() {
      super(
        true, // Include field set felds
        false, // enforce CRUD
        false
      ); // enforce FLS
    }

    public override List<DiscountCondition__c> selectByScheduleId(Set<Id> discountSchedulesIds) {
      return super.selectByScheduleId(discountSchedulesIds);
    }
  }
}