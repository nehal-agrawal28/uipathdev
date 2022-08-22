import {LightningElement,wire,api,track} from 'lwc';
import getBilltoAddress from '@salesforce/apex/AddressComponentController.getBilltoAddress';
import getShipToAddress from '@salesforce/apex/AddressComponentController.getShipToAddress';
import getWrappedAddress from '@salesforce/apex/AddressComponentController.getWrappedAddress';
import updateAddress from '@salesforce/apex/AddressComponentController.updateAddress';
import {refreshApex} from '@salesforce/apex';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import Order_Int_Address_Update_Success_Msg from '@salesforce/label/c.Order_Int_Address_Update_Success_Msg';

export default class AddressComponent extends NavigationMixin(LightningElement) {

    @api recordId;
    @wire(getBilltoAddress, {objectRecordId: '$recordId'}) billToaddress;
    @wire(getShipToAddress, {objectRecordId: '$recordId'}) shipToaddress;
    @track isOpen = false;
    @track addressList;
    @track selectedAddressId;
    @track addressType;
    @track error;
   
    //Method to open dailog box on click bill to address
    handleSelectBillToClick() {
        this.isOpen = true;
        this.okButtonDisabled = true;
        this.addressType = 'billToAddress';
        if(this.billToaddress != null && this.billToaddress.data != null)
            this.selectedAddressId = this.billToaddress.data.Id;
        getWrappedAddress({
                addressType: this.addressType,
                objectRecordId: this.recordId,
                selectedAddressId: this.selectedAddressId
            }) //get address method in cls query current address 
            .then(result => {
                this.addressList = result;
                this.error = undefined;
            })
            .catch(error => {
                this.error = error;
                this.addressList = undefined;
            });
    }
   
    //Method to open dailog box on click ship to address
    handleSelectShipToClick() {
        this.isOpen = true;
        this.okButtonDisabled = true;
        this.addressType = 'shipToAddress';
        if(this.selectedAddressId != null && this.selectedAddressId.data != null)
            this.selectedAddressId = this.shipToaddress.data.Id;
        getWrappedAddress({
                addressType: this.addressType,
                objectRecordId: this.recordId,
                selectedAddressId: this.selectedAddressId
            })
            .then(result => {
                this.addressList = result;
                this.error = undefined;
                
            })
            .catch(error => {
                this.error = error;
                this.addressList = undefined;
            });  
    }

    //close the dialogue box
    closeModal() {
        this.isOpen = false;
    }

    //Handle Radio button selection
    handleradiochange(event) {
        this.selectedAddressId = event.target.value;
        let radioInputs = this.template.querySelectorAll("input");
        radioInputs.forEach(function (element) {
            if(element.type === "radio" && element.value !== event.target.value)
                element.checked="";
        });
    }

    //Update address on Order
    updateAndCloseModal(event){
       updateAddress({
                addressType: this.addressType,
                selectedAddressId: this.selectedAddressId,
                objectRecordId: this.recordId
            })
            .then(result => {               
                const toastEvent = new ShowToastEvent({
                    variant : 'success',
                    title: 'Success',
                    message: Order_Int_Address_Update_Success_Msg
                });
                this.dispatchEvent(toastEvent);

                if (this.addressType === "billToAddress") {
                    refreshApex(this.billToaddress);
                } else {
                    refreshApex(this.shipToaddress);
                }
            
            })
            .catch((error) => {
                const errorEvent = new ShowToastEvent({
                    variant : 'error',
                    title: 'Error',
                    message: error.body.message,
                    mode: 'sticky'
                });
                this.dispatchEvent(errorEvent);
            });
                
        this.isOpen = false;
    }

    //Redirect to Address record on click of address hyperlink
    viewAddressRecord(event) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                "recordId": event.target.value,
                "objectApiName": "Address__c",
                "actionName": "view"
            },
        });
    }
    
}