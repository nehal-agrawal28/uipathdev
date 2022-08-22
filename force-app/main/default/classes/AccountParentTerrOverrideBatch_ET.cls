/**
 * @AUTHOR: UIPath
 * @DATE: 30/05/2022
 * @DESCRIPTION: This is AccountParentTerrOverrideBatch_ET class
 */
public class AccountParentTerrOverrideBatch_ET implements IGenericBatch {
  // Implemented execute method which gets called from generic batch execute
  public void execute(Database.BatchableContext BC, List<Sobject> sobjectList) {
    List<Account> updateAccounts = new List<Account>();
    for (Account acc : (List<Account>) sobjectList) {
      acc.Parent_Territory_Override__c = true;
      updateAccounts.add(acc);
    }
    try {
      Database.SaveResult[] saveResults = Database.update(updateAccounts, false);
      Logger.debug(new LogMessage('Account Parent_Territory_Override__c Result', ''), saveResults);
    } catch (Exception ex) {
      Logger.debug(new LogMessage('Account Parent_Territory_Override__c failed', ex.getLineNumber()));
    } finally {
      logger.saveLog();
    }
  }

  public void finish(Database.BatchableContext BC) {
  }
}