import { LightningElement, track, api} from 'lwc';
import { FlowNavigationBackEvent, FlowNavigationNextEvent } from 'lightning/flowSupport';
import { navigateToURLCurrentTab } from 'c/utils';

// Apex Methods
import getSelfRegDataApex from '@salesforce/apex/SelfRegController_PP.getSelfRegData';

// Custom Labels
import BECOMING_PARTNER_URL from '@salesforce/label/c.Becoming_Partner_Url';
import I_AM_A_PARTNER from '@salesforce/label/c.I_Am_A_Partner';
import I_WANT_TO_BECOME_A_PARTNER from '@salesforce/label/c.I_Want_To_Become_A_Partner';
import MAKE_SURE_YOU_HAVE_ENTERED_COMPANY_EMAIL from '@salesforce/label/c.Make_Sure_You_Have_Entered_Company_Email';
import NEXT from '@salesforce/label/c.Next';
import NO_RESULTS_FOUND from '@salesforce/label/c.No_Results_Found';
import PARTNER_ACCOUNT_SELECTION from '@salesforce/label/c.Partner_Account_Selection'
import PARTNER_BUT_ACCOUNT_NOT_DISPLAYED from '@salesforce/label/c.Partner_But_Account_Not_Displayed';
import PREVIOUS from '@salesforce/label/c.Previous';
import RESULTS_NOT_RIGHT_CONTACT_SUPPORT from '@salesforce/label/c.Results_Not_Right_Contact_Support';
import SELECT_ONE_OF_THE_FOLLOWING_OPTIONS from '@salesforce/label/c.Select_One_Of_The_Following_Options';
import SUPPORT_MAIL from '@salesforce/label/c.Support_Mail';


export default class SelfRegFlowScreenChooseAccount extends LightningElement
{
    customLabels = {
        BECOMING_PARTNER_URL,
        I_AM_A_PARTNER,
        I_WANT_TO_BECOME_A_PARTNER,
        MAKE_SURE_YOU_HAVE_ENTERED_COMPANY_EMAIL,
        NEXT,
        NO_RESULTS_FOUND,
        PARTNER_ACCOUNT_SELECTION,
        PARTNER_BUT_ACCOUNT_NOT_DISPLAYED,
        PREVIOUS,
        RESULTS_NOT_RIGHT_CONTACT_SUPPORT,
        SELECT_ONE_OF_THE_FOLLOWING_OPTIONS,
        SUPPORT_MAIL
    };

    mailToSupport = ('mailto:' + this.customLabels.SUPPORT_MAIL);

    @track m_Email;
    @track m_ContactId = '';
    @track m_SelectedPartnerAccountId;

    @track isLoaded = false;
    @track hasUser = false;
    @track isUserActive;
    @track isPartner = false;
    @track partnerAccounts = [];

    communityLoginUrl;
    communitySupportUrl;

    // Getter/Setter
    @api get email() { return this.m_Email; }
    set email(val) { this.m_Email = val; }

    @api get contactId() { return this.m_ContactId; }

    @api get selectedPartnerAccountId() { return this.m_SelectedPartnerAccountId; }

    get hasPartnerAccounts() { return this.partnerAccounts.length; }

    get isPartnerAccountNotSelected() { return (!this.selectedPartnerAccountId); }

    // Methods
    connectedCallback()
    {   
        this.createUrls();
        this.initializePartnerAccounts();
    }

    initializePartnerAccounts()
    {
        if(this.m_Email)
        {
            getSelfRegDataApex({
                email: this.m_Email
            })
            .then(result => {               
                if('Error' in result)
                {
                    this.isUserActive = result['Error'][0].isActive;
                    this.hasUser = true;
                }
                else
                {
                    if(result['Contacts'].length)
                        this.m_ContactId = result['Contacts'][0].Id;

                    for(let i = 0; i < result['Accounts'].length; i++)
                    {
                        this.partnerAccounts.push(
                            {
                                label: result['Accounts'][i].Name,
                                value: result['Accounts'][i].Id,
                                country:  result['Accounts'][i].BillingCountry
                            }
                        );
                    }
                }
                this.isLoaded = true;
            })
            .catch((error) => {
                this.isLoaded = true;
            })
        }
    }

    createUrls()
    {
        const communityBaseURL = window.location.href.substring(0, window.location.href.indexOf('/s/'));
        this.communityLoginUrl = communityBaseURL + '/login';
        this.communitySupportUrl = communityBaseURL + '/s/contactsupport';
    }
    
    // Events
    onclickPartnerAccountRadio(event)
    {
        this.m_SelectedPartnerAccountId = event.target.value;
    }

    onclickBtnIAmPartner(event)
    {

        window.open(this.communitySupportUrl);
    }

    onclickBtnBecomingPartner(event)
    { 
        navigateToURLCurrentTab(this.customLabels.BECOMING_PARTNER_URL);
    }

    onclickBtnPrevious(event)
    {
        this.dispatchEvent(new FlowNavigationBackEvent());
    }

    onclickBtnNext(event)
    {
        this.dispatchEvent(new FlowNavigationNextEvent());
    }
}

//https://innotrue-uipath.cs44.force.com/uipathpartnercommunity/login