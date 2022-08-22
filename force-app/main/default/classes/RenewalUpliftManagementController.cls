public without sharing class RenewalUpliftManagementController {
  public class RenewalUpliftManagementWrapper {
    @AuraEnabled
    public Opportunity opportunity { get; set; }
    @AuraEnabled
    public CPQ_Renewal_Uplift__mdt upliftGeoConfig { get; set; }
  }
  public class DealBuilderManageUpliftWrapper {
    @AuraEnabled
    public List<Contract> contractList { get; set; }
    @AuraEnabled
    public CPQ_Renewal_Uplift__mdt upliftGeoConfig { get; set; }
    @AuraEnabled
    public String accountGeo { get; set; }
    @AuraEnabled
    public String accountUpliftMethod { get; set; }
  }

  /**
   * @description get data for *RenewalUpliftManagement LWC
   * @param  opportunityId opportunityId
   * @return               Data wrapper
   */
  @AuraEnabled
  public static RenewalUpliftManagementWrapper getUpliftData(String opportunityId) {
    RenewalUpliftManagementWrapper wrapper = new RenewalUpliftManagementWrapper();

    wrapper.opportunity = [
      SELECT
        Id,
        Name,
        SBQQ__RenewedContract__c,
        SBQQ__RenewedContract__r.ContractNumber,
        SBQQ__RenewedContract__r.SBQQ__RenewalUpliftRate__c,
        SBQQ__RenewedContract__r.Uplift_Exception_Reason__c,
        SBQQ__RenewedContract__r.Contract_Uplift_Enabled__c,
        AccountId,
        Account.Name,
        Account.Geo__c,
        Account.Area__c,
        Account.SBQQ__RenewalPricingMethod__c
      FROM Opportunity
      WHERE Id = :opportunityId
    ];
    
    String geoArea = wrapper.opportunity.Account.Geo__c + wrapper.opportunity.Account.Area__c;
    String geo = wrapper.opportunity.Account.Geo__c;
    wrapper.upliftGeoConfig = ContractRenewalService_SL.getUpliftGeoConfig(geoArea, geo);

    return wrapper;
  }

  /**
   * @description get data for *DealBuilderManageUpliftModal LWC
   * @param  contractIds   contract Ids
   * @return               Data wrapper
   */
  @AuraEnabled
  public static DealBuilderManageUpliftWrapper getUpliftDataForDealBuilder(List<String> contractIds) {
    DealBuilderManageUpliftWrapper wrapper = new DealBuilderManageUpliftWrapper();

    wrapper.contractList = [
      SELECT
        Id,
        ContractNumber,
        SBQQ__RenewalUpliftRate__c,
        Uplift_Exception_Reason__c,
        Contract_Uplift_Enabled__c,
        ARR_to_Renew_USD__c,
        AccountId,
        Account.Name,
        Account.Geo__c,
        Account.Area__c,
        Account.SBQQ__RenewalPricingMethod__c
      FROM Contract
      WHERE Id IN :contractIds
    ];
    String geoArea = wrapper.contractList[0].Account.Geo__c + wrapper.contractList[0].Account.Area__c;
    String geo = wrapper.contractList[0].Account.Geo__c;
    wrapper.upliftGeoConfig = ContractRenewalService_SL.getUpliftGeoConfig(geoArea, geo);
    wrapper.accountGeo = wrapper.contractList[0].Account.Geo__c;
    wrapper.accountUpliftMethod = wrapper.contractList[0].Account.SBQQ__RenewalPricingMethod__c;

    return wrapper;
  }

  @AuraEnabled
  public static void setAccountMethodUplift(List<String> acountsNeedUpliftMethod) {
    // Update accounts renewal method
    try {
      if (acountsNeedUpliftMethod != null && acountsNeedUpliftMethod.size() > 0) {
        List<Account> accountsToUpdate = new List<Account>();
        Set<String> uniqueAccIds = new Set<String>();
        uniqueAccIds.addAll(acountsNeedUpliftMethod);
        for (String accId : uniqueAccIds) {
          Account acc = new Account(Id = accId, SBQQ__RenewalPricingMethod__c = 'Uplift');
          accountsToUpdate.add(acc);
        }
        update accountsToUpdate;
      }
    } catch (Exception e) {
      String errorStr = e.getMessage() + e.getStackTraceString();
      AuraHandledException exc = new AuraHandledException(errorStr);
      exc.setMessage(errorStr);
      throw exc;
    }
  }

  @AuraEnabled
  public static void applyRenewalUplift(List<String> contractIds, Boolean bypassThresholdValidation) {
    invokeUpliftService(contractIds, true, bypassThresholdValidation);
  }

  @AuraEnabled
  public static void removeRenewalUplift(List<String> contractIds) {
    invokeUpliftService(contractIds, false, false);
  }

  @AuraEnabled
  public static void uncheckRenewalQuoted(String opportunityId) {
    Opportunity opp = [
      SELECT Id, SBQQ__RenewedContract__c, SBQQ__RenewedContract__r.SBQQ__RenewalQuoted__c
      FROM Opportunity
      WHERE Id = :opportunityId
    ];
    if (opp.SBQQ__RenewedContract__r.SBQQ__RenewalQuoted__c) {
      Contract con = new Contract(Id = opp.SBQQ__RenewedContract__c, SBQQ__RenewalQuoted__c = false);
      update con;
    }
  }

  private static void invokeUpliftService(
    List<String> contractIds,
    Boolean applyUplift,
    Boolean bypassThresholdValidation
  ) {
    try {
      Set<Id> contractIdsSet = new Set<Id>((List<Id>) contractIds);
      // Contract renewal uplift service
      IContractRenewalService_SL contractService = (IContractRenewalService_SL) Application_SL.Service.newInstance(
        IContractRenewalService_SL.class
      );

      if (applyUplift) {
        // Apply uplift in realtime
        if (bypassThresholdValidation) {
          contractService.optInToUplift().bypassThresholdValidation().performUpliftCalculations(contractIdsSet);
        } else {
          contractService.optInToUplift().performUpliftCalculations(contractIdsSet);
        }
      } else {
        // Remove uplift in realtime
        contractService.optOutToUplift().performUpliftCalculations(contractIdsSet);
      }
    } catch (Exception e) {
      String errorStr = e.getMessage() + e.getStackTraceString();
      AuraHandledException exc = new AuraHandledException(errorStr);
      exc.setMessage(errorStr);
      throw exc;
    }
  }
}