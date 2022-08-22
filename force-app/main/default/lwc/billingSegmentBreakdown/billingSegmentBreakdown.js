import { LightningElement, api, wire } from 'lwc';

import getSegmentationData from '@salesforce/apex/BillingSegmentBreakdownController.getSegmentationData';
import genericErrorMessage from '@salesforce/label/c.GenericLWCErrorMessage';
import disclaimerMessage from '@salesforce/label/c.DisclaimerMessage';
import Billing_Segmentation_Title from '@salesforce/label/c.Billing_Segmentation_Title';
import ContractInformationTitle from '@salesforce/label/c.ContractInformationTitle';
import QuoteInformationTitle from '@salesforce/label/c.QuoteInformationTitle';

export default class billingSegmentBreakdown extends LightningElement{
    // Quote Id returned from VF Page
    @api quoteId;
    // URL Link to CPQ Quote Line Editor
    lineEditorLink;
    // URL Link to Quote
    quoteLink;
    // Disclaimer Message
    disclaimerMessage;
    // Billing Title 
    billingSegmentationTitle;
    // Contract Label
    contractInformationTitle;
    // Quote Title
    quoteInformationTitle;

    /* Error Handling */
    // Handles whether to display Error Message
    displayErrorMessage = false;
    // Error Message to return
    errorMessage;

    /* Data */
    // Quote Data
    quote = [];
    // Quote Currency
    quoteCurrency;
    // Quote Total Amount 
    quoteTotalAmount;
    // Billing Segments Data
    billingSegments = [];
    // QuoteLine Billing Segments Data
    qliSegments = [];
    // Contract
    contract = [];
    // Amendment Quote
    amendmentQuote = false;
    // Contract Anniversary Date
    contractAnniversary;
    
    /* Accordion */
    // List of active Billing Segment Sections
    activeSegmentSections = [];
    // List of active QuoteLine Billing Segment Sections
    activeQLISegmentSections = [];
    // List of all Billing Segment Names
    segmentNames = [];
    // List of all QuoteLine Billing Segment Names
    qliSegmmentNames = [];
    // Identifies whether all Accordion Sections should be expanded
    expanded = false;
    // Label on Expand button 
    expandButtonLabel = 'Expand All';

    /**
    *  Wired to Apex method that calculates all Billing Segments
    */
    @wire(getSegmentationData, { quoteId: '$quoteId' })
    valueList({error, data }) {
        console.log('Data >>', data);
        console.log('Error >>', error);

        if(data === null){
            this.displayErrorMessage = true;
            this.errorMessage = genericErrorMessage;
        } else if(data !== null && data !== undefined){
            if(data.errorMessage !== undefined){
                this.displayErrorMessage = true;
                this.errorMessage = data.errorMessage;
            } else {
                // Get all data
                this.quote = data.quote;
                this.quoteTotalAmount = data.quoteTotalAmount;
                this.billingSegments = data.billingSegments;
                this.qliSegments = data.qlSegmentsList;
                this.contract = data.contract;
                this.amendmentQuote = this.contract !== undefined ? true : false;
                this.contractAnniversary = data.contractAnniversary;

                // Get all Segment Names
                for(var x in this.billingSegments){
                    this.segmentNames.push(this.billingSegments[x].Name);
                }

                // Get all QLI Segment Names
                for(var x in this.qliSegments){
                    this.qliSegmmentNames.push(this.qliSegments[x].quoteLine.SBQQ__Product__r.Name);
                }

                this.quoteCurrency = this.quote.CurrencyIsoCode;
            }
        }

        // Build URL
        this.lineEditorLink = window.location.origin + '/apex/sbqq__sb?scontrolCaching=1&id=' + this.quoteId + '#quote/le?qId=' + this.quoteId;
        this.quoteLink = '/' + this.quoteId;
        
        // Build Custom Labels
        this.disclaimerMessage = disclaimerMessage;
        this.billingSegmentationTitle = Billing_Segmentation_Title;
        this.contractInformationTitle = ContractInformationTitle;
        this.quoteInformationTitle = QuoteInformationTitle;

        console.log('quote.Quote_Duration_YMD__c ', this.quote.Quote_Duration_YMD__c);
    }

    /**
    *  Expands or Closes Billing Segment Accordion sections on the LWC page
    */
    handleSegmentSectionToggle(event) {
        if(this.activeSegmentSections !== this.segmentNames.length){            
            this.activeSegmentSections = this.segmentNames;
        } 
        
        if(event.detail.openSections.length === 0){
            this.activeSegmentSections = [];
        }
    }

    /**
    *  Expands or Closes all Accordion sections on the LWC page
    */
    handleExpand(event){
        if(this.expanded){
            this.activeSegmentSections = [];
            this.activeQLISegmentSections = [];
            this.expanded = false;
            this.expandButtonLabel = 'Expand All';
        } else {
            this.activeSegmentSections = this.segmentNames;
            this.activeQLISegmentSections = this.qliSegmmentNames;
            this.expanded = true;
            this.expandButtonLabel = 'Close All';
        }
    }
}