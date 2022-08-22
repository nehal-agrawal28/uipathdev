/**
 * This queueable class process contracts where RenewalOpportunity lookup
 * was changed and set Dirty flag on both old/new RenewalOpprtunity records
 */
public with sharing class ContractOptyDirtyFlagQueueable extends AbstractQueueable {
  private final List<Contract> contractsLst;
  private final Map<Id, SObject> oldContractsMap;

  public ContractOptyDirtyFlagQueueable(List<SObject> contractsLst, Map<Id, SObject> oldContractsMap) {
    super('ContractOptyDirtyFlagQueueable');
    this.contractsLst = (List<Contract>) contractsLst;
    this.oldContractsMap = oldContractsMap;
    //to allow for logging against record. only used in non-bulk contexts
    if (contractsLst !=null && contractsLst.size() == 1) {
      this.setPrimaryRecordId(contractsLst.get(0).Id);
    }
  }

  public override void work() {
    this.updateDirtyFlagOnOpties(this.contractsLst, this.oldContractsMap);
  }

  private void updateDirtyFlagOnOpties(List<Contract> contractsLst, Map<Id, SObject> oldContractsMap) {
    List<Id> optiesToSetDirty = new List<Id>();
    optiesToSetDirty.addAll(Collection.of(contractsLst).pluckIds(Contract.SBQQ__RenewalOpportunity__c));
    optiesToSetDirty.addAll(Collection.of(oldContractsMap.values()).pluckIds(Contract.SBQQ__RenewalOpportunity__c));
    List<Opportunity> oppToUpdate = new List<Opportunity>();

    for (Id oppId : optiesToSetDirty) {
      if (oppId != null) {
        oppToUpdate.add(new Opportunity(Id = oppId, Financial_Metrics_Dirty__c = true));
      }
    }

    if (oppToUpdate.size() > 0) {
      update oppToUpdate;
    }
  }

  /**
   * Set opty dirty flag when SBQQ__RenewalOpportunity__c field changes on both old and new lookup
   */
  public static void setDirtyFlagOnRenewalOpties(List<Contract> contractsLst, Map<Id, SObject> oldContractsMap) {
    SObjectPredicate hasChanged = new HasRecordChanged(
      new Set<SObjectField>{ Contract.SBQQ__RenewalOpportunity__c },
      contractsLst,
      oldContractsMap
    );

    List<Contract> eligibleContracts = (List<Contract>) Collection.of(contractsLst).filter(hasChanged).asList();

    if (!eligibleContracts.isEmpty()) {
      AbstractQueueable.enqueue(new ContractOptyDirtyFlagQueueable(eligibleContracts, oldContractsMap));
    }
  }
}