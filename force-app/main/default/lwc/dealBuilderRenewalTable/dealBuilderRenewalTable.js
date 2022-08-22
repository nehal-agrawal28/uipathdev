/* eslint-disable no-console */
import { LightningElement, api, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getData_Apex from "@salesforce/apex/DealBuilderTableController.getData";
import hasRenewViaPermission from "@salesforce/customPermission/CPQ_Redirect_Renewals";
import { processRenewalsOfContracts } from "./processRenewalsOfContracts.js";

export default class DealBuilderRenewalTable extends LightningElement {
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
      type: "Renewals_of_Contracts"
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
    // Renewals_of_Contracts
    this.tableData = processRenewalsOfContracts(result);
    this.tableTitle = "Renewals of Contracts expiring this Fiscal year";
    // this.tableTitleIcon = "standard:loop";
    this.tableNoDataMessage = "No Renewals of Contracts expiring this Fiscal year";
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