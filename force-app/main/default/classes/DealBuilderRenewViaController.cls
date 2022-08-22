public with sharing class DealBuilderRenewViaController {
  public class DealBuilderWrapper {
    @AuraEnabled
    public List<Opportunity> oppList { get; set; }
  }

  public class DMLResultWrapper {
    @AuraEnabled
    public Boolean isSuccess { get; set; }
    @AuraEnabled
    public String title { get; set; }
    @AuraEnabled
    public String message { get; set; }
  }

  @AuraEnabled
  public static DealBuilderWrapper getInitialData(String accountId) {
    DealBuilderWrapper wrapper = new DealBuilderWrapper();

    wrapper.oppList = [SELECT Id, Name, StageName, CloseDate FROM Opportunity WHERE AccountId = :accountId];

    return wrapper;
  }

  @AuraEnabled
  public static DMLResultWrapper updateContracts(List<String> contractIds, List<String> selectedOppIds, String oppId) {
    DMLResultWrapper result = new DMLResultWrapper();
    result.isSuccess = true;

    List<Contract> contracts = [SELECT Id, SBQQ__RenewalOpportunity__c FROM Contract WHERE Id IN :contractIds];

    List<Opportunity> existingRenewalOpps = new List<Opportunity>();
    List<Opportunity> selectedOppList = new List<Opportunity>();

    Savepoint sp = Database.setSavepoint();

    for (Contract con : contracts) {
      if (con.SBQQ__RenewalOpportunity__c != null && con.SBQQ__RenewalOpportunity__c != oppId) {
        existingRenewalOpps.add(new Opportunity(Id = con.SBQQ__RenewalOpportunity__c, StageName = 'Closed Merged'));
      }
      con.SBQQ__RenewalOpportunity__c = oppId;
    }

    if (contracts.size() > 0) {
      try {
        update contracts;
      } catch (Exception ex) {
        result.isSuccess = false;
        result.title = 'Contract update failed';
        result.message = ex.getMessage();
        Database.rollback(sp);
        return result;
      }
    }

    if (existingRenewalOpps.size() > 0) {
      try {
        update existingRenewalOpps;
      } catch (Exception ex) {
        result.isSuccess = false;
        result.title = 'Renewal opportunity update failed';
        result.message = ex.getMessage();
        Database.rollback(sp);
        return result;
      }
    }

    if (selectedOppIds != null && selectedOppIds.size() > 0) {
      for (String oId : selectedOppIds) {
        selectedOppList.add(new Opportunity(Id = oId, Financial_Metrics_Dirty__c = true));
      }

      try {
        update selectedOppList;
      } catch (Exception ex) {
        result.isSuccess = false;
        result.title = 'Selected opportunity update failed';
        result.message = ex.getMessage();
        Database.rollback(sp);
        return result;
      }
    }

    return result;
  }
}