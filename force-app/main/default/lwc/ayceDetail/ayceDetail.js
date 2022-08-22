import { LightningElement, track, api, wire } from "lwc";
import { getRecord } from "lightning/uiRecordApi";
import QUOTELINE_CONFIG_FIELD from "@salesforce/schema/SBQQ__QuoteLine__c.Configuration_JSON__c";
import ASSET_CONFIG_FIELD from "@salesforce/schema/Asset.Configuration_JSON__c";

export default class AyceDetail extends LightningElement {
  @api recordId;
  @api objectApiName;
  @track tableData;

  @wire(getRecord, { recordId: "$recordId", fields: [QUOTELINE_CONFIG_FIELD] })
  currentQuoteLineRecord({ error, data }) {
    if (data && data.fields.Configuration_JSON__c) {
      this.processData(data.fields.Configuration_JSON__c.value);
    }
  }

  @wire(getRecord, { recordId: "$recordId", fields: [ASSET_CONFIG_FIELD] })
  currentAssetLineRecord({ error, data }) {
    if (data && data.fields.Configuration_JSON__c) {
      this.processData(data.fields.Configuration_JSON__c.value);
    }
  }

  processData(configJSON) {
    let configObj = JSON.parse(configJSON);
    let dataList = [];

    Object.keys(configObj).forEach(key => {
      if (key === "ayceconfig") {
        let options = configObj.ayceconfig;

        // eslint-disable-next-line guard-for-in
        for (let product in options) {
          let data = {};
          data.productName = product;
          data.Max_Allowed_Quantity__c =
            options[product].Max_Allowed_Quantity__c;
          data.Planned_Quantity__c = options[product].Planned_Quantity__c;
          data.Actual_Quantity__c = options[product].Actual_Quantity__c;

          dataList.push(data);
        }
      } else {
        let data = {};
        data.productName = key;
        data.Max_Allowed_Quantity__c = configObj[key];
        dataList.push(data);
      }
    });
    this.tableData = dataList;
  }
}