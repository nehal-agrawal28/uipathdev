/* eslint-disable no-console */
import { LightningElement, api, track } from "lwc";
import { subscribe, unsubscribe } from "lightning/empApi";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getData_Apex from "@salesforce/apex/DealBuilderTableController.getData";
import hasRenewViaPermission from "@salesforce/customPermission/CPQ_Redirect_Renewals";
import hasManageUpliftPermission from "@salesforce/customPermission/CPQ_Uplift_Renewals";

import { processRenewalsOfContracts } from "./processRenewalsOfContracts.js";
import { processOtherRenewals } from "./processOtherRenewals.js";
import { processNewBusinessUpsell } from "./processNewBusinessUpsell.js";
import { processOpenAmendments } from "./processOpenAmendments.js";
import { processActiveContracts } from "./processActiveContracts.js";

export default class DealBuilderTableWrapper extends LightningElement {
  @api accountId;
  @api type; // check processTableData() method

  // action buttons <true/false>
  @api actionRenewVia;
  @api actionManageUplift;
  @api actionRipReplace;

  dataList;
  @track tableData;
  @track tableTitle;
  @track tableSubTitle;
  @track tableTitleIcon;
  @track tableNoDataMessage;

  @track actionRenewViaIsActive;
  @track actionManageUpliftIsActive;
  @track actionRipReplaceIsActive;

  @track renewViaContractIds;
  @track renewViaSelectedOppIds;
  @track manageUpliftSelectedContractIds;
  @track ripReplaceSelectedContractIds;

  //Rip replace status trackers
  @track ripReplaceQuoteId;
  @track ripReplaceQuoteName;
  @track ripReplaceOpportunityId;
  @track ripReplaceJobs;
  @track ripReplaceJobStatuses;
  @track channelName = "/event/ContractModEvent__e";
  @track displayGoToNewQuoteCard = false;

  connectedCallback() {
    this.fetchTableData();
  }

  fetchTableData() {
    this.tableData = null;

    getData_Apex({
      accountId: this.accountId,
      type: this.type
    })
      .then((result) => {
        if (result) {
          this.dataList = result.dataList;
          this.processTableData(result);
        }
      })
      .catch((error) => {
        this.showToast("Error", "Something went wrong while fetching data", "error");
        console.error("Error DealBuilderTableDataProvider.getData: " + error);
        throw error;
      });
  }

  processTableData(result) {
    if (this.type === "Renewals_of_Contracts") {
      this.tableData = processRenewalsOfContracts(result);
      this.tableTitle = "Renewals of Contracts expiring this Fiscal year";
      this.tableTitleIcon = "standard:loop";
      this.tableNoDataMessage = "No Renewals of Contracts expiring this Fiscal year";
    } else if (this.type === "Other_Renewals_Merged") {
      this.tableData = processOtherRenewals(result);
      this.tableTitle = "Merged Renewals";
      this.tableTitleIcon = "standard:branch_merge";
      this.tableNoDataMessage = "No Merged Renewals Opportunities";
    } else if (this.type === "Other_Renewals_NotMerged") {
      this.tableData = processOtherRenewals(result);
      this.tableTitle = "Other Renewals (not in current Fiscal year)";
      this.tableTitleIcon = "standard:entity";
      this.tableNoDataMessage = "No Other Renewals Opportunities";
    } else if (this.type === "New_Business_Upsell") {
      this.tableData = processNewBusinessUpsell(result);
      this.tableTitle = "New Business/Upsell (Brand New Contract)";
      this.tableSubTitle = "Including past 3 years and future opportunities";
      this.tableTitleIcon = "standard:opportunity";
      this.tableNoDataMessage = "No New Business/Upsell Opportunities";
    } else if (this.type === "Open_Amendments") {
      this.tableData = processOpenAmendments(result);
      this.tableTitle = "Open Amendments Opportunities";
      this.tableTitleIcon = "standard:checkout";
      this.tableNoDataMessage = "No Open Amendments Opportunities";
    } else if (this.type === "Active_Contracts") {
      this.tableData = processActiveContracts(result);
      this.setupDataOnRefresh();
      this.tableTitle = "All Contracts";
      this.tableNoDataMessage = "No Contract";
    } else {
      this.tableData = null;
      this.tableTitle = "Table type is unknown";
      this.tableTitleIcon = "standard:generic_loading";
    }
  }

