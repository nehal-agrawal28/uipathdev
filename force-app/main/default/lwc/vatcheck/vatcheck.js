/**
 * Created by llyr.jones on 2019-03-20.
 */

import {LightningElement, track, api, wire} from 'lwc';
import checkVatNumber from '@salesforce/apex/VatCheckerController.validateNumber';
import { getRecord, getFieldValue, createRecord, updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';


import VAT_NUMBER_FIELD from '@salesforce/schema/Account.VAT_Number__c';
import VAT_NUMBER_LAST_VALIDATED_ON_FIELD from '@salesforce/schema/Account.VAT_Number_Last_Validated_On__c';
import VAT_NUMBER_STATUS_FIELD from '@salesforce/schema/Account.Vat_Number_Status__c';

import ACCOUNT_ID_FIELD from '@salesforce/schema/Account.Id';
import ACCOUNT_CHECK_VALIDATION_OBJECT from '@salesforce/schema/Account_Validation__c';
import ACCOUNT_VALIDATION_RESPONSE_JSON_FEILD from '@salesforce/schema/Account_Validation__c.Response_JSON__c';
import ACCOUNT_VALIDATION_ACCOUNT_FIELD from '@salesforce/schema/Account_Validation__c.Account__c';
import ACCOUNT_VALIDATION_NAME_FIELD from '@salesforce/schema/Account_Validation__c.Name';


export default class VatCheck extends LightningElement {

    @track responseMessage = '';
    @track responseName = '';
    @track responseAddress = '';
    @track error;
    @track validated = true;
    @track countryCode;
    @track vatNumber;
    @track record;
    @api recordId;


    @wire(getRecord, { recordId: '$recordId', fields: [VAT_NUMBER_FIELD, VAT_NUMBER_LAST_VALIDATED_ON_FIELD, VAT_NUMBER_STATUS_FIELD] }) wiredAccount
    ({ error, data }) {
        if (data) {

            this.record = data;
            this.error = undefined;

            let vatID = getFieldValue(this.record, VAT_NUMBER_FIELD);

            if(vatID) {
                let code = vatID.slice(0, 2);
                if( this.ctMap.has(code) ){
                    this.countryCode = code;
                    this.vatNumber = vatID.slice(2,vatID.length);

                }
                else{
                    this.countryCode = '';
                    this.vatNumber = vatID;
                }
            }
            else{
                this.countryCode = '';
                this.vatNumber = '';
            }

        } else if (error) {
            this.error = error;
            this.record = undefined;
        }
    }


    ctMap = new Map([
        ["AT", {label: "Austria - (AT)", validate:true}],
        ["BE", {label: "Belgium - (BE)", validate:true}],
        ["BG", {label: "Bulgaria - (BG)", validate:true}],
        ["CY", {label: "Cyprus - (CY)", validate:true}],
        ["CZ", {label: "Czech Republic - (CZ)", validate:true}],
        ["DE", {label: "Germany - (DE)", validate:true}],
        ["DK", {label: "Denmark - (DK)", validate:true}],
        ["EE", {label: "Estonia - (EE)", validate:true}],
        ["EL", {label: "Greece - (EL)", validate:true}],
        ["ES", {label: "Spain - (ES)", validate:true}],
        ["EU", {label: "MOSS Number - (EU)", validate:true}],
        ["FI", {label: "Finland - (FI)", validate:true}],
        ["FR", {label: "France - (FR)", validate:true}],
        ["HR", {label: "Croatia - (HR)", validate:true}],
        ["HU", {label: "Hungary - (HU)", validate:true}],
        ["IE", {label: "Ireland - (IE)", validate:true}],
        ["IT", {label: "Italy - (IT)", validate:true}],
        ["LT", {label: "Lithuania - (LT)", validate:true}],
        ["LU", {label: "Luxembourg- (LU)", validate:true}],
        ["LV", {label: "Latvia - (LV)", validate:true}],
        ["MT", {label: "Malta - (MT)", validate:true}],
        ["NO", {label: "Norway - (NO)", validate:false}],
        ["NL", {label: "The Netherlands - (NL)", validate:true}],
        ["PL", {label: "Poland - (PL)", validate:true}],
        ["PT", {label: "Portugal - (PT)", validate:true}],
        ["RO", {label: "Romania - (RO)", validate:true}],
        ["SE", {label: "Sweden - (SE)", validate:true}],
        ["SI", {label: "Slovenia - (SI)", validate:true}],
        ["SK", {label: "Slovakia - (SK)", validate:true}],
        ["GB", {label: "United Kingdom - (GB)", validate:true}],
        ["##", {label: "Other", validate:false}]]);


    handleCountryChange(event) {
        this.countryCode = event.detail.value;
        this.responseMessage = '';
    }


    validateVatNumber(){

        let vatNumToCheck = this.template.querySelector("[data-field='vatNumber']").value;

        if (!vatNumToCheck || !this.countryCode) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Missing Data',
                message: 'Please enter required fields.',
                variant: 'No VAT Number provided.'
            }));
        }

        else{
            this.validated = false;
            let option = this.ctMap.get(this.countryCode);

            if (option.validate) {

                let combinedNumberToCheck = this.countryCode + vatNumToCheck;
                this.responseMessage = '';

                checkVatNumber({vatNumber: combinedNumberToCheck})
                    .then(result => {
                        this.responseMessage = result.message;
                        this.responseName = (result.name) ? 'Name - ' + result.name : '';
                        this.responseAddress = (result.address) ? 'Address - ' + result.address : '';
                        this.createAccountValidation(result);
                        this.updateAccount(result);
                    })
                    .catch(error => {
                        if (!error) {
                            this.dispatchEvent(new ShowToastEvent({
                                title: 'Error',
                                message: 'There has been a problem',
                                variant: 'error'
                            }));
                        }
                        this.dispatchEvent(new ShowToastEvent({
                            title: 'Error searching VAT Number',
                            message: error.body.message,
                            variant: 'error'
                        }));
                    });
            } else {
                
                if(this.countryCode == '##'){
                    this.countryCode  = '';
                }

                let result = {vatID: this.countryCode + vatNumToCheck, validationStatus: 'ValidationNotRequired'};

                this.updateAccount(result);
            }
        }
    }


    createAccountValidation(result) {
        const fields = {};

        fields[ACCOUNT_VALIDATION_RESPONSE_JSON_FEILD.fieldApiName] = JSON.stringify(result);
        fields[ACCOUNT_VALIDATION_ACCOUNT_FIELD.fieldApiName] = this.recordId;
        fields[ACCOUNT_VALIDATION_NAME_FIELD.fieldApiName] = 'VAT Number Check';

        const recordInput = {apiName: ACCOUNT_CHECK_VALIDATION_OBJECT.objectApiName, fields};
        createRecord(recordInput);
    }

    updateAccount(result) {

        const fields = {};

        fields[ACCOUNT_ID_FIELD.fieldApiName] = this.recordId;
        fields[VAT_NUMBER_LAST_VALIDATED_ON_FIELD.fieldApiName] = new Date();
        fields[VAT_NUMBER_STATUS_FIELD.fieldApiName] = result.validationStatus;
        fields[VAT_NUMBER_FIELD.fieldApiName] = result.vatID;

        const recordInput = { fields };

        updateRecord(recordInput)
            .then(() => {
                this.validated = true;
                this.displayValidationResult(result);
            })
            .catch(error => {
                this.validated = true;

                if(!error){
                    this.dispatchEvent( new ShowToastEvent({ title: 'Error', message: 'There has been a problem', variant: 'error' }));
                }
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error creating record',
                        message: error.body.message,
                        variant: 'error'
                    })
                );
            });
    }

    displayValidationResult(result){

        if(result){
            switch(result.validationStatus) {
                case 'Valid':
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'VAT Number is valid',
                            message: 'Validation was successful. The VAT number has been update on the Account.',
                            variant: 'success'
                        })
                    );
                    break;
                case 'ValidationNotRequired':
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'VAT Number Saved',
                            message: 'The VAT number has been update on the Account.',
                            variant: 'success'
                        })
                    );
                    break;
                default:
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'VAT Number is not valid',
                            variant: 'error',
                            message: 'Validation was unsuccessful. The VAT number has been update on the Account.',

                        })
                    );
            }
        }

    }

    get showForm()
    {
        return (this.record && this.validated);
    }

    get validateButtonText(){
        let option = this.ctMap.get(this.countryCode);

        if(option){
            return option.validate ? 'Update and Validate':'Update Only';
        }
        else{
            return 'Update and Validate';
        }
    }

    get validationText(){
        let option = this.ctMap.get(this.countryCode);

        if(option){
            return option.validate ? '':'Validation will not be done for the country selected.';
        }
        else{
            return '';
        }
    }


    get countryCodeOptions() {

        const options = [];
        this.ctMap.forEach((k,v) => {
            options.push({value: v, label: k.label});
        });
        return options;
    }
}