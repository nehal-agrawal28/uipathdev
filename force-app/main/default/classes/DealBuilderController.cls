public with sharing class DealBuilderController {
  public class DealBuilderWrapper {
    @AuraEnabled
    public String vfBaseUrl { get; set; }
    @AuraEnabled
    public Account account { get; set; }
    @AuraEnabled
    public List<Contract> contractList { get; set; }
    @AuraEnabled
    public Boolean isOppCreatable { get; set; }
    @AuraEnabled
    public Boolean hasRRPermission { get; set; }
  }

  @AuraEnabled
  public static DealBuilderWrapper getInitialData(String accountId) {
    DealBuilderWrapper wrapper = new DealBuilderWrapper();

    if (String.isNotBlank(accountId)) {
      wrapper.account = [SELECT Id, Name, Country__c, State__c FROM Account WHERE Id = :accountId];

      // active contracts ending within last 6 months
      Date last6Month = System.today().addMonths(-6);
      wrapper.contractList = [
        SELECT Id, ContractNumber, StartDate, EndDate
        FROM Contract
        WHERE AccountId = :accountId AND EndDate > :last6Month
        ORDER BY StartDate ASC
      ];
    }

    wrapper.vfBaseUrl = URL.getSalesforceBaseUrl().toExternalForm();
    wrapper.isOppCreatable = Schema.getGlobalDescribe().get('Opportunity').getDescribe().isCreateable();
    wrapper.hasRRPermission = FeatureManagement.checkPermission('CPQ_Rip_Replace');

    return wrapper;
  }
}