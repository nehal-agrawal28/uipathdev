import { LightningElement, api, track } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getInitialData_Apex from "@salesforce/apex/CPQCloneRecordsController.getInitialData";
import cloneAndSaveRecords_Apex from "@salesforce/apex/CPQCloneRecordsController.cloneAndSaveRecords";
import { CloseActionScreenEvent } from "lightning/actions";

export default class CpqCloneRecords extends NavigationMixin(LightningElement) {
  @api recordId;
  @api objectApiName;

  @track record;
  @track childRelationLabels;
  @track showSpinner;

  connectedCallback() {
    this.fetchInitialData();
  }

  fetchInitialData() {
    this.showSpinner = true;
    getInitialData_Apex({
      recordId: this.recordId,
      objectApiName: this.objectApiName
    })
      .then((result) => {
        if (result) {
          this.record = result.record;
          this.childRelationLabels = result.childRelationLabels;
        }
        this.showSpinner = false;
      })
      .catch((e) => {
        console.error("Error CPQCloneRecordsController.getInitialData: " + JSON.stringify(e));
      });
  }

  handleCancel() {
    this.dispatchEvent(new CloseActionScreenEvent());
  }

  handleSave() {
    let prefix = this.template.querySelector(".prefix").value;
    if (prefix) {
      this.showSpinner = true;
      cloneAndSaveRecords_Apex({
        migrationIdPrefix: prefix,
        recordId: this.recordId,
        objectApiName: this.objectApiName
      })
        .then((result) => {
          this[NavigationMixin.Navigate]({
            type: "standard__recordPage",
            attributes: {
              actionName: "view",
              recordId: result
            }
          });
          this.showSpinner = false;
        })
        .catch((e) => {
          console.error("Error CPQCloneRecordsController.getInitialData: " + JSON.stringify(e));
          this.showToast("Error", "Something went wrong while cloning records", "error");
        });
    } else {
      this.template.querySelector(".prefix").showHelpMessageIfInvalid();
    }
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