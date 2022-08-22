public without sharing class PartnerInvolvementsService_PP {
  public void createPartnerInvolvements(
    Map<Id, Opportunity> opportunityByDealRegistration,
    Map<Id, DealRegistration__c> dealRegistrationById,
    Map<Id, User> ownerById
  ) {
    // validation rule requires sold to partner must be added before tier 2 partner
    fflib_ISObjectUnitOfWork unitOfWork = Application_PP.UnitOfWork.newInstance();
    fflib_ISObjectUnitOfWork unitOfWork2 = Application_PP.UnitOfWork.newInstance();

    for (DealRegistration__c dealRegistration : dealRegistrationById.values()) {
      if (
        dealRegistration.DealType__c == 'BPO' ||
        dealRegistration.DealType__c == 'Managed Services' ||
        dealRegistration.DealType__c == 'Partner Internal Infrastructure' ||
        dealRegistration.DealType__c == 'NFR'
      ) {
        continue;
      }

      User owner = ownerById.get(dealRegistration.OwnerId);

      if (owner == null)
        continue;
      if (String.isBlank(owner.Contact_Account_Id__c))
        continue;
      if (String.isBlank(owner.ContactAccountBusinessPartnerType__c))
        continue;

      String distributorOrResellerAccountId;
      Id opportunityId = opportunityByDealRegistration.get(dealRegistration.Id).Id;

      if (owner.ContactAccountBusinessPartnerType__c == 'Distributor') {
        distributorOrResellerAccountId = dealRegistration.Distributor__c;
        createSoldToPartnerInvolvement(unitOfWork, opportunityId, distributorOrResellerAccountId);

        if (dealRegistration.Tier2Partner__c != null) {
          createTier2PartnerInvolvement(unitOfWork2, opportunityId, dealRegistration.Tier2Partner__c);
        }
      }

      if (owner.ContactAccountBusinessPartnerType__c != 'Distributor' && dealRegistration.Distributor__c != null) {
        distributorOrResellerAccountId = dealRegistration.Tier2Partner__c;
        createSoldToPartnerInvolvement(unitOfWork, opportunityId, dealRegistration.Distributor__c);
        createTier2PartnerInvolvement(unitOfWork2, opportunityId, distributorOrResellerAccountId);
      }

      if (String.isNotBlank(distributorOrResellerAccountId))
        continue;

      createSoldToPartnerInvolvement(unitOfWork, opportunityId, owner.Contact_Account_Id__c, true);
    }

    unitOfWork.commitWork();
    unitOfWork2.commitWork();
  }

  public void createSoldToPartnerInvolvement(
    fflib_ISObjectUnitOfWork unitOfWork,
    Id opportunityId,
    Id distributorOrResellerAccountId
  ) {
    createSoldToPartnerInvolvement(unitOfWork, opportunityId, distributorOrResellerAccountId, false);
  }

  public void createSoldToPartnerInvolvement(
    fflib_ISObjectUnitOfWork unitOfWork,
    Id opportunityId,
    Id distributorOrResellerAccountId,
    Boolean direct
  ) {
    Partner_Involvement__c record = new Partner_Involvement__c(
      PartnerOpp_Name__c = opportunityId,
      Partner_Account_Name__c = distributorOrResellerAccountId,
      Partner_Sales_Role__c = System.Label.PartnerInvolvementSalesRoleSoldToPartner,
      Partner_Sales_Contribution__c = (direct ? 'Led' : 'None'),
      Opportunity_Sourced__c = (direct ? true : false),
      Partner_Technical_Contribution__c = System.Label.PartnerInvolvementDeliveryRoleNone
    );
    unitOfWork.registerNew(record);
  }

  public void createTier2PartnerInvolvement(
    fflib_ISObjectUnitOfWork unitOfWork,
    Id opportunityId,
    Id partnerAccountId
  ) {
    Partner_Involvement__c record = new Partner_Involvement__c(
      PartnerOpp_Name__c = opportunityId,
      Partner_Account_Name__c = partnerAccountId,
      Partner_Sales_Role__c = System.Label.PartnerInvolvementSalesRoleTier2Partner,
      Partner_Sales_Contribution__c = 'Led',
      Opportunity_Sourced__c = true,
      Partner_Technical_Contribution__c = System.Label.PartnerInvolvementDeliveryRoleNone
    );
    unitOfWork.registerNew(record);
  }
}