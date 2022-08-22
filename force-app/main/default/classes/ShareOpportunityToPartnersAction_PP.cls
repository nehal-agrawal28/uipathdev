public without sharing class ShareOpportunityToPartnersAction_PP extends AbstractQueueable {
  private List<Opportunity> recordsToShare;
  private List<Opportunity> recordsToUnshare;

  public ShareOpportunityToPartnersAction_PP(List<Opportunity> recordsToShare, List<Opportunity> recordsToUnshare) {
    super('ShareOpportunityToPartnersAction_PP');
    this.recordsToShare = recordsToShare;
    this.recordsToUnshare = recordsToUnshare;
  }

  public override void work() {
    try {
      OpportunitiesService_PP service = (OpportunitiesService_PP) Application_PP.Service.newInstance(
        OpportunitiesService_PP.class
      );

      service.unShareOppToDistributorAndReseller(recordsToUnshare);
      service.shareOppToDistributorAndReseller(recordsToShare);
    } catch (Exception e) {
      PartnerPortalException.LogException(
        e,
        'Opportunities Sharing Process',
        'Error while sharing opportunities to partners.'
      );
    }
  }
}