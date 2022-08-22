/* eslint-disable @lwc/lwc/no-inner-html */
/* eslint-disable no-console */
import { LightningElement, api, track } from "lwc";
import approvalPreviewHTML from "./approvalPreview.html";
import alreadyInApprovalHTML from "./alreadyInApproval.html";
import errorHTML from "./error.html";
import RESOURCE from "@salesforce/resourceUrl/ApprovalPreview";
import runPreview from "@salesforce/apex/ApprovalPreviewController.runPreview";
import submitForApproval from "@salesforce/apex/ApprovalPreviewController.submitForApproval";
import recallApproval from "@salesforce/apex/ApprovalPreviewController.recallApproval";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

export default class ApprovalPreview extends LightningElement {
	@api recordId;
	@track comments;
	@track wrapper;
	@track error;
	@track loading;
	@track avatarUrl;
	@track showRecallModal;
	approvalListUrl;
	alreadyInApproval = false;

	connectedCallback() {
		if (!this.wrapper) {
			this.loading = true;
			this.fetchData();
		}
		this.avatarUrl = RESOURCE + "/img/avatar1.jpg";
		this.approvalListUrl = `/lightning/r/${this.recordId}/related/ProcessSteps/view`;
	}

	render() {
		if (this.error) {
			return errorHTML;
		} else if (this.alreadyInApproval) {
			return alreadyInApprovalHTML;
		}

		return approvalPreviewHTML;
	}

	fetchData() {
		runPreview({ recordId: this.recordId })
			.then(result => {
				this.wrapper = result;
				if (this.wrapper.isError) {
					this.error = this.wrapper.errorMsg;
				} else if (this.wrapper.alreadyInApproval) {
					this.alreadyInApproval = true;

					for (let step of this.wrapper.approvalSteps) {
						if (step.isAlreadyApproved !== true) {
							step.isFirstWorkItem = true;
							break;
						}
					}
				}
				this.loading = false;
			})
			.catch(error => {
				this.error = "Something went wrong! Please reach out to your System Administrator for assistance.";
				console.error("Error in runPreview " + JSON.stringify(error));
				this.loading = false;
			});
	}

	submitRecord() {
		this.loading = true;

		submitForApproval({
			recordId: this.recordId,
			comments: this.comments
		})
			.then(result => {
				if (result.isError) {
					this.error = result.errorMsg;
				} else {
					//success
					this.dispatchEvent(
						new ShowToastEvent({
							title: "Success",
							message: "Record is submitted for approval",
							variant: "success"
						})
					);
					this.handleClose();
				}
				this.loading = false;
			})
			.catch(error => {
				this.error = error;
				console.error("Error in submitForApproval " + JSON.stringify(error));
				this.loading = false;
			});
	}

	handleComments(event) {
		this.comments = event.target.value;
	}

	showRecall() {
		this.comments = "";
		this.showRecallModal = true;
	}

	hideRecall() {
		this.showRecallModal = false;
	}

	handleRecall() {
		this.loading = true;
		this.hideRecall();

		recallApproval({
			recordId: this.recordId,
			comments: this.comments
		})
			.then(result => {
				if (result.isError) {
					this.error = result.errorMsg;
				} else {
					//success
					this.dispatchEvent(
						new ShowToastEvent({
							title: "Success",
							message: "Approval request is recalled",
							variant: "success"
						})
					);
					this.handleClose();
				}
				this.loading = false;
			})
			.catch(error => {
				this.error = error;
				console.error("Error in recallApproval " + JSON.stringify(error));
				this.loading = false;
			});
	}

	handleUserClick(event) {
		let userId = event.target.dataset.userId;
		if (userId) {
			window.open("/" + userId, "_blank");
		}
	}

	handleStatusClick() {
		window.open(`/lightning/r/${this.recordId}/related/ProcessSteps/view`, "_blank");
	}

	handleClose() {
		this.dispatchEvent(
			new CustomEvent("closeaction", {
				bubbles: true,
				composed: true
			})
		);
	}
}