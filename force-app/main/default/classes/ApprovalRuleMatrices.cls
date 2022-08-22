public without sharing class ApprovalRuleMatrices extends fflib_SObjectDomain implements IApprovalRuleMatrices {
  public static final String SYNC_STATUS_PENDING = 'Pending';

  public ApprovalRuleMatrices(List<ApprovalRuleMatrix__c> sObjectList) {
    super(sObjectList);
    this.Configuration.disableTriggerCRUDSecurity();
  }

  public override void onBeforeInsert() {
    populateFieldsBeforeCommit(Records, null);
  }

  public override void onBeforeUpdate(Map<Id, SObject> existingRecords) {
    populateFieldsBeforeCommit(Records, existingRecords);
  }

  /**
   * populate MD5Hash__c field before commit into database and set SyncStatus__c
   * TODO: Move this to function
   */
  public void populateFieldsBeforeCommit(List<ApprovalRuleMatrix__c> records, Map<Id, SObject> existingRecords) {
    Map<Id, ApprovalRuleMatrix__c> oldRecords = (Map<Id, ApprovalRuleMatrix__c>) (existingRecords);

    for (ApprovalRuleMatrix__c matrix : records) {
      //populate MD5Hash before commit into database
      matrix.MD5Hash__c = ApprovalMatrix.generateMatrixMD5Hash(matrix);

      //setting Sync status to pending
      if (
        oldRecords == null ||
        (matrix.MD5Hash__c != oldRecords.get(matrix.Id).MD5Hash__c &&
        matrix.SyncStatus__c == oldRecords.get(matrix.Id).SyncStatus__c) &&
        matrix.Active__c == oldRecords.get(matrix.Id).Active__c
      ) {
        matrix.SyncStatus__c = SYNC_STATUS_PENDING;
      }
    }
  }

  public class Constructor implements fflib_SObjectDomain.IConstructable {
    public fflib_SObjectDomain construct(List<SObject> sObjectList) {
      return new ApprovalRuleMatrices(sObjectList);
    }
  }
}