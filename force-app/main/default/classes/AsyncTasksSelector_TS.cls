public with sharing class AsyncTasksSelector_TS extends fflib_SObjectSelector {
  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField>{
      AsyncTask__c.Id,
      AsyncTask__c.Account__c,
      AsyncTask__c.CreatedDate,
      AsyncTask__c.Opportunity__c,
      AsyncTask__c.Order__c,
      AsyncTask__c.Quote__c,
      AsyncTask__c.Status__c,
      AsyncTask__c.Type__c
    };
  }

  public Schema.SObjectType getSObjectType() {
    return AsyncTask__c.SObjectType;
  }

  public List<AsyncTask__c> selectByRecordId(Id recordId) {
    fflib_QueryFactory query = newQueryFactory(false, false, true);

    fflib_StringBuilder strBuilder = new fflib_StringBuilder();
    strBuilder.add('Opportunity__c = \'');
    strBuilder.add(String.valueOf(recordId));
    strBuilder.add('\'');

    strBuilder.add(' OR ');

    strBuilder.add('Quote__c = \'');
    strBuilder.add(String.valueOf(recordId));
    strBuilder.add('\'');

    strBuilder.add(' OR ');

    strBuilder.add('Order__c = \'');
    strBuilder.add(String.valueOf(recordId));
    strBuilder.add('\'');

    query.setCondition(strBuilder.toString());
    query.setOrdering('CreatedDate', fflib_QueryFactory.SortOrder.DESCENDING);
    query.setLimit(1);
    System.debug('query.toSOQL(): ' + query.toSOQL());

    return (List<AsyncTask__c>) Database.query(query.toSOQL());
  }
}