import { LightningElement, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class PageRedirect extends NavigationMixin(LightningElement) {
    @track contentUrl
    renderedCallback() {
        this.redirect();
    }

    redirect() {
        const path = window.location.pathname.split("/");
        const contentKey = path.pop().slice(-28);
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: 'https://partnerportal.uipath.com/cms/delivery/media/' + contentKey
            }
        }, true);
    }

    handleClick(event) {
        // Stop the event's default behavior (don't follow the HREF link) and prevent click bubbling up in the DOM...
        event.preventDefault();
        event.stopPropagation();

        this.redirect();
    }
}