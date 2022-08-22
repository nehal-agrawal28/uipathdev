/********************************************************************************************************
*    Batch Name:  LeadSetOwnerBatch.cls
*    Author: Mirela Chituc (mirela.chituc@uipath.com) 
*    Date:  12/13/2019
*    // sets owner to queue for leads with status "New" older that ~24h
*    Scheduler Class: LeadSetOwnerScheduler.cls
*    Test class: LeadSetOwnerBatchTest.cls
********************************************************************************************************/

global class LeadSetOwnerScheduler implements Schedulable {
  global void execute(SchedulableContext sc) {
    LeadSetOwnerBatch lsob = new LeadSetOwnerBatch();
    Database.executebatch(lsob, 10);
  }
}