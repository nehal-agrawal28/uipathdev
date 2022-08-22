import { LightningElement, api, track } from 'lwc';

// Custom Labels
import CLICK_ON_FINISH_AND_REVIEW_RECORD from '@salesforce/label/c.Click_On_Finish_And_Review_Record';
import FINISH from '@salesforce/label/c.Finish';

export default class DealRegFinalScreenFlowComponent extends LightningElement
{
    customLabels = {
        CLICK_ON_FINISH_AND_REVIEW_RECORD,
        FINISH
    };

    @track m_DealRegId;
    @track m_LinkToDealReg;

    // Getter/Setter
    @api get dealRegId() { return this.m_DealRegId; }
    set dealRegId(val) { this.m_DealRegId = val; }

    // Events
    connectedCallback()
    {
        const communityBaseURL = window.location.href.substring(0, window.location.href.indexOf('/s/'));
        this.m_LinkToDealReg = `${communityBaseURL}/s/detail/${this.dealRegId}`;
    }

    onclickBtnFinish(event)
    {
        window.open(this.m_LinkToDealReg, '_self');
    }
}