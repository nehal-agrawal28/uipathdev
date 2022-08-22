/* eslint-disable no-console */
import { LightningElement, api, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getUpliftDataForDealBuilder_Apex from "@salesforce/apex/RenewalUpliftManagementController.getUpliftDataForDealBuilder";
import setAccountMethodUplift_Apex from "@salesforce/apex/RenewalUpliftManagementController.setAccountMethodUplift";
import applyRenewalUplift_Apex from "@salesforce/apex/RenewalUpliftManagementController.applyRenewalUplift";
import removeRenewalUplift_Apex from "@salesforce/apex/RenewalUpliftManagementController.removeRenewalUplift";

export default class DealBuilderManageUpliftModal extends LightningElement {
  @api contractIds;

  contractList;
  @track showContractTable;
  @track contractTableColumns;
  @track contractTableRows;
  @track showSpinner;
  @track error;
  @track requireRefreshOnClose;
  @track ARRTotal;
  @track upliftGeoConfig;
  @track accountGeo;
  @track accountUpliftMethod;

  connectedCallback() {
    if (this.contractIds && this.contractIds.length > 0) {
      this.fetchInitialData();
    }
  }

  fetchInitialData() {
    this.showSpinner = true;
    this.showContractTable = false;
    this.error = null;
    this.ARRTotal = 0;

    getUpliftDataForDealBuilder_Apex({
      contractIds: this.contractIds
    })
      .then(result => {
        if (result) {
          this.buildContractTable(result.contractList);
          this.upliftGeoConfig = result.upliftGeoConfig;
          this.accountGeo = result.accountGeo;
          this.accountUpliftMethod = result.accountUpliftMethod;
        }
        this.showSpinner = false;
      })
      .catch(error => {
        this.showToast("Error", "Something went wrong while fetching data", "error");
        console.error("Error getUpliftDataForDealBuilder_Apex: " + JSON.stringify(error));
        this.showSpinner = false;
      });
  }

  buildContractTable(contractList) {
    this.contractList = contractList;
    this.contractTableColumns = [];
    this.contractTableRows = [];

    this.contractTableColumns.push({ key: "Contract", label: "Contract" });
    this.contractTableColumns.push({ key: "ContractUpliftEnabled", label: "Contract Uplift Enabled" });
    this.contractTableColumns.push({ key: "Uplift%", label: "Current Uplift %" });
    this.contractTableColumns.push({ key: "UpliftExceptionReason", label: "Uplift Exception Reason" });
    this.contractTableColumns.push({ key: "ARRtoRenew,", label: "ARR To Renew" });

    for (let contract of this.contractList) {
      let row = { key: contract.Id, cellData: [] };
      row.cellData.push({
        key: contract.Id + "ContractNumber",
        data: contract.ContractNumber,
        isLookup: true,
        lookupId: contract.Id
      });
      row.cellData.push({
        key: contract.Id + "ContractUpliftEnabled",
        data: contract.Contract_Uplift_Enabled__c,
        isCheckbox: true
      });
      row.cellData.push({
        key: contract.Id + "Uplift%",
        data: contract.SBQQ__RenewalUpliftRate__c,
        isText: true
      });
      row.cellData.push({
        key: contract.Id + "UpliftExceptionReason",
        data: contract.Uplift_Exception_Reason__c,
        isText: true
      });
      row.cellData.push({
        key: contract.Id + "ARRtoRenew",
        data: contract.ARR_to_Renew_USD__c,
        isCurrency: true
      });

      this.contractTableRows.push(row);
      this.ARRTotal = !isNaN(contract.ARR_to_Renew_USD__c)
        ? parseFloat(contract.ARR_to_Renew_USD__c) + this.ARRTotal
        : this.ARRTotal;
    }

    this.showContractTable = true;
  }

  applyUplift() {
    this.showSpinner = true;
    let acountsNeedUpliftMethod = [];

    // prepare inputs
    for (let contract of this.contractList) {
      if (contract.Account.SBQQ__RenewalPricingMethod__c !== "Uplift") {
        acountsNeedUpliftMethod.push(contract.AccountId);
      }
    }

    if (acountsNeedUpliftMethod.length > 0) {
      setAccountMethodUplift_Apex({
        acountsNeedUpliftMethod: acountsNeedUpliftMethod
      })
        .then(() => {
          // uplift applying
          this.applyingUplift();
        })
        .catch(error => {
          this.error =
            "Something went wrong while applying uplift." +
            " Please try again with a smaller set of contracts or contact your administrator.";
          console.error("Error setAccountMethodUplift_Apex: " + JSON.stringify(error));
          this.showSpinner = false;
        });
    } else {
      this.applyingUplift();
    }
  }

  applyingUplift() {
    this.showSpinner = true;

    applyRenewalUplift_Apex({
      contractIds: this.contractIds,
      bypassThresholdValidation: true
    })
      .then(() => {
        this.showSpinner = false;
        this.requireRefreshOnClose = true;
        // uplift applying
        this.fetchInitialData();
      })
      .catch(error => {
        this.error =
          "Something went wrong while applying uplift." +
          " Please try again with a smaller set of contracts or contact your administrator.";
        console.error("Error applyRenewalUplift_Apex: " + JSON.stringify(error));
        this.showSpinner = false;
      });
  }

  removeUplift() {
    this.showSpinner = true;

    removeRenewalUplift_Apex({
      contractIds: this.contractIds
    })
      .then(() => {
        this.showSpinner = false;
        this.requireRefreshOnClose = true;
        // refresh UI
        this.fetchInitialData();
      })
      .catch(error => {
        this.error =
          "Something went wrong while removing uplift." +
          " Please try again with a smaller set of contracts or contact your administrator.";
        console.error("Error removeRenewalUplift_Apex: " + JSON.stringify(error));
        this.showSpinner = false;
      });
  }

  onrefreshcurrentdata() {
    this.dispatchEvent(new CustomEvent("refreshcurrentdata"));
  }

  hideModal() {
    if (this.requireRefreshOnClose) {
      this.onrefreshcurrentdata();
    }
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