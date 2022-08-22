public without sharing class OpportunitySplitSelector_ET extends fflib_SObjectSelector {
  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField>{
      Opportunity_Split__c.ID,
      Opportunity_Split__c.User__c,
      Opportunity_Split__c.Opportunity__c,
      Opportunity_Split__c.TeamMemberRole__c,
      Opportunity_Split__c.Territory_Reason__c
    };
  }

  public Schema.SObjectType getSObjectType() {
    return Opportunity_Split__c.sObjectType;
  }

  public List<Opportunity_Split__c> selectById(Set<Id> splitIds) {
    return (List<Opportunity_Split__c>) Database.query(
      newQueryFactory(false, false, true).setCondition('Id =: splitIds').toSOQL()
    );
  }

  public List<Opportunity_Split__c> selectByOppId(Set<Id> oppIds) {
    return (List<Opportunity_Split__c>) Database.query(
      newQueryFactory(false, false, true)
        .selectField('Opportunity__c')
        .selectField('Role__c')
        .selectField('Included_in_Compensation__c')
        .selectField('User__c')
        .selectField('User__r.Name')
        .selectField('Name')
        .selectField('Percentage__c')
        .selectField('Opportunity__r.Territory2Id')
        .selectField('Opportunity__r.AccountId')
        .setCondition('Opportunity__c =: oppIds')
        .toSOQL()
    );
  }

  public List<Opportunity_Split__c> selectByUserId(Set<Id> userIds) {
    return (List<Opportunity_Split__c>) Database.query(
      newQueryFactory(false, false, true).setCondition('User__c =: userIds').toSOQL()
    );
  }
}