public without sharing class OppRDCIntegrationService_SL {
  public static final Set<Id> ELIGIBLE_RECORD_TYPES = new Set<Id>{
    AccountMetadata.academicRecordType,
    AccountMetadata.customerRecordType,
    AccountMetadata.customerProspectRecordType,
    AccountMetadata.ProspectRecordType,
    AccountMetadata.partnerRecordType
  };
  public OppRDCIntegrationService_SL() {
  }

  public static void publish(List<Opportunity> Records) {
    Set<Id> accountIds = new Set<Id>(Collection.of(Records).pluckIds(Opportunity.AccountId));
    Set<Id> endCustomerIds = new Set<Id>(
      Collection.of(Records)
        .filter(Match.field(Opportunity.BPO_MS_End_Customer__c).hasValue())
        .pluckIds(Opportunity.BPO_MS_End_Customer__c)
    );
    Set<Id> allAccountIds = new Set<Id>(accountIds);
    allAccountIds.addAll(endCustomerIds);
    allAccountIds.remove(null);

    if (allAccountIds.isEmpty()) {
      return;
    }

    List<Account> accounts = [
      SELECT Id
      FROM Account
      WHERE Id IN :allAccountIds AND RecordTypeId IN :ELIGIBLE_RECORD_TYPES AND Legal_Compliance_Status__c = NULL
    ];
    if (!accounts.isEmpty()) {
      OrchestratorNotifierQueueable.beginSetup(accounts, CommonsConstants.ACC_RDC_UIPATH_SF_CONNECTOR_TEMPLATE)
        .endSetup()
        .publishNewRecords();
    }
  }

  public static void publish(List<Opportunity> Records, Map<Id, SObject> existingRecords) {
    SObjectPredicate hasChanged = new HasRecordChanged(
      new Set<SObjectField>{ Opportunity.BPO_MS_End_Customer__c },
      Records,
      existingRecords
    );
    Set<Id> endCustomerIds = new Set<Id>(
      Collection.of(Records)
        .filter(hasChanged)
        .filter(Match.field(Opportunity.BPO_MS_End_Customer__c).hasValue())
        .pluckIds(Opportunity.BPO_MS_End_Customer__c)
    );

    if (endCustomerIds.isEmpty()) {
      return;
    }

    List<Account> accounts = [
      SELECT Id
      FROM Account
      WHERE Id IN :endCustomerIds AND RecordTypeId IN :ELIGIBLE_RECORD_TYPES AND Legal_Compliance_Status__c = NULL
    ];
    if (!accounts.isEmpty()) {
      OrchestratorNotifierQueueable.beginSetup(accounts, CommonsConstants.ACC_RDC_UIPATH_SF_CONNECTOR_TEMPLATE)
        .endSetup()
        .publishNewRecords();
    }
  }
}