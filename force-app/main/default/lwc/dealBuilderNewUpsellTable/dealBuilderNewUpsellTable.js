/* eslint-disable no-console */
import { LightningElement, api, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getData_Apex from "@salesforce/apex/DealBuilderTableController.getData";
import { processNewBusinessUpsell } from "./processNewBusinessUpsell.js";

export default class DealBuilderNewUpsellTable extends LightningElement {
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
      type: "New_Business_Upsell"
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
    // New_Business_Upsell
    this.tableData = processNewBusinessUpsell(result);
    this.tableTitle = "New Business/Upsell (Brand New Contract)";
    this.tableSubTitle = "Including past 3 years and future opportunities";
    // this.tableTitleIcon = "standard:opportunity";
    this.tableNoDataMessage = "No New Business/Upsell Opportunities";
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