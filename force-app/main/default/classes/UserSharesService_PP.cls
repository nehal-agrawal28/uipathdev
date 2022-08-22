public without sharing class UserSharesService_PP {
  public void sharePartnerUsers(List<User> distributorUsers) {
    Map<Id, Set<Id>> distributorUserIdsByAccountId = buildDistributorUserIdsByAccountId(distributorUsers);

    Set<Id> accountIds = distributorUserIdsByAccountId.keySet();

    OpportunitiesSelector_PP opportunitiesSelector = (OpportunitiesSelector_PP) Application_PP.Selector.newInstance(
      Opportunity.SObjectType
    );

    List<Opportunity> opportunities = opportunitiesSelector.selectBySoldToPartnersOrTier2Partners(accountIds);

    Map<Id, Set<Id>> relatedUserIdsToAccountId = buildRelatedUserIdsToAccountId(opportunities);

    Set<Id> dealHubUserIds = buildDealHubUserIds();

    Map<Id, Set<Id>> relatedUserIdsToDistributorUserId = new Map<Id, Set<Id>>();

    for (Id accountId : accountIds) {
      Set<Id> relatedUserIds = new Set<Id>();
      if (relatedUserIdsToAccountId.get(accountId) != null) {
        relatedUserIds.addAll(relatedUserIdsToAccountId.get(accountId));
      }

      for (Id distributorUserId : distributorUserIdsByAccountId.get(accountId)) {
        if (!relatedUserIdsToDistributorUserId.containsKey(distributorUserId)) {
          relatedUserIdsToDistributorUserId.put(distributorUserId, new Set<Id>());
        }

        // @TODO should I loop these so there is no dupe?
        relatedUserIdsToDistributorUserId.get(distributorUserId).addAll(dealHubUserIds);
        if (relatedUserIds.isEmpty())
          continue;
        relatedUserIdsToDistributorUserId.get(distributorUserId).addAll(relatedUserIds);
      }
    }

    List<UserShare> shares = new List<UserShare>();

    for (Id distributorUserId : relatedUserIdsToDistributorUserId.keySet()) {
      for (Id relatedUserId : relatedUserIdsToDistributorUserId.get(distributorUserId)) {
        //relating to self throws INSUFFICIENT_ACCESS_ON_CROSS_REFERENCE_ENTITY
        if (distributorUserId == relatedUserId)
          continue;

        shares.add(new UserShare(UserId = relatedUserId, UserOrGroupId = distributorUserId, UserAccessLevel = 'Read'));
      }
    }

    shares.addAll(createSharesForApprovalChain(distributorUsers));

    insert shares;
  }

  private List<UserShare> createSharesForApprovalChain(List<User> distributorUsers) {
    List<UserShare> result = new List<UserShare>();
    Set<Id> userIds = getUserIdsFromApprovalChain();
    if (userIds.isEmpty())
      return result;

    for (User distributorUser : distributorUsers) {
      for (Id userId : userIds) {
        result.add(new UserShare(UserId = userId, UserOrGroupId = distributorUser.Id, UserAccessLevel = 'Read'));
      }
    }
    return result;
  }

  private Set<Id> getUserIdsFromApprovalChain() {
    Set<Id> result = new Set<Id>();

    IApprovalChains_PP approvalChains = ApprovalChains_PP.newInstance(
        ApprovalChainsSelector_PP.newWithoutSharingInstance().selectAll()
      )
      .selectNonJapan();
    if (approvalChains.isEmpty())
      return result;

    Set<Id> approverIds = ApprovalRules_PP.newInstance(
        ApprovalRulesSelector_PP.newWithoutSharingInstance().selectByChainId(approvalChains.getRecordIds())
      )
      .getApproverIds();
    if (approverIds.isEmpty())
      return result;

    // Add all the sbaa__Approver__c.sbaa__User__c user Ids
    IApprovers_PP approvers = Approvers_PP.newInstance(
      ApproversSelector_PP.newWithoutSharingInstance().selectById(approverIds)
    );
    result.addAll(approvers.getUserIds());

    // Add all the users which are member of the sbaa__Approver__c.sbaa__GroupId__c
    Set<Id> groupIds = approvers.getGroupIds();
    if (groupIds.isEmpty() == false) {
      GroupMembers_PP groupMembers = GroupMembers_PP.newInstance(
        GroupMembersSelector_PP.newInstance().selectById(groupIds)
      );
      result.addAll(groupMembers.getUserIds());
    }

    return result;
  }

  private Map<Id, Set<Id>> buildDistributorUserIdsByAccountId(List<User> users) {
    Map<Id, Set<Id>> distributorUserIdsByAccountId = new Map<Id, Set<Id>>();

    for (User user : users) {
      if (!distributorUserIdsByAccountId.containsKey(user.Contact_Account_Id__c)) {
        distributorUserIdsByAccountId.put(user.Contact_Account_Id__c, new Set<Id>());
      }

      distributorUserIdsByAccountId.get(user.Contact_Account_Id__c).add(user.Id);
    }

    return distributorUserIdsByAccountId;
  }

  private Map<Id, Set<Id>> buildRelatedUserIdsToAccountId(List<Opportunity> opportunities) {
    Map<Id, Set<Id>> relatedUserIdsToAccountId = new Map<Id, Set<Id>>();

    for (Opportunity opportunity : opportunities) {
      Id accountId;

      if (opportunity.Sold_to_Partner__r.Business_Partner_Type__c == 'Distributor') {
        accountId = opportunity.Sold_to_Partner__c;
      } else if (opportunity.Tier_2_Partner__r.Business_Partner_Type__c == 'Distributor') {
        accountId = opportunity.Tier_2_Partner__c;
      } else {
        // this opportunity is not mapped to distributor
        continue;
      }

      if (!relatedUserIdsToAccountId.containsKey(accountId)) {
        relatedUserIdsToAccountId.put(accountId, new Set<Id>());
      }

      for (OpportunityTeamMember member : opportunity.OpportunityTeamMembers) {
        relatedUserIdsToAccountId.get(accountId).add(member.UserId);
      }

      for (SBQQ__Quote__c quote : opportunity.SBQQ__Quotes2__r) {
        if (quote.X1st_Level_Approver__c != null) {
          relatedUserIdsToAccountId.get(accountId).add(quote.X1st_Level_Approver__c);
        }
        if (quote.Managing_Director__c != null) {
          relatedUserIdsToAccountId.get(accountId).add(quote.Managing_Director__c);
        }
        if (quote.Regional_Commercial_Finance_Leader__c != null) {
          relatedUserIdsToAccountId.get(accountId).add(quote.Regional_Commercial_Finance_Leader__c);
        }
        if (quote.Sales_Rep_s_Manager__c != null) {
          relatedUserIdsToAccountId.get(accountId).add(quote.Sales_Rep_s_Manager__c);
        }
        if (quote.Finance_Lead_Approver__c != null) {
          relatedUserIdsToAccountId.get(accountId).add(quote.Finance_Lead_Approver__c);
        }
        if (quote.Geo_Partner_VP__c != null) {
          relatedUserIdsToAccountId.get(accountId).add(quote.Geo_Partner_VP__c);
        }
      }

      relatedUserIdsToAccountId.get(accountId).add(opportunity.OwnerId);
    }

    return relatedUserIdsToAccountId;
  }

  private Set<Id> buildDealHubUserIds() {
    // @TODO check if null?
    Users_PP__c dealHub = Users_PP__c.getOrgDefaults();

    Set<String> uniqueUsernames = new Set<String>();

    for (String username : dealHub.Usernames__c.split('\n')) {
      uniqueUsernames.add(username.toLowerCase().trim());
    }

    UsersSelector_PP selector = (UsersSelector_PP) Application_PP.Selector.newInstance(User.SObjectType);

    List<User> dealHubUsers = selector.selectByUsernames(uniqueUsernames, false);

    Set<Id> dealHubUserIds = new Set<Id>();

    for (User dealHubUser : dealHubUsers) {
      dealHubUserIds.add(dealHubUser.Id);
    }

    return dealHubUserIds;
  }
}