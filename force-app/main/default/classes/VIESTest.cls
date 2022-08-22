/**
* @AUTHOR: Slalom Consulting
* @DATE: 05/04/2019
* @DESCRIPTION: Test class for VIES web service and VIES Wrapper
 */

@isTest
private class VIESTest {

    static final String countryCode = 'GB';
    static final String vatNumber = '12345678';
    static final String vatID = 'GB12345678';


    @isTest private static void checkVATID(){
        Test.setMock(WebServiceMock.class, new VIESCalloutMock());

        VIES.VATCheck result = VIES.checkVAT(vatID);
        System.assertEquals(true, result.isValid);
    }

    @isTest private static void checkVATNumber() {
        Test.setMock(WebServiceMock.class, new VIESCalloutMock());

        VIES.VATCheck result = VIES.checkVAT( countryCode, vatNumber );
        System.assertEquals( VIES.CHECK_STATUS_CODE.COMPLETED, result.statusCode );
        System.assertEquals( true, result.isValid );
    }


   @isTest private static void isValidVAT_InValidCheck(){
       Test.setMock(WebServiceMock.class, new VIESCalloutMock());

       VIES.VATCheck result = new VIES.VATCheck();
       result.vatID = 'XX' + vatNumber ;
       System.assertEquals(VIES.VAT_VALIDITY_CODE.INVALID, VIES.isValidVATID(result));
    }


    @isTest private static void isValidVAT_validCheck(){
        Test.setMock(WebServiceMock.class, new VIESCalloutMock());

        VIES.VATCheck result = new VIES.VATCheck();
        result.vatID = vatID;
        System.assertEquals(VIES.VAT_VALIDITY_CODE.Valid, VIES.isValidVATID(result));
    }

    @isTest private static void isValidVAT_validCheckWhenCompleted(){
        Test.setMock(WebServiceMock.class, new VIESCalloutMock());

        VIES.VATCheck result = new VIES.VATCheck();
        result.vatID = vatID;
        VIES.isValidVATID(result);

        System.assertEquals(VIES.VAT_VALIDITY_CODE.VALID, VIES.isValidVATID(result));
    }

    @isTest private static void isValidVAT_failedCheck(){
        VIES.VATCheck result = new VIES.VATCheck();
        System.assertEquals(VIES.VAT_VALIDITY_CODE.VALIDATION_FAILED, VIES.isValidVATID(result));
    }


    @isTest private static void nullInputs(){

        String emptyString;

        try {
            VIESTypes.CheckResponse resp = new VIESService().checkVAT(emptyString);
        } catch(Exception ex){
            System.assertEquals(true, ex instanceof VIESException);
        }

        try {
            VIESTypes.CheckResponse resp = new VIESService().checkVAT(emptyString,emptyString);
        } catch(Exception ex){
            System.assertEquals(true, ex instanceof VIESException);
        }

        try {
            VIES.VATCheck check = new VIES.VATCheck();
            check.checkVAT();
        }
        catch(Exception ex){
            System.assertEquals(true, ex instanceof VIESException);
        }
    }

    @isTest private static void utilTest(){

        System.assertEquals(countryCode, VIES.getCountryCode(vatID));
        System.assertEquals(vatNumber, VIES.getVATNumber(vatID));

        System.assertEquals(VIES.ERROR_CODE.INVALID_INPUT, VIES.getErrorCode('INVALID_INPUT'));
        System.assertEquals(VIES.ERROR_CODE.UNKNOWN, VIES.getErrorCode('UNDEFINED'));
    }

}