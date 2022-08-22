/**
 * File Name: DiscountUpliftConditionsSelector_PP
 *
 * @author: architect ir. Wilhelmus G.J. Velzeboer
 */
public virtual inherited sharing class DiscountUpliftConditionsSelector_PP extends fflib_SObjectSelector implements IDiscountUpliftConditionsSelector_PP {
  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField>{
      DiscountUpliftCondition__c.Id,
      DiscountUpliftCondition__c.DiscountUplift__c,
      DiscountUpliftCondition__c.Field__c,
      DiscountUpliftCondition__c.Operator__c,
      DiscountUpliftCondition__c.Sequence__c,
      DiscountUpliftCondition__c.Value__c
    };
  }

  public DiscountUpliftConditionsSelector_PP() {
    super();
  }

  public DiscountUpliftConditionsSelector_PP(Boolean includeFieldSetFields, Boolean enforceCRUD, Boolean enforceFLS) {
    super(includeFieldSetFields, enforceCRUD, enforceFLS);
  }

  public static IDiscountUpliftConditionsSelector_PP newInstance() {
    return (IDiscountUpliftConditionsSelector_PP) Application_PP.Selector.newInstance(
      DiscountUpliftCondition__c.SObjectType
    );
  }

  public static IDiscountUpliftConditionsSelector_PP newElevatedInstance() {
    return (IDiscountUpliftConditionsSelector_PP) Application_PP.ElevatedSelector.newInstance(
      DiscountUpliftCondition__c.SObjectType
    );
  }

  public Schema.SObjectType getSObjectType() {
    return DiscountUpliftCondition__c.SObjectType;
  }

  public virtual List<DiscountUpliftCondition__c> selectById(Set<Id> idSet) {
    return (List<DiscountUpliftCondition__c>) selectSObjectsById(idSet);
  }

  public virtual List<DiscountUpliftCondition__c> selectByUpliftId(Set<Id> upliftId) {
    return (List<DiscountUpliftCondition__c>) Database.query(
      newQueryFactory().setCondition('DiscountUplift__c IN :upliftId').toSOQL()
    );
  }

  public without sharing class WithoutSharing extends DiscountUpliftConditionsSelector_PP {
    public WithoutSharing() {
      super(
        true, // Include field set felds
        false, // enforce CRUD
        false
      ); // enforce FLS
    }

    public override List<DiscountUpliftCondition__c> selectById(Set<Id> idSet) {
      return super.selectById(idSet);
    }

    public override List<DiscountUpliftCondition__c> selectByUpliftId(Set<Id> upliftId) {
      return super.selectByUpliftId(upliftId);
    }
  }
}