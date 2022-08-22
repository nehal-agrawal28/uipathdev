/* eslint-disable @lwc/lwc/no-async-operation */
import { LightningElement, api } from "lwc";
import assignApprovalToMeApex from "@salesforce/apex/ApprovalAssignToMeController.assignApprovalToMe";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

export default class ApprovalAssignToMe extends LightningElement {
  @api recordId;
  invoked = false;

  @api invoke() {
    if (this.invoked || !this.recordId) {
      return;
    }

    this.invoked = true;

    assignApprovalToMeApex({
      approvalId: this.recordId
    })
      .then((result) => {
        if (result.success) {
          this.showToast("Success", result.message, "success");
          setTimeout(() => {
            window.location.reload();
          }, 1000);
        } else {
          this.showToast("Error", result.message, "error");
        }
      })
      .catch((error) => {
        this.showToast("Error", "Something went wrong", "error");
        console.error("Error: " + JSON.stringify(error));
      });
  }

  showToast(title, message, variant) {
    const evt = new ShowToastEvent({
      title: title,
      message: message,
      variant: variant
    });
    this.dispatchEvent(evt);
  }
}