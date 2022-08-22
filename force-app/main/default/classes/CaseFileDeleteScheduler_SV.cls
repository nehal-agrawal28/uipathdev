/**
 * Batch job to Delete Attachments of Closed Cases
 *
 * @author Salestech
 * @date  01/12/2021
 *
 */
public with sharing class CaseFileDeleteScheduler_SV implements Database.Batchable<sObject>, Database.Stateful, Schedulable {
  private String originalTransactionId;
  public Boolean isFullRun = false;

  public void execute(SchedulableContext sc) {
    CaseFileDeleteScheduler_SV b1 = new CaseFileDeleteScheduler_SV();
    b1.isFullRun = isFullRun;
    ID batchprocessid = Database.executeBatch(b1, 200);
  }

  public CaseFileDeleteScheduler_SV() {
  }

  public Database.QueryLocator start(Database.BatchableContext context) {
    this.originalTransactionId = Logger.getTransactionId();
    Logger.info('Starting CaseFileDeleteScheduler_SV Batch');
    Logger.saveLog();
    return this.getQueryLocator();
  }

  public void execute(Database.BatchableContext bc, List<Case> caseList) {
    try {
      List<Id> caseIdList = Collection.of(caseList).pluckIds();
      List<Attachment> deleteAttachmentList = [SELECT Id FROM Attachment WHERE ParentId IN :caseIdList];
      List<EmailMessage> emailMessageList = [SELECT Id FROM EmailMessage WHERE RelatedToId IN :caseIdList];
      List<Id> emailMessageIdList = Collection.of(emailMessageList).pluckIds();
      List<ContentDocumentLink> contentDocumentLinkList = [
        SELECT Id, ContentDocumentId
        FROM ContentDocumentLink
        WHERE LinkedEntityId IN :caseIdList OR LinkedEntityId IN :emailMessageIdList
      ];
      Set<Id> contentDocumentIdSet = new Set<Id>();
      List<ContentDocument> contentDocumentList = new List<ContentDocument>();
      for (ContentDocumentLink cdl : contentDocumentLinkList) {
        if (!contentDocumentIdSet.contains(cdl.ContentDocumentId)) {
          contentDocumentList.add(new ContentDocument(Id = cdl.ContentDocumentId));
          contentDocumentIdSet.add(cdl.ContentDocumentId);
        }
      }
      delete contentDocumentList;
      delete deleteAttachmentList;
    } catch (Exception e) {
      Logger.error('Error in CaseFileDeleteScheduler_SV Batch', e);
      Logger.saveLog();
    }
  }

  public void finish(Database.BatchableContext BC) {
    Logger.setParentLogTransactionId(this.originalTransactionId);
    Logger.info('Finishing CaseFileDeleteScheduler_SV Batch');
    Logger.saveLog();
  }

  public Database.QueryLocator getQueryLocator() {
    List<Id> recordTypeIdList = new List<Id>();
    recordTypeIdList.add(CaseMetadata_SV.IncidentRecordType);
    recordTypeIdList.add(CaseMetadata_SV.CloudElementsRecordType);
    recordTypeIdList.add(CaseMetadata_SV.JapanIncidentRecordType);
    Date closedDate = system.today().addmonths(-6);

    if (isFullRun) {
      return Database.getQueryLocator(
        [SELECT Id FROM Case WHERE ClosedDate <= :closedDate AND IsClosed = TRUE AND RecordTypeId IN :recordTypeIdList]
      );
    }
    if (Test.isRunningTest()) {
      return Database.getQueryLocator([SELECT Id FROM Case]);
    }
    return Database.getQueryLocator(
      [
        SELECT Id
        FROM Case
        WHERE DAY_ONLY(ClosedDate) = :closedDate AND IsClosed = TRUE AND RecordTypeId IN :recordTypeIdList
      ]
    );
  }
}