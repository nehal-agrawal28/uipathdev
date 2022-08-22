public with sharing class LeadIntegrationService {
	public static void publishLeadOwnerUpdatesToOrchestrator(List<SObject> records, Map<Id, SObject> oldRecords) {
		OrchestratorNotifierQueueable.beginSetup(records, CommonsConstants.LD_TEAMS_MEMBER_UIPATH_SF_CONNECTOR_TEMPLATE)
			.withFilterConditionsAndFunction(
				Match.field(Lead.Status).equals('New').also(Lead.OwnerId).hasValue(),
				new FilterLeadForOrchestrator()
			)
			.withFieldsToCheckForChange(new Set<SObjectField>{ Lead.OwnerId, Lead.Status })
			.withOldRecords(oldRecords)
			.endSetup()
			.publishUpdatedRecords();
	}

	public static void publishNewLeadToOrchestrator(List<SObject> records) {
		OrchestratorNotifierQueueable.beginSetup(records, CommonsConstants.LD_TEAMS_MEMBER_UIPATH_SF_CONNECTOR_TEMPLATE)
			.withFilterConditionsAndFunction(
				Match.field(Lead.Status).equals('New').also(Lead.OwnerId).hasValue(),
				new FilterLeadForOrchestrator()
			)
			.endSetup()
			.publishNewRecords();
	}

	/**
	 * Inner class for adding extra conditions to Account update orchestrator
	 *
	 */
	private class FilterLeadForOrchestrator implements SObjectToSObjectFunction {
		public SObject apply(SObject record) {
			if (String.valueOf(record.get('OwnerId')).startsWith('005')) {
				return record;
			} else {
				return null;
			}
		}
	}
}