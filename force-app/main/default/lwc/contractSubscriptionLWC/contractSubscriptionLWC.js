import { LightningElement, wire, api, track } from "lwc";
import { CloseActionScreenEvent } from "lightning/actions";
import { refreshApex } from "@salesforce/apex";
import { updateRecord } from "lightning/uiRecordApi";

import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getContractDetail from "@salesforce/apex/ContractSubscriptionController.getContractDetail";
import getExistingSubscription from "@salesforce/apex/ContractSubscriptionController.getSubscription";
import updateSubscription from "@salesforce/apex/ContractSubscriptionController.saveSubscription";
import reportURL from "@salesforce/label/c.Subscription_History_ELA_Swaps";

export default class ContractSubscriptionLWC extends LightningElement {
  @api recordId;
  @track isLoaded = true;
  @track qtyw;
  @track subList = [];
  @track isDataAvailable;
  @track errorMessage;
  @track totalEstSwap = 0;
  @track contract;
  @track currencyISOCode;
  @track reportURL;

  @track showCalculationError = false;
  @track calculationErrorMessage;

  @wire(getContractDetail, {
    contractId: "$recordId"
  })
  wireContract({ error, data }) {
    console.log("--" + data);
    console.log(data);
    if (data) {
      this.contract = data;
      this.reportURL = reportURL + "?fv0=" + this.contract.ContractNumber;
      this.CurrencyIsoCode = this.contract.CurrencyIsoCode;
    }
  }

  @wire(getExistingSubscription, {
    contractId: "$recordId"
  })
  wireSubscriptions({ error, data }) {
    console.log(data);
    console.log(error);
    this.isLoaded = false;
    if (data) {
      if (data.length > 0) {
        this.isDataAvailable = true;
        let mainData = [...data];
        let copyData = JSON.parse(JSON.stringify(mainData));
        for (var i = 0; i < copyData.length; i++) {
          var totalAccum = 0;
          for (var j = 0; j < copyData[i].subscriptions.length; j++) {
            copyData[i].subscriptions[j].accum =
              totalAccum + copyData[i].subscriptions[j].subscription.qtc_Cap_Quantity__c;
            copyData[i].subscriptions[j].currentAccum = copyData[i].subscriptions[j].accum;
            totalAccum = copyData[i].subscriptions[j].accum;
            copyData[i].subscriptions[j].estSwap = 0;
          }
        }
        this.subList = copyData;
      } else {
        this.isDataAvailable = false;
        this.errorMessage =
          "This contract does not contains any subscription related to 'Enterprise License Agreement' Product bundle";
      }
    }
  }

  changeCapQuantity(e) {
    var subListTemp = this.subList;
    let updatedQty = e.target.value;
    console.log(updatedQty);
    let uniqueKey = e.currentTarget.dataset.id;
    let productCode = null; // = e.currentTarget.dataset.productcode;
    console.log(uniqueKey);
    console.log(productCode);

    let items = this.subList;
    let mainData = [...items];
    let copyData = JSON.parse(JSON.stringify(mainData));
    let hasNegativeCapQuantity = false;
    var totalSwapReqeust = 0;
    this.totalEstSwap = 0;
    for (var i = 0; i < copyData.length; i++) {
      var totalAccum = 0;
      for (var j = 0; j < copyData[i].subscriptions.length; j++) {
        //if(parseInt(copyData[i].subscriptions[j].originalCapQuantity) > 0){
        //if(productCode==copyData[i].subscriptions[j].subscription.SBQQ__Product__r.ProductCode){
        //		copyData[i].subscriptions[j].swapRequest = updatedQty;
        //}

        if (uniqueKey == copyData[i].subscriptions[j].subscription.Id) {
          copyData[i].subscriptions[j].swapRequest = updatedQty;
          productCode = copyData[i].subscriptions[j].subscription.SBQQ__Product__r.ProductCode;
        }
        if (copyData[i].subscriptions[j].swapRequest == null) {
          copyData[i].subscriptions[j].swapRequest = 0;
        }
        copyData[i].subscriptions[j].subscription.qtc_Cap_Quantity__c =
          parseInt(copyData[i].subscriptions[j].originalCapQuantity) +
          parseInt(copyData[i].subscriptions[j].swapRequest);
        if (copyData[i].subscriptions[j].subscription.qtc_Cap_Quantity__c < 0) {
          hasNegativeCapQuantity = true;
        }
        totalSwapReqeust = totalSwapReqeust + parseInt(copyData[i].subscriptions[j].swapRequest);

        copyData[i].subscriptions[j].accum = totalAccum + copyData[i].subscriptions[j].subscription.qtc_Cap_Quantity__c;
        totalAccum = copyData[i].subscriptions[j].accum;

        copyData[i].subscriptions[j].estSwap =
          copyData[i].subscriptions[j].swapRequest *
          copyData[i].subscriptions[j].subscription.qtc_Above_the_Cap_Price__c;
        copyData[i].subscriptions[j].subscription.qtc_Current_Cap_Quantity__c = copyData[i].subscriptions[j].accum;

        this.totalEstSwap = this.totalEstSwap + copyData[i].subscriptions[j].estSwap;
        //}
      }
    }
    console.log(this.totalEstSwap);
    /*if(this.totalEstSwap!=0){
						this.showCalculationError=true;
						this.calculationErrorMessage = 'Total Est Swap Qty should be 0';
				}else{
						this.showCalculationError=false;
						this.calculationErrorMessage = '';
				}*/
    if (hasNegativeCapQuantity) {
      //this.showCalculationError=true;
      //this.calculationErrorMessage = 'New Cap Qty can\'t be less than 0';
    } else {
      /*if(totalSwapReqeust==0){
								this.showCalculationError=false;
						}else{
								this.showCalculationError=true;
								this.calculationErrorMessage = 'The Swap Request is mismatching by ' + totalSwapReqeust;
						}*/
    }
    console.log(totalSwapReqeust);
    this.subList = [...copyData];
  }

  cancel(event) {
    const filterChangeEvent = new CustomEvent("closemodal");
    this.dispatchEvent(filterChangeEvent);
  }

  saveOpration(event) {
    console.log("subList--", JSON.stringify(this.subList));
    this.isLoaded = true;
    updateSubscription({ updatedListStr: JSON.stringify(this.subList) }).then((result) => {
      if (result != "Success") {
        this.isLoaded = false;
        const evt = new ShowToastEvent({
          title: "Warning",
          message: result,
          variant: "warning",
          mode: "dismissable"
        });
        this.dispatchEvent(evt);
      } else {
        this.isLoaded = false;
        const evt = new ShowToastEvent({
          title: "Success",
          message: "Quantities updated sucessfully!",
          variant: "success",
          mode: "dismissable"
        });
        this.dispatchEvent(evt);
        this.dispatchEvent(new CloseActionScreenEvent());
        const filterChangeEvent = new CustomEvent("closemodal");
        this.dispatchEvent(filterChangeEvent);
      }
    });
  }
}