import { LightningElement, api } from "lwc";
import { FlowAttributeChangeEvent, FlowNavigationNextEvent } from "lightning/flowSupport";
import getBudgetQuoteProducts_Apex from "@salesforce/apex/BudgetQuoteController_SL.getBudgetQuoteProducts";

export default class BudgetQuote extends LightningElement {
  @api opportunityId; // Input from Budget_Quote.flow
  @api durationMonths; // Output for Budget_Quote.flow
  @api totalAmount; // Output for Budget_Quote.flow
  @api productIds; // Output for Budget_Quote.flow // comma separated string

  _durationMonths = null;
  _totalAmount = null;
  _productIds = [];

  productOptions;
  errorMessage = null;
  showSpinner = false;

  constructor() {
    super();
    this.fetchData();
  }

  fetchData() {
    getBudgetQuoteProducts_Apex()
      .then((result) => {
        this.productOptions = result.productOptions;
        if (this.productOptions && this.productOptions.length > 0) {
          this._productIds = [this.productOptions[0].value];
          this.dispatchEvent(new FlowAttributeChangeEvent("productIds", this._productIds.join(",")));
        }
      })
      .catch((e) => {
        console.error("ERROR" + JSON.stringify(e));
      });
  }

  handleFieldChange(event) {
    this.resetError();
    let field = event.target.dataset.field;
    event.target.showHelpMessageIfInvalid();

    // Push change into the flow variables
    if (field === "duration") {
      this._durationMonths = event.detail.value;
      this.dispatchEvent(new FlowAttributeChangeEvent("durationMonths", this._durationMonths));
    } else if (field === "totalamount") {
      this._totalAmount = event.detail.value;
      this.dispatchEvent(new FlowAttributeChangeEvent("totalAmount", this._totalAmount));
    } else if (field === "products") {
      let selectedProductId = event.detail.value;
      if (selectedProductId) {
        this._productIds = [];
        this._productIds.push(selectedProductId);
        this.dispatchEvent(new FlowAttributeChangeEvent("productIds", this._productIds.join(",")));
      }
    }
  }

  createQuote() {
    if (this.quoteValidations()) {
      // Navigate to the next screen
      const navigateNextEvent = new FlowNavigationNextEvent();
      this.dispatchEvent(navigateNextEvent);
    } else {
      this.errorMessage = "Please Complete all required fields";
    }
  }

  quoteValidations() {
    if (this._durationMonths && this._totalAmount && this._productIds && this._productIds.length > 0) {
      return true;
    }
    return false;
  }

  resetError() {
    this.errorMessage = null;
  }
}