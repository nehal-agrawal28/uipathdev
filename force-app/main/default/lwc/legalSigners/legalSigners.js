/* eslint-disable no-unused-vars */
import { LightningElement, track, api } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getSignerDataAPEX from "@salesforce/apex/LegalSignersController.getSignerData";
import saveSignerDataAPEX from "@salesforce/apex/LegalSignersController.saveSignerData";

export default class LegalSigners extends LightningElement {
  @api recordId;
  @api objectApiName;
  @api title;

  @track signerData;
  @track showSpinner = false;
  @track showEditModal = false;

  @track selectedEntity;
  @track selectedMetadataId;
  @track availableEntities = [];

  connectedCallback() {
    if (this.recordId) {
      this.fetchSignerData();
    }
  }

  fetchSignerData() {
    getSignerDataAPEX({
      caseId: this.recordId
    })
      .then((result) => {
        this.signerData = result;
      })
      .catch((error) => {
        console.error(error);
        this.showToast("Error", "Something went wrong while fetching signer data", "error");
      });
  }

  editHandler() {
    this.selectedEntity = this.signerData.caseRecord.UiPath_Signing_Entity__c;
    this.selectedMetadataId = null;
    this.filterAvailableEntities();

    this.showEditModal = true;
  }

  cancelModalHandler() {
    this.showEditModal = false;
  }

  entityChangeHandler(event) {
    this.selectedEntity = event.detail.value;
    this.filterAvailableEntities();
  }

  filterAvailableEntities() {
    this.availableEntities = [];
    for (let signer of this.signerData.signers) {
      if (this.selectedEntity === signer.entity) {
        this.availableEntities.push(signer);
      }
    }
  }

  selectMetadataHandler(event) {
    this.selectedMetadataId = event.target.value;
  }

  saveModalHandler() {
    if (this.selectedMetadataId) {
      this.showSpinner = true;
      this.showEditModal = false;
      saveSignerDataAPEX({
        caseId: this.recordId,
        entityName: this.selectedEntity,
        metadataId: this.selectedMetadataId
      })
        .then((result) => {
          // Success
          window.location.reload();
        })
        .catch((error) => {
          console.error(error);
          this.showToast("Error", error?.body?.message, "error");
        })
        .finally(() => {
          this.showSpinner = false;
        });
    } else {
      this.showToast("Error", "Please choose one option and then Save", "error");
    }
  }

  openRecord(event) {
    let rId = event.target.dataset.id;
    window.open(`/${rId}`, "_blank");
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