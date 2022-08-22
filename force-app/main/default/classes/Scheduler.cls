/*******************************************************************************
@author:        Sebastiaan Verstraelen
@date:          17 Jan 2019
@description:   Scheduler used to schedule batch apex jobs
*******************************************************************************/
global class Scheduler implements Schedulable{

    public static String sched = '0 00 00 * * ?';  //Every Day at Midnight
    //public static String sched = '0 0 * * * ?';  //Every hour

    // You just need to run Ent_Scheduler.scheduleMe(); from execute anonymous 
    // and it will be scheduled to run at your interval.
    global static String scheduleMe() {
        return scheduleMe('Nightly batch Job (Auto Close Renewal Opportunities)');
    }

    global static String scheduleMe(String batchJobName) {
        Scheduler SC = new Scheduler(); 
        return System.schedule(batchJobName, sched, SC);
    }
    
    global void execute(SchedulableContext sc) {

        BatchAutoCloseRenewalOpportunities batchAutoCloseRenewalOpps = new BatchAutoCloseRenewalOpportunities();
        //batch size 50
        ID renewalBatchprocessid = Database.executeBatch(batchAutoCloseRenewalOpps,50);

/*        
        Ent_BatchUpdateAccounts batchUpdateAccounts = new Ent_BatchUpdateAccounts();
        //batch size 50
        ID accountBatchprocessid = Database.executeBatch(batchUpdateAccounts,50);

        Ent_BatchSendTestResults batchSendResults = new Ent_BatchSendTestResults();
        //batch size 50
        ID testResultsBatchprocessid = Database.executeBatch(batchSendResults,50);     
*/
    }
}