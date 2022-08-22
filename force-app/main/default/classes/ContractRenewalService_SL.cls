/**
 * CPQ renewal uplift service implementation
 */
public with sharing class ContractRenewalService_SL implements IContractRenewalService_SL {
  private static final String ACCOUNT_RENEWAL_METHOD_UPLIFT = 'Uplift';

  private List<Contract> contractsToUpdate = new List<Contract>();
  private List<Contract> evaluateUplifts = new List<Contract>();
  private List<Contract> removeUplifts = new List<Contract>();
  private fflib_ISObjectUnitOfWork unitOfWork = Application_SL.UnitOfWork.newInstance();

  private ContractsSelector_SL contractSelector {
    get {
      return (ContractsSelector_SL) Application_SL.Selector.newInstance(Contract.SObjectType);
    }
    set;
  }

  private ISubscriptionUpliftService_SL subscriptionService = (ISubscriptionUpliftService_SL) Application_SL.Service.newInstance(
    ISubscriptionUpliftService_SL.class
  );

  private Boolean optIn;
  private Boolean applyOptInOptOut = false;
  private Boolean bypassThreshold = false;

  // Settings to manipulate service behaviour
  public ContractRenewalService_SL optInToUplift() {
    optIn = true;
    applyOptInOptOut = true;
    return this;
  }
  public ContractRenewalService_SL optOutToUplift() {
    optIn = false;
    applyOptInOptOut = true;
    return this;
  }
  public ContractRenewalService_SL bypassThresholdValidation() {
    bypassThreshold = true;
    return this;
  }

  /**
   * @description               process contract records to set renewal uplift fields
   * @param  contractIds        list of contract Ids
   */
  public void performUpliftCalculations(Set<Id> contractIds) {
    // Fetch contract records
    List<Contract> contractList = contractSelector.selectContractsForUplift(contractIds);

    // OptIn/OptOut contracts from uplift
    if (applyOptInOptOut) {
      contractUpliftOptInOptOut(contractList);
    }

    // Apply uplift business rules
    applyRulesAndFilterContracts(contractList);

    // Delegate work to subscription service
    if (evaluateUplifts.size() > 0) {
      subscriptionService.evaluateSubscriptionUplifts(new Map<Id, Contract>(evaluateUplifts).keySet());
    }
    if (removeUplifts.size() > 0) {
      subscriptionService.removeSubscriptionUplifts(new Map<Id, Contract>(removeUplifts).keySet());
    }

    // Commit contracts to database
    if (contractsToUpdate.size() > 0) {
      unitOfWork.registerDirty(contractsToUpdate);
      unitOfWork.commitWork();
    }
  }

  private void contractUpliftOptInOptOut(List<Contract> contractList) {
    for (Contract con : contractList) {
      if (optIn) {
        con.Contract_Uplift_Enabled__c = true;
      } else {
        con.Contract_Uplift_Enabled__c = false;
      }
    }
  }

  private void applyRulesAndFilterContracts(List<Contract> contractList) {
    for (Contract con : contractList) {
      CPQ_Renewal_Uplift__mdt configMetadata = ContractRenewalService_SL.getUpliftGeoConfig(
        con.Account.Geo__c + con.Account.Area__c,
        con.Account.Geo__c
      );

      if (!con.Contract_Uplift_Enabled__c) {
        // Excluded: Contract is opt out for uplift calculations
        excludeContract(con, null);
      } else if (
        con.SBQQ__Opportunity__r.Sold_to_Partner__c != null ||
        (con.SBQQ__Opportunity__r.Deal_Type__c == 'Managed Service/BPO' ||
        con.SBQQ__Opportunity__r.Deal_Type__c == 'Managed Services' ||
        con.SBQQ__Opportunity__r.Deal_Type__c == 'BPO')
      ) {
        // Excluded: Partner quote
        excludeContract(con, 'Partner Deal');
      } else if (con.Account.SBQQ__RenewalPricingMethod__c != ACCOUNT_RENEWAL_METHOD_UPLIFT) {
        // Excluded: Incorrect Account level renewal method
        excludeContract(con, 'Account Renewal Pricing not Uplift');
      } else if (con.ARR_to_Renew_USD__c < configMetadata.UpliftThreshold__c && !bypassThreshold) {
        // Excluded: Below threshold
        excludeContract(con, 'Below Deal Threshold');
      } else {
        // Included: Apply uplift
        includeContract(con, configMetadata.UpliftRate__c);
      }
    }
  }

  private void excludeContract(Contract con, String reason) {
    con.Uplift_Exception_Reason__c = reason;
    con.SBQQ__RenewalUpliftRate__c = null;

    removeUplifts.add(con);
    contractsToUpdate.add(con);
  }

  private void includeContract(Contract con, Decimal rate) {
    con.Uplift_Exception_Reason__c = null;
    con.SBQQ__RenewalUpliftRate__c = rate;

    evaluateUplifts.add(con);
    contractsToUpdate.add(con);
  }

  /**
   * @description       return uplift config metadata based on Geo
   * @return            uplift config metadata
   */
  private static Map<String, CPQ_Renewal_Uplift__mdt> upliftGeoConfigs {
    get {
      if (upliftGeoConfigs == null) {
        upliftGeoConfigs = new Map<String, CPQ_Renewal_Uplift__mdt>();

        for (CPQ_Renewal_Uplift__mdt cmt : CPQ_Renewal_Uplift__mdt.getAll().values()) {
          if (String.isNotBlank(cmt.Geo__c)) {
            String geoArea = String.isNotBlank(cmt.Area__c) ? cmt.Geo__c + cmt.Area__c : cmt.Geo__c;
            upliftGeoConfigs.put(geoArea, cmt);
          }
        }

        upliftGeoConfigs.put('Default', CPQ_Renewal_Uplift__mdt.getInstance('Default_Config'));
      }
      return upliftGeoConfigs;
    }
    set;
  }
  public static CPQ_Renewal_Uplift__mdt getUpliftGeoConfig(String geoArea, String geo) {
    return upliftGeoConfigs.containsKey(geoArea)
      ? upliftGeoConfigs.get(geoArea)
      : (upliftGeoConfigs.containsKey(geo) ? upliftGeoConfigs.get(geo) : upliftGeoConfigs.get('Default'));
  }
}