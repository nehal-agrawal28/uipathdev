/* eslint-disable no-console */
import { LightningElement, api, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { NavigationMixin } from "lightning/navigation";
import getInitialData_Apex from "@salesforce/apex/DealBuilderOppController.getInitialData";

export default class DealBuilderOppModal extends NavigationMixin(LightningElement) {
  @api accountId;

  @track oppFormLoaded;
  @track askConfirmation;
  @track oppFields;
  @track cpqDefaultRT;
  @track currentAccount;
  @track creditHoldMessage;
  @track showSpinner;
  @track isAcknowledged;

  connectedCallback() {
    this.fetchInitialData();
  }

  fetchInitialData() {
    this.showSpinner = true;

    getInitialData_Apex({
      accountId: this.accountId
    })
      .then((result) => {
        if (result) {
          this.askConfirmation = result.askConfirmation;
          this.oppFields = result.oppFields;
          this.cpqDefaultRT = result.cpqDefaultRT;
          this.currentAccount = result.currentAccount;

          if (this.currentAccount.Credit_Hold__c === "On") {
            this.creditHoldMessage =
              "This Company is on Credit Hold - The opportunity will only close if Finance approves.";
          }
        }
        this.showSpinner = false;
      })
      .catch((error) => {
        this.showToast("Error", "Something went wrong while fetching data", "error");
        console.error("Error DealBuilderOppController.getInitialData: " + error);
        this.showSpinner = false;
      });
  }

  handleAcknowledged(event) {
    if (event && event.target && event.target.checked) {
      this.isAcknowledged = true;
    } else {
      this.isAcknowledged = false;
    }
  }

  handleConfirmation() {
    this.askConfirmation = false;
  }

  handleLoad() {
    this.oppFormLoaded = true;
  }

  handleSubmit() {
    this.showSpinner = true;
    this.showToast("Please wait", "We are creating a new Opportunity", "info");
  }

  handleError() {
    this.showSpinner = false;
  }

  handleSuccess(event) {
    this.showToast("Success", "Your new Opportunity is ready", "success");
    let oppId = event.detail.id;
    if (oppId) {
      this[NavigationMixin.Navigate]({
        type: "standard__recordPage",
        attributes: {
          actionName: "view",
          recordId: oppId
        }
      });
    }
    this.showSpinner = false;
  }

  hideOpportunityModal() {
    this.dispatchEvent(new CustomEvent("hidemodal"));
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