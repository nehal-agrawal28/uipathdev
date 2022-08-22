/**
 * @AUTHOR: UIPath
 * @DATE: 01/10/2021
 * @DESCRIPTION: This is AccountOwnerSyncBatch class
 */
public without sharing class AccountOwnerSyncBatch_ET implements IGenericBatch {
  public Set<Id> setOfExceptionAccountIds = new Set<Id>();

  // Implemented execute method which gets called from generic batch execute
  public void execute(Database.BatchableContext BC, List<Sobject> sobjectList) {
    List<Account> accountList = (List<Account>) sobjectList;

    // Create map of account id and account instance
    Map<Id, Account> accountMap = new Map<Id, Account>(accountList);

    AccountsService_ET service = (AccountsService_ET) Application_ET.Service.newInstance(AccountsService_ET.class);
    Skip_Email_Alerts__c skipEmailAlert = Skip_Email_Alerts__c.getInstance();
    List<Account> accList = service.syncAccountOwner(accountMap.keyset());
    if (skipEmailAlert != null && !skipEmailAlert.Skip_Email_Alerts_Account__c) {
      for (Account objAccount : accList) {
        if (objAccount.Owner_Sync_Status__c == ETMConstant.OWNER_STATUS_EXCEPTION) {
          setOfExceptionAccountIds.add(objAccount.Id);
        }
      }
    }
  }
  public void finish(Database.BatchableContext BC) {
    Skip_Email_Alerts__c skipEmailAlert = Skip_Email_Alerts__c.getInstance();
    if (skipEmailAlert != null && !skipEmailAlert.Skip_Email_Alerts_Account__c) {
      AccountsSelector_ET accountSelector = (AccountsSelector_ET) Application_ET.Selector.newInstance(
        Account.SObjectType
      );
      ETMSystemNotificationService etmSystem = new ETMSystemNotificationService();
      etmSystem.accountOwnerSyncException(accountSelector.selectById(setOfExceptionAccountIds));
    }
  }
}