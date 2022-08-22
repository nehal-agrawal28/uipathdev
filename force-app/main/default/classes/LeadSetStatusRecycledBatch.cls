/********************************************************************************************************
*    Batch Name:  LeadSetStatusRecycledBatch.cls
*    Author: Mirela Chituc (mirela.chituc@uipath.com) 
*    Date:  11/5/2020
*    // sets Status = 'Recycle' for leads with 
*    Status "New" and New Date older that 180 days or
*    Status "Working" and Working Date older than 90 days
*    Scheduler Class: LeadSetOwnerScheduler.cls
*    Test class: LeadSetStatusRecycledTest.cls

*    Manual run (copy code in developer console) 
*    
     LeadSetStatusRecycledBatch lssr = new LeadSetStatusRecycledBatch();
     database.executeBatch(lssr, 10);
********************************************************************************************************/

global class LeadSetStatusRecycledBatch implements Schedulable, Database.Batchable<sObject> {
  global Id recordTypeStandardId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName()
    .get('Standard')
    .getRecordTypeId();

  global void execute(SchedulableContext SC) {
    Database.executeBatch(new LeadSetStatusRecycledBatch());
  }

  global Database.QueryLocator start(Database.BatchableContext BC) {
    /*String query = 'SELECT Id, Status, Recycled_Reason__c, No_of_days_since_last_activity__c FROM Lead WHERE ' + 
        + '(((Geo__c = \'AMER\' OR Geo__c = \'EMEA\' OR Geo__c = \'India\') AND RecordTypeId =: recordTypeStandardId AND ' + 
        + '((No_of_days_since_last_activity__c != NULL AND ((Status = \'New\' AND No_of_days_since_last_activity__c >= 180) OR (Status = \'Working\' AND No_of_days_since_last_activity__c >= 90))) OR ' + 
        + '(No_of_days_since_last_activity__c = NULL AND ((Status = \'New\' AND No_of_days_in_current_status__c >= 180) OR (Status = \'Working\' AND No_of_days_in_current_status__c >= 90))))) ' + 
        + 'OR ((Geo__c = \'APAC\' OR Geo__c = \'Japan\') AND RecordTypeId =: recordTypeStandardId AND ' +
        + '((No_of_days_since_last_activity__c != NULL AND ((Status = \'New\' AND No_of_days_since_last_activity__c >= 90) OR (Status = \'Working\' AND No_of_days_since_last_activity__c >= 180))) OR ' + 
        + '(No_of_days_since_last_activity__c = NULL AND ((Status = \'New\' AND No_of_days_in_current_status__c >= 90) OR (Status = \'Working\' AND No_of_days_in_current_status__c >= 180))))))';*/

    String query =
      'SELECT Id, Status, Recycled_Reason__c, No_of_days_since_last_activity__c FROM Lead WHERE ' +
      +'(((Geo__c = \'AMER\' OR Geo__c = \'EMEA\' OR (Geo__c = \'APJ\' AND Area__c = \'India\')) AND RecordTypeId =: recordTypeStandardId AND ' +
      +'((No_of_days_since_last_activity__c != NULL AND ((Status = \'New\' AND No_of_days_since_last_activity__c >= 180) OR (Status = \'Working\' AND No_of_days_since_last_activity__c >= 90))) OR ' +
      +'(No_of_days_since_last_activity__c = NULL AND ((Status = \'New\' AND No_of_days_in_current_status__c >= 180) OR (Status = \'Working\' AND No_of_days_in_current_status__c >= 90))))) ' +
      +'OR ((Geo__c = \'APJ\' AND Area__c != \'India\') AND RecordTypeId =: recordTypeStandardId AND ' +
      +'((No_of_days_since_last_activity__c != NULL AND ((Status = \'New\' AND No_of_days_since_last_activity__c >= 90) OR (Status = \'Working\' AND No_of_days_since_last_activity__c >= 180))) OR ' +
      +'(No_of_days_since_last_activity__c = NULL AND ((Status = \'New\' AND No_of_days_in_current_status__c >= 90) OR (Status = \'Working\' AND No_of_days_in_current_status__c >= 180))))))';

    return Database.getQueryLocator(query);
  }

  global void execute(Database.BatchableContext BC, List<sObject> scope) {
    system.debug(' ' + scope);
    for (Lead l : (List<Lead>) scope) {
      l.Status = 'Recycle';
      l.Recycled_Reason__c = 'Automatically Recycled';
    }
    update scope;
  }

  global void finish(Database.BatchableContext BC) {
  }
}