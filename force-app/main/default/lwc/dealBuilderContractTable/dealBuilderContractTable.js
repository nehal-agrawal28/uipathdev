/* eslint-disable eqeqeq */
/* eslint-disable @lwc/lwc/no-async-operation */
/* eslint-disable no-unused-vars */
/* eslint-disable dot-notation */
/* eslint-disable no-console */
import { LightningElement, api, track } from "lwc";
import { subscribe, unsubscribe } from "lightning/empApi";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getData_Apex from "@salesforce/apex/DealBuilderTableController.getData";
import hasManageUpliftPermission from "@salesforce/customPermission/CPQ_Uplift_Renewals";
import hasRipReplacePermission from "@salesforce/customPermission/CPQ_Rip_Replace";

import { processActiveContracts } from "./processActiveContracts.js";

export default class DealBuilderContractTable extends LightningElement {
  @api accountId;

  // action buttons <true/false>
  @api actionManageUplift;
  @api actionRipReplace;

  type = "Active_Contracts";
  dataList;
  @track tableData;
  @track tableTitle;
  @track tableSubTitle;
  @track tableTitleIcon;
  @track tableNoDataMessage;
  @track showFlag;

  @track actionManageUpliftIsActive;
  @track actionRipReplaceIsActive;

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
  @track errorOccuredInJob = false;
  @track goToNewQuoteCardHeading;
  @track goToNewQuoteCardDesc;

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
    // Active_Contracts
    this.tableData = processActiveContracts(result);
    this.setupDataOnRefresh();
    this.tableTitle = "All Contracts";
    this.tableNoDataMessage = "No Contract";
  }

  // Used to temporarily mark each selected / edited contract as 'Updating'.
  markContractUpdating(event) {
    try {
      console.log("event markContractUpdating processing...");

      this.ripReplaceQuoteId = event.detail.quoteId;
      this.ripReplaceQuoteName = event.detail.quoteName;
      this.ripReplaceOpportunityId = event.detail.opportunityId;
      this.ripReplaceOpportunityId = event.detail.error;
      this.ripReplaceJobs = event.detail.jobs;

      this.showFlag = true;

      for (let i = 0; i < this.ripReplaceSelectedContractIds.length; i++) {
        for (let j = 0; j < this.tableData.rows.length; j++) {
          // console.log("this.tableData.rows[j]", JSON.stringify(this.tableData.rows[j]));
          if (this.ripReplaceSelectedContractIds[i] === this.tableData.rows[j].key) {
            console.log("*******MATCHED*******");
            this.tableData.rows[j].updateInProgress = true;
            this.tableData.rows[j].customRowClass = "slds-hint-parent orange-background";
            this.tableData.rows[j].flag = {
              inprogressFlag: true,
              message: "Job is running in the background to generate cancellation quote for this contract"
            };
            // Put this object in front of the array, so the all appear on top.
            let item = this.tableData.rows.splice(j, 1); // removes the current object.
            this.tableData.rows.unshift(item[0]); // adds it back to the beginning.
          }
        }
      }

      //force rerender
      this.forceTableRerender();

      // Callback invoked whenever a new event message is received
      const messageCallback = (response) => {
        console.log(this.channelName + "callback>>>", JSON.stringify(response.data));
        this.contractIsDoneUpdating(response);
      };
      // Invoke subscribe method of empApi. Pass reference to messageCallback
      subscribe(this.channelName, -1, messageCallback);
    } catch (e) {
      console.error(e);
      throw e;
    }
  }

  // Used to unmark contracts one by one, as they are done updating.
  contractIsDoneUpdating(response) {
    let contractId = response.data.payload.ContractId__c;
    let error = response.data.payload.Error__c;
    for (let i = 0; i < this.tableData.rows.length; i++) {
      // Splice removes quotes here.
      if (contractId == this.tableData.rows[i].key) {
        if (error) {
          this.errorOccuredInJob = true;
          this.tableData.rows[i].flag = {
            errorFlag: true,
            message: "Error occurred : " + error
          };
        } else {
          this.tableData.rows[i].customRowClass = "slds-hint-parent";
          this.tableData.rows[i].flag = {
            successFlag: true,
            message: "Cancellation quote has been generated and products were added into the replacement quote."
          };
        }
        this.tableData.rows[i].updateInProgress = false;
        break;
      }
    }

    // When there are no more jobs left to listen to, finish everything up and unsub.
    let unProcessedRecords = this.tableData.rows.filter((contract) => {
      return contract.updateInProgress === true;
    });

    if (unProcessedRecords.length === 0) {
      if (this.errorOccuredInJob) {
        this.goToNewQuoteCardHeading =
          "Replacement quote " + this.ripReplaceQuoteName + " generated with <span style='color:red;'>errors</span>";
        this.goToNewQuoteCardDesc =
          "Contracts with an error against them below have not been included on the Replacement quote";
      } else {
        this.goToNewQuoteCardHeading = "Replacement quote " + this.ripReplaceQuoteName + " generated successfully";
        this.goToNewQuoteCardDesc = "Cancellation quotes have been generated for the selected contracts";
      }
      this.displayGoToNewQuoteCard = true;
      console.log("setting displayGoToNewQuoteCard");

      // leaving a blank callback, we are not doing anything when we unsubscribe
      const messageCallback = (res) => {
        console.log("unsubscribe response: " + res);
      };
      unsubscribe(this.channelName, -1, messageCallback);

      if (!this.errorOccuredInJob) {
        setTimeout(() => {
          // reset row UI and rerender table
          for (let row of this.tableData.rows) {
            row.customRowClass = "slds-hint-parent";
            row.flag = null;
          }
          this.showFlag = false;
          this.forceTableRerender();
        }, 5000);
      }
    }

    //force rerender
    this.forceTableRerender();
  }

  forceTableRerender() {
    this.tableData = JSON.parse(JSON.stringify(this.tableData));
  }

  setupDataOnRefresh() {
    for (let i = 0; i < this.tableData.rows.length; i++) {
      this.tableData.rows[i].updateInProgress = false;
      this.tableData.rows[i].customRowClass = "slds-hint-parent";
    }
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
    if (hasRipReplacePermission) {
      let table = this.template.querySelector("c-deal-builder-data-table");
      if (table) {
        this.ripReplaceSelectedContractIds = table.selectedRowKeys();
      }

      if (this.ripReplaceSelectedContractIds && this.ripReplaceSelectedContractIds.length > 0) {
        this.displayGoToNewQuoteCard = false;
        this.errorOccuredInJob = false;
        if (this.ripReplaceSelectedContractIds.length > 30) {
          this.showToast("Error", "Maximum 30 contracts are allowed in Rip & Replace transaction", "error");
          this.actionRipReplaceIsActive = false;
        } else {
          this.actionRipReplaceIsActive = true;
        }
      } else {
        this.showToast("Error", "Please select contract(s)", "error");
      }
    } else {
      this.showToast(
        "Error",
        "Sorry you do not have the necessary system permission to initiate Rip & Replace transaction",
        "error"
      );
    }
  }

  actionManageUpliftDeactivate() {
    this.actionManageUpliftIsActive = false;
  }

  actionRipReplaceDectivate() {
    this.actionRipReplaceIsActive = false;
  }

  toggleHierarchicalContracts(event) {
    let checked = event.detail.checked;
    if (checked) {
      this.type = "Active_Contracts_Within_Hierarchy";
    } else {
      this.type = "Active_Contracts";
    }
    this.fetchTableData();
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