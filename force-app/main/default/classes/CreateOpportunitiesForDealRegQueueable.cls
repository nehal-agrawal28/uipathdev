public with sharing class CreateOpportunitiesForDealRegQueueable
		extends AbstractQueueable
{
	private Set<Id> dealRegistrationIds;
	public CreateOpportunitiesForDealRegQueueable(Set<Id> dealRegistrationIds)
	{
		super('CreateOpportunitiesForDealRegQueueable');
		this.dealRegistrationIds = dealRegistrationIds;
	}

	protected override void work()
	{
		DealRegistrations_PP dealRegistrations =
				((DealRegistrations_PP) Application_PP.Domain.newInstance(dealRegistrationIds));

		if (dealRegistrations.getRecords().isEmpty()) return;

		dealRegistrations.createOpportunities();
	}
}