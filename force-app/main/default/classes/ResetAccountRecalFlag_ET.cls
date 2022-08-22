/**
 * This batch will reset the Recalculate Compensation flag for Account
 */
public without sharing class ResetAccountRecalFlag_ET implements IGenericBatch {
  public void execute(Database.BatchableContext BC, List<Sobject> sobjectList) {
    // Defer Queueable
    AbstractQueueable.deferEnqueue();
    List<Account> listOfAccounts = new List<Account>();
    List<Account> accountList = (List<Account>) sobjectList;
    for (Account objAcc : accountList) {
      objAcc.Recalculate_Compensation__c = false;
      listOfAccounts.add(objAcc);
    }
    try {
      List<Database.SaveResult> result = Database.update(listOfAccounts, false);
      Logger.debug(new LogMessage('Updated Account Result', ''), result);
    } catch (Exception ex) {
      Logger.debug(new LogMessage('Account Update failed', ex.getLineNumber() + ex.getMessage()));
    } finally {
      logger.saveLog();
    }
  }

  public void finish(Database.BatchableContext BC) {
  }
}