/* eslint-disable @lwc/lwc/no-async-operation */
/* eslint-disable no-console */
import { LightningElement, api, track } from "lwc";
import getUpliftData_Apex from "@salesforce/apex/RenewalUpliftManagementController.getUpliftData";
import uncheckRenewalQuoted_Apex from "@salesforce/apex/RenewalUpliftManagementController.uncheckRenewalQuoted";
import setAccountMethodUplift_Apex from "@salesforce/apex/RenewalUpliftManagementController.setAccountMethodUplift";
import applyRenewalUplift_Apex from "@salesforce/apex/RenewalUpliftManagementController.applyRenewalUplift";
import removeRenewalUplift_Apex from "@salesforce/apex/RenewalUpliftManagementController.removeRenewalUplift";
import { FlowAttributeChangeEvent, FlowNavigationNextEvent } from "lightning/flowSupport";

export default class RenewalUpliftManagement extends LightningElement {
  @api availableActions = [];
  @api opportunityId;
  @api isNewQuote;
  @track showSpinner;
  @track error;
  @track opportunity;
  @track upliftGeoConfig;
  @track blankQuote;

  connectedCallback() {
    this.fetchUpliftData();
  }

  fetchUpliftData() {
    if (!this.opportunityId) {
      this.error = "Opportunity Id is missing";
    }

    this.showSpinner = true;
    this.error = null;
    getUpliftData_Apex({
      opportunityId: this.opportunityId
    })
      .then((result) => {
        if (result.opportunity && result.opportunity.SBQQ__RenewedContract__c) {
          this.opportunity = result.opportunity;
          this.upliftGeoConfig = result.upliftGeoConfig;
          this.opportunity.AccountLink = "/" + this.opportunity.AccountId;
          this.opportunity.RenewedContractLink = "/" + this.opportunity.SBQQ__RenewedContract__c;
        } else {
          this.error = "This opportunity is not renewing any contract";
        }
        this.showSpinner = false;
      })
      .catch((error) => {
        this.error = JSON.stringify(error);
        this.showSpinner = false;
        console.error("Error in getUpliftData_Apex: " + error);
      });
  }

  applyUplift() {
    this.showSpinner = true;
    let acountsNeedUpliftMethod = [];

    // prepare inputs
    if (this.opportunity.Account.SBQQ__RenewalPricingMethod__c !== "Uplift") {
      acountsNeedUpliftMethod.push(this.opportunity.AccountId);
    }

    if (acountsNeedUpliftMethod.length > 0) {
      setAccountMethodUplift_Apex({
        acountsNeedUpliftMethod: acountsNeedUpliftMethod
      })
        .then(() => {
          // uplift applying
          this.applyingUplift();
        })
        .catch((error) => {
          this.error = "Something went wrong while applying uplift. Please try again or contact your administrator.";
          this.showSpinner = false;
          console.error("Error in setAccountMethodUplift_Apex: " + JSON.stringify(error));
        });
    } else {
      this.applyingUplift();
    }
  }

  newBlankQuote() {
    this.showSpinner = true;
    const attributeChangeEvent = new FlowAttributeChangeEvent("isNewQuote", true);
    this.dispatchEvent(attributeChangeEvent);
    setTimeout(() => {
      // allow attribute change to propagate
      this.handleGoNext();
    }, 1000);
  }

  newRenewalQuote() {
    this.showSpinner = true;
    uncheckRenewalQuoted_Apex({
      opportunityId: this.opportunityId
    })
      .then(() => {
        this.showSpinner = false;
        this.handleGoNext();
      })
      .catch((error) => {
        this.error = "Something went wrong. Please try again or contact your salesforce administrator.";
        this.showSpinner = false;
        console.error("Error in uncheckRenewalQuoted_Apex: " + JSON.stringify(error));
      });
  }

  handleGoNext() {
    if (this.availableActions.find((action) => action === "NEXT")) {
      // navigate to the next screen
      const navigateNextEvent = new FlowNavigationNextEvent();
      this.dispatchEvent(navigateNextEvent);
    }
  }

  applyingUplift() {
    this.showSpinner = true;
    let contractIds = [];

    // prepare inputs
    contractIds.push(this.opportunity.SBQQ__RenewedContract__c);

    applyRenewalUplift_Apex({
      contractIds: contractIds,
      bypassThresholdValidation: false
    })
      .then(() => {
        this.showSpinner = false;
        // refresh UI
        this.fetchUpliftData();
      })
      .catch((error) => {
        this.error = "Something went wrong while applying uplift. Please try again or contact your administrator.";
        this.showSpinner = false;
        console.error("Error in applyRenewalUplift_Apex: " + JSON.stringify(error));
      });
  }

  removeUplift() {
    this.showSpinner = true;
    let contractIds = [];

    // prepare inputs
    contractIds.push(this.opportunity.SBQQ__RenewedContract__c);

    removeRenewalUplift_Apex({
      contractIds: contractIds
    })
      .then(() => {
        this.showSpinner = false;
        // refresh UI
        this.fetchUpliftData();
      })
      .catch((error) => {
        this.error = "Something went wrong while removing uplift. Please try again or contact your administrator.";
        this.showSpinner = false;
        console.error("Error in removeRenewalUplift_Apex: " + JSON.stringify(error));
      });
  }
}