/**
 * @AUTHOR: UIPath
 * @DATE: 01/10/2021
 * @DESCRIPTION: This class is application layer for ETM which registers domain, service and selector classes
 */
public with sharing class Application_ET {
  public static final fflib_Application.ServiceFactory Service = new fflib_Application.ServiceFactory(
    new Map<Type, Type>{
      AccountsService_ET.class => AccountsService_ET.class,
      PartnerInvolvementsService_ET.class => PartnerInvolvementsService_ET.class,
      UserTerritory2AssociationsService_ET.class => UserTerritory2AssociationsService_ET.class,
      UsersService_ET.class => UsersService_ET.class,
      OpportunitiesService_ET.class => OpportunitiesService_ET.class,
      TerritoriesService_ET.class => TerritoriesService_ET.class,
      OpportunityCompensationService_ET.class => OpportunityCompensationService_ET.class,
      OpportunityTeamMemberService_ET.class => OpportunityTeamMemberService_ET.class
    }
  );

  public static final fflib_Application.SelectorFactory Selector = new fflib_Application.SelectorFactory(
    new Map<SObjectType, Type>{
      UserTerritory2Association.SObjectType => UserTerritory2AssociationsSelector_ET.class,
      Territory2.SObjectType => Territory2sSelector_ET.class,
      User.SObjectType => UsersSelector_ET.class,
      Territory_Postal_Code_Mapping__c.SObjectType => TerritoryPostalCodeMappingsSelector_ET.class,
      Account.SObjectType => AccountsSelector_ET.class,
      ObjectTerritory2Association.getSObjectType() => ObjectTerritory2AssociationsSelector_ET.class,
      Batch_Apex__c.SObjectType => BatchApexSelector.class,
      Opportunity.SObjectType => OpportunitiesSelector_ET.class,
      Opportunity_Split__c.SObjectType => OpportunitySplitSelector_ET.class,
      Partner_Involvement__c.SObjectType => PartnerInvolvementSelector_ET.class,
      Default_Compensation__mdt.getSObjectType() => CompensationSelector_ET.class
    }
  );

  public static final fflib_Application.UnitOfWorkFactory UnitOfWork = new fflib_Application.UnitOfWorkFactory(
    new List<SObjectType>{
      Account.SObjectType,
      Opportunity.SObjectType,
      Opportunity_Split__c.SObjectType,
      UserTerritory2Association.SObjectType,
      Territory2.SObjectType,
      Batch_Apex__c.SObjectType,
      Partner_Involvement__c.SObjectType,
      OpportunityTeamMember.SObjectType
    }
  );

  public static final fflib_Application.DomainFactory Domain = new fflib_Application.DomainFactory(
    Application_ET.Selector,
    new Map<SObjectType, Type>{
      UserTerritory2Association.SObjectType => UserTerritory2Associations_ET.Constructor.class,
      Account.SObjectType => Accounts_ET.Constructor.class,
      User.SObjectType => Users_ET.Constructor.class,
      Partner_Involvement__c.SObjectType => PartnerInvolvements_ET.Constructor.class,
      Territory2.SObjectType => Territories_ET.Constructor.class,
      OpportunityTeamMember.SObjectType => OpportunityTeamMember_ET.Constructor.class
    }
  );
}