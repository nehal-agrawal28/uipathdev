/**
 * Renewal forecast contract
 */
public with sharing class ContractRenewalQueueable_SL extends AbstractQueueable {
  private static final String STATUS_ACTIVATED = 'Activated';
  private static final String CONTRACT_TYPE_STRIPE = 'Stripe';
  private final Contract con;

  public ContractRenewalQueueable_SL(Contract con) {
    super('ContractRenewalQueueable_SL');
    this.con = con;
    //to allow for logging against record. only used in non-bulk contexts
    if (con != null) {
      this.setPrimaryRecordId(con.Id);
    }
  }

  public override void work() {
    Contract contractToUpdate = new Contract(Id = con.Id, SBQQ__RenewalForecast__c = true);

    if (con.Contract_Uplift_Enabled__c == false) {
      contractToUpdate.SBQQ__RenewalUpliftRate__c = null;
      contractToUpdate.Uplift_Exception_Reason__c = null;
    }
    // OTO-1142 : setting again to true before generating renewal opportunity
    contractToUpdate.SBQQ__PreserveBundleStructureUponRenewals__c = true;

    update contractToUpdate;
  }

  /**
   * Generate renewal opportunity for a contract
   * * CPQ Forecasting can't process multiple contracts in a queueable context
   * @param contracts
   * @param existingRecords
   */
  public static void renewalsForecast(List<Contract> contracts, Map<Id, SObject> existingContracts) {
    SObjectPredicate hasChanged = new HasRecordChanged(
      new Set<SObjectField>{ Contract.Status },
      contracts,
      existingContracts
    );
    List<Contract> eligibleContracts = (List<Contract>) Collection.of(contracts)
      .filter(
        Match.field(Contract.SBQQ__RenewalForecast__c)
          .equals(false)
          .also(Contract.Status)
          .equals(STATUS_ACTIVATED)
          .also(Contract.Contract_Type__c)
          .notEquals(CONTRACT_TYPE_STRIPE)
      )
      .filter(hasChanged)
      .asList();

    // CPQ Forecasting can't process multiple contracts in a queueable context
    // Spawn a future to run a new queueable for single contract
    // *CPQ generate contract from a managed queueable service
    // to forecast on contract creation, invoke a future method
    if (eligibleContracts.size() > 0) {
      for (Contract con : eligibleContracts) {
        if (!System.isQueueable()) {
          AbstractQueueable.enqueue(new ContractRenewalQueueable_SL(con));
        } else {
          forecastContract(con.Id);
        }
      }
    }
  }

  @future
  private static void forecastContract(String contractId) {
    Contract con = new Contract(Id = contractId);
    AbstractQueueable.enqueue(new ContractRenewalQueueable_SL(con));
  }
}