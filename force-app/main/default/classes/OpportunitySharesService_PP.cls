public without sharing class OpportunitySharesService_PP {
  public void createOpportunityShares(List<User> records) {
    Users_PP usersDomain = (Users_PP) Application_PP.Domain.newInstance(records, User.SObjectType);

    Set<Id> accountIds = usersDomain.getAccountIds();
    OpportunitiesSelector_PP opportunitiesSelector = (OpportunitiesSelector_PP) Application_PP.Selector.newInstance(
      Opportunity.SObjectType
    );
    List<Opportunity> opportunitiesToShare = opportunitiesSelector.selectByAccountId(accountIds, false);
    List<Opportunity> withSoldToPartners = getDomain(opportunitiesToShare).selectWithSoldToPartner().getOpportunities();
    Map<Id, Set<Id>> opportunitiesByAccountId = getDomain(opportunitiesToShare).getOpportunityIdsByAccountId();
    Map<Id, Set<Id>> opportunitiesBySoldToPartner = getDomain(withSoldToPartners).getOpportunityIdsBySoldToPartnerId();
    List<OpportunityShare> opportunitySharesRecords = new List<OpportunityShare>();
    opportunitySharesRecords = createOpportunityShares(usersDomain.getRecords(), opportunitiesByAccountId);
    opportunitySharesRecords.addAll(createOpportunityShares(usersDomain.getRecords(), opportunitiesBySoldToPartner));

    List<Database.SaveResult> results = Database.insert(opportunitySharesRecords, false);
  }

  public List<OpportunityShare> createOpportunityShares(List<User> users, Map<Id, Set<Id>> opportunitiesByAccountId) {
    List<OpportunityShare> opportunitySharesRecords = new List<OpportunityShare>();
    Map<String, OpportunityShare> opportunityShareMap = new Map<String, OpportunityShare>();
    for (User record : users) {
      if (opportunitiesByAccountId.containsKey(record.AccountId)) {
        Set<Id> opportunityIds = opportunitiesByAccountId.get(record.AccountId);
        constructOpportunityShareRecord(opportunityIds, record.Id, opportunityShareMap);
      }
    }
    opportunitySharesRecords.addAll(opportunityShareMap.values());
    return opportunitySharesRecords;
  }

  private Opportunities_PP getDomain(List<Opportunity> opportunities) {
    Opportunities_PP domain = (Opportunities_PP) Application_PP.Domain.newInstance(
      opportunities,
      Opportunity.SObjectType
    );
    return domain;
  }

  private Map<String, OpportunityShare> constructOpportunityShareRecord(
    Set<Id> opportunityIds,
    Id userId,
    Map<String, OpportunityShare> opportunityShareMap
  ) {
    for (Id opportunityId : opportunityIds) {
      OpportunityShare record = new OpportunityShare();
      record.OpportunityId = opportunityId;
      record.UserOrGroupId = userId;
      record.RowCause = 'Edit';
      opportunityShareMap.put(String.valueOf(opportunityId) + String.valueOf(userId), record);
    }
    return opportunityShareMap;
  }
}