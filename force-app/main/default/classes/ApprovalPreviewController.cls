/**********************************************************
 * Author        :  UiPath
 * CreatedBy     :  Raghu Rankawat
 * CreatedDate   :  06-Oct-2020
 * Description   :  controller class for approvalPreview LWC
 *
 * Modifications :
 * [DD-MMM-YYYY] : [Name] : [Description]
 **********************************************************/
public without sharing class ApprovalPreviewController {
	/**
	 * Build approval process step details
	 */
	@AuraEnabled
	public static ApprovalPreviewHelper.ApprovalProcessWrapper runPreview(String recordId) {
		ApprovalPreviewHelper.ApprovalProcessWrapper apWrapper = new ApprovalPreviewHelper.ApprovalProcessWrapper();

		//set savepoint, so that any database changes during the try/catch block can get rolled back
		System.savepoint savePoint = Database.setSavepoint();

		try {
			//submit request for approval
			Map<String, Object> result = ApprovalPreviewHelper.approvalSubmit(recordId, 'ApprovalPreview', false);

			String newInstanceId = (String) result.get('processInstanceId');
			if ((String) result.get('status') == 'Pending' || (String) result.get('status') == 'Started') {
				//iterate through steps ELSE auto approved
				ApprovalPreviewHelper.goThroughSteps(newInstanceId, false);
			}

			apWrapper = ApprovalPreviewHelper.buildApprovalWrapper(newInstanceId, result);
		} catch (Exception e) {
			apWrapper = handleCatchException(apWrapper, e.getMessage());
		}

		Database.rollback(savePoint);

		return apWrapper;
	}

	/**
	 * Submit record for approval
	 */
	@AuraEnabled
	public static ApprovalPreviewHelper.ApprovalProcessWrapper submitForApproval(String recordId, String comments) {
		ApprovalPreviewHelper.ApprovalProcessWrapper apWrapper = new ApprovalPreviewHelper.ApprovalProcessWrapper();

		try {
			//submit request for approval
			ApprovalPreviewHelper.approvalSubmit(recordId, comments, false);
		} catch (Exception e) {
			apWrapper = handleCatchException(apWrapper, e.getMessage());
		}

		return apWrapper;
	}

	/**
	 * Submit record for approval
	 */
	@AuraEnabled
	public static ApprovalPreviewHelper.ApprovalProcessWrapper recallApproval(String recordId, String comments) {
		ApprovalPreviewHelper.ApprovalProcessWrapper apWrapper = new ApprovalPreviewHelper.ApprovalProcessWrapper();

		try {
			ProcessInstanceWorkitem[] piWorkItems = [
				SELECT Id
				FROM ProcessInstanceWorkItem
				WHERE ProcessInstance.TargetObjectId = :recordId AND ProcessInstance.Status = 'Pending'
			];
			if (piWorkItems.size() > 0) {
				Approval.ProcessWorkItemRequest pwiRequest = new Approval.ProcessWorkItemRequest();
				pwiRequest.setAction('Removed');
				pwiRequest.setComments(comments);
				pwiRequest.setWorkItemId(piWorkItems[0].Id);
				Approval.ProcessResult result = Approval.process(pwiRequest);
			}
		} catch (Exception e) {
			String errorMsg = e.getMessage();
			if (e.getMessage().contains('INSUFFICIENT_ACCESS_ON_CROSS_REFERENCE_ENTITY')) {
				errorMsg =
					'You do not have permission to recall this approval request. ' +
					'Please contact initial submitter or your system administrator.';
			}
			apWrapper = handleCatchException(apWrapper, errorMsg);
		}

		return apWrapper;
	}

	private static ApprovalPreviewHelper.ApprovalProcessWrapper handleCatchException(
		ApprovalPreviewHelper.ApprovalProcessWrapper apWrapper,
		String errorMsg
	) {
		apWrapper.isError = true;
		apWrapper.errorMsg = errorMsg;
		return apWrapper;
	}
}