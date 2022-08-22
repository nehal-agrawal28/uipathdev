/* eslint-disable no-console */
import { LightningElement, api, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { NavigationMixin } from "lightning/navigation";
import getInitialData_Apex from "@salesforce/apex/DealBuilderRenewViaController.getInitialData";
import updateContracts_Apex from "@salesforce/apex/DealBuilderRenewViaController.updateContracts";

export default class DealBuilderRenewViaModal extends NavigationMixin(LightningElement) {
	@api accountId;
	@api contractIds;
	@api selectedOppIds;

	oppList;
	@track showSpinner;
	@track columnData;
	@track rowData;
	@track error;

	connectedCallback() {
		if (this.accountId && this.contractIds && this.contractIds.length > 0) {
			this.fetchInitialData();
		}
	}

	fetchInitialData() {
		this.showSpinner = true;

		getInitialData_Apex({
			accountId: this.accountId
		})
			.then(result => {
				if (result) {
					this.oppList = result.oppList;

					this.columnData = [
						{ key: "Name", label: "Name" },
						{ key: "Stage", label: "Stage" },
						{ key: "CloseDate", label: "Close Date" }
					];
					this.rowData = [];

					for (let opp of this.oppList) {
						let row = {
							key: opp.Id,
							selected: false,
							cellData: [
								{ key: opp.Id + "Name", data: opp.Name, isLookup: true, lookupId: opp.Id },
								{ key: opp.Id + "Stage", isText: true, data: opp.StageName },
								{ key: opp.Id + "CloseDate", isDate: true, data: opp.CloseDate }
							]
						};
						this.rowData.push(row);
					}
				}
				this.showSpinner = false;
			})
			.catch(error => {
				this.showToast("Error", "Something went wrong while fetching data", "error");
				console.error("Error DealBuilderRenewViaController.getInitialData: " + error);
				this.showSpinner = false;
			});
	}

	handleSubmit() {
		let table = this.template.querySelector("c-deal-builder-data-table");
		if (table) {
			let selectedKeyList = table.selectedRowKeys();
			if (selectedKeyList && selectedKeyList[0]) {
				let selectedOpp = selectedKeyList[0];

				this.updateContracts(selectedOpp);
			} else {
				this.showToast("Error", "Please select a renew opportunity and try again", "error");
			}
		}
	}

	updateContracts(oppId) {
		this.showSpinner = true;
		this.error = null;
		let contractIdsSetArray = [...new Set(this.contractIds)];

		updateContracts_Apex({
			contractIds: contractIdsSetArray,
			selectedOppIds: this.selectedOppIds,
			oppId: oppId
		})
			.then((result) => {
				if(result.isSuccess){
					this.refreshAllData();
				}
				else{
					this.error = result;
				}
				this.showSpinner = false;
			})
			.catch(error => {
				this.showToast("Error", "Something went wrong while updating contracts", "error");
				console.error("Error DealBuilderRenewViaController.updateContracts: " + JSON.stringify(error));
				this.showSpinner = false;
			});
	}

	refreshAllData() {
		this.dispatchEvent(new CustomEvent("refreshalldata"));
	}

	hideModal() {
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