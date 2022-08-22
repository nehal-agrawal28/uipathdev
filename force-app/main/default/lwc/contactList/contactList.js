import { LightningElement, wire, api, track } from 'lwc';
import getContacts from '@salesforce/apex/AccountController_PP.getContacts';

/** The delay used when debouncing event handlers before invoking Apex. */
const columns = [
    { label: 'Name', fieldName: 'Name', sortable: true},
    { label: 'Role', fieldName: 'Role', sortable: true },
    { label: 'Email', fieldName: 'Email', sortable: true }
];

export default class ContactList extends LightningElement {
    @api recordId;
    error;
    columns = columns;
    @track contacts;

    @wire(getContacts, { accountId: '$recordId' })
    wiredContacts( {error, data }) {
        if (Array.isArray(data) && data.length > 0) {
            this.contacts = data.map((item) => 
            {
                return { Name:item.User.Name, Role:item['RoleInTerritory2'], Email:item.User.Email };
            });
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.contacts = undefined;
            console.error(error);
        }
    }
}