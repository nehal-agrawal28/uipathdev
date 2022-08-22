global class LeadDoNotContactBatch implements Schedulable, Database.Batchable<sObject> {

    global void execute(SchedulableContext SC) {
        Database.executeBatch(new LeadDoNotContactBatch());
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator('SELECT Id FROM Lead WHERE Status = \'Suspect\' AND Do_Not_Contact__c <= TODAY');
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope) {
        for (Lead l : (List<Lead>)scope) {
            l.Status = 'New';
            l.Trigger_Assignment__c = true;
        }
        update scope;
    }
    
    global void finish(Database.BatchableContext BC) {
    }
}