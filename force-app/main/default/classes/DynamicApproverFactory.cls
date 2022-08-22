public with sharing class DynamicApproverFactory {
  private static final String DEFAULT_SERVICE_APEX = 'DefaultDynamicApproverService';

  /**
   * Populate dynamic approvers using default service implementation
   */
  public static List<SBQQ__Quote__c> populateDynamicApprovers(List<Id> quoteIdList) {
    return service(DEFAULT_SERVICE_APEX).populateDynamicApprovers(quoteIdList);
  }

  /**
   * Populate dynamic approvers using client provided service implementation
   */
  public static List<SBQQ__Quote__c> populateDynamicApprovers(List<Id> quoteIdList, String serviceApex) {
    if (quoteIdList.size() == 1) {
      return new List<SBQQ__Quote__c>{ service(serviceApex).populateDynamicApprover(quoteIdList.get(0)) };
    } else {
      return service(serviceApex).populateDynamicApprovers(quoteIdList);
    }
  }

  private static IDynamicApproverService service(String serviceApex) {
    Type t = Type.forName(serviceApex);
    return (IDynamicApproverService) t.newInstance();
  }
}