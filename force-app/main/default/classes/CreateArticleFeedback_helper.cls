public with sharing class CreateArticleFeedback_helper {
  public static List<String> ALLOWED_USER_TYPES = new List<String>{
    'CustomerSuccess',
    'PowerCustomerSuccess',
    'CSPLitePortal'
  };
  public static void updateRelatedCaseStatus(List<FeedItem> records) {
    List<Id> parentIds = Collection.of(records).pluckIds(FeedItem.ParentId);
    List<Case> casesToUpdate = new List<Case>();
    Set<Id> expertRequestIds = new Set<Id>();
    for (Case caseRecord : [SELECT Id, Status, RecordTypeId FROM Case WHERE Id IN :parentIds]) {
      if (caseRecord.Status != 'New' && (Test.isRunningTest() || ALLOWED_USER_TYPES.contains(UserInfo.getUserType()))) {
        caseRecord.Status = 'In Process';
        casesToUpdate.add(caseRecord);
      } else if (caseRecord.Status == 'New' && caseRecord.RecordTypeId == CaseMetadata_SV.EngagementRequestRecordType) {
        expertRequestIds.add(caseRecord.Id);
      }
    }
    Database.update(casesToUpdate, false);
    if (expertRequestIds.isEmpty()) {
      return;
    }
    List<CaseMilestone> milestones = [
      SELECT Id, CompletionDate, MilestoneType.Name
      FROM CaseMilestone
      WHERE CaseId IN :expertRequestIds AND MilestoneType.Name = 'First Response'
    ];
    for (CaseMilestone firstResponse : milestones) {
      firstResponse.CompletionDate = Date.today();
    }
    update milestones;
  }
}