public without sharing class OpportunitiesSelector_PP extends fflib_SObjectSelector {
  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField>{
      Opportunity.Id,
      Opportunity.AccountId,
      Opportunity.Deal_Type__c,
      Opportunity.Sold_to_Partner__c,
      Opportunity.Tier_2_Partner__c,
      Opportunity.OwnerId
    };
  }

  public Schema.SObjectType getSObjectType() {
    return Opportunity.sObjectType;
  }

  public List<Opportunity> selectByAccountId(Set<Id> ids, Boolean withSharing) {
    if (withSharing)
      return (List<Opportunity>) Database.query(newQueryFactory().setCondition('AccountId IN :ids').toSOQL());
    else
      return (List<Opportunity>) Database.query(
        newQueryFactory(false, false, true).setCondition('AccountId IN :ids').toSOQL()
      );
  }

  public List<Opportunity> selectById(Set<Id> ids, Boolean withSharing) {
    if (withSharing)
      return (List<Opportunity>) selectSObjectsById(ids);
    else
      return (List<Opportunity>) Database.query(
        newQueryFactory(false, false, true).setCondition('Id IN :ids').toSOQL()
      );
  }

  public List<Opportunity> selectBySoldToPartnersOrTier2Partners(Set<Id> accountIds) {
    return [
      SELECT
        Id,
        Name,
        Sold_to_Partner__r.Name,
        Sold_to_Partner__r.Business_Partner_Type__c,
        Tier_2_Partner__r.Name,
        Tier_2_Partner__r.Business_Partner_Type__c,
        OwnerId,
        (SELECT Name, UserId FROM OpportunityTeamMembers),
        (
          SELECT
            X1st_Level_Approver__c,
            Managing_Director__c,
            Sales_Rep_s_Manager__c,
            Finance_Lead_Approver__c,
            Regional_Commercial_Finance_Leader__c,
            Geo_Partner_VP__c
          FROM SBQQ__Quotes2__r
        )
      FROM Opportunity
      WHERE
        (Sold_to_Partner__c IN :accountIds
        OR Tier_2_Partner__c IN :accountIds)
        AND Sold_to_Partner__c != NULL
        AND Tier_2_Partner__c != NULL
        AND LastModifiedDate = LAST_N_DAYS:10
      ORDER BY Sold_to_Partner__c ASC, Tier_2_Partner__c ASC
    ];
  }

  public Database.QueryLocator queryLocatorWithSoldToAndTier2ByCreatedDate(Date createdDate) {
    return Database.getQueryLocator(
      newQueryFactory()
        .setCondition('Sold_to_Partner__c <> NULL AND Tier_2_Partner__c <> NULL AND CreatedDate >= :createdDate')
        .toSOQL()
    );
  }

  public Database.QueryLocator queryLocatorRenewalsForIngram() {
    return Database.getQueryLocator(
      newQueryFactory()
        .setCondition(
          'Sold_to_Partner__r.Partner_Reporting_Name__c = \'Ingram Micro\' AND Opportunity_Type__c = \'Renewal\''
        )
        .toSOQL()
    );
  }

  public Database.QueryLocator queryLocatorOpenResaleWithSoldToPartner() {
    return Database.getQueryLocator(
      newQueryFactory()
        .setCondition(
          'Sold_to_Partner__c <> NULL AND Deal_Type__c = \'Resale\' AND StageName IN (\'Deal Registration\', \'Discovery\') AND Sold_to_Partner__r.Partner_Buys_Through_Disti__c = true'
        )
        .toSOQL()
    );
  }
}