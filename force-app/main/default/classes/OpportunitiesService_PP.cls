public without sharing class OpportunitiesService_PP {
  public static final Id DEAL_REGISTRATION_RT = SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
    .get('Deal_Registration')
    .getRecordTypeId();

  public static final String SHARE_OPPORTUNITY_TO_PARTNER_ACCESS_LEVEL = 'Edit';

  public Opportunity createOpportunityWithProducts(
    DealRegistration__c dealReg,
    List<DealRegistrationProduct__c> dealRegProducts
  ) {
    fflib_ISObjectUnitOfWork unitOfWork = Application_PP.UnitOfWork.newInstance();

    Opportunity opportunity = createOpportunityWithProducts(unitOfWork, dealReg, dealRegProducts);

    unitOfWork.commitWork();

    return opportunity;
  }

  public Opportunity createOpportunityWithProducts(
    fflib_ISObjectUnitOfWork unitOfWork,
    DealRegistration__c dealReg,
    List<DealRegistrationProduct__c> dealRegProducts
  ) {
    final UsersSelector_PP usersSelector = (UsersSelector_PP) Application_PP.Selector.newInstance(User.SObjectType);
    final User partnerUser = usersSelector.selectById(new Set<Id>{ UserInfo.getUserId() }, false)[0];

    final AccountsSelector_PP accountsSelector = (AccountsSelector_PP) Application_PP.Selector.newInstance(
      Account.SObjectType
    );
    final Account dealRegPartnerAccount = accountsSelector.selectByName(
      new Set<String>{ System.Label.Deal_Reg_Partner_Account_Name },
      false
    )[0];

    Opportunity opportunity = new Opportunity(
      AccountId = dealRegPartnerAccount.Id,
      Account_City__c = dealReg.City__c,
      Account_Country__c = dealReg.Country__c,
      Account_Name__c = dealReg.EndCustomerAccountName__c,
      Amount = dealReg.DealRegistrationAmount__c,
      CloseDate = dealReg.CloseDate__c,
      Competition__c = dealReg.Competition__c,
      CurrencyIsoCode = dealReg.CurrencyIsoCode,
      DealRegEndCustomerWebsite__c = dealReg.EndCustomerWebsite__c,
      Deal_Reg_Notes_Comments__c = dealReg.DealRegNotesComments__c,
      Deal_Reg_Partner_SFDC_Id__c = partnerUser.Contact_Account_Id__c,
      Deal_Registration_System__c = 'Community',
      Deal_Type__c = dealReg.DealType__c,
      LeadSource = 'Partner',
      Partner_Lead_Source__c = dealReg.PartnerLeadSource__c,
      Name = dealReg.Name,
      OwnerId = (dealReg.dealType__c == 'BPO' &&
        dealRegPartnerAccount.KAM_Id__c != null)
        ? dealRegPartnerAccount.KAM_Id__c
        : dealRegPartnerAccount.OwnerId,
      Partner_Sales_Email__c = dealReg.PartnerCompanySalesEmail__c,
      Partner_Sales_Phone__c = dealReg.PartnerCompanySalesPhone__c,
      Partner_Sales_Rep__c = dealReg.PartnerCompanySalesRep__c,
      Pricebook2Id = dealReg.PriceBook__c,
      Probability = 0,
      RecordTypeId = DEAL_REGISTRATION_RT,
      StageName = 'Deal Registration'
    );

    if (dealReg.DealType__c == 'Partner Internal Infrastructure' || dealReg.DealType__c == 'NFR') {
      opportunity.Deal_Reg_Status__c = 'Created';
    }

    if (
      dealReg.DealType__c == 'Partner Internal Infrastructure' ||
      dealReg.DealType__c == 'NFR' ||
      dealReg.DealType__c == 'BPO' ||
      dealReg.DealType__c == 'Managed Services'
    ) {
      opportunity.AccountId = dealReg.Tier2Partner__c;
    }

    linkOpportunityToCampaign(opportunity, dealReg);

    if (dealReg.DealType__c == 'Partner Internal Infrastructure' || dealReg.DealType__c == 'NFR') {
      opportunity.Deal_Reg_Status__c = 'Submitted';
    }

    unitOfWork.registerNew(opportunity);

    if (dealRegProducts != null && !dealRegProducts.isEmpty()) {
      for (DealRegistrationProduct__c dealRegProduct : dealRegProducts) {
        unitOfWork.registerNew(
          new OpportunityLineItem(
            PricebookEntryId = dealRegProduct.PricebookEntryId__c,
            Quantity = dealRegProduct.Quantity__c,
            UnitPrice = dealRegProduct.UnitPrice__c
          ),
          OpportunityLineItem.OpportunityId,
          opportunity
        );
      }
    }

    unitOfWork.registerDirty(dealReg, DealRegistration__c.Opportunity__c, opportunity);

    return opportunity;
  }

  public void notifyDealRegistrationApproval(List<Opportunity> opportunities) {
    OrgWideEmailAddressesSelector_PP orgWideEmailAddressesSelector = (OrgWideEmailAddressesSelector_PP) Application_PP.Selector.newInstance(
      OrgWideEmailAddress.SObjectType
    );

    List<OrgWideEmailAddress> orgEmails = orgWideEmailAddressesSelector.selectByAddresses(
      new Set<String>{ 'partners@uipath.com' },
      false
    );

    Id orgEmailId = orgEmails.isEmpty() ? null : orgEmails.get(0).Id;

    EmailTemplatesSelector_PP emailTemplatesSelector = (EmailTemplatesSelector_PP) Application_PP.Selector.newInstance(
      EmailTemplate.SObjectType
    );

    List<EmailTemplate> emailTemplates = emailTemplatesSelector.selectByDeveloperNames(
      new Set<String>{ 'Deal_Registration_Approved2' },
      false
    );

    if (emailTemplates.isEmpty())
      return;

    Id emailTemplateId = emailTemplates.get(0).Id;

    Map<Id, Set<String>> emailsByAccountId = getEmailsByAccountId(opportunities);

    List<Messaging.SingleEmailMessage> messages = new List<Messaging.SingleEmailMessage>();

    for (Opportunity opportunity : opportunities) {
      if (opportunity.Deal_Reg_Status__c != 'Approved')
        continue;

      Set<String> emails = buildRecipients(opportunity, emailsByAccountId);

      if (emails.isEmpty())
        continue;

      Messaging.SingleEmailMessage message = Messaging.renderStoredEmailTemplate(
        emailTemplateId,
        opportunity.OwnerId,
        opportunity.Id
      );

      message.setSaveAsActivity(false);
      message.setToAddresses(new List<String>(emails));

      if (String.isNotBlank(orgEmailId)) {
        message.setOrgWideEmailAddressId(orgEmailId);
      }

      messages.add(message);
    }

    if (messages.isEmpty())
      return;

    List<Messaging.SendEmailResult> results = Messaging.sendEmail(messages);
  }

  private Map<Id, Set<String>> getEmailsByAccountId(List<Opportunity> opportunities) {
    Set<Id> accountIds = new Set<Id>();
    Set<String> types = new Set<String>{ 'Deal Registration Approved' };

    for (Opportunity opportunity : opportunities) {
      if (opportunity.Sold_to_Partner__c != null)
        accountIds.add(opportunity.Sold_to_Partner__c);

      if (opportunity.Tier_2_Partner__c != null)
        accountIds.add(opportunity.Tier_2_Partner__c);
    }

    GenericNotificationsSelector_PP selector = (GenericNotificationsSelector_PP) Application_PP.Selector.newInstance(
      GenericNotification_PP__c.SObjectType
    );

    List<GenericNotification_PP__c> records = selector.selectByAccountIdsAndTypes(accountIds, types, false);

    Map<Id, Set<String>> emailsByAccountId = new Map<Id, Set<String>>();

    for (GenericNotification_PP__c record : records) {
      if (!emailsByAccountId.containsKey(record.Account__c)) {
        emailsByAccountId.put(record.Account__c, new Set<String>());
      }

      if (String.isNotBlank(record.Email__c)) {
        emailsByAccountId.get(record.Account__c).add(record.Email__c);
      }
    }

    return emailsByAccountId;
  }

  private Set<String> buildRecipients(Opportunity opportunity, Map<Id, Set<String>> emailsByAccountId) {
    Set<String> recipients = new Set<String>();

    if (
      String.isNotBlank(opportunity.Sold_to_Partner__c) && emailsByAccountId.containsKey(opportunity.Sold_to_Partner__c)
    ) {
      for (String email : emailsByAccountId.get(opportunity.Sold_to_Partner__c)) {
        if (String.isNotBlank(email)) {
          // string set is case sensitive, transform to lowercase to avoid dupes
          recipients.add(email.toLowerCase());
        }
      }
    }

    if (
      String.isNotBlank(opportunity.Tier_2_Partner__c) && emailsByAccountId.containsKey(opportunity.Tier_2_Partner__c)
    ) {
      for (String email : emailsByAccountId.get(opportunity.Tier_2_Partner__c)) {
        if (String.isNotBlank(email)) {
          // string set is case sensitive, transform to lowercase to avoid dupes
          recipients.add(email.toLowerCase());
        }
      }
    }

    return recipients;
  }

  public void shareOppToDistributorAndReseller(List<Opportunity> opportunities) {
    shareOpportunityToGroups(getGroupIdsByOpportunityId(opportunities));
  }

  public void unShareOppToDistributorAndReseller(List<Opportunity> opportunities) {
    Map<Id, Set<Id>> groupIdsByOpportunityId = getGroupIdsByOpportunityId(opportunities);

    System.debug('@@@ groupIdsByOpportunityId ' + groupIdsByOpportunityId);

    Map<Id, List<OpportunityShare>> sharesByOpportunityId = getSharesByOpportunityId(groupIdsByOpportunityId);

    System.debug('@@@ sharesByOpportunityId ' + sharesByOpportunityId);

    fflib_ISObjectUnitOfWork unitOfWork = Application_PP.UnitOfWork.newInstance();

    // double check that correct share record is being removed
    for (Id opportunityId : groupIdsByOpportunityId.keySet()) {
      Set<Id> groupIds = groupIdsByOpportunityId.get(opportunityId);
      for (Id groupId : groupIds) {
        List<OpportunityShare> opportunityShares = sharesByOpportunityId.get(opportunityId);
        if (opportunityShares == null || opportunityShares.isEmpty()) {
          continue;
        }

        for (OpportunityShare share : opportunityShares) {
          if (share.UserOrGroupId == groupId) {
            System.debug('@@@ adding delete share ' + share);
            unitOfWork.registerDeleted(share);
          }
        }
      }
    }

    unitOfWork.commitWork();
  }

  public Map<Id, Set<Id>> getGroupIdsByOpportunityId(List<Opportunity> opportunities) {
    // get account relationship by opp's sold to partner and tier 2 partner
    Set<String> relationshipTypes = new Set<String>{ 'distributor', 'var/reseller' };
    Set<Id> accountIds = new Set<Id>();
    Set<Id> soldToAccountIds = new Set<Id>();

    for (Opportunity opportunity : opportunities) {
      if (String.isNotBlank(opportunity.Sold_to_Partner__c)) {
        accountIds.add(opportunity.Sold_to_Partner__c);
        soldToAccountIds.add(opportunity.Sold_to_Partner__c);
      }
      if (String.isNotBlank(opportunity.Tier_2_Partner__c)) {
        accountIds.add(opportunity.Tier_2_Partner__c);
      }
    }

    System.debug('@@@ account Ids ' + accountIds);

    AccountsSelector_PP accountsSelector = (AccountsSelector_PP) Application_PP.Selector.newInstance(
      Account.SObjectType
    );
    Map<Id, Account> soldToAccountById = new Map<Id, Account>(accountsSelector.selectById(soldToAccountIds, false));

    AccountRelationshipsSelector_PP accountRelationshipsSelector = (AccountRelationshipsSelector_PP) Application_PP.Selector.newInstance(
      AccountRelationship.SObjectType
    );

    List<AccountRelationship> relationships = accountRelationshipsSelector.selectByAccountIdsAndTypes(
      accountIds,
      relationshipTypes,
      false
    );

    // get the role names of these accounts only if they are related to each other per opp's sold to and tier 2 fields
    Set<String> roleNames = new Set<String>();
    Map<Id, Set<String>> roleNamesByOpportunityId = new Map<Id, Set<String>>();

    for (Opportunity opportunity : opportunities) {
      Account soldToPartner = soldToAccountById.get(opportunity.Sold_to_Partner__c);
      if (!String.isBlank(soldToPartner?.Name)) {
        roleNames.add(soldToPartner.Name + ' Partner Manager');

        if (!roleNamesByOpportunityId.containsKey(opportunity.Id)) {
          roleNamesByOpportunityId.put(opportunity.Id, new Set<String>());
        }

        roleNamesByOpportunityId.get(opportunity.Id).add(soldToPartner.Name + ' Partner Manager');
      }

      if (String.isBlank(opportunity.Sold_to_Partner__c) && String.isBlank(opportunity.Tier_2_Partner__c))
        continue;

      for (AccountRelationship relationship : relationships) {
        // is the opp's sold to partner and tier 2 partner related?
        if (
          (relationship.AccountFromId == opportunity.Sold_to_Partner__c &&
          relationship.AccountToId == opportunity.Tier_2_Partner__c) ||
          (relationship.AccountFromId == opportunity.Tier_2_Partner__c &&
          relationship.AccountToId == opportunity.Sold_to_Partner__c)
        ) {
          // yes, collect role names from account names
          String accountFromRoleName = relationship.AccountFrom.Name + ' Partner Manager';
          String accountToRoleName = relationship.AccountTo.Name + ' Partner Manager';

          roleNames.add(accountFromRoleName);
          roleNames.add(accountToRoleName);

          if (!roleNamesByOpportunityId.containsKey(opportunity.Id)) {
            roleNamesByOpportunityId.put(opportunity.Id, new Set<String>());
          }

          roleNamesByOpportunityId.get(opportunity.Id).add(accountFromRoleName);
          roleNamesByOpportunityId.get(opportunity.Id).add(accountToRoleName);

          // we collected the account, no need to continue looping relationships
          break;
        }
      }
    }

    System.debug('@@@ roleNames ' + roleNames);
    System.debug('@@@ roleNamesByOpportunityId ' + roleNamesByOpportunityId);

    // find role by account name + 'Partner Manager' to get role id
    // find the group for this role
    // apex share the opp

    // SELECT Id, Name, DeveloperName, OpportunityAccessForAccountOwner, PortalRole, PortalType FROM UserRole WHERE Name IN ('Distributor A Partner Manager', 'Distributor B Partner Manager', 'Distributor C (No Reseller) Partner Manager', 'Reseller A Partner Manager')
    // SELECT Id, Name, DeveloperName, RelatedId, Type FROM Group WHERE RelatedId IN ('00E0r000000KrDKEA0', '00E0r000000KsRIEA0', '00E0r000000KsRNEA0', '00E0r000000KrDFEA0') AND Type IN ('RoleAndSubordinates')
    // SELECT Id, OpportunityAccessLevel, RowCause, UserOrGroupId FROM OpportunityShare WHERE UserOrGroupId IN ('00G0r000000wQxLEAU', '00G0r000000wQxMEAU', '00G0r000000wQy4EAE', '00G0r000000wQy5EAE', '00G0r000000waufEAA', '00G0r000000waugEAA', '00G0r000000waupEAA', '00G0r000000wauqEAA')

    // which group type to share to? Role or RoleAndSubordinates : answer latter

    // would account name have dupe?
    // what happens when account name is changed again? 'role name is updated but not dev name'

    UserRolesSelector_PP userRolesSelector = (UserRolesSelector_PP) Application_PP.Selector.newInstance(
      UserRole.SObjectType
    );

    Map<Id, UserRole> roleById = new Map<Id, UserRole>(userRolesSelector.selectByName(roleNames, false));

    System.debug('@@@ roleById ' + roleById);

    GroupsSelector_PP groupsSelector = (GroupsSelector_PP) Application_PP.Selector.newInstance(Group.SObjectType);

    Set<String> groupTypes = new Set<String>{ 'RoleAndSubordinates' };
    List<Group> groups = groupsSelector.selectByRelatedIdsAndTypes(roleById.keySet(), groupTypes, false);

    System.debug('@@@ groups ' + groups);

    // climb up the relationship to get the opportunity back
    Map<Id, Set<Id>> groupIdsByOpportunityId = new Map<Id, Set<Id>>();

    for (Group roleGroup : groups) {
      UserRole role = roleById.get(roleGroup.RelatedId);

      for (Id opportunityId : roleNamesByOpportunityId.keySet()) {
        if (roleNamesByOpportunityId.get(opportunityId).contains(role.Name)) {
          if (!groupIdsByOpportunityId.containsKey(opportunityId)) {
            groupIdsByOpportunityId.put(opportunityId, new Set<Id>());
          }

          groupIdsByOpportunityId.get(opportunityId).add(roleGroup.Id);
        }
      }
    }

    System.debug('@@@ groupIdsByOpportunityId ' + groupIdsByOpportunityId);

    return groupIdsByOpportunityId;
  }

  public void shareOpportunityToGroups(Map<Id, Set<Id>> groupIdsByOpportunityId) {
    List<OpportunityShare> shares = new List<OpportunityShare>();

    for (Id opportunityId : groupIdsByOpportunityId.keySet()) {
      for (Id groupId : groupIdsByOpportunityId.get(opportunityId)) {
        shares.add(
          new OpportunityShare(
            OpportunityId = opportunityId,
            UserOrGroupId = groupId,
            OpportunityAccessLevel = SHARE_OPPORTUNITY_TO_PARTNER_ACCESS_LEVEL
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

  public Map<Id, List<OpportunityShare>> getSharesByOpportunityId(Map<Id, Set<Id>> groupIdsByOpportunityId) {
    Set<Id> opportunityIds = new Set<Id>();
    Set<Id> userOrGroupIds = new Set<Id>();
    Set<String> opportunityAccessLevels = new Set<String>{ SHARE_OPPORTUNITY_TO_PARTNER_ACCESS_LEVEL };

    for (Id opportunityId : groupIdsByOpportunityId.keySet()) {
      opportunityIds.add(opportunityId);
      for (Id groupId : groupIdsByOpportunityId.get(opportunityId)) {
        userOrGroupIds.add(groupId);
      }
    }

    System.debug('@@@ opportunityIds ' + opportunityIds);
    System.debug('@@@ userOrGroupIds ' + userOrGroupIds);
    System.debug('@@@ opportunityAccessLevels ' + opportunityAccessLevels);

    OpportunitySharesSelector_PP selector = (OpportunitySharesSelector_PP) Application_PP.Selector.newInstance(
      OpportunityShare.SObjectType
    );

    List<OpportunityShare> shares = selector.selectApexSharingByOpportunityIdsAndUserOrGroupIdsAndOpportunityAccessLevels(
      opportunityIds,
      userOrGroupIds,
      opportunityAccessLevels,
      false
    );

    System.debug('@@@ shares ' + shares);

    Map<Id, List<OpportunityShare>> sharesByOpportunityId = new Map<Id, List<OpportunityShare>>();

    for (OpportunityShare share : shares) {
      if (!sharesByOpportunityId.containsKey(share.OpportunityId)) {
        sharesByOpportunityId.put(share.OpportunityId, new List<OpportunityShare>());
      }

      sharesByOpportunityId.get(share.OpportunityId).add(share);
    }

    return sharesByOpportunityId;
  }

  /**
   * Link the opportunity to the campaign set in the Deal registration field CampaignId__c
   * The field can either contain a Campaign Id or a Campaign Name
   *
   * @param opportunity The opportunity to link
   * @param dealRegistration The Deal registration containing the Campaign Id or Name
   */
  private void linkOpportunityToCampaign(Opportunity opportunity, DealRegistration__c dealRegistration) {
    if (String.isBlank(dealRegistration.CampaignId__c))
      return; // nothing to do here

    Id campaignId = getCampaignId(dealRegistration.CampaignId__c);

    if (campaignId == null)
      return; // The dealRegistration did not contain either a valid campaign Id or an existing campaign name

    opportunity.CampaignId = campaignId;
  }

  /**
   * Gets the campaign Id based on the given string that could either contain a campaign Id or a campaign Name
   * When multiple campaigns are found with the same name, only the first one found will be used
   *
   * @param campaignIdOrName A string containing either the campaign name or Id
   *
   * @return Returns a campaignId or Null when it failed to find it.
   */
  private Id getCampaignId(String campaignIdOrName) {
    // Assume it contains an Id
    Id campaignId = getIdFromString(campaignIdOrName);

    if (campaignId == null) {
      // Assume it is a campaign name, let's try and find it
      List<Campaign> campaigns = CampaignsSelector_PP.newWithoutSharingInstance().selectByName(campaignIdOrName);

      if (campaigns.size() > 1)
        System.debug(System.LoggingLevel.WARN, 'Multiple Campaigns found with the same name: ' + campaignIdOrName);
      else if (campaigns.isEmpty()) {
        System.debug(System.LoggingLevel.WARN, 'No campaign found with the name: ' + campaignIdOrName);
        return null;
      }
      return campaigns.get(0).Id;
    } else if (campaignId.getSobjectType() == Schema.Campaign.SObjectType)
      // Yes, it is an true campaign Id
      return campaignId;
    else
      // Nothing could be traced to a campaign
      return null;
  }

  private Id getIdFromString(String idString) {
    try {
      return Id.valueOf(idString);
    } catch (StringException e) {
      return null;
    }
  }
}