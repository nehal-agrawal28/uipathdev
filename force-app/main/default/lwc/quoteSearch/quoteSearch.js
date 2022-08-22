import { LightningElement, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import findQuotes from '@salesforce/apex/SearchController_PP.findQuotes';
import getQuotesList from '@salesforce/apex/SearchController_PP.getQuoteList';
import communityBasePath from '@salesforce/community/basePath';

/** The delay used when debouncing event handlers before invoking Apex. */
const DELAY = 350;
const actions = [
    { label: 'Open quote', name: 'show_quote' }
];
const columns = [
    { type: 'action', typeAttributes: { rowActions: actions, menuAlignment: 'left' } },
    { label: 'Name', fieldName: 'Name', initialWidth: 150, sortable: true },
    { label: 'Customer', fieldName: 'AccountName', sortable: true },
    { label: 'Partner', fieldName: 'PartnerName', sortable: true },
    { label: 'Opportunity', fieldName: 'OpportunityName', sortable: true }
];

export default class QuoteSearch extends NavigationMixin(LightningElement) {
    @track sortedBy;
    @track sortedDirection = 'asc';

    error;
    columns = columns;
    quotes;

    @wire(getQuotesList)
    wiredQuotes( {error, data }) {
        if (data) {
            this.quotes = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.quotes = undefined;
        }
    }

    handleRowAction(event) {
        const action = event.detail.action;
        const row = event.detail.row;
        switch (action.name) {
            case 'show_quote':
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
            findQuotes({ searchKey })
                .then((result) => {
                    this.quotes = {};
                    this.quotes = result;
                    this.error = undefined;
                })
                .catch((error) => {
                    this.error = error;
                    this.quotes = undefined;
                });
        }, DELAY);
    }

    updateColumnSorting(event){
        this.sortedBy = event.detail.fieldName;
        this.sortedDirection = event.detail.sortDirection;
        this.sortData(this.sortedBy,this.sortedDirection);       
    }

    sortData(fieldName, sortDirection){
        var data = JSON.parse(JSON.stringify(this.quotes));
        //function to return the value stored in the field
        var key =(a) => a[fieldName]; 
        var reverse = sortDirection === 'asc' ? 1: -1;
        data.sort((a,b) => {
            let valueA = key(a) ? key(a).toLowerCase() : '';
            let valueB = key(b) ? key(b).toLowerCase() : '';
            return reverse * ((valueA > valueB) - (valueB > valueA));
        });

        //set sorted data to accounts attribute
        this.quotes = data;
    }
}