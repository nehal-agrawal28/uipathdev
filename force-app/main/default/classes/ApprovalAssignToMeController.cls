public without sharing class ApprovalAssignToMeController {
  public class ApprovalAssignToMeWrapper {
    @AuraEnabled
    public Boolean success { get; set; }
    @AuraEnabled
    public String message { get; set; }
  }

  @AuraEnabled
  public static ApprovalAssignToMeWrapper assignApprovalToMe(String approvalId) {
    try {
      ApprovalAssignToMeWrapper wrapper = new ApprovalAssignToMeWrapper();
      sbaa__Approval__c request = [
        SELECT Id, sbaa__Approver__r.sbaa__GroupId__c, Quote__c
        FROM sbaa__Approval__c
        WHERE Id = :approvalId
      ];

      if (request.sbaa__Approver__c != null && String.isNotBlank(request.sbaa__Approver__r.sbaa__GroupId__c)) {
        Boolean isMember = false;

        for (GroupMember gm : [
          SELECT group.Id, group.DeveloperName
          FROM GroupMember
          WHERE UserOrGroupId = :UserInfo.getUserId()
        ]) {
          if (request.sbaa__Approver__r.sbaa__GroupId__c == gm.group.Id) {
            isMember = true;
            break;
          }
        }

        if (isMember) {
          assignSameGroupApprovalsToMe(request);

          wrapper.success = true;
          wrapper.message = 'This approval request has been assigned to you';
        } else {
          wrapper.success = false;
          wrapper.message = 'You do not belong to the Approval Group for this approval request';
        }
      } else {
        wrapper.success = false;
        wrapper.message = 'This approval request does not belong to a group';
      }

      return wrapper;
    } catch (Exception e) {
      AuraHandledException ax = new AuraHandledException(e.getMessage());
      ax.setMessage(e.getMessage());
      throw ax;
    }
  }

  private static void assignSameGroupApprovalsToMe(sbaa__Approval__c request) {
    request.sbaa__AssignedTo__c = UserInfo.getUserId();
    update request;

    List<sbaa__Approval__c> otherOpenApprovals = [
      SELECT Id, sbaa__Approver__r.sbaa__GroupId__c, Quote__c
      FROM sbaa__Approval__c
      WHERE
        Quote__c = :request.Quote__c
        AND Id != :request.Id
        AND sbaa__Status__c IN ('Requested', 'Assigned')
        AND sbaa__Approver__r.sbaa__GroupId__c = :request.sbaa__Approver__r.sbaa__GroupId__c
    ];
    for (sbaa__Approval__c approval : otherOpenApprovals) {
      approval.sbaa__AssignedTo__c = UserInfo.getUserId();
    }
    if (otherOpenApprovals.size() > 0) {
      update otherOpenApprovals;
    }
  }
}