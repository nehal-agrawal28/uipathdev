public without sharing class CreateOpportunityAction_PP extends AbstractQueueable {
  private DealRegistration__c m_DealReg;
  private List<DealRegistrationProduct__c> m_DealRegProducts;
  private Map<String, String> m_TeamMemberData;
  private Opportunity m_Opportunity;

  public CreateOpportunityAction_PP(
    DealRegistration__c dealReg,
    List<DealRegistrationProduct__c> dealRegProducts,
    Map<String, String> teamMemberData
  ) {
    super('CreateOpportunityAction_PP');
    m_DealReg = dealReg;
    m_DealRegProducts = dealRegProducts;
    m_TeamMemberData = teamMemberData;
  }

  public override void work() {
    try {
      createOpportunity();
      createOpportunityTeam();
    } catch (Exception e) {
      PartnerPortalException.LogException(e, 'Opportunities Creating Process', 'Error while creating opportunities');
    }
  }

  private void createOpportunity() {
    if (m_DealReg == null)
      return;

    OpportunitiesService_PP opptiesService = (OpportunitiesService_PP) Application_PP.Service.newInstance(
      OpportunitiesService_PP.class
    );
    m_Opportunity = opptiesService.createOpportunityWithProducts(m_DealReg, m_DealRegProducts);
  }

  private void createOpportunityTeam() {
    if (m_Opportunity == null && m_TeamMemberData == null)
      return;

    OpportunityTeamMembersService_PP opptyTeamMembersService = (OpportunityTeamMembersService_PP) Application_PP.Service.newInstance(
      OpportunityTeamMembersService_PP.class
    );
    opptyTeamMembersService.createTeamMember(
      m_Opportunity.Id,
      m_TeamMemberData.get('UserId'),
      m_TeamMemberData.get('MemberRole'),
      m_TeamMemberData.get('AccessLevel')
    );
  }
}