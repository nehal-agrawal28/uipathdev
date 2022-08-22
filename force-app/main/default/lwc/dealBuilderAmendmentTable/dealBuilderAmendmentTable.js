/* eslint-disable no-console */
import { LightningElement, api, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getData_Apex from "@salesforce/apex/DealBuilderTableController.getData";
import { processOpenAmendments } from "./processOpenAmendments.js";

export default class DealBuilderAmendmentTable extends LightningElement {
  @api accountId;

  dataList;
  @track tableData;
  @track tableTitle;
  @track tableSubTitle;
  @track tableTitleIcon;
  @track tableNoDataMessage;

  connectedCallback() {
    this.fetchTableData();
  }

  fetchTableData() {
    this.tableData = null;

    getData_Apex({
      accountId: this.accountId,
      type: "Open_Amendments"
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
    // Open_Amendments
    this.tableData = processOpenAmendments(result);
    this.tableTitle = "Open Amendments Opportunities";
    // this.tableTitleIcon = "standard:checkout";
    this.tableNoDataMessage = "No Open Amendments Opportunities";
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