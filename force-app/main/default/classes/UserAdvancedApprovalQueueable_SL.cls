public with sharing class UserAdvancedApprovalQueueable_SL extends AbstractQueueable {
  private final List<SObject> records;
  public UserAdvancedApprovalQueueable_SL(List<SObject> records) {
    super('UserAdvancedApprovalQueueable_SL');
    this.records = records;
  }

  public override void work() {
    this.updateApprovalRecords(records);
  }

  private void updateApprovalRecords(List<User> records) {
    List<sbaa__Approver__c> existingApproverRecords = new List<sbaa__Approver__c>();
    List<Id> userIds = Collection.of(records).pluckIds();
    List<Id> delegatedUserIds = Collection.of(records).pluckIds(User.DelegatedApproverId);
    Map<Id, sbaa__Approver__c> currentUserApproverMap = new Map<Id, sbaa__Approver__c>(getApprovers(userIds));
    Map<Id, sbaa__Approver__c> delegatedUserApproverMap = new Map<Id, sbaa__Approver__c>(
      getApprovers(delegatedUserIds)
    );
    if (!currentUserApproverMap.isEmpty()) {
      for (User usr : records) {
        if (currentUserApproverMap.containsKey(usr.Id)) {
          sbaa__Approver__c approver = currentUserApproverMap.get(usr.Id);
          if (!delegatedUserApproverMap.isEmpty() && delegatedUserApproverMap.containsKey(usr.DelegatedApproverId)) {
            approver.sbaa__DelegatedApprover__c = delegatedUserApproverMap.get(usr.DelegatedApproverId).Id;
            approver.sbaa__DelegationStart__c = Date.today();
            approver.sbaa__DelegationEnd__c = Date.today().addDays(30);
          } else {
            approver.sbaa__DelegatedApprover__c = null;
            approver.sbaa__DelegationStart__c = null;
            approver.sbaa__DelegationEnd__c = null;
          }
          existingApproverRecords.add(approver);
        }
      }
    }
    if (!existingApproverRecords.isEmpty()) {
      update existingApproverRecords;
    }
  }

  private Map<Id, sbaa__Approver__c> getApprovers(List<Id> userIds) {
    Map<Id, sbaa__Approver__c> approverMap = new Map<Id, sbaa__Approver__c>();
    if (!userIds.isEmpty()) {
      for (sbaa__Approver__c approver : [
        SELECT Id, Name, sbaa__DelegatedApprover__c, sbaa__User__c, sbaa__DelegationStart__c, sbaa__DelegationEnd__c
        FROM sbaa__Approver__c
        WHERE sbaa__User__c IN :userIds AND sbaa__User__c != NULL
      ]) {
        approverMap.put(approver.sbaa__User__c, approver);
      }
    }
    return approverMap;
  }

  public static void populateApprovers(List<User> records, Map<Id, SObject> existingRecords) {
    SObjectPredicate hasChanged = new HasRecordChanged(
      new Set<SObjectField>{ User.DelegatedApproverId },
      records,
      existingRecords
    );

    List<User> eligibleRecords = Collection.of(records).filter(hasChanged).asList();

    if (!eligibleRecords.isEmpty()) {
      AbstractQueueable.enqueue(new UserAdvancedApprovalQueueable_SL(eligibleRecords));
    }
  }
}