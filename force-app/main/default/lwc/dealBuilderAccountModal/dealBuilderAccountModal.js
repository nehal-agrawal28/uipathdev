import { LightningElement, api, wire } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { NavigationMixin } from "lightning/navigation";
import search from "@salesforce/apex/DealBuilderAccountController.search";
import getRecentlyViewed from "@salesforce/apex/DealBuilderAccountController.getRecentlyViewed";

export default class DealBuilderAccountModal extends NavigationMixin(LightningElement) {
	@api selectedAccount;

	maxSelectionSize = 1;
	errors = [];
	recentlyViewed = [];

	/**
	 * Loads recently viewed records and set them as default lookpup search results (optional)
	 */
	@wire(getRecentlyViewed)
	getRecentlyViewed({ data }) {
		if (data) {
			this.recentlyViewed = data;
			this.initLookupDefaultResults();
		}
	}

	connectedCallback() {
		this.initLookupDefaultResults();
	}

	/**
	 * Initializes the lookup default results with a list of recently viewed records (optional)
	 */
	initLookupDefaultResults() {
		// Make sure that the lookup is present and if so, set its default results
		const lookup = this.template.querySelector("c-lookup-s-l");
		if (lookup) {
			lookup.setDefaultResults(this.recentlyViewed);
		}
	}

	/**
	 * Handles the lookup search event.
	 * Calls the server to perform the search and returns the resuls to the lookup.
	 * @param {event} event `search` event emmitted by the lookup
	 */
	handleLookupSearch(event) {
		const lookupElement = event.target;
		// Call Apex endpoint to search for records and pass results to the lookup
		search(event.detail)
			.then(results => {
				lookupElement.setSearchResults(results);
			})
			.catch(error => {
				this.notifyUser("Lookup Error", "An error occured while searching with the lookup field.", "error");
				// eslint-disable-next-line no-console
				console.error("Lookup error", JSON.stringify(error));
				this.errors = [error];
			});
	}

	/**
	 * Handles the lookup selection change
	 * @param {event} event `selectionchange` event emmitted by the lookup.
	 * The event contains the list of selected ids.
	 */
	// eslint-disable-next-line no-unused-vars
	handleLookupSelectionChange(event) {
		this.checkForErrors();
	}

	handleSelectionConfirm(){
		this.checkForErrors();
		
		// if no error than proceed
		if (this.errors.length === 0) {
			const selectionList = this.template.querySelector("c-lookup-s-l").getSelection();
			if (selectionList && selectionList[0]) {
				let accountId = selectionList[0].id;
				window.open("/lightning/n/Deal_Builder?c__accountId=" + accountId, "_self");
			}
		}
	}

	checkForErrors() {
		this.errors = [];
		const selection = this.template.querySelector("c-lookup-s-l").getSelection();
		// Custom validation rule
		if (this.isMultiEntry && selection.length > this.maxSelectionSize) {
			this.errors.push({ message: `You may only select up to ${this.maxSelectionSize} items.` });
		}
		// Enforcing required field
		if (selection.length === 0) {
			this.errors.push({ message: "Please choose an account." });
		}
	}

	notifyUser(title, message, variant) {
		const toastEvent = new ShowToastEvent({ title, message, variant });
		this.dispatchEvent(toastEvent);
	}

	hideModal() {
		this.dispatchEvent(new CustomEvent("hidemodal"));
	}
}