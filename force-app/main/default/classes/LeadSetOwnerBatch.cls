/********************************************************************************************************
*    Batch Name:  LeadSetOwnerBatch.cls
*    Author: Mirela Chituc (mirela.chituc@uipath.com) 
*    Date:  12/13/2019
*    // sets owner to queue for leads with status "New" older that ~24h
*    Scheduler Class: LeadSetOwnerScheduler.cls
*    Test class: LeadSetOwnerBatchTest.cls

*    Manual run (copy code in developer console) 
*    
     LeadSetOwnerBatch lso = new LeadSetOwnerBatch();
     database.executeBatch(lso, 10);
********************************************************************************************************/

global class LeadSetOwnerBatch implements Database.Batchable<sObject> {

// Start Method

    global Database.QueryLocator start(Database.BatchableContext BC) {
        Date yesterday = (Date.today()).addDays(-1);
        // String query = 'SELECT Id, Status, OwnerId, Owner.Name, Disable_Owner_Change__c, Account__c, Account__r.EDR__c FROM Lead WHERE Last_Change_Status_Date__c =: yesterday AND Status =\'New\' AND Geo__c = \'AMER\' AND Tier__c = \'1\' AND First_Contact_Us_Date__c != null';
        String query = 'SELECT Id, Status, OwnerId, Owner.Name, Disable_Owner_Change__c, Account__c, Account__r.EDR__c FROM Lead WHERE Last_Change_Status_Date__c =: yesterday AND Status =\'New\' AND Geo__c = \'AMER\' AND Progressed_to_MQL__c = true AND First_Contact_Us_Date__c != null';
        return Database.getQueryLocator(query);

    }

   // Execute method

    global void execute(Database.BatchableContext BC, List<Lead> scope) {
         
         List<Lead> leadsToUpdate = new List<Lead>();
         List<Lead> assignementRulesLeads = new List<Lead>();
         for(Lead l: scope) {
             l.Disable_Owner_Change__c = true;
             if(l.Account__c != null && l.Account__r.EDR__c != null) {
                 l.OwnerId = l.Account__r.EDR__c;
                 leadsToUpdate.add(l);
             } else
                 assignementRulesLeads.add(l);
         }
         if(leadsToUpdate.size() > 0)
             update leadsToUpdate;
         
         if(assignementRulesLeads.size() > 0) {
             AssignmentRule ar = [SELECT Id from AssignmentRule where SobjectType  = 'Lead' and active = true AND Name = 'Assignment based on Territory' limit 1];
             Database.DMLOptions dmlOpts = new Database.DMLOptions();
             dmlOpts.assignmentRuleHeader.assignmentRuleId = ar.id;
             database.update(assignementRulesLeads, dmlOpts);  
         }         
    }   

    // Finish Method

    global void finish(Database.BatchableContext BC) {

    }

}