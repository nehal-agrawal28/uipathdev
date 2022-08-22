public without sharing class DealRegistrationsService_PP {
  public static final Id DRAFT_DEAL_REGISTRATION_RT = SObjectType.DealRegistration__c.getRecordTypeInfosByDeveloperName()
    .get('DraftDealRegistration')
    .getRecordTypeId();
  public static final Id SUBMITTED_DEAL_REGISTRATION_RT = SObjectType.DealRegistration__c.getRecordTypeInfosByDeveloperName()
    .get('SubmittedDealRegistration')
    .getRecordTypeId();

  private DealRegistrationProductsSelector_PP dealRegistrationProductsSelector {
    get {
      return (DealRegistrationProductsSelector_PP) Application_PP.Selector.newInstance(
        DealRegistrationProduct__c.SObjectType
      );
    }
    set;
  }

  private DealRegistrationsSelector_PP dealRegistrationsSelector {
    get {
      return (DealRegistrationsSelector_PP) Application_PP.Selector.newInstance(DealRegistration__c.SObjectType);
    }
    set;
  }

  public Id createDealRegWithProducts(DealRegistration__c dealReg, List<DealRegistrationProduct__c> dealRegProducts) {
    fflib_ISObjectUnitOfWork unitOfWork = Application_PP.UnitOfWork.newInstance();

    dealReg.SkipAmountValidation__c = true;
    unitOfWork.registerNew(dealReg);
    Decimal dealRegistrationAmount = 0;

    for (DealRegistrationProduct__c dealRegProduct : dealRegProducts) {
      dealRegistrationAmount += (dealRegProduct.UnitPrice__c * dealRegProduct.Quantity__c);
      unitOfWork.registerNew(dealRegProduct, DealRegistrationProduct__c.DealRegistration__c, dealReg);
    }

    dealReg.DealRegistrationAmount__c = dealRegistrationAmount;
    dealReg.RecordTypeId = DRAFT_DEAL_REGISTRATION_RT;

    unitOfWork.commitWork();

    fflib_ISObjectUnitOfWork unitOfWork2 = Application_PP.UnitOfWork.newInstance();

    dealReg.SkipAmountValidation__c = false;
    unitOfWork2.registerDirty(dealReg);
    unitOfWork2.commitWork();

    return dealReg.Id;
  }

  public void updateDealRegRecordType(DealRegistration__c dealReg, Id newRecordTypeId) {
    dealReg.RecordTypeId = newRecordTypeId;
    updateDealRegs(new List<DealRegistration__c>{ dealReg });
  }

  public Set<Id> getDealRegIdsWithProducts(Map<Id, DealRegistration__c> dealRegById) {
    List<DealRegistrationProduct__c> products = dealRegistrationProductsSelector.selectByDealRegistrationId(
      dealRegById.keySet(),
      false
    );
    Set<Id> dealRegIdsWithProducts = Utilities_PP.pluckIdField(
      products,
      DealRegistrationProduct__c.DealRegistration__c
    );

    return dealRegIdsWithProducts;
  }

  public void updateAmounts(Set<Id> dealRegids) {
    final Map<Id, DealRegistration__c> dealRegById = new Map<Id, DealRegistration__c>{};

    for (DealRegistration__c dealReg : dealRegistrationsSelector.selectById(dealRegids, false)) {
      dealReg.SkipAmountValidation__c = true;
      dealRegById.put(dealReg.Id, dealReg);
    }

    final Map<Id, List<DealRegistrationProduct__c>> dealRegProductsByDealRegId = new Map<Id, List<DealRegistrationProduct__c>>{};

    for (
      DealRegistrationProduct__c dealRegProduct : dealRegistrationProductsSelector.selectByDealRegistrationId(
        dealRegids,
        false
      )
    ) {
      if (dealRegProductsByDealRegId.containsKey(dealRegProduct.DealRegistration__c)) {
        dealRegProductsByDealRegId.get(dealRegProduct.DealRegistration__c).add(dealRegProduct);
      } else {
        dealRegProductsByDealRegId.put(
          dealRegProduct.DealRegistration__c,
          new List<DealRegistrationProduct__c>{ dealRegProduct }
        );
      }
    }

    Decimal tempAmount;
    for (Id dealRegId : dealRegById.keySet()) {
      tempAmount = 0;
      if (dealRegProductsByDealRegId.containsKey(dealRegId)) {
        for (DealRegistrationProduct__c dealRegProduct : dealRegProductsByDealRegId.get(dealRegId)) {
          tempAmount += (dealRegProduct.Quantity__c * dealRegProduct.UnitPrice__c);
        }
      }
      if (tempAmount == 0) {
        tempAmount = null;
      }
      dealRegById.get(dealRegId).DealRegistrationAmount__c = tempAmount;
    }

    updateDealRegs(dealRegById.values());

    List<DealRegistration__c> finishedDealRegs = dealRegById.values();
    for (DealRegistration__c dealReg : finishedDealRegs) {
      dealReg.SkipAmountValidation__c = false;
    }

    updateDealRegs(finishedDealRegs);
  }

  public void setErrorMessageOnAmount(DealRegistration__c dealReg) {
    dealReg.DealRegistrationAmount__c.addError(System.Label.Amount_Not_Editable_Error_Message);
  }

  public void setErrorMessageGeneral(DealRegistration__c dealReg, String errorMessage) {
    dealReg.addError(errorMessage);
  }

  private void updateDealRegs(List<DealRegistration__c> dealRegs) {
    fflib_ISObjectUnitOfWork unitOfWork = Application_PP.UnitOfWork.newInstance();

    unitOfWork.registerDirty(dealRegs);
    unitOfWork.commitWork();
  }

  public void createOpportunitiesFromDealRegistrations(List<DealRegistration__c> dealRegistrations) {
    Set<Id> dealRegistrationIds = new Set<Id>();
    Set<Id> dealRegistrationOwnerIds = new Set<Id>();
    for (DealRegistration__c dealRegistration : dealRegistrations) {
      dealRegistrationIds.add(dealRegistration.Id);
      dealRegistrationOwnerIds.add(dealRegistration.OwnerId);
    }

    DealRegistrationProductsService_PP dealRegistrationProductsService = (DealRegistrationProductsService_PP) Application_PP.Service.newInstance(
      DealRegistrationProductsService_PP.class
    );

    Map<Id, List<DealRegistrationProduct__c>> dealRegistrationProductsByDealRegistrationId = dealRegistrationProductsService.getDealRegistrationProductsByDealRegistrationId(
      dealRegistrationIds
    );

    Map<Id, Opportunity> opportunityByDealRegistration = createDealRegistrationOpportunity(
      dealRegistrations,
      dealRegistrationProductsByDealRegistrationId
    );

    OpportunityTeamMembersService_PP opportunityTeamMembersService = (OpportunityTeamMembersService_PP) Application_PP.Service.newInstance(
      OpportunityTeamMembersService_PP.class
    );

    opportunityTeamMembersService.createTeamMembers(
      opportunityByDealRegistration,
      new Map<Id, DealRegistration__c>(dealRegistrations)
    );

    UsersSelector_PP usersSelector = (UsersSelector_PP) Application_PP.Selector.newInstance(User.SObjectType);
    Map<Id, User> ownerById = new Map<Id, User>(usersSelector.selectById(dealRegistrationOwnerIds, false));

    PartnerInvolvementsService_PP partnerInvolvementsService = (PartnerInvolvementsService_PP) Application_PP.Service.newInstance(
      PartnerInvolvementsService_PP.class
    );

    partnerInvolvementsService.createPartnerInvolvements(
      opportunityByDealRegistration,
      new Map<Id, DealRegistration__c>(dealRegistrations),
      ownerById
    );
  }

  private Map<Id, Opportunity> createDealRegistrationOpportunity(
    List<DealRegistration__c> dealRegistrations,
    Map<Id, List<DealRegistrationProduct__c>> dealRegistrationProductsByDealRegistrationId
  ) {
    fflib_ISObjectUnitOfWork unitOfWork = Application_PP.UnitOfWork.newInstance();

    OpportunitiesService_PP opportunitiesService = (OpportunitiesService_PP) Application_PP.Service.newInstance(
      OpportunitiesService_PP.class
    );

    Map<Id, Opportunity> opportunityByDealRegistration = new Map<Id, Opportunity>();

    for (DealRegistration__c dealRegistration : dealRegistrations) {
      opportunityByDealRegistration.put(
        dealRegistration.Id,
        opportunitiesService.createOpportunityWithProducts(
          unitOfWork,
          dealRegistration,
          dealRegistrationProductsByDealRegistrationId.get(dealRegistration.Id)
        )
      );
    }

    unitOfWork.commitWork();

    return opportunityByDealRegistration;
  }

  public void shareDealRegistrationToPartners(List<DealRegistration__c> dealRegistrations) {
    // get account relationship by deal registration's account, distributor or tier 2 partner fields
    Set<String> relationshipTypes = new Set<String>{ 'distributor', 'var/reseller' };
    Set<Id> accountIds = new Set<Id>();

    List<DealRegistration__c> dealRegistrationsWithRelationships = new List<DealRegistration__c>();

    for (DealRegistration__c dealRegistration : dealRegistrations) {
      if (String.isNotBlank(dealRegistration.Distributor__c) && String.isNotBlank(dealRegistration.Tier2Partner__c)) {
        accountIds.add(dealRegistration.Distributor__c);
        accountIds.add(dealRegistration.Tier2Partner__c);
        dealRegistrationsWithRelationships.add(dealRegistration);
      } else if (String.isNotBlank(dealRegistration.Account__c) && String.isNotBlank(dealRegistration.Distributor__c)) {
        if (dealRegistration.Account__c != dealRegistration.Distributor__c) {
          accountIds.add(dealRegistration.Account__c);
          accountIds.add(dealRegistration.Distributor__c);
          dealRegistrationsWithRelationships.add(dealRegistration);
        }
      } else if (
        String.isNotBlank(dealRegistration.Account__c) && String.isNotBlank(dealRegistration.Tier2Partner__c)
      ) {
        if (dealRegistration.Account__c != dealRegistration.Tier2Partner__c) {
          accountIds.add(dealRegistration.Account__c);
          accountIds.add(dealRegistration.Tier2Partner__c);
          dealRegistrationsWithRelationships.add(dealRegistration);
        }
      }
    }

    System.debug('@@@ account Ids ' + accountIds);

    AccountRelationshipsSelector_PP accountRelationshipsSelector = (AccountRelationshipsSelector_PP) Application_PP.Selector.newInstance(
      AccountRelationship.SObjectType
    );

    List<AccountRelationship> relationships = accountRelationshipsSelector.selectByAccountIdsAndTypes(
      accountIds,
      relationshipTypes,
      false
    );

    // get the role names of these accounts only if they are related to each other per deal registration's fields
    Set<String> roleNames = new Set<String>();
    Map<Id, Set<String>> roleNamesByDealRegistrationId = new Map<Id, Set<String>>();

    for (DealRegistration__c dealRegistration : dealRegistrationsWithRelationships) {
      for (AccountRelationship relationship : relationships) {
        Id accountA;
        Id accountB;

        if (String.isNotBlank(dealRegistration.Distributor__c) && String.isNotBlank(dealRegistration.Tier2Partner__c)) {
          accountA = dealRegistration.Distributor__c;
          accountB = dealRegistration.Tier2Partner__c;
        } else if (
          String.isNotBlank(dealRegistration.Account__c) && String.isNotBlank(dealRegistration.Distributor__c)
        ) {
          if (dealRegistration.Account__c != dealRegistration.Distributor__c) {
            accountA = dealRegistration.Account__c;
            accountB = dealRegistration.Distributor__c;
          }
        } else if (
          String.isNotBlank(dealRegistration.Account__c) && String.isNotBlank(dealRegistration.Tier2Partner__c)
        ) {
          if (dealRegistration.Account__c != dealRegistration.Tier2Partner__c) {
            accountA = dealRegistration.Account__c;
            accountB = dealRegistration.Tier2Partner__c;
          }
        }

        if (String.isBlank(accountA) || String.isBlank(accountB))
          continue;

        // is the deal registration's account a and account b related?
        if (
          (relationship.AccountFromId == accountA && relationship.AccountToId == accountB) ||
          (relationship.AccountFromId == accountB &&
          relationship.AccountToId == accountA)
        ) {
          // yes, collect role names from account names
          String accountFromRoleName = relationship.AccountFrom.Name + ' Partner Manager';
          String accountToRoleName = relationship.AccountTo.Name + ' Partner Manager';

          roleNames.add(accountFromRoleName);
          roleNames.add(accountToRoleName);

          if (!roleNamesByDealRegistrationId.containsKey(dealRegistration.Id)) {
            roleNamesByDealRegistrationId.put(dealRegistration.Id, new Set<String>());
          }

          roleNamesByDealRegistrationId.get(dealRegistration.Id).add(accountFromRoleName);
          roleNamesByDealRegistrationId.get(dealRegistration.Id).add(accountToRoleName);

          // we collected the account, no need to continue looping relationships
          break;
        }
      }
    }

    System.debug('@@@ roleNames ' + roleNames);
    System.debug('@@@ roleNamesByDealRegistrationId ' + roleNamesByDealRegistrationId);

    UserRolesSelector_PP userRolesSelector = (UserRolesSelector_PP) Application_PP.Selector.newInstance(
      UserRole.SObjectType
    );

    Map<Id, UserRole> roleById = new Map<Id, UserRole>(userRolesSelector.selectByName(roleNames, false));

    System.debug('@@@ roleById ' + roleById);

    GroupsSelector_PP groupsSelector = (GroupsSelector_PP) Application_PP.Selector.newInstance(Group.SObjectType);

    Set<String> groupTypes = new Set<String>{ 'RoleAndSubordinates' };
    List<Group> groups = groupsSelector.selectByRelatedIdsAndTypes(roleById.keySet(), groupTypes, false);

    System.debug('@@@ groups ' + groups);

    // climb up the relationship to get the deal registration back
    Map<Id, Set<Id>> groupIdsByDealRegistrationId = new Map<Id, Set<Id>>();

    for (Group roleGroup : groups) {
      UserRole role = roleById.get(roleGroup.RelatedId);

      for (Id dealRegistrationId : roleNamesByDealRegistrationId.keySet()) {
        if (roleNamesByDealRegistrationId.get(dealRegistrationId).contains(role.Name)) {
          if (!groupIdsByDealRegistrationId.containsKey(dealRegistrationId)) {
            groupIdsByDealRegistrationId.put(dealRegistrationId, new Set<Id>());
          }

          groupIdsByDealRegistrationId.get(dealRegistrationId).add(roleGroup.Id);
        }
      }
    }

    System.debug('@@@ groupIdsByDealRegistrationId ' + groupIdsByDealRegistrationId);

    shareDealRegistrationToGroups(groupIdsByDealRegistrationId);
  }

  public void shareDealRegistrationToGroups(Map<Id, Set<Id>> groupIdsByDealRegistrationId) {
    List<DealRegistration__Share> shares = new List<DealRegistration__Share>();

    for (Id dealRegistrationId : groupIdsByDealRegistrationId.keySet()) {
      for (Id groupId : groupIdsByDealRegistrationId.get(dealRegistrationId)) {
        shares.add(
          new DealRegistration__Share(ParentId = dealRegistrationId, UserOrGroupId = groupId, AccessLevel = 'Edit')
        );
      }
    }

    // check docs see if some errors are due to access level because of object's default
    // @see https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_bulk_sharing_creating_with_apex.htm
    List<Database.SaveResult> results = Database.insert(shares, false);

    // @TODO remove
    for (Database.SaveResult result : results) {
      System.debug('@@@ Result: ' + result);
    }
  }
}