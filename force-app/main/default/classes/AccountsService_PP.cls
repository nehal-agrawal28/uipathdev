public without sharing class AccountsService_PP {
  public static final Id PARTNER_RT = SObjectType.Account.getRecordTypeInfosByDeveloperName()
    .get('Partner')
    .getrecordTypeId();

  public Set<Id> getAccountIdsForSelfReg(Contact contact, String email) {
    final Set<Id> accountIds = new Set<Id>{};
    final String emailDomain = Utilities_PP.getDomainFromEmail(email);
    final AccountRelatedEmailDomainsSelector_PP accountRelatedEmailDomainsSelector = (AccountRelatedEmailDomainsSelector_PP) Application_PP.Selector.newInstance(
      AccountRelatedEmailDomain__c.SObjectType
    );

    for (
      AccountRelatedEmailDomain__c accountRelatedEmailDomain : accountRelatedEmailDomainsSelector.selectBySelfRegCriterias(
        new Set<String>{ emailDomain },
        false
      )
    ) {
      if (contact != null) {
        if (contact.AccountId.equals(accountRelatedEmailDomain.Account__c)) {
          accountIds.add(accountRelatedEmailDomain.Account__c);
          break;
        }
      } else {
        accountIds.add(accountRelatedEmailDomain.Account__c);
      }
    }
    return accountIds;
  }

  public void setRelationshipOnAccount(List<AccountRelationship> records) {
    Map<Id, Set<Id>> resellersByDistributor = new Map<Id, Set<Id>>();
    for (AccountRelationship relationship : records) {
      if (relationship.type == 'var/reseller') {
        if (!resellersByDistributor.containsKey(relationship.AccountToId)) {
          resellersByDistributor.put(relationship.AccountToId, new Set<Id>());
        }
        resellersByDistributor.get(relationship.AccountToId).add(relationship.AccountFromId);
      }
    }

    Set<Id> allResellerIds = new Set<Id>();

    for (Set<Id> idSet : resellersByDistributor.values()) {
      allResellerIds.addAll(idSet);
    }

    AccountsSelector_PP accountsSelector = (AccountsSelector_PP) Application_PP.Selector.newInstance(
      Account.SObjectType
    );
    Map<Id, Account> distributors = new Map<Id, Account>(
      accountsSelector.selectById(resellersByDistributor.keySet(), false)
    );
    Map<Id, Account> resellers = new Map<Id, Account>(accountsSelector.selectById(allResellerIds, false));
    Map<Id, Set<String>> distributorTypesByResellerId = new Map<Id, Set<String>>();

    List<Account> result = new List<Account>();

    for (Account distributor : distributors.values()) {
      String distributorType = (distributor.Regional_Business_Partner_Type__c == 'Federal Partners')
        ? 'Public Sector'
        : 'Commercial';
      Set<Id> resellerIds = resellersByDistributor.get(distributor.Id);
      for (Id resellerId : resellerIds) {
        if (!distributorTypesByResellerId.containsKey(resellerId)) {
          distributorTypesByResellerId.put(resellerId, new Set<String>());
        }
        distributorTypesByResellerId.get(resellerId).add(distributorType);
      }
    }

    for (Account reseller : resellers.values()) {
      Set<String> distributionRelation = new Set<String>();
      if (String.isNotBlank(reseller.DistributionRelationship__c))
        distributionRelation.addAll(reseller.DistributionRelationship__c.split(';'));
      distributionRelation.addAll(distributorTypesByResellerId.get(reseller.Id));
      Account updatedAccount = new Account();
      updatedAccount.Id = reseller.Id;
      updatedAccount.DistributionRelationship__c = String.join(new List<String>(distributionRelation), ';');
      result.add(updatedAccount);
    }

    update result;
  }

  public Set<Id> getDistributorOrResellerAccountIds(Id partnerUserId) {
    Set<Id> distributorOrResellerAccountIds = new Set<Id>();

    UsersSelector_PP usersSelector = (UsersSelector_PP) Application_PP.Selector.newInstance(User.SObjectType);
    List<User> partnerUsers = usersSelector.selectById(new Set<Id>{ partnerUserId }, false);

    if (
      partnerUsers.isEmpty() ||
      String.isBlank(partnerUsers.get(0).Contact_Account_Id__c) ||
      String.isBlank(partnerUsers.get(0).ContactAccountBusinessPartnerType__c)
    ) {
      return distributorOrResellerAccountIds;
    }

    // NOTE: Account.Business_Partner_Type__c: 'VAR' is reseller, 'Distributor' is distributor
    // NOTE: AccountRelationship.Type: 'VAR/Reseller' is reseller, 'Distributor' is distributor
    // if partner user is distributor, look for reseller accounts
    String accountRelationshipType = '';

    if (partnerUsers.get(0).ContactAccountBusinessPartnerType__c == 'Distributor') {
      accountRelationshipType = 'VAR/Reseller';
    } else if (
      partnerUsers.get(0).ContactAccountBusinessPartnerType__c == 'VAR' ||
      partnerUsers.get(0).ContactAccountBusinessPartnerType__c == 'GSI' ||
      partnerUsers.get(0).ContactAccountBusinessPartnerType__c == 'LSP'
    ) {
      accountRelationshipType = 'Distributor';
    }

    if (String.isBlank(accountRelationshipType))
      return distributorOrResellerAccountIds;

    AccountRelationshipsSelector_PP selector = (AccountRelationshipsSelector_PP) Application_PP.Selector.newInstance(
      AccountRelationship.SObjectType
    );

    List<AccountRelationship> relationships = selector.selectByAccountToIdsAndTypes(
      new Set<Id>{ partnerUsers.get(0).Contact_Account_Id__c },
      new Set<String>{ accountRelationshipType },
      false
    );

    for (AccountRelationship relationship : relationships) {
      distributorOrResellerAccountIds.add(relationship.AccountFromId);
    }

    return distributorOrResellerAccountIds;
  }

  public void shareToPartners(List<AccountRelationship> accountRelationships) {
    // re-query account relationships because it doesn't include account name from trigger
    Set<Id> accountRelationshipIds = new Set<Id>();

    for (AccountRelationship accountRelationship : accountRelationships) {
      accountRelationshipIds.add(accountRelationship.Id);
    }

    System.debug('@@@ accountRelationshipIds ' + accountRelationshipIds);

    AccountRelationshipsSelector_PP accountRelationshipsSelector = (AccountRelationshipsSelector_PP) Application_PP.Selector.newInstance(
      AccountRelationship.SObjectType
    );

    List<AccountRelationship> relationships = accountRelationshipsSelector.selectByIds(accountRelationshipIds, false);

    System.debug('@@@ relationships ' + relationships);

    Set<String> roleNames = new Set<String>();
    Map<Id, Set<String>> roleNamesByAccountId = new Map<Id, Set<String>>();
    for (AccountRelationship relationship : relationships) {
      if (relationship.AccountFromId == relationship.AccountToId)
        continue;

      String accountFromRoleName = relationship.AccountFrom.Name + ' Partner Manager';
      String accountToRoleName = relationship.AccountTo.Name + ' Partner Manager';

      roleNames.add(accountFromRoleName);
      roleNames.add(accountToRoleName);

      // add from
      if (!roleNamesByAccountId.containsKey(relationship.AccountFromId)) {
        roleNamesByAccountId.put(relationship.AccountFromId, new Set<String>());
      }

      roleNamesByAccountId.get(relationship.AccountFromId).add(accountToRoleName);

      // add to
      if (!roleNamesByAccountId.containsKey(relationship.AccountToId)) {
        roleNamesByAccountId.put(relationship.AccountToId, new Set<String>());
      }

      roleNamesByAccountId.get(relationship.AccountToId).add(accountFromRoleName);
    }

    System.debug('@@@ roleNames ' + roleNames);
    System.debug('@@@ roleNamesByAccountId ' + roleNamesByAccountId);

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
    Map<Id, Set<Id>> groupIdsByAccountId = new Map<Id, Set<Id>>();

    for (Group roleGroup : groups) {
      UserRole role = roleById.get(roleGroup.RelatedId);

      for (Id accountId : roleNamesByAccountId.keySet()) {
        if (roleNamesByAccountId.get(accountId).contains(role.Name)) {
          if (!groupIdsByAccountId.containsKey(accountId)) {
            groupIdsByAccountId.put(accountId, new Set<Id>());
          }

          groupIdsByAccountId.get(accountId).add(roleGroup.Id);
        }
      }
    }

    System.debug('@@@ groupIdsByAccountId ' + groupIdsByAccountId);

    shareToGroups(groupIdsByAccountId);
  }

  public void shareToGroups(Map<Id, Set<Id>> groupIdsByAccountId) {
    // account share has more fields than other share objects
    // @see https://developer.salesforce.com/docs/atlas.en-us.230.0.object_reference.meta/object_reference/sforce_api_objects_accountshare.htm
    List<AccountShare> shares = new List<AccountShare>();

    for (Id accountId : groupIdsByAccountId.keySet()) {
      for (Id groupId : groupIdsByAccountId.get(accountId)) {
        shares.add(
          new AccountShare(
            AccountId = accountId,
            UserOrGroupId = groupId,
            AccountAccessLevel = 'Edit',
            CaseAccessLevel = 'None',
            //ContactAccessLevel = 'None',
            OpportunityAccessLevel = 'None'
          )
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

  public void setPartnerContributingStatusToActiveAfterOneYear(List<Account> accounts) {
    setPartnerContributingStatusToActiveAfterOneYear(Accounts_PP.newInstance(accounts));
  }

  public void setPartnerContributingStatusToActiveAfterOneYear(Accounts_PP accounts) {
    fflib_ISObjectUnitOfWork unitOfWork = Application_PP.UnitOfWork.newInstance();
    setPartnerContributingStatusToActiveAfterOneYear(unitOfWork, accounts);
    unitOfWork.commitWork();
  }

  public void setPartnerContributingStatusToActiveAfterOneYear(
    fflib_ISObjectUnitOfWork unitOfWork,
    Accounts_PP accounts
  ) {
    Accounts_PP scope = accounts.selectByBuysThroughDistributor().selectByDateJoinedProgramOlderThanYears(1);

    if (scope.isEmpty())
      return;

    scope.setPartnerContributingStatus('Active');

    unitOfWork.registerDirty(scope.getRecords());
  }

  public static void updateAccountRtypeANDPaf(Set<Id> accIds, Id recordTypeId, Id pafId) {
    fflib_ISObjectUnitOfWork uow = Application_PP.UnitOfWork.newInstance();
    AccountsSelector_PP accSelector = (AccountsSelector_PP) Application_PP.Selector.newInstance(Account.SObjectType);
    uow.registerDirty(
      AccountsService_PP.updateAccountRtypeANDPaf(accSelector.selectById(accIds, false), recordTypeId, pafId)
    );
    uow.commitWork();
  }

  public static List<Account> updateAccountRtypeANDPaf(List<Account> accs, Id recordTypeId, Id pafId) {
    Accounts_PP accDomain = (Accounts_PP) Application_PP.Domain.newInstance(accs, Account.SObjectType);
    return accDomain.setAccountRtype(recordTypeId).setAccountPartnerApplicationForm(pafId).getRecords();
  }
}