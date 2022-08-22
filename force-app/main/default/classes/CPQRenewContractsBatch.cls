/**
 * Created by pierre.gousse on 9/11/2019.
 * Used for CPQ data load migration
 * Flag 'Renewal Forecast' checkbox to TRUE for all CPQ migrated Contract
 */

global class CPQRenewContractsBatch implements Database.Batchable<SObject>, Database.Stateful {
    global Integer recordsProcessed = 0;

    global Database.QueryLocator start(Database.BatchableContext bc){
        return Database.getQueryLocator(
                'SELECT SBQQ__RenewalForecast__c, Id FROM Contract WHERE SBQQ__RenewalForecast__c = FALSE AND CPQ_Migration__c = TRUE LIMIT 500'
        );
    }
    global void execute(Database.BatchableContext bc, List<Contract> scope){
        for(Contract contract:scope){
            contract.SBQQ__RenewalForecast__c = TRUE;
            recordsProcessed = recordsProcessed + 1;
        }
        update scope;
    }
    global void finish(Database.BatchableContext bc){
        // Get the ID of the AsyncApexJob representing this batch job
        // from Database.BatchableContext.
        // Query the AsyncApexJob object to retrieve the current job's information.
        AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed,
                TotalJobItems, CreatedBy.Email
        FROM AsyncApexJob WHERE Id =
                :BC.getJobId()];
        // OPTIONAL: Send an email to the Apex job's submitter notifying of job completion.
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddresses = new String[] {a.CreatedBy.Email};
        mail.setToAddresses(toAddresses);
        mail.setSubject('Contract Renewal Batch ' + a.Status);
        mail.setPlainTextBody
                ('The batch Apex job processed ' + a.TotalJobItems +
                        ' batches with '+ a.NumberOfErrors + ' failures.');
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
}