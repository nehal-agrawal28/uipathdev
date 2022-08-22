import { LightningElement, api } from "lwc";
import { NavigationMixin } from "lightning/navigation";
export default class NavigateToQuote extends NavigationMixin(LightningElement) {
  @api quoteId;
  @api headerText;
  @api descText;

  /**
   * Redirects user to quote record screen.
   */
  gotoQuote() {
    window.open("/" + this.quoteId, "_blank");
  }
}