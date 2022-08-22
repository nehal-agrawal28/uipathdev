import { LightningElement, api } from 'lwc';

export default class AlertMessage extends LightningElement {

    @api message = 'Placeholder message';
    @api theme = 'Info';

    get themeClasses(){
        let cssClasses = 'slds-notify slds-notify_toast slds-theme_alert-texture message-container ';
        switch(this.theme) {
            case 'Error':
                cssClasses += 'slds-theme_error'; 
                break;
            case 'Warning':
                cssClasses += 'slds-theme_warning'; 
                break;
            case 'Success':
                cssClasses += 'slds-theme_success'; 
                break;
            case 'Info':
                cssClasses += 'slds-theme_info'; 
                break;
            default:
                cssClasses += 'slds-theme_info';
          }
        return cssClasses;
    }
}