/* run batch =============================================================
   AccountSetRenewalExpDateBatch accBatchObject = new AccountSetRenewalExpDateBatch(); 
   Id batchId = Database.executeBatch(accBatchObject);
==========================================================================*/

global class AccountSetRenewalExpDateBatch implements Database.Batchable<sObject> {
   
    global Database.QueryLocator start(Database.BatchableContext BC) {
        Set<String> excludedOppStages = new Set<String>{'Closed Won Booked', 'Closed Lost', 'Closed Merged', 'Closed Won Pending'};
        String query = 'SELECT Id, Earliest_Renewal_Expiry_Date__c, (SELECT Id, Renewal_Expiry_Date__c FROM Opportunities WHERE Renewal_Expiry_Date__c != null AND Renewal_Expiry_Date__c >= TODAY AND ARR_to_Renew__c > 0 AND ARR_to_Renew__c != null AND StageName NOT IN: excludedOppStages ORDER BY Renewal_Expiry_Date__c ASC LIMIT 1) FROM Account';
        return Database.getQueryLocator(query);
    }
     
    global void execute(Database.BatchableContext BC, List<Account> accList) {
        List<Account> accToUpdate = new List<Account>();
        for(Account acc : accList) {  
            List<Opportunity> relOpps = acc.Opportunities;
            if(relOpps.size() > 0 && acc.Earliest_Renewal_Expiry_Date__c != relOpps[0].Renewal_Expiry_Date__c) {      
                acc.Earliest_Renewal_Expiry_Date__c = (acc.Opportunities).size() > 0 ? acc.Opportunities[0].Renewal_Expiry_Date__c : null;
                accToUpdate.add(acc);
            }
        }
        if(accToUpdate.size() > 0) {
            try {
                update accToUpdate;
            } catch(Exception e) {
                System.debug(e);
            }
        }
    }

    global void finish(Database.BatchableContext BC) {
        // execute any post-processing operations like sending email
    }
}