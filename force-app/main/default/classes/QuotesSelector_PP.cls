/**
 * File Name: QuotesSelector_PP
 *
 * @author : architect ir. Wilhelmus G.J. Velzeboer
 */
public virtual inherited sharing class QuotesSelector_PP extends fflib_SObjectSelector implements IQuotesSelector_PP {
  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField>{
      SBQQ__Quote__c.Id,
      SBQQ__Quote__c.SBQQ__Account__c,
      SBQQ__Quote__c.SBQQ__Distributor__c,
      SBQQ__Quote__c.SBQQ__Partner__c
    };
  }

  public QuotesSelector_PP() {
    super();
  }

  public QuotesSelector_PP(Boolean includeFieldSetFields, Boolean enforceCRUD, Boolean enforceFLS) {
    super(includeFieldSetFields, enforceCRUD, enforceFLS);
  }

  public static IQuotesSelector_PP newInstance() {
    return (IQuotesSelector_PP) Application_PP.Selector.newInstance(SBQQ__Quote__c.getSObjectType());
  }

  public static IQuotesSelector_PP newWithoutSharingInstance() {
    return (IQuotesSelector_PP) Application_PP.ElevatedSelector.newInstance(Schema.SBQQ__Quote__c.getSObjectType());
  }

  public Schema.SObjectType getSObjectType() {
    return SBQQ__Quote__c.getSObjectType();
  }

  public virtual List<SBQQ__Quote__c> selectById(Set<Id> idSet) {
    return (List<SBQQ__Quote__c>) selectSObjectsById(idSet);
  }

  public virtual List<SBQQ__Quote__c> selectByIdWithReferences(Set<Id> quoteIds, Set<String> referencedFields) {
    return (List<SBQQ__Quote__c>) Database.query(
      newQueryFactory().selectFields(referencedFields).setCondition('Id IN :quoteIds').toSOQL()
    );
  }

  public without sharing class WithoutSharing extends QuotesSelector_PP {
    public WithoutSharing() {
      super(true, false, false);
    }

    public override List<SBQQ__Quote__c> selectByIdWithReferences(Set<Id> quoteIds, Set<String> referencedFields) {
      return super.selectByIdWithReferences(quoteIds, referencedFields);
    }
  }
}