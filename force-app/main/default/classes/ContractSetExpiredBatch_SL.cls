/**
 * Batch that sets Contracts to Expired after their End Date
 */
public class ContractSetExpiredBatch_SL implements System.Schedulable, Database.Batchable<sObject> {
  public void execute(SchedulableContext context) {
    Database.executeBatch(new ContractSetExpiredBatch_SL());
  }

  public static String scheduleJob(String scheduleString) {
    String name = ContractSetExpiredBatch_SL.class.getName() + System.now().format(' yyyy-MM-dd HH:mm:ss z');

    return scheduleJob(name, scheduleString);
  }

  public static String scheduleJob(String name, String scheduleString) {
    return System.schedule(name, scheduleString, new ContractSetExpiredBatch_SL());
  }

  public Database.QueryLocator start(Database.BatchableContext ctx) {
    CPQ_Config__c CPQSetting = [SELECT Id, Expiration_Interval__c FROM CPQ_Config__c LIMIT 1];
    String query =
      'SELECT Status, EndDate, AccountId FROM Contract WHERE EndDate < LAST_N_DAYS:' +
      CPQSetting.Expiration_Interval__c +
      ' AND Status!=\'Expired\' ORDER BY AccountId';
    return Database.getQueryLocator(query);
  }

  public void execute(Database.BatchableContext ctx, List<Contract> scope) {
    System.debug('Setting the queried Contracts to expired');
    List<Contract> contractToUpdate = new List<Contract>();
    for (Contract contractInScope : scope) {
      contractInScope.Status = 'Expired';
      contractToUpdate.add(contractInScope);
    }
    Database.SaveResult[] saveResults = Database.update(contractToUpdate, false);
  }

  public void finish(Database.BatchableContext bc) {
  }
}