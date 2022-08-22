/**
 * File Name: DiscountUpliftsSelector_PP
 *
 * @author: architect ir. Wilhelmus G.J. Velzeboer
 */
public virtual inherited sharing class DiscountUpliftsSelector_PP extends fflib_SObjectSelector implements IDiscountUpliftsSelector_PP {
  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField>{
      DiscountUplift__c.Id,
      DiscountUplift__c.Active__c,
      DiscountUplift__c.Account__c,
      DiscountUplift__c.ConditionFormula__c,
      DiscountUplift__c.DiscountTable__c,
      DiscountUplift__c.EndDate__c,
      DiscountUplift__c.Name,
      DiscountUplift__c.StartDate__c
    };
  }

  public DiscountUpliftsSelector_PP() {
    super();
  }

  public DiscountUpliftsSelector_PP(Boolean includeFieldSetFields, Boolean enforceCRUD, Boolean enforceFLS) {
    super(includeFieldSetFields, enforceCRUD, enforceFLS);
  }

  public static IDiscountUpliftsSelector_PP newInstance() {
    return (IDiscountUpliftsSelector_PP) Application_PP.Selector.newInstance(Schema.DiscountUplift__c.SObjectType);
  }

  public static IDiscountUpliftsSelector_PP newElevatedInstance() {
    return (IDiscountUpliftsSelector_PP) Application_PP.ElevatedSelector.newInstance(
      Schema.DiscountUplift__c.SObjectType
    );
  }

  public Schema.SObjectType getSObjectType() {
    return DiscountUplift__c.SObjectType;
  }

  public virtual List<DiscountUplift__c> selectByAccountIdWithConditionsAndItems(Set<Id> accountIds) {
    fflib_QueryFactory queryFactory = newQueryFactory();

    new DiscountUpliftConditionsSelector_PP().addQueryFactorySubselect(queryFactory);

    return (List<DiscountUplift__c>) Database.query(
      queryFactory
        .setCondition(
          '(Account__c IN :accountIds OR Account__c = null) ' +
          'AND Active__c = true ' +
          'AND StartDate__c < TODAY AND EndDate__c > TODAY'
        )
        .toSOQL()
    );
  }

  public virtual List<DiscountUplift__c> selectById(Set<Id> idSet) {
    return (List<DiscountUplift__c>) selectSObjectsById(idSet);
  }

  public without sharing class WithoutSharing extends DiscountUpliftsSelector_PP {
    public WithoutSharing() {
      super(
        true, // Include field set felds
        false, // enforce CRUD
        false
      ); // enforce FLS
    }

    public override List<DiscountUplift__c> selectById(Set<Id> idSet) {
      return super.selectById(idSet);
    }

    public override List<DiscountUplift__c> selectByAccountIdWithConditionsAndItems(Set<Id> accountIds) {
      return super.selectByAccountIdWithConditionsAndItems(accountIds);
    }
  }
}