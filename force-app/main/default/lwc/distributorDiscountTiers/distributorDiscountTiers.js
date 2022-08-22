import { LightningElement, api } from 'lwc';
import hasDistributorAssociation from '@salesforce/apex/LookupDistributorResellerController_PP.hasDistributorAssociation';
import USER_ID from '@salesforce/user/Id';

export default class DistributorDiscountTiers extends LightningElement {
  @api
  recordId;

  showDiscountTiers = false;

  connectedCallback() {
    hasDistributorAssociation({ resellerUserId: USER_ID, distributorAccountId: this.recordId })
    .then((result) => {
      this.showDiscountTiers = result;
    })
    .catch((error) => console.log(JSON.stringify(error)));
  }
}