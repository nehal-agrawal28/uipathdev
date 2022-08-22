import { LightningElement, api, wire, track } from "lwc";
import { getObjectInfo } from "lightning/uiObjectInfoApi";
import OPPORTUNITY_OBJECT from "@salesforce/schema/Opportunity";

export default class GuidedSellingCreateOpportunity extends LightningElement {
  //ts-ignore
  @api accountId;

  @wire(getObjectInfo, { objectApiName: OPPORTUNITY_OBJECT })
  objectInfo;

  @track isSubmitted = false;

  handleSubmit(event) {
    event.preventDefault();
    this.template
      .querySelector("lightning-record-edit-form")
      .submit(event.detail.fields);
    this.isSubmitted = true;
  }

  handleError(event) {
    event.preventDefault();
    this.isSubmitted = false;
  }

  // Navigate to View Opty Page
  navigateToViewOptyPage(event) {
    window.location.assign("/" + event.detail.id);
  }

  get recordTypeId() {
    // Returns a map of record type Ids
    const rtis =
      this.objectInfo &&
      this.objectInfo.data &&
      this.objectInfo.data.recordTypeInfos;

    if (rtis) {
      return Object.keys(rtis).find((rti) => rtis[rti].name === "CPQ Default");
    } else {
      return null;
    }
  }
}