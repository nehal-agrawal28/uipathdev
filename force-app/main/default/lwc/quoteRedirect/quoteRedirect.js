import { api, LightningElement, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import isQuoteAccessible from '@salesforce/apex/SearchController_PP.isQuoteAccessible';

export default class QuoteRedirect extends NavigationMixin(LightningElement) {
    @api recordId;
    @track isLoading = true;
    @track isAccessible = false;

    renderedCallback() {
        this.redirect();
    }

    redirect() {
        isQuoteAccessible({ quoteId: this.recordId })
            .then(result => {
                this.isAccessible = result;
                this.isLoading = false;
                if (!this.isAccessible && !result) {
                    this[NavigationMixin.Navigate]({
                        type: 'standard__namedPage',
                        attributes: {
                            name: 'Error'
                        }
                    }, true);
                }
            })
            .catch(error => {
                this.isLoading = false;
                console.log(error);
            })
    }
}