/**
* @AUTHOR: Slalom Consulting
* @DATE: 05/04/2019
* @DESCRIPTION: This class is a wrapper for validating VAT Ids against VIES WebService
*/




/**
 * API for validating VAT Ids against VIES WebService
 */
public class VIES {

    public static final String NO_VALUE_STRING = '---';


    /**
    * Error codes the the service might cause
    *
    * INVALID_INPUT - The provided CountryCode is invalid or the VAT number is empty
    * SERVICE_UNAVAILABLE - The SOAP service is unavailable, try again later
    * MS_UNAVAILABLE - The Member State service is unavailable, try again later or with another Member State
    * TIMEOUT - The Member State service could not be reach in time, try again later or with another Member State
    * SERVER_BUSY - The service can't process your request. Try again latter.
    * UNKNOWN - custom error code
    */
    public enum ERROR_CODE {

        INVALID_INPUT,
        SERVICE_UNAVAILABLE,
        MS_UNAVAILABLE,
        TIMEOUT,
        SERVER_BUSY,
        UNKNOWN
    }


    public static ERROR_CODE getErrorCode(String errorMessage){
        for(ERROR_CODE ecode : ERROR_CODE.values()){
            if(errorMessage.contains(ecode.name())) return ecode;
        }
        return ERROR_CODE.UNKNOWN;
    }

    public static VAT_VALIDITY_CODE isValidVATID(VATCheck check){

        VATCheck toCheck = check.statusCode == VIES.CHECK_STATUS_CODE.PENDING
                ? check.checkVAT()
                : check;

        return toCheck.statusCode == VIES.CHECK_STATUS_CODE.FAILED
                ? VAT_VALIDITY_CODE.VALIDATION_FAILED
                : (toCheck.isValid
                        ? VAT_VALIDITY_CODE.VALID
                        : VAT_VALIDITY_CODE.INVALID
                );
    }


    public static VATCheck checkVAT(String vatID){

        VATCheck result = new VATCheck();
        result.vatId = vatId;
        return result.checkVAT();
    }


    public static VATCheck checkVAT(String countryCode, String vatNumber){

        VATCheck result = new VATCheck();
        result.countryCode = countryCode.trim();
        result.vatNumber = vatNumber.trim();
        result.checkVAT();
        return result.checkVAT();
    }


    public static String getCountryCode(String vatID){
        return vatID.trim().substring(0,2);
    }

    public static String getVATnumber(String vatID){
        return vatID.trim().substring(2,vatID.trim().length());
    }


    /**
     * Status codes for VATCheck objects
     */
    public enum CHECK_STATUS_CODE {
        PENDING,
        COMPLETED,
        FAILED
    }

    /**
     * VAT Validity codes
     */
    public enum VAT_VALIDITY_CODE {

        VALIDATION_FAILED,
        VALID,
        INVALID
    }


    /**
     * Wrapper class
     */
    public class VATCheck {

        public VATCheck(){
            this.statusCode = VIES.CHECK_STATUS_CODE.PENDING;
            this.statusMessage = '';
        }

        // WEB SERVICE PARAMS
        public String vatID {get;set;}
        public String countryCode {get;set;}
        public String vatNumber {get;set;}

        // WEB SERVICE RESPONSE
        public Boolean isValid {get;set;}
        public Date requestDate {get;set;}
        public String name {get;set;}
        public String address {get;set;}

        // CHECK STATUS
        public VIES.CHECK_STATUS_CODE statusCode {get;private set;}
        public ERROR_CODE errorCode {get;private set;}
        public String statusMessage {get;private set;}


        public VATCheck checkVAT(){

            try {

                VIESTypes.CheckResponse resp;
                resp = vatID != null
                        ? new VIESService().checkVAT(this.vatID.trim())
                        : new VIESService().checkVAT(this.countryCode, this.vatNumber);

                this.isValid = resp.valid;
                this.requestDate = resp.requestDate;
                this.name = (resp.name == NO_VALUE_STRING)? '' : resp.name;
                this.address = (resp.address == NO_VALUE_STRING)? '' : resp.address;
                this.statusCode = CHECK_STATUS_CODE.COMPLETED;

            } catch(VIESException ex){

                this.statusCode = CHECK_STATUS_CODE.FAILED;
                this.errorCode = ERROR_CODE.INVALID_INPUT;
                this.statusMessage = ex.getMessage();

            } catch(Exception ex){

                this.statusMessage =  ex.getTypeName() + '\n' + ex.getMessage();

                this.errorCode = getErrorCode(this.statusMessage);

                // Invalid input indicates there's something wrong the VAT Number
                this.isValid = this.errorCode == ERROR_CODE.INVALID_INPUT
                        ? false
                        : null;

                this.statusCode = this.isValid == null
                        ? CHECK_STATUS_CODE.FAILED
                        : CHECK_STATUS_CODE.COMPLETED;
            }

            return this;
        }
    }
}