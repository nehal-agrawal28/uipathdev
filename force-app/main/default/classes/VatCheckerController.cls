/**
* @AUTHOR: Slalom Consulting
* @DATE: 05/04/2019
* @DESCRIPTION: This class is the controller for the Lightning web component to validate a VAT Number "
*/

public with sharing class VatCheckerController {

    @AuraEnabled
    public static VatCheckResponse validateNumber (String vatNumber) {

        VIES.VATCheck checkVatResponse = VIES.checkVAT(vatNumber);

        VatCheckResponse response = new VatCheckResponse();
        response.vatId = checkVatResponse.vatID;
        response.countryCode = checkVatResponse.countryCode;
        response.vatNumber = checkVatResponse.vatNumber;
        response.name = checkVatResponse.name;
        response.address = checkVatResponse.address;

        switch on VIES.isValidVATID(checkVatResponse) {
            when VALID {
                response.message = Label.VatCheckerValidMessage;
                response.validationStatus = Label.VatCheckerValidStatus;
            }
            when INVALID {
                response.message =  Label.VatCheckerInvalidMessage;
                response.validationStatus =  Label.VatCheckerInvalidStatus;

            }
            when else {
                response.message = Label.VatCheckerFailedMessage;
                response.validationStatus = Label.VatCheckerFailedStatus;
            }
        }

        return response;
    }

    //Call it account validation service
    // so we can use companies house

    public class VatCheckResponse{

        @AuraEnabled public String vatID {get;set;}
        @AuraEnabled public String countryCode {get;set;}
        @AuraEnabled public String vatNumber {get;set;}
        @AuraEnabled public String name {get;set;}
        @AuraEnabled public String address {get;set;}
        @AuraEnabled public String message {get;set; }
        @AuraEnabled public String validationStatus {get;set; }


        public VatCheckResponse(){}
    }
}