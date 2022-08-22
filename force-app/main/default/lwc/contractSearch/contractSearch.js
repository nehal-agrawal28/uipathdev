import { LightningElement, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import findContracts from '@salesforce/apex/SearchController_PP.findContracts';
import getContractsList from '@salesforce/apex/SearchController_PP.getContractsList';
import communityBasePath from '@salesforce/community/basePath';

/** The delay used when debouncing event handlers before invoking Apex. */
const DELAY = 350;
const actions = [
  { label: 'Open contract', name: 'show_contract' }
];
const columns = [
  { type: 'action', typeAttributes: { rowActions: actions, menuAlignment: 'left' } },
  { label: 'Number', fieldName: 'ContractNumber', initialWidth: 150, sortable: true },
  { label: 'Customer', fieldName: 'AccountName', sortable: true },
  { label: 'Start Date', fieldName: 'StartDate', sortable: true },
  { label: 'End Date', fieldName: 'EndDate', sortable: true },
  { label: 'Term', fieldName: 'Term', sortable: true }
];

export default class ContractSearch extends  NavigationMixin(LightningElement) {
  @track sortedBy;
  @track sortedDirection = 'asc';

  error;
  columns = columns;
  contracts;

  @wire(getContractsList)
  wiredContracts( {error, data }) {
    if (data) {
      this.contracts = data;
      this.error = undefined;
    } else if (error) {
      this.error = error;
      this.contracts = undefined;
    }
  }

  handleRowAction(event) {
    const action = event.detail.action;
    const row = event.detail.row;
    switch (action.name) {
      case 'show_contract':
        const pageName = `${window.location.origin}${communityBasePath}/detail/${row.Id}`;
        this[NavigationMixin.Navigate]({
          type: 'standard__webPage',
          attributes: {
            url: pageName
          }
        }, true);
        break;
    }
  }

  handleKeyChange(event) {
    // Debouncing this method: Do not actually invoke the Apex call as long as this function is
    // being called within a delay of DELAY. This is to avoid a very large number of Apex method calls.
    window.clearTimeout(this.delayTimeout);
    const searchKey = event.target.value;
    // eslint-disable-next-line @lwc/lwc/no-async-operation
    this.delayTimeout = setTimeout(() => {
      findContracts({ searchKey })
        .then((result) => {
          this.contracts = {};
          this.contracts = result;
          this.error = undefined;
        })
        .catch((error) => {
          this.error = error;
          this.contracts = undefined;
        });
    }, DELAY);
  }

  updateColumnSorting(event){
    this.sortedBy = event.detail.fieldName;
    this.sortedDirection = event.detail.sortDirection;
    this.sortData(this.sortedBy,this.sortedDirection);
  }

  sortData(fieldName, sortDirection){
    var data = JSON.parse(JSON.stringify(this.contracts));
    //function to return the value stored in the field
    var key =(a) => a[fieldName];
    var reverse = sortDirection === 'asc' ? 1: -1;
    data.sort((a,b) => {
      let valueA = key(a) ? key(a).toLowerCase() : '';
      let valueB = key(b) ? key(b).toLowerCase() : '';
      return reverse * ((valueA > valueB) - (valueB > valueA));
    });

    //set sorted data to accounts attribute
    this.contracts = data;
  }
}