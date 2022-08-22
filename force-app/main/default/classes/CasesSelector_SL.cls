public with sharing class CasesSelector_SL extends fflib_SObjectSelector {
  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField>{
      Case.Cancellation_Transaction__c,
      Case.Deal_Hub_Owner__c,
      Case.Id,
      Case.Opportunity__c,
      Case.Replacement_Transaction__c,
      Case.Status
    };
  }

  public Schema.SObjectType getSObjectType() {
    return Case.SObjectType;
  }

  public List<Case> selectById(Set<Id> ids, Boolean enforceSecurity) {
    if (enforceSecurity) {
      return (List<Case>) selectSObjectsById(ids);
    } else {
      return (List<Case>) Database.query(newQueryFactory(false, false, true).setCondition('Id IN :ids').toSOQL());
    }
  }

  public List<Case> selectReplacementTransactionQuoteIdsByCaseId(Set<Id> caseIds, Boolean enforceSecurity) {
    if (caseIds.isEmpty()) {
      return new List<Case>();
    }

    fflib_QueryFactory queryFactory;

    if (enforceSecurity) {
      queryFactory = newQueryFactory(true, true, true);
    } else {
      queryFactory = newQueryFactory(false, false, true);
    }
    List<Schema.SObjectField> registerFields = new List<Schema.SObjectField>{ Opportunity.SBQQ__PrimaryQuote__c };
    queryFactory.selectField('Opportunity__r.SBQQ__PrimaryQuote__c');
    queryFactory.setCondition('Id IN :caseIds AND Replacement_Transaction__c = true');

    return Database.query(queryFactory.toSOQL());
  }

  public List<Case> selectCancellationTransactionCasesByReplacementQuoteIds(Set<Id> quoteIds, Boolean enforceSecurity) {
    if (quoteIds.isEmpty()) {
      return new List<Case>();
    }

    fflib_QueryFactory queryFactory;

    if (enforceSecurity) {
      queryFactory = newQueryFactory(true, true, true);
    } else {
      queryFactory = newQueryFactory(false, false, true);
    }
    List<Schema.SObjectField> registerFields = new List<Schema.SObjectField>{
      Opportunity.SBQQ__PrimaryQuote__c,
      SBQQ__Quote__c.Replacement_Quote__c
    };
    queryFactory.selectField('Opportunity__r.SBQQ__PrimaryQuote__r.Replacement_Quote__c');
    queryFactory.setCondition(
      'Opportunity__r.SBQQ__PrimaryQuote__r.Replacement_Quote__c IN :quoteIds AND Cancellation_Transaction__c = true'
    );

    return Database.query(queryFactory.toSOQL());
  }
}