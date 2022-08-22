/* eslint-disable no-console */
import { LightningElement, api, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getData_Apex from "@salesforce/apex/DealBuilderTableController.getData";
import hasRenewViaPermission from "@salesforce/customPermission/CPQ_Redirect_Renewals";
import { processOtherRenewals } from "./processOtherRenewals.js";

export default class DealBuilderOtherRenewalTable extends LightningElement {
  @api accountId;

  // action buttons <true/false>
  @api actionRenewVia;

  dataList;
  @track tableData;
  @track tableTitle;
  @track tableSubTitle;
  @track tableTitleIcon;
  @track tableNoDataMessage;

  @track actionRenewViaIsActive;

  @track renewViaContractIds;
  @track renewViaSelectedOppIds;

  connectedCallback() {
    this.fetchTableData();
  }

  fetchTableData() {
    this.tableData = null;

    getData_Apex({
      accountId: this.accountId,
      type: "Other_Renewals_NotMerged"
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
    // Other_Renewals_NotMerged
    this.tableData = processOtherRenewals(result);
    this.tableTitle = "Other Renewals (not in current Fiscal year)";
    // this.tableTitleIcon = "standard:entity";
    this.tableNoDataMessage = "No Other Renewals Opportunities";
  }

  actionRenewViaActivate() {
    if (hasRenewViaPermission) {
      let table = this.template.querySelector(".other-renewal-table");
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