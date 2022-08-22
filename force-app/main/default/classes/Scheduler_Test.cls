@isTest
private class Scheduler_Test {
	
	@isTest static void testJobIsScheduled() {
		

  		Test.startTest();
		    String jobId = Scheduler.scheduleMe('Nightly batch Job (Auto Close Renewal Opportunities) - Test');
	    Test.stopTest();

    	// Check Scheduler is in the job list
    	List<AsyncApexJob> jobsScheduled = [select Id, ApexClass.Name from AsyncApexJob where JobType = 'ScheduledApex'];
	    System.assertEquals(1, jobsScheduled.size(), 'expecting one scheduled job');
	    System.assertEquals('Scheduler', jobsScheduled[0].ApexClass.Name, 'expecting specific scheduled job');

	    List<AsyncApexJob> jobsApexBatch = [select Id, ApexClassID, ApexClass.Name, Status, JobType from AsyncApexJob where JobType = 'BatchApex'];
    	System.assertEquals(1, jobsApexBatch.size(), 'expecting one apex batch job');
    	System.assertEquals('BatchAutoCloseRenewalOpportunities', jobsApexBatch[0].ApexClass.Name, 'expecting specific batch job');

	}

	
}