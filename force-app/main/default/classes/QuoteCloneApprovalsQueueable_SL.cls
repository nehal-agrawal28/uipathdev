public with sharing class QuoteCloneApprovalsQueueable_SL extends AbstractQueueable {
  private final List<SBQQ__Quote__c> records;
  public QuoteCloneApprovalsQueueable_SL(List<SBQQ__Quote__c> records) {
    super('QuoteCloneApprovalsQueueable_SL');
    this.records = records;
    //to allow for logging against record. only used in non-bulk contexts
    if (records != null && records.size() == 1) {
      this.setPrimaryRecordId(records.get(0).Id);
    }
  }

  public override void work() {
    this.copyApprovalsToNewQuote();
  }

  private void copyApprovalsToNewQuote() {
    List<sbaa__Approval__c> approvalsToInsert = new List<sbaa__Approval__c>();
    List<sbaa__ApprovalSnapshot__c> snapshotsToInsert = new List<sbaa__ApprovalSnapshot__c>();

    // Source quote and related quote Map
    Map<Id, List<SBQQ__Quote__c>> sourceIdNewQuotesMap = new Map<Id, List<SBQQ__Quote__c>>();
    for (SBQQ__Quote__c quote : records) {
      if (quote.SBQQ__Source__c != null) {
        if (!sourceIdNewQuotesMap.containsKey(quote.SBQQ__Source__c)) {
          sourceIdNewQuotesMap.put(quote.SBQQ__Source__c, new List<SBQQ__Quote__c>());
        }
        sourceIdNewQuotesMap.get(quote.SBQQ__Source__c).add(quote);
      }
    }

    // Querying approval records for cloning
    for (sbaa__Approval__c approval : [
      SELECT
        Id,
        Discount_Reasons__c,
        Quote__c,
        sbaa__ApprovalChain__c,
        sbaa__ApprovalStep__c,
        sbaa__ApprovalTemplateId__c,
        sbaa__ApprovedBy__c,
        sbaa__Approver__c,
        sbaa__ApproverField__c,
        sbaa__Archived__c,
        sbaa__AssignedGroupId__c,
        sbaa__AssignedTo__c,
        sbaa__CommentsLong__c,
        sbaa__DelegatedApprover__c,
        sbaa__Opportunity__c,
        sbaa__RecallTemplateId__c,
        sbaa__RecordField__c,
        sbaa__RejectedBy__c,
        sbaa__RejectionTemplateId__c,
        sbaa__RequestTemplateId__c,
        sbaa__RequireExplicitApproval__c,
        sbaa__Rule__c,
        sbaa__Status__c,
        sbaa__Unanimous__c,
        (
          SELECT
            Id,
            sbaa__Approval__c,
            sbaa__ApprovalCondition__c,
            sbaa__ApprovedValueDate__c,
            sbaa__ApprovedValueLongText__c,
            sbaa__ApprovedValueNumeric__c,
            sbaa__ApprovedValueText__c
          FROM sbaa__ApprovalSnapshot__r
        )
      FROM sbaa__Approval__c
      WHERE Quote__c IN :sourceIdNewQuotesMap.keySet() AND sbaa__Status__c = 'Approved'
    ]) {
      // Clone Approvals from related Source quote and add into each quote
      for (SBQQ__Quote__c relatedQuote : sourceIdNewQuotesMap.get(approval.Quote__c)) {
        sbaa__Approval__c approvalClone = approval.clone(false, true, true, true);
        approvalClone.Id = null;
        approvalClone.Quote__c = relatedQuote.Id;
        approvalsToInsert.add(approvalClone);
      }
    }
    insert approvalsToInsert;

    // Clone Approval Snapshots
    for (sbaa__Approval__c approvalClone : approvalsToInsert) {
      for (sbaa__ApprovalSnapshot__c snapshotClone : approvalClone.sbaa__ApprovalSnapshot__r) {
        snapshotClone.Id = null;
        snapshotClone.sbaa__Approval__c = approvalClone.Id;
        snapshotsToInsert.add(snapshotClone);
      }
    }
    insert snapshotsToInsert;
  }

  /**
   * Copy Approvals and Approval Snapshots into newly cloned quote
   * Source quote is being set on Update only
   */
  public static void copyApprovalsAndSnapshotsOnUpdate(List<SObject> records, Map<Id, SObject> existingRecords) {
    SObjectPredicate hasChanged = new HasRecordChanged(
      new Set<SObjectField>{ SBQQ__Quote__c.SBQQ__Source__c },
      records,
      existingRecords
    );
    List<SBQQ__Quote__c> eligibleRecords = Collection.of(records)
      .filter(hasChanged)
      .filter(Match.field(SBQQ__Quote__c.SBQQ__Source__c).hasValue())
      .asList();

    if (!eligibleRecords.isEmpty()) {
      AbstractQueueable.enqueue(new QuoteCloneApprovalsQueueable_SL(eligibleRecords));
    }
  }
}