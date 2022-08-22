/* eslint-disable no-console */
/* eslint-disable radix */
import { LightningElement, api, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getRipReplaceData_Apex from "@salesforce/apex/DealBuilderContractsController_DB.getRipReplaceData";
import amendContracts from "@salesforce/apex/DealBuilderContractsController_DB.amendContracts";
import amendContractsSerialise from "@salesforce/apex/DealBuilderContractsController_DB.amendContractsSerialise";
import searchSoldToPartner from "@salesforce/apex/DealBuilderContractsController_DB.searchSoldToPartner";
import searchOpportunity from "@salesforce/apex/DealBuilderContractsController_DB.searchOpportunity";
import searchQuote from "@salesforce/apex/DealBuilderContractsController_DB.searchQuote";
import RipReplaceCommercialPolicyUrl from "@salesforce/label/c.RipReplaceCommercialPolicyUrl";

export default class DealBuilderRipReplaceModal extends LightningElement {
  @api selectedContracts; // Contract Ids
  @api accountId;

  /**
   * Expose Salesforce custom labels.
   */
  label = {
    cancel: "Cancel",
    continueBtn: "Continue",
    chooseADate: "Replacement Quote",
    term: "Term",
    whenDoYouWantToStart: "Start date of Replacement Quote",
    opportunity: "Opportunity",
    stage: "Stage",
    dealType: "Deal Type",
    amendmentError: "Error on creating amendments.",
    ripReplaceCommercialPolicyUrl: RipReplaceCommercialPolicyUrl
  };

  @track contractRecords = [];

  @track showSpinner = false;
  @track disableContinueBtn = true;
  @track termLength = "";
  @track selectedStartDate = "";
  @track selectedEndDate = "";
  @track enteredOpportunity = "";
  @track opportunityStageValues;
  @track opportunityDealTypeValues;
  @track opportunityCurrencyValues;
  @track stageSelected = "";
  @track dealTypeSelected = "";
  @track currencySelected = "USD";
  @track soldToPartnerSelected = null;
  @track showCreateAmendmentsError = false;
  @track showWarningValidation = true;
  @track warnings = [];
  @track validations = [];
  @track contractCurrency;
  @track warningConfirmDisabled = true;
  @track existingOpportunity = false;
  @track existingOpportunityId;
  @track existingQuoteId;
  @track serialMode = true;
  @track errorMessage = null;

  connectedCallback() {
    this.fetchInitialData();
  }

  hideRipAndReplaceModal() {
    this.dispatchEvent(new CustomEvent("hidemodal"));
  }

  handleWarningConfirm() {
    this.showWarningValidation = false;

    if (this.existingOpportunity) {
      this.initOppSearch();
    }
  }
  handleWarningAcknowledged(event) {
    if (event && event.target && event.target.checked) {
      this.warningConfirmDisabled = false;
    } else {
      this.warningConfirmDisabled = true;
    }
  }

  handleExistingOpp(event) {
    if (event && event.target && event.target.checked) {
      this.existingOpportunity = true;
    } else {
      this.existingOpportunity = false;
    }
  }

  /**
   * Helper method to see if Continue button can be enabled.
   * And to make sure all fields are valid.
   */
  checkTheForm() {
    if (
      this.selectedStartDate.length > 0 &&
      this.selectedEndDate.length > 0 &&
      this.checkTheOpportunity() &&
      this.checkStage() &&
      this.checkCurrency() &&
      this.checkDealType() &&
      this.checkSoldToPartner()
    ) {
      this.disableContinueBtn = false;
    } else {
      this.disableContinueBtn = true;
    }
  }

  /**
   * Checks the date to see if it's in the past.
   */
  checkIfDateIsPast(date) {
    if (this.beforeToday(date)) {
      this.showToast("Error", "Please select a future date", "error");
      return true;
    }
    return false;
  }

  /**
   * Check the start date input.
   */
  checkTheDate() {
    // We have to have a non standard validation here because we do not want to display the toast multiple times.
    var startdate = this.template.querySelector(".startdate");
    var enddate = this.template.querySelector(".enddate");

    if (startdate.value != null) {
      this.selectedStartDate = startdate.value;
      // Check to see if a past date toast need to be displayed. Run only once.
      if (this.checkIfDateIsPast(startdate.value)) {
        this.selectedStartDate = "";
        this.disableContinueBtn = true;
      } else {
        // compare start date with contracts enddate
        for (let contract of this.contractRecords) {
          if (new Date(startdate.value) > new Date(contract.EndDate)) {
            this.showToast(
              "Error",
              "Replacement Start Date must be before all Cancellation Contract End Dates",
              "error"
            );
            this.selectedStartDate = "";
            this.disableContinueBtn = true;
            break;
          }
        }
      }
    }
    if (enddate.value != null) {
      this.selectedEndDate = enddate.value;
      // Check to see if a past date toast need to be displayed. Run only once.
      if (this.checkIfDateIsPast(enddate.value)) {
        this.selectedEndDate = "";
        this.disableContinueBtn = true;
      } else {
        // compare end date with contracts enddate
        for (let contract of this.contractRecords) {
          if (new Date(enddate.value) < new Date(contract.EndDate)) {
            this.showToast("Error", "Replacement End Date must be after all Cancelled Contract End Dates", "error");
            this.selectedStartDate = "";
            this.disableContinueBtn = true;
            break;
          }
        }
      }
    }

    this.checkTheForm();

    if (!startdate.value || !enddate.value) {
      this.disableContinueBtn = true;
    }
  }

  /**
   * Check the opportunity
   */
  checkTheOpportunity() {
    var input = this.template.querySelector(".opportunity");
    if (input.validity.valid) {
      this.enteredOpportunity = input.value;
      return true;
    }
    return false;
  }

  /**
   * Check the stage input.
   */
  checkStage() {
    var input = this.template.querySelector(".selectedstage");
    if (input.validity.valid) {
      this.stageSelected = input.value;
      return true;
    }
    return false;
  }

  /**
   * Check the deal type input.
   */
  checkDealType() {
    var input = this.template.querySelector(".selecteddealtype");
    if (input.validity.valid) {
      this.dealTypeSelected = input.value;
      return true;
    }
    return false;
  }

  /**
   * Check the currency input.
   */
  checkCurrency() {
    var input = this.template.querySelector(".selectedcurrency");
    if (input.validity.valid) {
      this.currencySelected = input.value;
      return true;
    }
    return false;
  }

  /**
   * Check the sold to partner input
   */
  checkSoldToPartner() {
    if (this.dealTypeSelected === "Resale") {
      this.getSoldToPartner();
      if (this.soldToPartnerSelected) {
        return true;
      }
      this.showToast("Attention", "Sold to Partner is required when deal type is Resale", "Warning");
      return false;
    }
    return true;
  }

  toggleSerial(event) {
    this.serialMode = event.detail.checked;
  }

  /**
   * Handles modal's Continue btn click.
   */
  handleContinueClick() {
    this.showSpinner = true;

    let parameterObject = {
      contractIds: this.selectedContracts,
      startDate: this.selectedStartDate,
      endDate: this.selectedEndDate,
      opportunityStage: this.stageSelected,
      opportunityDealType: this.dealTypeSelected,
      opportunityCurrency: this.currencySelected,
      soldToPartnerId: this.soldToPartnerSelected,
      opportunityName: this.enteredOpportunity,
      accountId: this.accountId,
      existingOpportunityId: this.existingOpportunityId,
      existingQuoteId: this.existingQuoteId
    };

    let modeFn = amendContracts;
    if (this.serialMode) {
      modeFn = amendContractsSerialise;
    }
    modeFn({ amendContracts: parameterObject })
      .then((res) => {
        var jobsIdsOnly = [];
        for (let i = 0; i < res.jobs.length; i++) {
          jobsIdsOnly.push(res.jobs[i].jobId);
        }
        this.resetFormValues();
        // Creates the event.
        const selectedEvent = new CustomEvent("markcontractupdating", {
          detail: {
            quoteId: res.quoteId,
            // OK for now, but needs to be quote name
            quoteName: res.quoteName,
            opportunityId: res.opportunityId,
            jobs: jobsIdsOnly
          }
        });
        // Dispatches the event.
        this.dispatchEvent(selectedEvent);
        this.hideRipAndReplaceModal();
        this.showSpinner = false;
      })
      .catch((error) => {
        console.error("Error DealBuilderContractsController_DB.amendContracts" + JSON.stringify(error));
        this.showCreateAmendmentsError = true;
        this.errorMessage = error?.body?.message;
        this.showSpinner = false;
        throw error;
      });
  }

  /**
   *  checkIfDateIsPast helper function.
   */
  beforeToday(date) {
    var selectedDate = new Date(date);
    var now = new Date();
    var beforeToday = false;
    // Fix so we can properly convert and compare the dates, allowing today's date not be in the past.
    if (selectedDate.getYear() < now.getYear()) {
      beforeToday = true;
    } else if (
      selectedDate.getDate() + 1 < now.getDate() &&
      selectedDate.getMonth() <= now.getMonth() &&
      selectedDate.getYear() < now.getYear() + 1
    ) {
      beforeToday = true;
    } else if (
      selectedDate.getDate() + 1 > now.getDate() &&
      selectedDate.getMonth() < now.getMonth() &&
      selectedDate.getYear() < now.getYear() + 1
    ) {
      beforeToday = true;
    }
    return beforeToday;
  }

  /**
   *  Upon modal load, get a list of opportunity stage values.
   */
  fetchInitialData() {
    this.showSpinner = true;

    getRipReplaceData_Apex({
      contractIds: this.selectedContracts
    })
      .then((res) => {
        this.opportunityStageValues = res.stagePicklist;
        this.opportunityDealTypeValues = res.dealTypePicklist;
        this.opportunityCurrencyValues = res.currencyPicklist;
        this.warnings = res.warnings;
        this.validations = res.validations;
        this.contractCurrency = res.contractCurrency;
        this.contractRecords = res.contractRecords;

        this.showSpinner = false;
      })
      .catch((error) => {
        console.error("Error DealBuilderContractsController_DB.getOpportunityStageValues" + JSON.stringify(error));
        this.showSpinner = false;
      });
  }

  getSoldToPartner() {
    const selectedSoldToPartners = this.template.querySelector(".soldtopartner").getSelection();
    if (selectedSoldToPartners && selectedSoldToPartners[0]) {
      this.soldToPartnerSelected = selectedSoldToPartners[0].id;
    } else {
      this.soldToPartnerSelected = null;
    }
  }

  handleSoldToPartnerSearch(event) {
    const lookupElement = event.target;
    searchSoldToPartner(event.detail)
      .then((results) => {
        lookupElement.setSearchResults(results);
      })
      .catch((error) => {
        this.showToast("Error", "An error occured while searching with the lookup field.", "error");
        console.error("Error", JSON.stringify(error));
      });
  }

  initOppSearch() {
    searchOpportunity({
      searchTerm: null,
      selectedIds: null,
      accountId: this.accountId
    })
      .then((results) => {
        const lookup = this.template.querySelector(".existingopp");
        if (lookup) {
          lookup.setDefaultResults(results);
          lookup.setSearchResults(results);
        }
      })
      .catch((error) => {
        this.showToast("Error", "An error occured while searching with the lookup field.", "error");
        console.error("Error", JSON.stringify(error));
      });
  }
  handleOppSearch(event) {
    const lookupElement = event.target;
    let params = event.detail;
    params.accountId = this.accountId;
    searchOpportunity(params)
      .then((results) => {
        lookupElement.setSearchResults(results);
      })
      .catch((error) => {
        this.showToast("Error", "An error occured while searching with the lookup field.", "error");
        console.error("Error", JSON.stringify(error));
      });
  }
  handleOppSelectionChange() {
    const selectedOpps = this.template.querySelector(".existingopp").getSelection();
    if (selectedOpps && selectedOpps[0]) {
      this.existingOpportunityId = selectedOpps[0].id;
    } else {
      this.existingOpportunityId = null;
      this.disableContinueBtn = true;
    }
    this.initQuoteSearch();
  }

  initQuoteSearch() {
    searchQuote({
      searchTerm: null,
      selectedIds: null,
      oppId: this.existingOpportunityId
    })
      .then((results) => {
        const lookup = this.template.querySelector(".existingquote");
        if (lookup) {
          lookup.setDefaultResults(results);
          lookup.setSearchResults(results);
        }
      })
      .catch((error) => {
        this.showToast("Error", "An error occured while searching with the lookup field.", "error");
        console.error("Error", JSON.stringify(error));
      });
  }
  handleQuoteSearch(event) {
    const lookupElement = event.target;
    let params = event.detail;
    params.oppId = this.existingOpportunityId;
    searchQuote(params)
      .then((results) => {
        lookupElement.setSearchResults(results);
      })
      .catch((error) => {
        this.showToast("Error", "An error occured while searching with the lookup field.", "error");
        console.error("Error", JSON.stringify(error));
      });
  }
  handleQuoteSelectionChange() {
    const selectedQuotes = this.template.querySelector(".existingquote").getSelection();
    if (selectedQuotes && selectedQuotes[0]) {
      this.existingQuoteId = selectedQuotes[0].id;
      this.disableContinueBtn = false;
    } else {
      this.existingQuoteId = null;
      this.disableContinueBtn = true;
    }
  }

  showToast(title, message, variant) {
    const evt = new ShowToastEvent({
      title: title,
      message: message,
      variant: variant
    });
    this.dispatchEvent(evt);
  }

  resetFormValues() {
    // Resetting form and var values.
    this.showCreateAmendmentsError = false;
    try {
      this.template.querySelector(".selectedstage").value = undefined;
      this.template.querySelector(".opportunity").value = undefined;
      this.template.querySelector(".enddate").value = undefined;
      this.template.querySelector(".startdate").value = undefined;
    } catch (e) {
      console.log(e);
    }
    this.termLength = "";
    this.selectedStartDate = "";
    this.enteredOpportunity = "";
    this.stageSelected = "";
    this.dealTypeSelected = "";
    this.currencySelected = "USD";
    this.soldToPartnerSelected = null;
    this.errorMessage = null;
    this.existingOpportunity = false;
    this.existingOpportunityId = null;
    this.existingQuoteId = null;
  }
}