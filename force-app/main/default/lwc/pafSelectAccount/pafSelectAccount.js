import { LightningElement, api } from 'lwc';
import getRecentlyViewedAccounts from '@salesforce/apex/PafSelectAccountController_PP.getRecentlyViewedAccounts';
import getRecentlyViewedContactsForAccount from '@salesforce/apex/PafSelectAccountController_PP.getRecentlyViewedContactsForAccount';
import searchAccounts from '@salesforce/apex/PafSelectAccountController_PP.searchAccounts';
import searchContactsForAccount from '@salesforce/apex/PafSelectAccountController_PP.searchContactsForAccount';

const DEFAULT_OPTION_VALUE = 'create';

export default class PafSelectAccount extends LightningElement {
  @api
  accountId;

  @api
  contactId;

  leadIntoAccountValue = DEFAULT_OPTION_VALUE;

  leadIntoAccountOptions = [
    { label: 'Creating a new Account', value: DEFAULT_OPTION_VALUE },
    { label: 'Choosing an existing Account', value: 'choose' },
  ];

  leadIntoContactValue = DEFAULT_OPTION_VALUE;

  leadIntoContactOptions = [
    { label: 'Creating a new Contact', value: DEFAULT_OPTION_VALUE },
    { label: 'Choosing an existing Contact', value: 'choose' },
  ];

  @api
  maxResults = 5;

  get showSearchAccount() {
    return this.leadIntoAccountValue === 'choose';
  }

  get showContactOptions() {
    return !!this.accountId;
  }

  get showSearchContact() {
    return this.leadIntoContactValue === 'choose';
  }

  handleChangeLeadIntoAccount(event) {
    // reset dependent properties
    this.accountId = undefined;
    this.contactId = undefined;
    this.leadIntoContactValue = DEFAULT_OPTION_VALUE;

    this.leadIntoAccountValue = event.detail.value;

    if (this.showSearchAccount) {
      getRecentlyViewedAccounts({ maxResults: this.maxResults })
        .then((response) => {
          this.template.querySelector('c-lookup.account-lookup').setDefaultResults(response);
        })
        .catch((error) => console.error(JSON.stringify(error)));
    }
  }

  handleChangeLeadIntoContact(event) {
    // reset dependent properties
    this.contactId = undefined;

    this.leadIntoContactValue = event.detail.value;

    if (this.showSearchContact) {
      const parameters = {
        accountId: this.accountId,
        maxResults: this.maxResults,
      };

      getRecentlyViewedContactsForAccount(parameters)
        .then((response) => {
          this.template.querySelector('c-lookup.contact-lookup').setDefaultResults(response);
        })
        .catch((error) => console.error(JSON.stringify(error)));
    }
  }

  handleLookupSearchAccount(event) {
    const parameters = {
      searchTerm: event.detail.searchTerm,
      maxResults: this.maxResults,
    };

    searchAccounts(parameters)
      .then((response) => {
        this.template.querySelector('c-lookup.account-lookup').setSearchResults(response);
      })
      .catch((error) => console.error(JSON.stringify(error)));
  }

  handleSearchContact(event) {
    const parameters = {
      searchTerm: event.detail.searchTerm,
      accountId: this.accountId,
      maxResults: this.maxResults,
    };

    searchContactsForAccount(parameters)
      .then((response) => {
        this.template.querySelector('c-lookup.contact-lookup').setSearchResults(response);
      })
      .catch((error) => console.error(JSON.stringify(error)));
  }

  handleSelectionChangeAccount(event) {
    // reset dependent properties
    this.contactId = undefined;
    this.leadIntoContactValue = DEFAULT_OPTION_VALUE;

    [this.accountId] = event.detail;
  }

  handleSelectionChangeContact(event) {
    [this.contactId] = event.detail;
  }
}