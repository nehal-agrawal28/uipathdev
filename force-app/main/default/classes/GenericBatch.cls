/**
 * @AUTHOR: UIPath
 * @DATE: 01/10/2021
 * @DESCRIPTION: This is a generic batch class
 */
global class GenericBatch implements Database.Batchable<sObject>, Database.Stateful, System.Schedulable {
  Batch_Apex__c batch;
  IGenericBatch batchImp;
  String loggerTransactionId;

  global GenericBatch(String parentName, Integer orderNumber) {
    BatchApexSelector batchSelector = (BatchApexSelector) Application_ET.Selector.newInstance(
      Batch_Apex__c.SObjectType
    );
    List<Batch_Apex__c> batchList = batchSelector.selectByBatchOrder(orderNumber, parentName);
    if (batchList.size() > 0) {
      batch = batchList[0];
      Type batchType = Type.forName(batch.Batch_Class__c);
      batchImp = (IGenericBatch) batchType.newInstance();
    } else {
      throw new GenericBatchException('Batch not found');
    }
  }

  global GenericBatch(Batch_Apex__c batch) {
    this.batch = batch;
    if (batch == null) {
      throw new GenericBatchException('Batch not found');
    }
    Type batchType = Type.forName(batch.Batch_Class__c);
    batchImp = (IGenericBatch) batchType.newInstance();
  }

  global GenericBatch(Batch_Apex__c batch, String loggerTrasactionId) {
    this(batch);
    this.loggerTransactionId = loggerTransactionId;
  }

  // Logic only works if user is added / updated in ObjectTerritory2Association on Sales Territory
  global Database.QueryLocator start(Database.BatchableContext BC) {
    if (loggerTransactionId != null) {
      Logger.setParentLogTransactionId(loggerTransactionId);
    }
    String query = createQuery(batch);
    Logger.debug(query);
    Logger.saveLog();
    if (loggerTransactionId == null) {
      loggerTransactionId = Logger.getTransactionId();
    }
    batch.Last_Run_DateTime__c = System.now();
    return Database.getQueryLocator(query);
  }

  global void execute(System.SchedulableContext ctx) {
    // Run batch for object territory association
    Database.executeBatch(
      new GenericBatch(batch),
      batch.Batch_Size__c != null ? Integer.ValueOf(batch.Batch_Size__c) : 200
    );
  }

  global void execute(Database.BatchableContext BC, List<Sobject> sobjectList) {
    Logger.setParentLogTransactionId(loggerTransactionId);
    batchImp.execute(BC, sobjectList);
  }

  // Create query
  private String createQuery(Batch_Apex__c batch) {
    String query = '';
    if (batch != null) {
      query = batch.Start_Query__c.toLowerCase();
      if (batch.DateTime_Filter__c != null && batch.Last_Run_DateTime__c != null) {
        if (query.contains('where')) {
          query += ' AND ';
        } else {
          query += ' where ';
        }
        String dateTimeFilter = batch.DateTime_Filter__c;
        dateTimeFilter = dateTimeFilter.replace(
          '[DATE_VALUE]',
          batch.Last_Run_DateTime__c.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'')
        );
        query += dateTimeFilter;
      }

      query = query + ' ' + (batch.Start_Query_Order_By__c != null ? ' Order By ' + batch.Start_Query_Order_By__c : '');
    }
    return query;
  }

  global void finish(Database.BatchableContext BC) {
    batchImp.finish(BC);
    Logger.saveLog();
    final fflib_ISObjectUnitOfWork unitOfWork = Application_ET.UnitOfWork.newInstance();
    unitOfWork.registerDirty(batch);
    unitOfWork.commitWork();
    BatchApexSelector batchSelector = (BatchApexSelector) Application_ET.Selector.newInstance(
      Batch_Apex__c.SObjectType
    );
    Batch_Apex__c nextBatch = batchSelector.getNextOrder(batch);
    if (nextBatch != null) {
      Database.executeBatch(
        new GenericBatch(nextBatch, logger.getTransactionId()),
        nextBatch.Batch_Size__c != null ? Integer.ValueOf(nextBatch.Batch_Size__c) : 200
      );
    }
  }

  public class GenericBatchException extends Exception {
  }
}