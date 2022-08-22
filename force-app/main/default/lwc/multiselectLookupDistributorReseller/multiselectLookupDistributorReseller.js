import { LightningElement, api } from 'lwc';
import searchDistributorsOrResellers from '@salesforce/apex/LookupDistributorResellerController_PP.searchDistributorsOrResellers';

// @see https://github.com/pozil/sfdc-ui-lookup-lwc
export default class MultiselectLookupDistributorReseller extends LightningElement {
  @api
  businessPartnerType = 'Distributor';

  @api
  accountIds = '';
  @api
  maxResults = 5;
  errors = [];
  get label() {
    return this.businessPartnerType === 'Distributor'
      ? 'Distributor Accounts'
      : 'Reseller Accounts';
  }
  get placeholder() {
    return this.businessPartnerType === 'Distributor'
      ? 'Search Distributor Accounts...'
      : 'Search Reseller Accounts...';
  }
  handleLookupSearch(event) {
    const parameters = {
      searchTerm: event.detail.searchTerm,
      partnerType: this.businessPartnerType,
      maxResults: this.maxResults,
    };
    searchDistributorsOrResellers(parameters)
      .then((results) => {
        this.template.querySelector('c-lookup').setSearchResults(results);
      })
      .catch((error) => this.addError(JSON.stringify(error)));
  }
  handleLookupSelectionChange(event) {
    this.accountIds = event.detail.join(',');
  }
}