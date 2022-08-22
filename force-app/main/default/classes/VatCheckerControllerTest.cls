/**
* @AUTHOR: Slalom Consulting
* @DATE: 05/04/2019
* @DESCRIPTION: Unit Test class for VatCheckerController
*/

@IsTest
private class VatCheckerControllerTest {

    static final String vatID = 'GB12345678';


    @isTest private static void checkValidId() {
        Test.setMock(WebServiceMock.class, new VIESCalloutMock());
        VatCheckerController.VatCheckResponse response =  VatCheckerController.validateNumber('GB12345678');
        System.assertEquals( Label.VatCheckerValidMessage, response.message );
        System.assertEquals( Label.VatCheckerValidStatus, response.validationStatus );
    }


    @isTest private static void checkInvalidId() {
        Test.setMock(WebServiceMock.class, new VIESCalloutMock());
        VatCheckerController.VatCheckResponse response =  VatCheckerController.validateNumber('XX12345678');
        System.assertEquals( Label.VatCheckerInvalidMessage, response.message );
        System.assertEquals( Label.VatCheckerInvalidStatus, response.validationStatus );
    }

    @isTest private static void checkFailedId() {
        Test.setMock(WebServiceMock.class, new VIESCalloutMock());
        VatCheckerController.VatCheckResponse response =  VatCheckerController.validateNumber('');
        System.assertEquals( Label.VatCheckerFailedMessage, response.message );
        System.assertEquals( Label.VatCheckerFailedStatus, response.validationStatus );
    }
}