  // Used to temporarily mark each selected / edited contract as 'Updating'.
  markContractUpdating(event) {
    try {
      console.log("event markContractUpdating processing...");

      this.ripReplaceQuoteId = event.detail.quoteId;
      this.ripReplaceQuoteName = event.detail.quoteName;
      this.ripReplaceOpportunityId = event.detail.opportunityId;
      this.ripReplaceJobs = event.detail.jobs;

      for (let i = 0; i < this.ripReplaceSelectedContractIds.length; i++) {
        for (let j = 0; j < this.tableData.rows.length; j++) {
          // console.log("this.tableData.rows[j]", JSON.stringify(this.tableData.rows[j]));
          if (this.ripReplaceSelectedContractIds[i] === this.tableData.rows[j].key) {
            console.log("MATCHED***************");
            this.tableData.rows[j].updateInProgress = true;
            this.tableData.rows[j].customRowClass = "slds-hint-parent orange-background";
            // Put this object in front of the array, so the all appear on top.
            let item = this.tableData.rows.splice(j, 1); // removes the contact object.
            this.tableData.rows.unshift(item[0]); // adds it back to the beginning.
          }
        }
      }
      //force a refresh
      this.tableData = JSON.parse(JSON.stringify(this.tableData));
      // Callback invoked whenever a new event message is received
      const messageCallback = (response) => {
        console.log("callback>>>", JSON.stringify(response.data));
        this.contractIsDoneUpdating(JSON.stringify(response.data.payload["ContractId__c"]));
      };

      // Invoke subscribe method of empApi. Pass reference to messageCallback
      subscribe(this.channelName, -1, messageCallback);
    } catch (e) {
      console.error(e);
      throw e;
    }
  }

  // Used to unmark contracts one by one, as they are done updating.
  contractIsDoneUpdating(contractId) {
    for (let i = 0; i < this.tableData.rows.length; i++) {
      // Splice removes quotes here.
      if (contractId.slice(1, -1) === this.tableData.rows[i].key) {
        this.tableData.rows[i].updateInProgress = false;
        this.tableData.rows[i].customRowClass = "slds-hint-parent";
        // Put this object in end of the array, so the the rest of orange rows appear on top.
        let item = this.tableData.rows.splice(i, 1); // removes the contact object.
        this.tableData.rows.push(item[0]); // adds it back to the end.
      }
    }
    //force child rerender
    this.tableData = JSON.parse(JSON.stringify(this.tableData));

    // When there are no more jobs left to listen to, finish everything up and unsub.
    let unProcessedRecords = this.tableData.rows.filter((contract) => {
      return contract.updateInProgress === true;
    });
    if (unProcessedRecords.length === 0) {
      this.displayGoToNewQuoteCard = true;
      console.log("setting displayGoToNewQuoteCard");
      // leaving a blank callback, we are not doing anything when we unsubscribe
      const messageCallback = (response) => {};
      unsubscribe(this.channelName, -1, messageCallback);
    }
  }

  setupDataOnRefresh() {
    for (let i = 0; i < this.tableData.rows.length; i++) {
      this.tableData.rows[i].updateInProgress = false;
      this.tableData.rows[i].customRowClass = "slds-hint-parent";
    }
  }

  unSelectAllContracts() {
    this.ripReplaceSelectedContractIds = [];
  }

  actionRenewViaActivate() {
    if (hasRenewViaPermission) {
      let table = this.template.querySelector("c-deal-builder-data-table");
      if (table) {
        this.renewViaContractIds = [];

        this.renewViaSelectedOppIds = table.selectedRowKeys();
        for (let opp of this.dataList) {
          if (this.renewViaSelectedOppIds.includes(opp.Id) && opp.SBQQ__RenewedContracts__r) {
            for (let contract of opp.SBQQ__RenewedContracts__r) {
              this.renewViaContractIds.push(contract.Id);
            }
          }
        }
      }

      if (this.renewViaContractIds.length > 0) {
        this.actionRenewViaIsActive = true;
      } else {
        this.showToast("Error", "Please select an Opportunity", "error");
      }
    } else {
      this.showToast("Error", "Sorry you do not have the necessary system permission to redirect renewals", "error");
    }
  }
  actionRenewViaDeactivate() {
    this.actionRenewViaIsActive = false;
  }

  actionManageUpliftActivate() {
    if (hasManageUpliftPermission) {
      let table = this.template.querySelector("c-deal-builder-data-table");
      if (table) {
        this.manageUpliftSelectedContractIds = table.selectedRowKeys();
      }

      if (this.manageUpliftSelectedContractIds.length > 0) {
        this.actionManageUpliftIsActive = true;
      } else {
        this.showToast("Error", "Please select contract(s)", "error");
      }
    } else {
      this.showToast("Error", "Sorry you do not have the necessary system permission to uplift renewals", "error");
    }
  }

  actionRipReplaceActivate() {
    let table = this.template.querySelector("c-deal-builder-data-table");
    if (table) {
      this.ripReplaceSelectedContractIds = table.selectedRowKeys();
    }

    if (this.ripReplaceSelectedContractIds && this.ripReplaceSelectedContractIds.length > 0) {
      this.actionRipReplaceIsActive = true;
      this.displayGoToNewQuoteCard = false;

      this.template.querySelector("c-deal-builder-rip-replace-modal").open();
    } else {
      this.showToast("Error", "Please select contract(s)", "error");
    }
  }

  actionManageUpliftDeactivate() {
    this.actionManageUpliftIsActive = false;
  }

  actionRipReplaceDectivate() {
    this.actionRipReplaceIsActive = false;
  }

  refreshAllData() {
    this.dispatchEvent(new CustomEvent("refreshalldata"));
  }

  refreshCurrentData() {
    this.fetchTableData();
  }

  handleTableRowAction(event) {
    console.log("handleTableRowAction: " + JSON.stringify(event.detail));
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