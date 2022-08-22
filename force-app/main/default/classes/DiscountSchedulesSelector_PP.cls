/**
 * File Name: DiscountSchedulesSelector_PP
 *
 * @author: architect ir. Wilhelmus G.J. Velzeboer
 */
public virtual inherited sharing class DiscountSchedulesSelector_PP extends fflib_SObjectSelector implements IDiscountSchedulesSelector_PP {
  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField>{
      DiscountSchedule__c.Id,
      DiscountSchedule__c.Account__c,
      DiscountSchedule__c.Active__c,
      DiscountSchedule__c.ConditionFormula__c,
      DiscountSchedule__c.DiscountTable__c,
      DiscountSchedule__c.EndDate__c,
      DiscountSchedule__c.Name,
      DiscountSchedule__c.Sequence__c,
      DiscountSchedule__c.StartDate__c
    };
  }

  public DiscountSchedulesSelector_PP() {
    super();
  }

  public DiscountSchedulesSelector_PP(Boolean includeFieldSetFields, Boolean enforceCRUD, Boolean enforceFLS) {
    super(includeFieldSetFields, enforceCRUD, enforceFLS);
  }

  public static IDiscountSchedulesSelector_PP newInstance() {
    return (IDiscountSchedulesSelector_PP) Application_PP.Selector.newInstance(DiscountSchedule__c.SObjectType);
  }

  public static IDiscountSchedulesSelector_PP newElevatedInstance() {
    return (IDiscountSchedulesSelector_PP) Application_PP.ElevatedSelector.newInstance(DiscountSchedule__c.SObjectType);
  }

  public Schema.SObjectType getSObjectType() {
    return DiscountSchedule__c.SObjectType;
  }

  public virtual List<DiscountSchedule__c> selectActiveByAccountId(Set<Id> accountIds) {
    fflib_QueryFactory queryFactory = newQueryFactory();

    new DiscountConditionsSelector_PP().addQueryFactorySubselect(queryFactory);

    return (List<DiscountSchedule__c>) Database.query(
      queryFactory
        .setCondition(
          '(Account__c IN :accountIds OR Account__c = null) ' +
          'AND Active__c = true ' +
          'AND StartDate__c < TODAY AND EndDate__c > TODAY'
        )
        .toSOQL()
    );
  }

  public virtual List<DiscountSchedule__c> selectById(Set<Id> idSet) {
    return (List<DiscountSchedule__c>) selectSObjectsById(idSet);
  }

  public without sharing class WithoutSharing extends DiscountSchedulesSelector_PP {
    public WithoutSharing() {
      super(
        true, // Include field set felds
        false, // enforce CRUD
        false
      ); // enforce FLS
    }

    public override List<DiscountSchedule__c> selectActiveByAccountId(Set<Id> accountIds) {
      return super.selectActiveByAccountId(accountIds);
    }
  }
}