public class OpportunitiesSelector_ET extends fflib_SObjectSelector {
  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField>{
      Opportunity.AccountId,
      Opportunity.CreatedById,
      Opportunity.Territory2Id,
      Opportunity.Deal_Type__c,
      Opportunity.OwnerId,
      Opportunity.Name,
      Opportunity.Exclude_from_Territory_Realignment__c
    };
  }
  public Schema.SObjectType getSObjectType() {
    return Opportunity.sObjectType;
  }
  public List<Opportunity> selectOpenOppsById(Set<Id> oppIds) {
    return (List<Opportunity>) Database.query(
      newQueryFactory(false, false, true)
        .setCondition('Id =: oppIds and IsClosed = false')
        .selectField('Geo_Ops_Lock__c')
        .selectField('Account.RecordTypeId')
        .selectField('Owner_Sync_Status__c')
        .toSOQL()
    );
  }

  public List<Opportunity> selectOppById(Set<Id> oppIds) {
    return (List<Opportunity>) Database.query(
      newQueryFactory(false, false, true)
        .setCondition('Id =: oppIds')
        .selectField('Geo_Ops_Lock__c')
        .selectField('RecordType.DeveloperName')
        .selectField('Territory2Id')
        .selectField('AccountId')
        .selectField('IsClosed')
        .selectField('Territory_Geo__c')
        .selectField('Territory2.Name')
        .selectField('Territory2.DeveloperName')
        .selectField('Account.RecordType.DeveloperName')
        .toSOQL()
    );
  }

  public List<Opportunity> selectOpenOppsByAccountId(Set<Id> accountIds) {
    return (List<Opportunity>) Database.query(
      newQueryFactory(false, false, true)
        .setCondition('AccountId =: accountIds and IsClosed = false')
        .selectField('Territory2.Primary_Account_Manager_Id__c')
        .selectField('Territory2.Interim_Account_Manager_Id__c')
        .selectField('Territory2.Sales_Territory__c')
        .toSOQL()
    );
  }

  public List<Opportunity> selectOpportunitiesTobeRealigned(Set<Id> accountIds) {
    return (List<Opportunity>) Database.query(
      newQueryFactory(false, false, true)
        .setCondition(
          'AccountId =: accountIds and ((IsClosed = false and RecordType.Name != \'CPQ Locked\') OR (IsClosed = true and SBQQ__PrimaryQuote__r.SBQQ__BillingFrequency__c = \'Annual\'))'
        )
        .selectField('Territory2.Primary_Account_Manager_Id__c')
        .selectField('Territory2.Interim_Account_Manager_Id__c')
        .selectField('Territory2.Sales_Territory__c')
        .selectField('RecordType.Name')
        .toSOQL()
    );
  }

  public List<Opportunity> selectCompOpportunities(Set<Id> accountIds) {
    return (List<Opportunity>) Database.query(
      newQueryFactory(false, false, true)
        .setCondition('AccountId =: accountIds and (IsClosed = false )')
        .selectField('Territory2.Primary_Account_Manager_Id__c')
        .selectField('Territory2.Interim_Account_Manager_Id__c')
        .selectField('Territory2.Sales_Territory__c')
        .selectField('Territory2.Ultimate_Geo__c')
        .selectField('Territory2.Area__c')
        .selectField('Territory2.Region__c')
        .selectField('Account.RecordTypeId')
        .selectField('Is_Partner_Sourced__c')
        .selectField('BPO_MS_End_Customer__c')
        .selectField('BPO_MS_End_Customer__r.RecordTypeId')
        .toSOQL()
    );
  }
}