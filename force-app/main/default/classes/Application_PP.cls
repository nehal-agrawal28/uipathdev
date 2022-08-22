public with sharing class Application_PP {
  public static final fflib_ClassicServiceFactory Service = new fflib_ClassicServiceFactory(
    new Map<Type, Type>{
      AccountsService_PP.class => AccountsService_PP.class,
      DealRegistrationProductsService_PP.class => DealRegistrationProductsService_PP.class,
      DealRegistrationsService_PP.class => DealRegistrationsService_PP.class,
      DistributorConfigurationsService_PP.class => DistributorConfigurationsService_PP.class,
      EmailsService_PP.class => EmailsService_PP.class,
      ErrorLogsService_PP.class => ErrorLogsService_PP.class,
      GroupsService_PP.class => GroupsService_PP.class,
      IPartnerDiscountSchedulesService_PP.class => PartnerDiscountSchedulesServiceImpl_PP.class,
      IPartnerDiscountsService_PP.class => PartnerDiscountsServiceImpl_PP.class,
      LeadsService_PP.class => LeadsService_PP.class,
      NetworksService_PP.class => NetworksService_PP.class,
      OpportunitiesService_PP.class => OpportunitiesService_PP.class,
      OpportunitySharesService_PP.class => OpportunitySharesService_PP.class,
      OpportunityTeamMembersService_PP.class => OpportunityTeamMembersService_PP.class,
      PartnerApplicationFormsService_PP.class => PartnerApplicationFormsService_PP.class,
      PartnerInvolvementsService_PP.class => PartnerInvolvementsService_PP.class,
      UserSharesService_PP.class => UserSharesService_PP.class,
      UsersService_PP.class => UsersService_PP.class
    }
  );

  public static final fflib_ClassicSelectorFactory Selector = new fflib_ClassicSelectorFactory(
    new Map<SObjectType, Type>{
      Account.SObjectType => AccountsSelector_PP.class,
      AccountRelatedEmailDomain__c.SObjectType => AccountRelatedEmailDomainsSelector_PP.class,
      AccountRelationship.SObjectType => AccountRelationshipsSelector_PP.class,
      Campaign.SObjectType => CampaignsSelector_PP.WithSharing.class,
      Contact.SObjectType => ContactsSelector_PP.class,
      CPI__c.SObjectType => CorruptionPerceptionsIndexSelector_PP.class,
      DealRegistrationProduct__c.SObjectType => DealRegistrationProductsSelector_PP.class,
      DealRegistration__c.SObjectType => DealRegistrationsSelector_PP.class,
      Default_Application_Manager_PP__mdt.SObjectType => DefaultApplicationManagersSelector_PP.WithSharing.class,
      DiscountCondition__c.SObjectType => DiscountConditionsSelector_PP.class,
      DiscountSchedule__c.SObjectType => DiscountSchedulesSelector_PP.class,
      DiscountTable__c.SObjectType => DiscountTablesSelector_PP.class,
      DiscountTableItem__c.SObjectType => DiscountTableItemsSelector_PP.class,
      DiscountUplift__c.SObjectType => DiscountUpliftsSelector_PP.class,
      DiscountUpliftCondition__c.SObjectType => DiscountUpliftConditionsSelector_PP.class,
      DistributorConfiguration__c.SObjectType => DistributorConfigurationsSelector_PP.class,
      EmailTemplate.SObjectType => EmailTemplatesSelector_PP.class,
      GenericNotification_PP__c.SObjectType => GenericNotificationsSelector_PP.class,
      Group.SObjectType => GroupsSelector_PP.class,
      GroupMember.SObjectType => GroupMembersSelector_PP.class,
      Lead.SObjectType => LeadsSelector_PP.class,
      Network.SObjectType => NetworksSelector_PP.class,
      Opportunity.SObjectType => OpportunitiesSelector_PP.class,
      OpportunityShare.SObjectType => OpportunitySharesSelector_PP.class,
      OrgWideEmailAddress.SObjectType => OrgWideEmailAddressesSelector_PP.class,
      Partner_Application_Form__c.SObjectType => PartnerApplicationFormsSelector_PP.class,
      PricebookEntry.SObjectType => PricebookEntriesSelector_PP.class,
      Product2.SObjectType => ProductsSelector_PP.WithSharing.class,
      Profile.SObjectType => ProfilesSelector_PP.class,
      sbaa__ApprovalChain__c.SObjectType => ApprovalChainsSelector_PP.WithSharing.class,
      sbaa__ApprovalRule__c.SObjectType => ApprovalRulesSelector_PP.WithSharing.class,
      sbaa__Approver__c.SObjectType => ApproversSelector_PP.WithSharing.class,
      SBQQ__Quote__c.getSObjectType() => QuotesSelector_PP.class,
      User.SObjectType => UsersSelector_PP.class,
      UserRole.SObjectType => UserRolesSelector_PP.class
    }
  );

  public static final fflib_ClassicSelectorFactory ElevatedSelector = new fflib_ClassicSelectorFactory(
    new Map<SObjectType, Type>{
      Campaign.SObjectType => CampaignsSelector_PP.WithoutSharing.class,
      Default_Application_Manager_PP__mdt.SObjectType => DefaultApplicationManagersSelector_PP.WithoutSharing.class,
      DiscountCondition__c.SObjectType => DiscountConditionsSelector_PP.WithoutSharing.class,
      DiscountSchedule__c.SObjectType => DiscountSchedulesSelector_PP.WithoutSharing.class,
      DiscountTableItem__c.SObjectType => DiscountTableItemsSelector_PP.WithoutSharing.class,
      DiscountTable__c.SObjectType => DiscountTablesSelector_PP.WithoutSharing.class,
      DiscountUpliftCondition__c.SObjectType => DiscountUpliftConditionsSelector_PP.WithoutSharing.class,
      DiscountUplift__c.SObjectType => DiscountUpliftsSelector_PP.WithoutSharing.class,
      Partner_Application_Form__c.SObjectType => PartnerApplicationFormsSelector_PP.class,
      Product2.SObjectType => ProductsSelector_PP.WithoutSharing.class,
      sbaa__ApprovalChain__c.SObjectType => ApprovalChainsSelector_PP.WithoutSharing.class,
      sbaa__ApprovalRule__c.SObjectType => ApprovalRulesSelector_PP.WithoutSharing.class,
      sbaa__Approver__c.SObjectType => ApproversSelector_PP.WithoutSharing.class,
      SBQQ__Quote__c.getSObjectType() => QuotesSelector_PP.WithoutSharing.class
    }
  );

  public static final fflib_ClassicSelectorFactory InheritedSharingSelector = new fflib_ClassicSelectorFactory(
    new Map<SObjectType, Type>{
      Default_Application_Manager_PP__mdt.SObjectType => DefaultApplicationManagersSelector_PP.class,
      sbaa__ApprovalChain__c.SObjectType => ApprovalChainsSelector_PP.class,
      sbaa__ApprovalRule__c.SObjectType => ApprovalRulesSelector_PP.class,
      sbaa__Approver__c.SObjectType => ApproversSelector_PP.class
    }
  );

  public static final fflib_Application.UnitOfWorkFactory UnitOfWork = new fflib_Application.UnitOfWorkFactory(
    new List<SObjectType>{
      Account.SObjectType,
      Contact.SObjectType,
      ErrorLog__c.SObjectType,
      GroupMember.SObjectType,
      Lead.SObjectType,
      Opportunity.SObjectType,
      OpportunityLineItem.SObjectType,
      OpportunityTeamMember.SObjectType,
      OpportunityShare.SObjectType,
      Partner_Application_Form__c.SObjectType,
      Partner_Involvement__c.SObjectType,
      DealRegistration__c.SObjectType,
      DealRegistrationProduct__c.SObjectType
    }
  );

  public static final fflib_ClassicDomainFactory Domain = new fflib_ClassicDomainFactory(
    Application_PP.Selector,
    new Map<Object, Type>{
      Account.SObjectType => Accounts_PP.Constructor.class,
      AccountRelatedEmailDomain__c.SObjectType => AccountRelatedEmailDomains_PP.Constructor.class,
      AccountRelationship.SObjectType => AccountRelationships_PP.Constructor.class,
      Case.SObjectType => Cases_PP.Constructor.class,
      Contact.SObjectType => Contacts_PP.Constructor.class,
      CPI__c.SObjectType => CorruptionPerceptionsIndexes_PP.Constructor.class,
      DealRegistrationProduct__c.SObjectType => DealRegistrationProducts_PP.Constructor.class,
      DealRegistration__c.SObjectType => DealRegistrations_PP.Constructor.class,
      Default_Application_Manager_PP__mdt.SObjectType => DefaultApplicationManagers_PP.Constructor.class,
      DiscountSchedule__c.SObjectType => DiscountSchedules_PP.Constructor.class,
      DiscountCondition__c.SObjectType => DiscountConditions_PP.Constructor.class,
      DiscountTable__c.SObjectType => DiscountTables_PP.Constructor.class,
      DiscountUplift__c.SObjectType => DiscountUplifts_PP.Constructor.class,
      DiscountUpliftCondition__c.SObjectType => DiscountUpliftConditions_PP.Constructor.class,
      GenericNotification_PP__c.SObjectType => GenericNotifications_PP.Constructor.class,
      GroupMember.SObjectType => GroupMembers_PP.Constructor.class,
      Lead.SObjectType => Leads_PP.Constructor.class,
      Opportunity.SObjectType => Opportunities_PP.Constructor.class,
      Partner_Application_Form__c.SObjectType => PartnerApplicationForms_PP.Constructor.class,
      Partner_Involvement__c.SObjectType => PartnerInvolvements_PP.Constructor.class,
      Product2.SObjectType => Products_PP.Constructor.class,
      sbaa__ApprovalChain__c.SObjectType => ApprovalChains_PP.Constructor.class,
      sbaa__ApprovalRule__c.SObjectType => ApprovalRules_PP.Constructor.class,
      sbaa__Approver__c.SObjectType => Approvers_PP.Constructor.class,
      SBQQ__Quote__c.SObjectType => Quotes_PP.Constructor.class,
      SBQQ__QuoteLine__c.SObjectType => QuoteLineItems_PP.Constructor.class,
      User.SObjectType => Users_PP.Constructor.class
    }
  );
}