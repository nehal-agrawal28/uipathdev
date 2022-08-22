import { LightningElement, api, track } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import { CloseActionScreenEvent } from "lightning/actions";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import validateQuote_Apex from "@salesforce/apex/QuoteSubmitForApprovalController.validateQuote";

export default class QuoteSubmitForApproval extends NavigationMixin(LightningElement) {
  @api
  set recordId(recordId) {
    if (recordId !== this._recordId) {
      this._recordId = recordId;
      this.initialQuoteValidation();
    }
  }
  get recordId() {
    return this._recordId;
  }
  @track _recordId;
  @track showSpinner = true;
  @track showContinue = false;
  @track validationData = { errors: [], warnings: [] };
  @track submitPageUrl;

  connectedCallback() {}

  initialQuoteValidation() {
    this.showSpinner = true;
    validateQuote_Apex({ quoteId: this._recordId })
      .then((result) => {
        this.validationData = {
          errors: result.errors,
          warnings: result.warnings
        };
        this.submitPageUrl = result.submitPageUrl;

        if (this.validationData.errors.length > 0) {
          this.showContinue = false;
          this.showSpinner = false;
        } else if (this.validationData.warnings.length > 0) {
          this.showContinue = true;
          this.showSpinner = false;
        } else {
          this.continueSubmit();
        }
      })
      .catch((error) => {
        this.showToast("Error", error, "error");
        console.error(error);
      });
  }

  closeModal() {
    this.dispatchEvent(new CloseActionScreenEvent());
  }

  continueSubmit() {
    this[NavigationMixin.Navigate](
      {
        type: "standard__webPage",
        attributes: {
          url: this.submitPageUrl
        }
      },
      true
    );
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