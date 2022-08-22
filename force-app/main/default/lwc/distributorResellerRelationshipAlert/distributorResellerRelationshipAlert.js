import { LightningElement } from 'lwc';
import getInitialData from '@salesforce/apex/LookupDistributorResellerController_PP.getInitialData';
import getDistributorOrResellerAccounts from '@salesforce/apex/LookupDistributorResellerController_PP.getDistributorOrResellerAccounts';
import LINKED_ACCOUNTS_MESSAGE from '@salesforce/label/c.PartnerProgramLinkedAccountsMessage';
import PARTNER_USER_ID from '@salesforce/user/Id';

export default class DistributorResellerRelationshipAlert extends LightningElement {
  accounts = [];

  accountsAsString = '';

  get message() {
    return LINKED_ACCOUNTS_MESSAGE.replace('{ACCOUNTS}', this.accountsAsString);
  }

  get showAlert() {
    return Array.isArray(this.accounts) && this.accounts.length > 0 && !!this.accountsAsString;
  }

  connectedCallback() {
    getInitialData({ partnerUserId: PARTNER_USER_ID })
      .then((result) => {
        if (result.isPartnerUserReseller && result.resellerAccountId) {
          this.getRelatedDistributors();
        }
      })
      .catch((error) => console.log(JSON.stringify(error)));
  }

  getRelatedDistributors() {
    getDistributorOrResellerAccounts({ partnerUserId: PARTNER_USER_ID })
      .then((result) => {
        this.accounts = result;
        this.generateAccountsAsString();
      })
      .catch((error) => console.log(JSON.stringify(error)));
  }

  generateAccountsAsString() {
    this.accountsAsString = this.accounts.reduce((accumulator, currentValue, index, array) => {
      const email = Object.prototype.hasOwnProperty.call(currentValue, 'Partner_Locator_Contact_Email__c')
        ? ` (${currentValue.Partner_Locator_Contact_Email__c})`
        : '';
      const comma = index === array.length - 1 ? '' : ', ';

      return accumulator + currentValue.Name + email + comma;
    }, '');
  }
}