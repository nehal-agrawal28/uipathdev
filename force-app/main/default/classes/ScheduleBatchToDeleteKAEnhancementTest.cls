/*
* Author: Deepali
* Date: 25th March 2019
* Description: To test ScheduleBatchToDeleteKAChildEnhancements schedule class and BatchToDeleteKAChildEnhancements batch class*/
@IsTest(isParallel=true)
public class ScheduleBatchToDeleteKAEnhancementTest {

	//added by Deepali
	//Purpose: To create test setup data
	@testSetup 
	static void setup(){
		List<Knowledge_Enhancement__c> keList = new List<Knowledge_Enhancement__c>();
		for(Integer i = 0; i < 50; i++){
			keList.add(new Knowledge_Enhancement__c(Enhance_reason__c = 'Just like that'));
		}		
		insert keList;
	}	
	 
	//added by Deepali
	//Purpose: To test schedule class and corresponding batch class
	static TestMethod void testScheduledBatchForDeletingAQI() {
	    String CRON_EXP = '0 0 3 * * ?';
	    Test.startTest();
	    String jobId = System.schedule('Cascade Delete KE', CRON_EXP, new ScheduleBatchToDeleteKAChildEnhancements());
	    CronTrigger ct = [Select Id, CronExpression, TimesTriggered, NextFireTime from CronTrigger where id=:jobId];
	    System.assertEquals(0,ct.TimesTriggered);	
	    Test.stopTest();
	}
	
}