public with sharing class ContractSetSupportFlagOnAccQueueable_SL extends AbstractQueueable {
  private final List<Contract> contracts;

  public ContractSetSupportFlagOnAccQueueable_SL(List<Contract> contracts) {
    super('ContractSetSupportFlagOnAccQueueable_SL');
    this.contracts = contracts;
    //to allow for logging against record. only used in non-bulk contexts
    if (contracts != null && contracts.size() == 1) {
      this.setPrimaryRecordId(contracts.get(0).Id);
    }
  }

  public override void work() {
    this.updateClearForSuppOnAccounts(this.contracts);
  }

  private void updateClearForSuppOnAccounts(List<Contract> contracts) {
    List<Id> accountIds = Collection.of(contracts).pluckIds(Contract.AccountId);

    Map<Id, AggregateResult> contractCountMap = new Map<Id, AggregateResult>(
      [
        SELECT AccountId Id, COUNT(Id) ContractCount
        FROM Contract
        WHERE AccountId != NULL AND AccountId IN :accountIds AND Status = :Constants_SL.CONTRACT_STATUS_ACTIVATED
        GROUP BY AccountId
      ]
    );

    List<Account> accountsToUpdate = new List<Account>();
    for (Account acct : [SELECT Id, Cleared_for_Support__c FROM Account WHERE Id IN :accountIds]) {
      if (contractCountMap.get(acct.Id) != null) {
        acct.Cleared_for_Support__c = ((Integer) contractCountMap.get(acct.Id).get('ContractCount') <= 1);
        accountsToUpdate.add(acct);
      }
    }
    update accountsToUpdate;
  }

  /**
   * @param contracts
   * @param existingRecords
   */
  public static void setClearForSuppOnUpdate(List<Contract> contracts, Map<Id, SObject> existingContracts) {
    SObjectPredicate hasChanged = new HasRecordChanged(
      new Set<SObjectField>{ Contract.Status },
      contracts,
      existingContracts
    );
    List<Contract> eligibleContracts = (List<Contract>) Collection.of(contracts)
      .filter(hasChanged)
      .filter(
        Match.field(Contract.Status)
          .isIn(new Set<String>{ Constants_SL.CONTRACT_STATUS_ACTIVATED, Constants_SL.CONTRACT_STATUS_EXPIRED })
      )
      .asList();

    if (eligibleContracts.size() > 0) {
      AbstractQueueable.enqueue(new ContractSetSupportFlagOnAccQueueable_SL(eligibleContracts));
    }
  }
}