/**
 * @AUTHOR: UIPath
 * @DATE: 01/10/2021
 * @DESCRIPTION: This is Batch_Apex__c object selector class
 */
public class BatchApexSelector extends fflib_SObjectSelector {
  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField>{
      Batch_Apex__c.Batch_Class__c,
      Batch_Apex__c.DateTime_Filter__c,
      Batch_Apex__c.Last_Run_DateTime__c,
      Batch_Apex__c.Parent__c,
      Batch_Apex__c.Start_Query__c,
      Batch_Apex__c.Batch_Size__c,
      Batch_Apex__c.Start_Query_Order_By__c,
      Batch_Apex__c.Order__c
    };
  }
  public Schema.SObjectType getSObjectType() {
    return Batch_Apex__c.sObjectType;
  }
  public override String getOrderBy() {
    return 'Order__c asc';
  }

  public List<Batch_Apex__c> selectById(Id recordId) {
    return (List<Batch_Apex__c>) Database.query(
      newQueryFactory(false, false, true)
        .selectField('Parent__r.Name')
        .setCondition('Status__c = \'Active\' AND Id =: recordId')
        .toSOQL()
    );
  }

  public List<Batch_Apex__c> selectByBatchOrder(Integer orderNumber, String parentName) {
    return (List<Batch_Apex__c>) Database.query(
      newQueryFactory(false, false, true)
        .selectField('Parent__r.Name')
        .setCondition('Status__c = \'Active\' AND Order__c =: orderNumber And Parent__r.Name =: parentName')
        .toSOQL()
    );
  }

  public List<Batch_Apex__c> selectNextBatch(Integer orderNumber, String parentName) {
    return (List<Batch_Apex__c>) Database.query(
      newQueryFactory(false, false, true)
        .selectField('Parent__r.Name')
        .setCondition('Status__c = \'Active\' AND Order__c >=: orderNumber And Parent__r.Name =: parentName')
        .addOrdering('Order__c', fflib_QueryFactory.SortOrder.ASCENDING)
        .toSOQL()
    );
  }

  public Batch_Apex__c getNextOrder(Batch_Apex__c batch) {
    if (batch.Order__c != null) {
      List<Batch_Apex__c> batchApexList = selectNextBatch(Integer.ValueOf(batch.Order__c) + 1, batch.Parent__r.Name);
      if (batchApexList.size() > 0) {
        return batchApexList[0];
      }
    }
    return null;
  }
}