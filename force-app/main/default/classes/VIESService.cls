/**
* @AUTHOR: Slalom Consulting
* @DATE: 05/04/2019
* @DESCRIPTION: VIESservice provides simpliefed access to VIES VAT Number validation WebService, WSDL: http://ec.europa.eu/taxation_customs/vies/checkVatService.wsdl
 */
public class VIESService {

    public String endpoint_x = 'http://ec.europa.eu/taxation_customs/vies/services/checkVatService';
    public Map<String,String> inputHttpHeaders_x;
    public Map<String,String> outputHttpHeaders_x;
    public String clientCertName_x;
    public String clientCert_x;
    public String clientCertPasswd_x;
    public Integer timeout_x;
    private String[] ns_map_type_info = new String[]{'urn:ec.europa.eu:taxud:vies:services:checkVat:types', 'VIEStypes', 'urn:ec.europa.eu:taxud:vies:services:checkVat', 'VIESservice'};


    public VIESTypes.CheckResponse checkVAT(String vatID){
        if(vatID == null || vatID.length() == 0){
            throw new VIESException('VAT ID is required');
        }
        String trimmedId = vatID.trim().replaceAll(' ','');//vatID = vatID.trim();
        return checkVAT(VIES.getCountryCode(trimmedId), VIES.getVATNumber(trimmedId));
    }

    /**
     * Method invokes Webservice Callout and returns VIESResponse object
     */
    public VIESTypes.CheckResponse checkVAT(String countryCode, String vatNumber){

        if(countryCode == null || countryCode.length() == 0 || vatNumber == null || vatNumber.length() == 0){
            throw new VIESException('Country Code and VAT Number ID are required');
        }

        VIESTypes.CheckRequest request_x = new VIESTypes.CheckRequest();
        VIESTypes.CheckResponse response_x = new VIESTypes.CheckResponse();
        request_x.countryCode = countryCode.trim().replaceAll(' ','');
        request_x.vatNumber = vatNumber.trim().replaceAll(' ','');

        Map<String, VIEStypes.CheckResponse> response_map_x = new Map<String, VIEStypes.CheckResponse>{
                'response_x'=>response_x
        };


        WebServiceCallout.invoke(
                this,
                request_x,
                response_map_x,
                new String[]{endpoint_x,
                        '',
                        'urn:ec.europa.eu:taxud:vies:services:checkVat:types',
                        'checkVat',
                        'urn:ec.europa.eu:taxud:vies:services:checkVat:types',
                        'checkVatResponse',
                        'VIESTypes.CheckResponse'}
        );

        return response_map_x.get('response_x');

    }

}