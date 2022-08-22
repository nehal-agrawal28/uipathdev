/**********************************************************
 * Author        :  UiPath
 * CreatedBy     :  Raghu Rankawat
 * CreatedDate   :  06-Oct-2020
 * Description   :  helper class for ApprovalPreviewController
 *
 * Modifications :
 * [DD-MMM-YYYY] : [Name] : [Description]
 **********************************************************/
public without sharing class ApprovalPreviewHelper {
	/**
	 * submit record for approval
	 */
	public static Map<String, Object> approvalSubmit(String recordId, String comments, Boolean isManual) {
		//instantiate variables
		Map<String, Object> result = new Map<String, Object>();
		result.put('status', '');
		result.put('processInstanceId', '');

		try {
			//submit request for approval
			Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
			req.setObjectId(recordId);
			req.setComments(comments);
			req.setSubmitterId(UserInfo.getUserId());
			if (isManual) {
				req.setComments('ApprovalPreview_ManualUser');
				req.setNextApproverIds(new List<Id>{ UserInfo.getUserId() });
			}

			Approval.ProcessResult submitResult = Approval.process(req);

			result.put('status', submitResult.getInstanceStatus());
			result.put('processInstanceId', submitResult.getInstanceId());
		} catch (Exception e) {
			String message = e.getMessage();
			if (message.contains('NO_APPLICABLE_PROCESS')) {
				throw new ApprovalException(
					'This record does not meet the entry criteria for any approval processes. ' +
					'Please reach out to your system administrator for assistance.'
				);
			} else if (message.contains('ALREADY_IN_PROCESS')) {
				ProcessInstance pI = [
					SELECT Id, (SELECT Id FROM StepsAndWorkItems WHERE StepStatus = 'Approved' ORDER BY Id)
					FROM ProcessInstance
					WHERE TargetObjectId = :recordId AND Status IN ('Started', 'Pending')
					ORDER BY CreatedDate DESC
					LIMIT 1
				];

				result.put('status', 'Pending');
				result.put('processInstanceId', pI.Id);
				result.put('exception', 'ALREADY_IN_PROCESS');
				result.put('alreadyApprovedItems', pI.StepsAndWorkItems);
			} else if (message.contains('REQUIRED_FIELD_MISSING') && message.contains('nextApproverIds')) {
				result = approvalSubmit(recordId, comments, true);
			} else {
				throw new ApprovalException(message + e.getStackTraceString());
			}
		}

		return result;
	}

	/**
	 * process each approval step recursively
	 */
	public static void goThroughSteps(String processInstanceId, Boolean isManual) {
		List<ProcessInstanceWorkitem> piw = [
			SELECT Id
			FROM ProcessInstanceWorkitem
			WHERE ProcessInstanceId = :processInstanceId
		];

		// Instantiate the new ProcessWorkitemRequest object and populate it
		Approval.ProcessWorkitemRequest req2 = new Approval.ProcessWorkitemRequest();
		req2.setComments('Approve');
		req2.setAction('Approve');

		// Use the Id from the newly created item to specify the item to be worked
		req2.setWorkitemId(piw[0].Id);

		if (isManual) {
			req2.setComments('ApprovalPreview_ManualUser');
			req2.setNextApproverIds(new List<Id>{ UserInfo.getUserId() });
		}

		try {
			// Submit the request for approval
			Approval.ProcessResult result2 = Approval.process(req2);

			if (!result2.getNewWorkitemIds().isEmpty()) {
				goThroughSteps(processInstanceId, false);
			}
		} catch (Exception e) {
			String message = e.getMessage();
			if (message.contains('REQUIRED_FIELD_MISSING') && message.contains('nextApproverIds')) {
				goThroughSteps(processInstanceId, true);
			} else {
				throw new ApprovalException(message + e.getStackTraceString());
			}
		}
	}

	/**
	 * create wrapper for output to LWC
	 */
	public static ApprovalProcessWrapper buildApprovalWrapper(
		String newInstanceId,
		Map<String, Object> approvalResult
	) {
		ApprovalProcessWrapper apWrapper = new ApprovalProcessWrapper();
		List<ProcessInstanceHistory> alreadyApprovedItems;

		if (
			approvalResult.containsKey('exception') &&
			approvalResult.containsKey('alreadyApprovedItems') &&
			(String) approvalResult.get('exception') == 'ALREADY_IN_PROCESS'
		) {
			apWrapper.alreadyInApproval = true;
			alreadyApprovedItems = (List<ProcessInstanceHistory>) approvalResult.get('alreadyApprovedItems');
		} else {
			apWrapper.alreadyInApproval = false;
		}

		List<ProcessInstance> newInstanceList = [
			SELECT
				Id,
				ProcessDefinition.Name,
				ProcessDefinition.Description,
				(
					SELECT
						Id,
						Comments,
						StepStatus,
						ProcessInstanceId,
						OriginalActorId,
						OriginalActor.Name,
						OriginalActor.Email,
						ProcessNodeId,
						ProcessNode.Name
					FROM StepsAndWorkItems
					WHERE StepStatus = 'Approved'
					ORDER BY Id
				)
			FROM ProcessInstance
			WHERE Id = :newInstanceId
			LIMIT 1
		];

		Boolean nextApproverWasManual = false;
		Set<Id> approverUserIds = new Set<Id>();
		ProcessInstance newInstance = newInstanceList[0];
		apWrapper.processName = newInstance.ProcessDefinition.Name;
		apWrapper.processDescription = newInstance.ProcessDefinition.Description;

		for (ProcessInstanceHistory pih : newInstance.StepsAndWorkitems) {
			ApprovalStepWrapper aStep = new ApprovalStepWrapper();
			aStep.stepNumber = apWrapper.approvalSteps.size() + 1;
			aStep.stepName = pih.ProcessNode.Name;
			aStep.approver = pih.OriginalActor.Name;
			aStep.approverEmail = pih.OriginalActor.Email;
			aStep.approverId = pih.OriginalActorId;

			if (((String) (pih.OriginalActorId)).startsWith('00G')) {
				aStep.isQueue = true;
			} else {
				aStep.isQueue = false;
				approverUserIds.add(pih.OriginalActorId);
			}
			if (apWrapper.alreadyInApproval) {
				for (ProcessInstanceHistory aItem : alreadyApprovedItems) {
					if (pih.Id == aItem.Id) {
						aStep.isAlreadyApproved = true;
						break;
					}
				}
			}

			// checking for the next item in the list
			if (pih.OriginalActorId == UserInfo.getUserId()) {
				aStep.selfOrManual = true;
			} else {
				aStep.selfOrManual = false;
			}

			apWrapper.approvalSteps.add(aStep);
		}

		//populate approver User details
		for (User aUser : [SELECT Id, mediumPhotoUrl, Email FROM User WHERE Id IN :approverUserIds]) {
			for (ApprovalStepWrapper aStep : apWrapper.approvalSteps) {
				if (aStep.approverId == aUser.Id) {
					aStep.approverPhotoUrl = aUser.mediumPhotoUrl;
				}
			}
		}

		return apWrapper;
	}

	/**
	 * Wrapper classes
	 */
	public class ApprovalProcessWrapper {
		@AuraEnabled
		public Boolean isError { get; set; }
		@AuraEnabled
		public String errorMsg { get; set; }
		@AuraEnabled
		public Boolean alreadyInApproval { get; set; }
		@AuraEnabled
		public String processName { get; set; }
		@AuraEnabled
		public String processDescription { get; set; }
		@AuraEnabled
		public List<ApprovalStepWrapper> approvalSteps {
			get {
				if (approvalSteps == null) {
					approvalSteps = new List<ApprovalStepWrapper>();
				}
				return approvalSteps;
			}
			set;
		}
	}
	public class ApprovalStepWrapper {
		@AuraEnabled
		public Integer stepNumber { get; set; }
		@AuraEnabled
		public String stepName { get; set; }
		@AuraEnabled
		public String approver { get; set; }
		@AuraEnabled
		public String approverId { get; set; }
		@AuraEnabled
		public String approverPhotoUrl { get; set; }
		@AuraEnabled
		public String approverEmail { get; set; }
		@AuraEnabled
		public Boolean isQueue { get; set; }
		@AuraEnabled
		public Boolean isAlreadyApproved { get; set; }
		@AuraEnabled
		public Boolean selfOrManual { get; set; }
	}

	class ApprovalException extends Exception {
	}
}