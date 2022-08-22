/*******************************************************************************
@author:        Sebastiaan Verstraelen
@date:          17 Jan 2019
@description:   Batch apex class to auto close renewal opportunities 7 days before close date
*******************************************************************************/
global class BatchAutoCloseRenewalOpportunities implements Database.Batchable<sObject>{

    /*******************************************************************************
    @author:        Sebastiaan Verstraelen
    @date:          17 Jan 2019
    @description:   Finds all relevant opportunities
    *******************************************************************************/
    global Database.QueryLocator start(Database.BatchableContext BC){       
        Datetime startTime = Datetime.now().addMinutes(-120);
        System.Debug('startTime execute: ' + startTime );


        /** CPQ Controls **/
        Id cpqRtId = null;
        CPQ_Controls__mdt cpqControls = null;
        try {
            cpqControls = [SELECT Id, Opp_CPQ_Record_Type_Developer_Name__c, Opp_C_BatchAutoCloseRenewalOpportunities__c FROM CPQ_Controls__mdt LIMIT 1];

            if(Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get(cpqControls.Opp_CPQ_Record_Type_Developer_Name__c).getRecordTypeId() != null){
                cpqRtId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get(cpqControls.Opp_CPQ_Record_Type_Developer_Name__c).getRecordTypeId();
            }
        }
        catch(Exception e){
            System.debug(LoggingLevel.ERROR, 'Metadata and system have not been correctly configured for CPQ operation');
        }
        /** **/

        String query = 'SELECT Id, Name, StageName, Type, CloseDate ' +
                        'FROM Opportunity ' +
                        'WHERE Type = \'Renewal\' ' +
                        '     AND Mid_Term_Renewal__c = TRUE ' +
                        '     AND StageName != \'Closed Won Pending\' ' +
                        '     AND StageName != \'Closed Won Booked\' ' +
                        '     AND StageName != \'Closed Lost\' ' +
                        '     AND StageName != \'Dropped\' ' +
                        '     AND CloseDate = NEXT_N_DAYS:7';

        //CPQ exclusion
        if(cpqRtId != null && !cpqControls.Opp_C_BatchAutoCloseRenewalOpportunities__c){
            query += ' AND RecordTypeId != \'' + cpqRtId +'\'';
        }

        System.debug('query: ' + query);

        return Database.getQueryLocator(query);
    }

    /*******************************************************************************
    @author:        Sebastiaan Verstraelen
    @date:          17 Jan 2019
    @description:   Based on results of query, loops through opportunities and set them
                    to closed won pending
    *******************************************************************************/
    global void execute(Database.BatchableContext BC, List<Opportunity> scope){
        
        System.Debug('execute ');
        System.Debug('scope ' + scope);
        try{

            List<Opportunity> opportunitiesToClose = new List<Opportunity>();

            for(Opportunity renewalOpp : scope){
                //Opportunity oppToClose = new Opportunity();
                System.Debug('renewalOpp: ' + renewalOpp);
                renewalOpp.StageName = 'Closed Won Pending';
                opportunitiesToClose.add(renewalOpp);
            }

            update opportunitiesToClose;
        }
        catch (Exception ex){
            System.Debug('BatchAutoCloseRenewalOpportunities execute: ' + ex );
        }

    }

    /*******************************************************************************
    @author:        Sebastiaan Verstraelen
    @date:          17 Jan 2019
    @description:   Final finish method that will email results
    *******************************************************************************/
    global void finish(Database.BatchableContext BC){

        Boolean batchApexEmailEnabled = false;

        List<System_Settings__mdt> settings = [SELECT Id, Label, Batch_Apex_Emails_Enabled__c FROM System_Settings__mdt ];
        if(settings.size() > 0){
            batchApexEmailEnabled = settings[0].Batch_Apex_Emails_Enabled__c;
        }

        if(Test.isrunningTest()){
            batchApexEmailEnabled = true;
        }

        if(batchApexEmailEnabled){
            // Get the ID of the AsyncApexJob representing this batch job
            // from Database.BatchableContext.
            // Query the AsyncApexJob object to retrieve the current job's information.
            AsyncApexJob a = [  SELECT  Id, Status, NumberOfErrors, JobItemsProcessed,
                                        TotalJobItems, CreatedBy.Email
                                FROM AsyncApexJob WHERE Id = :BC.getJobId()];
            // Send an email to the Apex job's submitter notifying of job completion.
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            String[] toAddresses = new String[] {a.CreatedBy.Email};
            mail.setToAddresses(toAddresses);
            mail.setSubject('BatchAutoCloseRenewalOpportunities ' + a.Status);
            mail.setPlainTextBody(   'The batch Apex job processed ' + a.TotalJobItems +
                                    ' batches with '+ a.NumberOfErrors + ' failures.');
            try{
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
            }
            catch(EmailException e){
                System.debug(LoggingLevel.ERROR, 'EmailException: ' + e.getMessage());
            }
        }

    }

}