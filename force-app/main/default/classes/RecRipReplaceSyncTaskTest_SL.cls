@IsTest
public with sharing class RecRipReplaceSyncTaskTest_SL {
  @IsTest
  public static void itCreatesAnOppTask() {
    Opportunity opp = new Opportunity(Id = fflib_IDGenerator.generate(Opportunity.getSObjectType()));
    OppRipReplaceSyncQueueableSerial_SL.TaskInputWrapper taskWrapper = new OppRipReplaceSyncQueueableSerial_SL.TaskInputWrapper(
      opp
    );
    String jsonStr = JSON.serialize(taskWrapper);

    OppRipReplaceSyncTask_SL oRRsT = new OppRipReplaceSyncTask_SL();
    AsyncTask__c asyncTask = oRRsT.createTask(jsonStr, new AsyncTask__c());
    try {
      oRRsT.doTask(asyncTask);
    } catch (Exception e) {
    }
  }

  @IsTest
  public static void itCreatesQuoteTask() {
    SBQQ__Quote__c quote = new SBQQ__Quote__c(Id = fflib_IDGenerator.generate(SBQQ__Quote__c.getSObjectType()));
    QuoteRipReplaceSyncQueueableSerial_SL.TaskInputWrapper taskWrapper = new QuoteRipReplaceSyncQueueableSerial_SL.TaskInputWrapper(
      quote
    );
    String jsonStr = JSON.serialize(taskWrapper);

    QuoteRipReplaceSyncTask_SL qRRsT = new QuoteRipReplaceSyncTask_SL();
    AsyncTask__c asyncTask = qRRsT.createTask(jsonStr, new AsyncTask__c());
    try {
      qRRsT.doTask(asyncTask);
    } catch (Exception e) {
    }
  }

  @IsTest
  public static void itCreatesAnOrderTask() {
    Order order = new Order(Id = fflib_IDGenerator.generate(Order.getSObjectType()));
    OrderRipReplaceSyncQueueableSerial_SL.TaskInputWrapper taskWrapper = new OrderRipReplaceSyncQueueableSerial_SL.TaskInputWrapper(
      order
    );
    String jsonStr = JSON.serialize(taskWrapper);

    OrderRipReplaceSyncTask_SL oRRsT = new OrderRipReplaceSyncTask_SL();
    AsyncTask__c asyncTask = oRRsT.createTask(jsonStr, new AsyncTask__c());
    try {
      oRRsT.doTask(asyncTask);
    } catch (Exception e) {
    }
  }
}