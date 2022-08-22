/*
* Author: Deepali
* Date: 22nd May 2019
* Description: To test ScheduleBatchToDeleteKAChildAQI schedule class and BatchToDeleteKAChildAQI batch class*/
@IsTest(isParallel=true)
public class ScheduleBatchToDeleteOldCaseAttchmntTest {

	//added by Deepali
	//Purpose: To create test setup data
	@testSetup 
	static void setup(){
		List<Case> caseList = new List<Case>();
        List<Attachment> caseattchList = new List<Attachment>();
		for(Integer i = 0; i < 10; i++){
			caseList.add(new Case(Subject = 'Test Case Subject', RecordTypeId = SupportConstants.incidentRtId));
		}		
		insert caseList;
        
        for(Case ca : caseList){
            Blob bodyBlob=Blob.valueOf('Unit Test Attachment Body');
            caseattchList.add(new Attachment(ParentID = ca.Id, Name = 'Attch', Body = bodyBlob));
        }
        insert caseattchList;
        
	}	
	 
	//added by Deepali
	//Purpose: To test schedule class and corresponding batch class
	static TestMethod void testScheduledBatchForDeletingCaseAttchmnt() {
	    String CRON_EXP = '0 0 3 * * ?';
	    Test.startTest();
	    String jobId = System.schedule('Delete Old Case Attachment', CRON_EXP, new ScheduleBatchToDeleteOldCaseAttchmnt());
	    CronTrigger ct = [Select Id, CronExpression, TimesTriggered, NextFireTime from CronTrigger where id=:jobId];
	    System.assertEquals(0,ct.TimesTriggered);	
	    Test.stopTest();
	}
	
}