/**
* @AUTHOR: Slalom Consulting
* @DATE: 05/04/2019
* @DESCRIPTION: This class is a the mock web service class for validating a VAT Number
*/

@IsTest(isParallel=true)
global class VIESCalloutMock implements WebServiceMock {
    global void doInvoke(
        Object stub,
        Object request,
        Map<String, Object> response,
        String endpoint,
        String soapAction,
        String requestName,
        String responseNS,
        String responseName,
        String responseType) {


        if(request instanceof VIESTypes.CheckRequest) {

            VIESTypes.CheckResponse response_x = new VIESTypes.CheckResponse();
            VIESTypes.CheckRequest mockRequest = (VIESTypes.CheckRequest) request;

            if (mockRequest.countryCode.startsWith('XX')) {
                //Invalid response
                response_x.address = '';
                response_x.name = '';
                response_x.valid = false;
                response_x.requestDate = Date.newInstance( 2019, 05, 01 );

            } else {
                // Valid Reponse
                response_x.address = '2 EDGEFIELD CLOSE\nBECKENHAM\nKENT\n\n\nBR3 1DJ';
                response_x.name = 'A Company Name';
                response_x.valid = true;
                response_x.requestDate = Date.newInstance( 2019, 05, 01 );
            }
            response.put( 'response_x', response_x );
        }
    }
}