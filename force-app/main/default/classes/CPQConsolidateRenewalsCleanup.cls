/**================================================================
 * Uipath, Inc
 * Description: REST service invoked from CPQGuidedTransactions
 * Created Date: 24-Sept-2021
 * Created By: Raghu Rankawat
 *
 * Date Modified      Modified By      Description of the update
 *
 ==================================================================*/
@RestResource(urlMapping='/consolidate/renewals/cleanup')
global without sharing class CPQConsolidateRenewalsCleanup {
  @HttpPost
  global static String cleanupExtraRenewals() {
    RestRequest req = RestContext.request;
    RestResponse res = RestContext.response;
    List<String> conIds = new List<String>();
    Id masterRenewalId;
    List<Contract> conToUpdate = new List<Contract>();
    Map<Id, Opportunity> oppToDelete = new Map<Id, Opportunity>();

    String masterConId = EncodingUtil.urlDecode(req.params.get('masterid'), 'UTF-8');
    String conIdsStr = EncodingUtil.urlDecode(req.params.get('conids'), 'UTF-8');
    if (String.isNotBlank(conIdsStr)) {
      conIds = conIdsStr.split(',');

      List<Contract> conList = [SELECT Id, SBQQ__RenewalOpportunity__c FROM Contract WHERE Id IN :conIds];
      for (Contract con : conList) {
        if (con.Id == masterConId) {
          masterRenewalId = con.SBQQ__RenewalOpportunity__c;
          break;
        }
      }

      // updating master renewal on contracts
      for (Contract con : conList) {
        if (con.SBQQ__RenewalOpportunity__c != masterRenewalId) {
          if (con.SBQQ__RenewalOpportunity__c != null) {
            oppToDelete.put(con.SBQQ__RenewalOpportunity__c, new Opportunity(Id = con.SBQQ__RenewalOpportunity__c));
          }

          con.SBQQ__RenewalOpportunity__c = masterRenewalId;
          conToUpdate.add(con);
        }
      }
      Database.update(conToUpdate, false);

      List<Partner_Involvement__c> pList = [
        SELECT Id
        FROM Partner_Involvement__c
        WHERE PartnerOpp_Name__c IN :oppToDelete.keyset()
      ];
      List<SBQQ__Quote__c> qList = [SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__c IN :oppToDelete.keyset()];

      try {
        // clean up partner involvement records
        delete pList;

        // clean up quote records
        delete qList;

        // clean up renewal opportunities
        delete oppToDelete.values();
      } catch (Exception e) {
        return 'Exception: ' + e.getMessage() + e.getStackTraceString();
      }
    }

    return 'Deleted renewals: ' + oppToDelete.keyset();
  }
}