import { LightningElement, api } from 'lwc';
import getInitialData from '@salesforce/apex/LookupDistributorResellerController_PP.getInitialData';
import getInitialDistributorOrResellerAccounts from '@salesforce/apex/LookupDistributorResellerController_PP.getInitialDistributorOrResellerAccounts';
import searchDistributorOrResellerAccounts from '@salesforce/apex/LookupDistributorResellerController_PP.searchDistributorOrResellerAccounts';
import PARTNER_USER_ID from '@salesforce/user/Id';

// @see https://github.com/pozil/sfdc-ui-lookup-lwc
export default class LookupDistributorResellerAccount extends LightningElement {
  @api
  dealType;

  @api
  distributorAccountId;

  @api
  resellerAccountId;

  @api
  userCountry;

  @api
  maxResults = 5;

  @api
  isBpoOpportunity;

  errors = [];

  hasDistributorOrResellerAccounts = false;

  isPartnerUserDistributor = false;

  isPartnerUserReseller = false;

  get label() {
    if (this.isPartnerUserDistributor) return 'Reseller Account';
    if (this.isPartnerUserReseller) return 'Distributor Account';

    return 'Account';
  }

  get placeholder() {
    if (this.isPartnerUserDistributor) return 'Search Reseller Accounts...';
    if (this.isPartnerUserReseller) return 'Search Distributor Accounts...';

    return 'Search Accounts...';
  }

  get requireDistributorOrReseller() {

    console.log(
      '@@@ requireDistributorOrReseller',
      !this.hasDistributorOrResellerAccounts,
      !this.isPartnerUserDistributor && !this.isPartnerUserReseller
    );

    switch (this.dealType) {
      case 'BPO':
        if (this.userCountry === 'India') break;
        return false;
      case 'Partner Internal Infrastructure':
        return false;
      case 'Managed Services':
        return false;
      case 'NFR':
        return false;
      default:
        break;
    }
    if (!this.hasDistributorOrResellerAccounts) return false;
    if (!this.isPartnerUserDistributor && !this.isPartnerUserReseller) return false;

    return true;
  }

  connectedCallback() {
    getInitialData({ partnerUserId: PARTNER_USER_ID })
      .then((result) => {
        this.hasDistributorOrResellerAccounts = result.hasDistributorOrResellerAccounts;
        this.isPartnerUserDistributor = result.isPartnerUserDistributor;
        this.isPartnerUserReseller = result.isPartnerUserReseller;

        if (result.isPartnerUserDistributor && result.distributorAccountId) {
          this.distributorAccountId = result.distributorAccountId;
        }

        if (result.isPartnerUserReseller && result.resellerAccountId) {
          this.resellerAccountId = result.resellerAccountId;
        }

        if (this.isPartnerUserReseller) {
          getInitialDistributorOrResellerAccounts({ partnerUserId: PARTNER_USER_ID })
            .then((results) => {
              this.template.querySelector('c-lookup').setDefaultResults(results);
            })
            .catch((error) => this.addError(JSON.stringify(error)));
        }
      })
      .catch((error) => this.addError(JSON.stringify(error)));
  }

  addError(errorMessage) {
    this.errors.push({ id: this.errors.length, message: errorMessage });
  }

  checkForErrors() {
    this.errors = [];
    const selection = this.template.querySelector('c-lookup').getSelection();

    // enforce required field
    if (selection.length === 0) this.addError(`Please choose ${this.label}.`);
  }

  @api
  validate() {
    if (!this.requireDistributorOrReseller) return { isValid: true };

    this.checkForErrors();

    if (!this.errors.length) return { isValid: true };

    return {
      isValid: false,
      errorMessage: this.errors.reduce((prev, curr) => prev.concat(' ', curr.message), ''),
    };
  }

  handleLookupSearch(event) {
    const parameters = {
      searchTerm: event.detail.searchTerm,
      partnerUserId: PARTNER_USER_ID,
      maxResults: this.maxResults,
    };

    searchDistributorOrResellerAccounts(parameters)
      .then((results) => {
        this.template.querySelector('c-lookup').setSearchResults(results);
      })
      .catch((error) => this.addError(JSON.stringify(error)));
  }

  handleLookupSelectionChange(event) {
    this.checkForErrors();

    if (this.errors.length === 0 && event.detail.length > 0) {
      if (this.isPartnerUserDistributor) {
        this.resellerAccountId = event.detail[0];
      } else if (this.isPartnerUserReseller) {
        this.distributorAccountId = event.detail[0];
      }
    }
  }
}