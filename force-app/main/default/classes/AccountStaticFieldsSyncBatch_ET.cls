/**
 * @AUTHOR: UIPath
 * @DATE: 12/01/2022
 * @DESCRIPTION: This is Account Static Fields Sync Batch which will fetch all account records and update static fields with
 * Is_Domestic_Child__c and Territory_Postal_Code_Mapping__c field for the existing account records
 */
public class AccountStaticFieldsSyncBatch_ET implements IGenericBatch {
  public void execute(Database.BatchableContext BC, List<Sobject> sobjectList) {
    List<Account> listOfAccounts = (List<Account>) sobjectList;
    if (!listOfAccounts.isEmpty() && listOfAccounts.size() > 0) {
      AccountsService_ET instance = new AccountsService_ET();
      instance.populateTerritoryZipcodeMapping(listOfAccounts, null, true, false);
      Logger.saveLog();
    }
  }
  public void finish(Database.BatchableContext BC) {
  }
}