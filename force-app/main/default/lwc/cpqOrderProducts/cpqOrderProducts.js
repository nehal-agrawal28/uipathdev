/* eslint-disable no-console */
import { LightningElement, wire, track, api } from "lwc";
// import { refreshApex } from "@salesforce/apex";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getInitialData from "@salesforce/apex/CPQOrderProductsController.getInitialData";
import saveOrderProducts from "@salesforce/apex/CPQOrderProductsController.saveOrderProducts";

export default class CpqOrderProducts extends LightningElement {
	@api recordId;
	initialData;
	@track error;
	@track order;
	@track productList;
	@track deploymentList;
	@track orchestrationTypeList;
	@track fieldPermissionMap;
	@track showSpinner = true;
	@track showSave = false;
	orderItems;
	requiredById; 

  // commented beacuse of cache issue
	// @wire(getInitialData, { orderId: "$recordId" })
	// getInitialData(response) {
	// 	// Hold on to the provisioned value so we can refresh it later.
	// 	this.initialData = response;
	// 	if (response.data) {
	// 		this.order = response.data.order;
	// 		this.productList = response.data.productList;
	// 		this.deploymentList = response.data.deploymentList;
	// 		this.orderItems = JSON.parse(JSON.stringify(response.data.orderItems)); //wire returns readonly

	// 		this.fieldPermissionMap = {};
	// 		for (let fls of response.data.fieldPermissionList) {
	// 			if (fls.value === "true") {
	// 				this.fieldPermissionMap[fls.label] = true;
	// 				this.showSave = true;
	// 			} else {
	// 				this.fieldPermissionMap[fls.label] = false;
	// 			}
	// 		}
	// 	} else if (response.error) {
	// 		this.error = response.error;
	// 		console.error("Error: " + JSON.stringify(response.error));
	// 	}
	// 	this.showSpinner = false;
	// }

	connectedCallback() {
		this.fetchInitialData();
  }
  
  fetchInitialData(){
    getInitialData({ orderId: this.recordId })
    .then(result => {
      if (result) {
        this.order = result.order;
        this.productList = result.productList;
		this.deploymentList = result.deploymentList;
		this.orchestrationTypeList = result.orchestrationTypeList;
        this.orderItems = result.orderItems;

        this.fieldPermissionMap = {};
        for (let fls of result.fieldPermissionList) {
          if (fls.value === "true") {
            this.fieldPermissionMap[fls.label] = true;
            this.showSave = true;
          } else {
            this.fieldPermissionMap[fls.label] = false;
          }
        }
      }

      setTimeout(()=>{
        this.showSpinner = false;
      },1000);
    })
    .catch(error => {
      this.error = error;
      console.error("Error: " + JSON.stringify(error));
      this.showSpinner = false;
    });
  }

	handleSave() {
		this.showSpinner = true;
		saveOrderProducts({
			orderItems: this.orderItems
		})
			.then(() => {
				this.showSpinner = false;
				this.fetchInitialData();

				this.dispatchEvent(
					new ShowToastEvent({
						title: "Success",
						message: "Order products updated successfully",
						variant: "success"
					})
				);

				this.handleClose();
			})
			.catch(error => {
				console.error("Error: " + JSON.stringify(error));
				this.dispatchEvent(
					new ShowToastEvent({
						title: "Error",
						message: "Something went wrong while updating data",
						variant: "error"
					})
				);
			});
	}

	handleClose() {
		this.dispatchEvent(
			new CustomEvent("closeaction", {
				bubbles: true,
				composed: true
			})
		);
	}

	handleDataChange(event) {
		for (let item of this.orderItems) {
			if (item.Id === event.detail.Id) {
				item[event.detail.field] = event.detail.value;
				break;
			}
		}
	}
}