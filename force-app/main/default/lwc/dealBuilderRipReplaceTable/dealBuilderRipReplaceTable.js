/* eslint-disable no-console */
import { LightningElement, api, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getData_Apex from "@salesforce/apex/DealBuilderTableController.getData";
import retryJob_Apex from "@salesforce/apex/DealBuilderContractsController_DB.retryJob";
import { processRiplacementData } from "./processRiplacementData.js";

export default class DealBuilderMergedTable extends LightningElement {
  @api accountId;

  dataList;
  @track tableData;
  @track tableTitle;
  @track tableSubTitle;
  @track tableTitleIcon;
  @track tableNoDataMessage;
  @track showSpinner;

  connectedCallback() {
    this.fetchTableData();
  }

  fetchTableData() {
    this.tableData = null;

    getData_Apex({
      accountId: this.accountId,
      type: "Rip_Replace_Transactions"
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
    // Rip_Replace_Transactions
    this.tableData = processRiplacementData(result);
    this.tableTitle = "Rip & Replace Transactions";
    this.tableSubTitle = "Expand the row to find contracts replaced by the transaction";
    // this.tableTitleIcon = "standard:branch_merge";
    this.tableNoDataMessage = "No Rip & Replace Transaction";
  }

  refreshAllData() {
    this.dispatchEvent(new CustomEvent("refreshalldata"));
  }

  refreshCurrentData() {
    this.fetchTableData();
  }

  handleTableRowAction(event) {
    if (event.detail && event.detail.value === "RetryAsyncTask" && event.detail.rowKey) {
      this.retryCancellationJob(event.detail.rowKey);
    }
  }

  retryCancellationJob(taskId) {
    this.showToast("Retrying Job", "System will retrigger contract cancellation job", "info");
    this.showSpinner = true;

    retryJob_Apex({
      asyncTaskId: taskId
    })
      .then(() => {
        this.showSpinner = false;
        this.refreshCurrentData();
      })
      .catch((error) => {
        this.showSpinner = false;
        this.showToast(
          "Error",
          "Something went wrong while retrying job. Please contact system administrator.",
          "error"
        );
        console.error("Error DealBuilderContractsController_DB.retryJob: " + JSON.stringify(error));
        throw error;
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