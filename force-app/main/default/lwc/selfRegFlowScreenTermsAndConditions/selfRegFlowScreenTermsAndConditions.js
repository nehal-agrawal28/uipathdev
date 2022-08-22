import { LightningElement, api, track } from 'lwc';
import { FlowNavigationBackEvent, FlowNavigationNextEvent, FlowNavigationFinishEvent } from 'lightning/flowSupport';

// Apex Methods
import createPartnerApex from '@salesforce/apex/SelfRegController_PP.createPartner';

// Custom Labels
import PREVIOUS from '@salesforce/label/c.Previous';
import NEXT from '@salesforce/label/c.Next';
import RESET from '@salesforce/label/c.Reset';
import SUBMIT_REGISTRATION from '@salesforce/label/c.Submit_Registration';


export default class SelfRegFlowScreenTermsAndConditions extends LightningElement
{
    customLabels = {
        PREVIOUS,
        NEXT,
        RESET,
        SUBMIT_REGISTRATION
    };

    @track m_Firstname;
    @track m_Lastname;
    @track m_Email;
    @track m_ContactId;
    @track m_SelectedPartnerAccountId;
    @track m_UserTraining;
    @track m_UserDealRegistration;
    @track m_PartnerUserCreated = false;
    @track m_isJapanUser;

    @track isLoaded = true;
    @track isCheckboxTaCChecked = false;
    @track isCheckboxPpChecked = false;

    // Getter/Setter
    @api get firstname() { return this.m_Firstname; }
    set firstname(val) { this.m_Firstname = val; }

    @api get lastname() { return this.m_Lastname; }
    set lastname(val) { this.m_Lastname = val; }

    @api get email() { return this.m_Email; }
    set email(val) { this.m_Email = val; }

    @api get contactId() { return this.m_ContactId; }
    set contactId(val) { this.m_ContactId = val; }

    @api get selectedPartnerAccountId() { return this.m_SelectedPartnerAccountId; }
    set selectedPartnerAccountId(val) { this.m_SelectedPartnerAccountId = val; }

    @api get userTraining() { return this.m_UserTraining; }
    set userTraining(val) { this.m_UserTraining = val; }

    @api get userDealRegistration() { return this.m_UserDealRegistration; }
    set userDealRegistration(val) { this.m_UserDealRegistration = val; }

    @api get partnerUserCreated() { return this.m_PartnerUserCreated; }

    @api get isJapanUser() { return this.m_isJapanUser; }
    set isJapanUser(val) { this.m_isJapanUser = val; }

    get tacNotAccepted()
    {
        return (!this.isCheckboxTaCChecked || !this.isCheckboxPpChecked);
    }

    // Events
    onchangeCheckbox(event)
    {
        this.isCheckboxTaCChecked = this.template.querySelector(".checkbox-tac").checked;
        this.isCheckboxPpChecked = this.template.querySelector(".checkbox-pp").checked;
    }

    onclickBtnSubmit(event)
    {
        this.dispatchEvent(new FlowNavigationNextEvent());

        /*
        this.isLoaded = false;

        createPartnerApex({
            contactId: this.m_ContactId,
            accountId: this.m_SelectedPartnerAccountId,
            firstname: this.m_Firstname,
            isContentUser: !this.m_UserDealRegistration,
            lastname: this.m_Lastname,
            workEmail: this.m_Email
        })
        .then(result => {
            console.log({result});

            if(result)
            {
                this.m_PartnerUserCreated = true;
            }
            console.log(this.m_PartnerUserCreated);

            this.dispatchEvent(new FlowNavigationNextEvent());
        })
        .catch((error) => {
            this.dispatchEvent(new FlowNavigationNextEvent());
        })
        */
    }

    onclickBtnReset(event)
    {
        location.reload();
    }

  handleClickPrevious() {
    this.dispatchEvent(new FlowNavigationBackEvent());
  }
}