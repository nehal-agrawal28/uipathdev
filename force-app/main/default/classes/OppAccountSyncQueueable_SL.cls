public with sharing class OppAccountSyncQueueable_SL extends AbstractQueueable {
  private List<SObject> opps;

  public OppAccountSyncQueueable_SL(List<SObject> opps) {
    super('OppAccountSyncQueueable_SL');
    this.opps = opps;
    //to allow for logging against record. only used in non-bulk contexts
    if (opps != null && opps.size() == 1) {
      this.setPrimaryRecordId(opps.get(0).Id);
    }
  }

  public override void work() {
    this.setValidationStatus(this.opps);
  }

  private void setValidationStatus(List<Opportunity> opps) {
    Set<Id> accountIds = new Set<Id>();
    accountIds.addAll(Collection.of(opps).pluckIds(Opportunity.AccountId));
    accountIds.addAll(Collection.of(opps).pluckIds(Opportunity.Sold_to_Partner__c));
    updateAccountValidationStatusToReadyForReview(accountIds);
  }

  public static void setValidationStatus(List<SObject> records, Map<Id, SObject> existingRecords) {
    SObjectPredicate hasChanged = new HasRecordChanged(
      new Set<SObjectField>{ Opportunity.StageName },
      records,
      existingRecords
    );

    List<Opportunity> eligibleRecordds = Collection.of(records)
      .filter(hasChanged)
      .filter(
        Match.field(Opportunity.StageName)
          .equals(OpportunityMetadata_SL.NEGOTIATION)
          .also(Opportunity.SBQQ__RenewedContract__c)
          .equals(null)
      )
      .asList();

    // NS account and address sync when stage is Negotiation
    if (!eligibleRecordds.isEmpty()) {
      AbstractQueueable.enqueue(new OppAccountSyncQueueable_SL(eligibleRecordds));
    } else {
      // NS account and address sync when stage is Closed Won Pending
      eligibleRecordds = Collection.of(records)
        .filter(hasChanged)
        .filter(Match.field(Opportunity.StageName).equals(OpportunityMetadata_SL.CLOSED_WON_PENDING))
        .asList();

      if (!eligibleRecordds.isEmpty()) {
        AbstractQueueable.enqueue(new OppAccountSyncQueueable_SL(eligibleRecordds));
      }
    }
  }

  private static void updateAccountValidationStatusToReadyForReview(Set<Id> accountIds) {
    List<Account> accountsToUpdate = [
      SELECT Id, Validation_Status__c
      FROM Account
      WHERE Id IN :accountIds AND Validation_Status__c = :CommonsConstants.ACC_SYNC_STATUS_PENDING
    ];

    for (Account acct : accountsToUpdate) {
      acct.Validation_Status__c = CommonsConstants.ACC_VALIDATION_STATUS_READY_FOR_REVIEW;
    }

    List<Address__c> addressesToUpdate = [
      SELECT Id, Validation_Status__c, Account__c
      FROM Address__c
      WHERE Account__c IN :accountIds AND Validation_Status__c = :CommonsConstants.ACC_SYNC_STATUS_PENDING
    ];

    for (Address__c address : addressesToUpdate) {
      address.Validation_Status__c = CommonsConstants.ACC_VALIDATION_STATUS_READY_FOR_REVIEW;
    }

    update accountsToUpdate;
    update addressesToUpdate;
  }
}