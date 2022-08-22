/**
 * --
 * @date 2020
 *
 * @group CPQQuote
 * @group-content ../../ApexDocContent/CPQQuote.htm
 *
 * @description REST resource to handle cloning of lines from a VF client page
 */
@RestResource(urlMapping='/quotes/*/clonelinesfromslaves')
global with sharing class CPQQuotesResource {
  @HttpPost
  /**
   * @description masterQuoteId: Id of main quote supplied as part of the resource path
   * clonelinesfromslaves: Ids of all the slave quotes supplied as a CSV; note in the example %2C is the encoded value for comma
   * example: https://ue2.salesforce.com/services/apexrest/quotes/006b0000003u4Ln/clonelinesfromslaves?slaves=a513I000000IdqD%2Ca513I000000IrqD
   */
  global static List<SBQQ__QuoteLine__c> cloneLinesFromSlaves() {
    // Take apart the URI to discover the Master Quote Id
    RestRequest req = RestContext.request;
    RestResponse res = RestContext.response;
    String[] uriParts = req.requestURI.split('/');

    // Determine service parameter values from REST context
    Id masterQuoteId = uriParts[2]; // get from URL path
    String slavesCsv = EncodingUtil.urlDecode(req.params.get('slaves'), 'UTF-8');
    List<String> slaveIdStrings = slavesCsv.split(',');
    if (slaveIdStrings.size() <= 0) {
      throw new InvalidInputException('At least one valid slave Quote Id is required');
    }
    Set<Id> slaveIds = new Set<Id>();

    for (String str : slaveIdStrings) {
      slaveIds.add(Id.valueOf(str));
    }

    // Call Service Method
    return CPQQuoteClonerService.cloneLinesIntoMasterQuote(masterQuoteId, slaveIds);
  }

  public class InvalidInputException extends Exception {
  }
}