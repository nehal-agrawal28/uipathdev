/*
* Author: Deepali
* Date: 25th March 2019
* Description: To test ScheduleBatchToDeleteKAChildTechReviews schedule class and BatchToDeleteKAChildTechReviews batch class*/
@IsTest(isParallel=true)
public class ScheduleBatchToDeleteKATechReviewsTest {

	//added by Deepali
	//Purpose: To create test setup data
	@testSetup 
	static void setup(){
		List<Technical_Review__c> keList = new List<Technical_Review__c>();
		for(Integer i = 0; i < 50; i++){
			keList.add(new Technical_Review__c(Technical_Check_Result__c = 'Pass'));
		}		
		insert keList;
	}	
	 
	//added by Deepali
	//Purpose: To test schedule class and corresponding batch class
	static TestMethod void testScheduledBatchForDeletingAQI() {
	    String CRON_EXP = '0 0 3 * * ?';
	    Test.startTest();
	    String jobId = System.schedule('Cascade Delete KE', CRON_EXP, new ScheduleBatchToDeleteKAChildTechReviews());
	    CronTrigger ct = [Select Id, CronExpression, TimesTriggered, NextFireTime from CronTrigger where id=:jobId];
	    System.assertEquals(0,ct.TimesTriggered);
	    Test.stopTest();
	}
	
}