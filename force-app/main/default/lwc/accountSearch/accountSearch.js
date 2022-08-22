import { LightningElement, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import findAccounts from '@salesforce/apex/SearchController_PP.findAccounts';
import getAccountList from '@salesforce/apex/SearchController_PP.getAccountList';

/** The delay used when debouncing event handlers before invoking Apex. */
const DELAY = 350;
const columns = [
    {label: 'Name', fieldName: 'AccountUrl', type: 'url',
        typeAttributes: {label: { fieldName: 'Name' }, target: '_top'}, sortable: true},
    { label: 'Street', fieldName: 'BillingStreet', sortable: true },
    { label: 'City', fieldName: 'BillingCity', sortable: true },
    { label: 'State', fieldName: 'BillingState', sortable: true },
    { label: 'Country', fieldName: 'BillingCountry', sortable: true },
    { label: 'Partner Level', fieldName: 'Business_Partner_Level__c', sortable: true },
    { label: 'Resale Discount Tier', fieldName: 'Resale_Discount_Tier__c', sortable: true },
    { label: 'Indirect Reseller Signed?', fieldName: 'Indirect_Reseller_Signed__c', sortable: true },
    { label: 'Contributing Status', fieldName: 'PartnerContributingStatus__c', sortable: true },
    { label: 'Date Joined Program', fieldName: 'Date_Joined_Program__c', sortable: true }
];

export default class AccountSearch extends NavigationMixin(LightningElement) {
    @track sortedBy;
    @track sortedDirection = 'asc';

    url = window.location.href.substring(0, window.location.href.lastIndexOf('/'));
    error;
    columns = columns;
    accounts;

    @wire(getAccountList)
    wiredAccounts( {error, data }) {
        if (data) {
            this.accounts = data.map((item) => 
                Object.assign({}, item, {AccountUrl:'/detail/' + item['Id']})
            );
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.accounts = undefined;
        }
    }

    handleKeyChange(event) {
        // Debouncing this method: Do not actually invoke the Apex call as long as this function is
        // being called within a delay of DELAY. This is to avoid a very large number of Apex method calls.
        window.clearTimeout(this.delayTimeout);
        const searchKey = event.target.value;
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this.delayTimeout = setTimeout(() => {
            findAccounts({ searchKey })
                .then((result) => {
                    this.accounts = {};
                    this.accounts = result.map((item) => 
                        Object.assign({}, item, {AccountUrl:'/detail/' + item['Id']})
                    );
                    this.error = undefined;
                })
                .catch((error) => {
                    this.error = error;
                    this.accounts = undefined;
                });
        }, DELAY);
    }

    updateColumnSorting(event){
        this.sortedBy = event.detail.fieldName;
        this.sortedDirection = event.detail.sortDirection;
        this.sortData(this.sortedBy,this.sortedDirection);       
    }

    sortData(fieldName, sortDirection){
        var data = JSON.parse(JSON.stringify(this.accounts));
        //function to return the value stored in the field
        var key =(a) => a[fieldName]; 
        var reverse = sortDirection === 'asc' ? 1: -1;
        data.sort((a,b) => {
            let valueA = key(a) ? key(a).toLowerCase() : '';
            let valueB = key(b) ? key(b).toLowerCase() : '';
            return reverse * ((valueA > valueB) - (valueB > valueA));
        });

        //set sorted data to accounts attribute
        this.accounts = data;
    }
}