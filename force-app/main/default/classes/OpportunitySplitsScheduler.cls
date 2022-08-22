/********************************************************************************************************
*    Batch Name:  OpportunitySplitsBatch.cls
*    Author: Mirela Chituc (mirela.chituc@uipath.com) 
*    Date:  2/3/2021
*    // adds opp splits for the OTM added from the default Opp Team
*    Scheduler Class: OpportunitySplitsScheduler.cls
*    Test class: OpportunitySplitsBatchTest.cls
********************************************************************************************************/

global class OpportunitySplitsScheduler implements Schedulable {
  global void execute(SchedulableContext sc) {
    OpportunitySplitsBatch osb = new OpportunitySplitsBatch();
    Database.executebatch(osb, 50);
  }
}