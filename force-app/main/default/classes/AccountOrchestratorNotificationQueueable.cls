/**
 * Publishes events to the Uipath Connector framework - which then sends the account to Netsuite
 */
public with sharing class AccountOrchestratorNotificationQueueable extends AbstractQueueable {
  private final List<SObject> accountList;
  public static Integer numEvents = 0;
  public AccountOrchestratorNotificationQueueable(List<SObject> accountList) {
    super('AccountOrchestratorNotificationQueueable');
    this.accountList = accountList;
     //to allow for logging against record. only used in non-bulk contexts
     if (accountList !=null && accountList.size() == 1) {
      this.setPrimaryRecordId(accountList.get(0).Id);
    }
  }

  public override void work() {
    this.publishOrchestratorNotification(this.accountList);
  }

  private void publishOrchestratorNotification(List<Account> accountList) {
    Set<Id> accIds = new Set<Id>();

    for (Account acc : accountList) {
      if (
        acc.Sync_Status__c == CommonsConstants.ACC_SYNC_STATUS_VALID ||
        acc.Sync_Status__c == CommonsConstants.ACC_SYNC_STATUS_PENDING
      ) {
        accIds.add(acc.Id);
      }
    }
    if (!accIds.isEmpty()) {
      numEvents = numEvents + accIds.size();
      IntegrationHandler.callUipathSFConnectorTemplate(accIds, CommonsConstants.ACC_UIPATH_SF_CONNECTOR_TEMPLATE);
    }
  }

  public static void publishNewAccountsToNetsuite(List<Account> accounts) {
    List<Account> eligibleAccounts = (List<Account>) Collection.of(accounts)
      .filter(Match.field(Account.Sync_Status__c).hasValue())
      .filter(
        Match.field(Account.Sync_Status__c)
          .isIn(new Set<String>{ CommonsConstants.ACC_SYNC_STATUS_VALID, CommonsConstants.ACC_SYNC_STATUS_PENDING })
      )
      .asList();

    if (!eligibleAccounts.isEmpty()) {
      AbstractQueueable.enqueue(new AccountOrchestratorNotificationQueueable(eligibleAccounts));
    }
  }

  public static void publishUpdatedAccountsToNetsuite(List<Account> accounts, Map<Id, SObject> existingAccounts) {
    SObjectPredicate hasChanged = new HasRecordChanged(
      new Set<SObjectField>{ Account.Sync_Status__c },
      accounts,
      existingAccounts
    );
    List<Account> eligibleAccounts = (List<Account>) Collection.of(accounts)
      .filter(Match.field(Account.Sync_Status__c).hasValue())
      .filter(
        Match.field(Account.Sync_Status__c)
          .isIn(new Set<String>{ CommonsConstants.ACC_SYNC_STATUS_VALID, CommonsConstants.ACC_SYNC_STATUS_PENDING })
      )
      .filter(hasChanged)
      .asList();

    if (!eligibleAccounts.isEmpty()) {
      AbstractQueueable.enqueue(new AccountOrchestratorNotificationQueueable(eligibleAccounts));
    }
  }
}