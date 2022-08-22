public without sharing class AccountUpdateRenewalOwnerQueueable extends AbstractQueueable {
  private final List<Account> accountsList;
  private final static String UPDATE_REN_OWN_SERVICE = 'UpdateRenewalOwnerService_SL';

  public AccountUpdateRenewalOwnerQueueable(List<Account> accountsList) {
    super('AccountUpdateRenewalOwnerQueueable');
    this.accountsList = accountsList;
    //to allow for logging against record. only used in non-bulk contexts
    if (accountsList !=null && accountsList.size() == 1) {
      this.setPrimaryRecordId(accountsList.get(0).Id);
    }
  }

  public override void work() {
    this.updateRenewalAmendmentOwners();
  }

  private void updateRenewalAmendmentOwners() {
    Type updateRenOwnerService = Type.forName(UPDATE_REN_OWN_SERVICE);

    if (updateRenOwnerService != null) {
      // Calling service implementation class
      IUpdateRenewalOwnerService serviceInstance = (IUpdateRenewalOwnerService) updateRenOwnerService.newInstance();
      serviceInstance.updateContractFieldsAndRenewalOwners(this.accountsList);
    } else {
      System.debug('Implementation class ' + UPDATE_REN_OWN_SERVICE + ' not found');
    }
  }

  /**
   * Loop and set Owner on all contacts to the owner of Account
   * @param existingRecords
   */
  public static void setRenewalAmendmentOwners(List<Account> accounts, Map<Id, SObject> existingAccounts) {
    SObjectPredicate hasChanged = new HasRecordChanged(
      new Set<SObjectField>{ Account.OwnerId },
      accounts,
      existingAccounts
    );
    List<Account> eligibleAccounts = (List<Account>) Collection.of(accounts)
      .filter(Match.field(Account.OwnerId).hasValue())
      .filter(hasChanged)
      .asList();

    if (eligibleAccounts.size() > 0) {
      AbstractQueueable.enqueue(new AccountUpdateRenewalOwnerQueueable(eligibleAccounts));
    }
  }
}