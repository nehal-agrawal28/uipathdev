/*
* Author: Deepali
* Date: 25th March 2019
* Description: To test ScheduleBatchToDeleteKAChildAQI schedule class and BatchToDeleteKAChildAQI batch class*/
@IsTest(isParallel=true)
public class ScheduleBatchToDeleteKAChildAQITest {

	//added by Deepali
	//Purpose: To create test setup data
	@testSetup 
	static void setup(){
		List<Article_Quality_Index__c> aqiList = new List<Article_Quality_Index__c>();
		for(Integer i = 0; i < 50; i++){
			aqiList.add(new Article_Quality_Index__c(Article_Categories_correct_complete__c = 'Yes'));
		}		
		insert aqiList;
	}	
	 
	//added by Deepali
	//Purpose: To test schedule class and corresponding batch class
	static TestMethod void testScheduledBatchForDeletingAQI() {
	    String CRON_EXP = '0 0 3 * * ?';
	    Test.startTest();
	    String jobId = System.schedule('Cascade Delete AQI', CRON_EXP, new ScheduleBatchToDeleteKAChildAQI());
	    CronTrigger ct = [Select Id, CronExpression, TimesTriggered, NextFireTime from CronTrigger where id=:jobId];
	    System.assertEquals(0,ct.TimesTriggered);	
	    Test.stopTest();
	}
	
}