public without sharing class OpportunityTeamMembersService_PP {
  public void createTeamMembers(
    Map<Id, Opportunity> opportunityByDealRegistration,
    Map<Id, DealRegistration__c> dealRegistrationById
  ) {
    if (opportunityByDealRegistration.isEmpty() || dealRegistrationById.isEmpty())
      return;

    fflib_ISObjectUnitOfWork unitOfWork = Application_PP.UnitOfWork.newInstance();

    for (DealRegistration__c dealRegistration : dealRegistrationById.values()) {
      Id opportunityId = opportunityByDealRegistration.get(dealRegistration.Id).Id;
      Id userId = dealRegistration.CreatedById;

      createTeamMember(unitOfWork, opportunityId, userId, 'Partner Community User', 'Read');
    }

    unitOfWork.commitWork();
  }

  public void createTeamMember(Id opportunityId, Id userId, String memberRole, String accessLevel) {
    fflib_ISObjectUnitOfWork unitOfWork = Application_PP.UnitOfWork.newInstance();

    createTeamMember(unitOfWork, opportunityId, userId, memberRole, accessLevel);

    unitOfWork.commitWork();
  }

  public void createTeamMember(
    fflib_ISObjectUnitOfWork unitOfWork,
    Id opportunityId,
    Id userId,
    String memberRole,
    String accessLevel
  ) {
    unitOfWork.registerNew(
      new OpportunityTeamMember(
        OpportunityId = opportunityId,
        OpportunityAccessLevel = accessLevel,
        TeamMemberRole = memberRole,
        UserId = userId
      )
    );
  }
}