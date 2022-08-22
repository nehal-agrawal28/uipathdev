import { LightningElement, api, track } from 'lwc';
import { FlowNavigationBackEvent, FlowNavigationNextEvent } from 'lightning/flowSupport';

// Apex Methods
import sendVerificationCodeApex from '@salesforce/apex/SelfRegController_PP.sendVerificationCode';

// Custom Labels
import PREVIOUS from '@salesforce/label/c.Previous';
import VERIFICATION_CODE_NOT_VALID from '@salesforce/label/c.Verification_Code_Not_Valid';


export default class SelfRegFlowScreenValidateEmailAddress extends LightningElement
{
    customLabels = {
        PREVIOUS,
        VERIFICATION_CODE_NOT_VALID
    };

    @track m_Email;
    @track m_VerificationCode;
    @track m_IsVerificationSuccessful;
    @track isLoaded = false;

    // Getter/Setter
    @api get email() { return this.m_Email; }
    set email(val) { this.m_Email = val; }

    @api get isVerificationSuccessful() { return this.m_IsVerificationSuccessful; }

    // Events
    connectedCallback()
    {
        sendVerificationCodeApex({
            workEmail: this.m_Email
        })
        .then(result => {

            if(result)
            {
                this.m_VerificationCode = result;
                this.isLoaded = true;
            }
            else
            {
                this.processError();
            }
        })
        .catch((error) => {
            console.log(error);
            this.processError();
        })
    }

    onclickBtnSubmit(event)
    {
        if(this.isVerificationCodeValid())
        {
            this.m_IsVerificationSuccessful = true;
            this.dispatchEvent(new FlowNavigationNextEvent());
        }    
    }

    onclickBtnPrevious(event)
    {
        this.dispatchEvent(new FlowNavigationBackEvent());
    }
    
    // Methods
    isVerificationCodeValid()
    {
        const inputVerificationCodeCMP = this.template.querySelector('.inputVerificationCode');

        if(inputVerificationCodeCMP.value)
        {
            if(inputVerificationCodeCMP.value === this.m_VerificationCode)
            {
                return true;
            }
            else
            {
                inputVerificationCodeCMP.setCustomValidity(this.customLabels.VERIFICATION_CODE_NOT_VALID);
                inputVerificationCodeCMP.reportValidity();
                return false;
            }
        }

        inputVerificationCodeCMP.setCustomValidity("");
        inputVerificationCodeCMP.reportValidity();
        return false;
    }

    processError()
    {
        this.m_IsVerificationSuccessful = false;
        this.dispatchEvent(new FlowNavigationNextEvent());
    }
}