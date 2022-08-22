public with sharing class CaseIntegrationService_SL {
  private static final Set<String> ELIGIBLE_STATUS = new Set<String>{
    CaseMetadata_SL.INVOICED_DELIVERED,
    CaseMetadata_SL.PENDING_BILLING_EVENT_PS
  };
  private static void publish(List<SObject> records) {
    OrchestratorNotifierQueueable.beginSetup(records, CommonsConstants.KLARITY_SF_CONNECTOR_TEMPLATE)
      .withFilterConditions(Match.field(Case.Status).isIn(ELIGIBLE_STATUS))
      .endSetup()
      .publishNewRecords();
  }

  public static void publishToUiPathConnector(List<Case> records, Map<Id, SObject> existingRecords) {
    SObjectPredicate hasChanged = new HasRecordChanged(new Set<SObjectField>{ Case.Status }, records, existingRecords);

    List<Case> filteredRecords = (List<Case>) Collection.of(records)
      .filter(hasChanged)
      .filter(
        Match.field(Case.RecordTypeId)
          .isIn(new Set<String>{ CaseMetadata_SL.FinanceRequestRecordType })
          .also(Case.Status)
          .isIn(ELIGIBLE_STATUS)
          .also(Case.Opportunity__c)
          .hasValue()
      )
      .asList();

    if (filteredRecords.isEmpty()) {
      return;
    }

    List<Case> eligibleRecords = [
      SELECT Id, Status
      FROM Case
      WHERE
        Id IN :filteredRecords
        AND Account.Area__c != 'Japan'
        AND Opportunity__r.Sold_to_Partner__r.Area__c != 'Japan'
        AND Opportunity__r.Amount >= USD50000
    ];

    if (!eligibleRecords.isEmpty()) {
      publish(eligibleRecords);
    }
  }
}