@IsTest
public with sharing class BatchWithDeferredQueueableChainTest {
	public static Boolean started = false;
	public static Boolean workDone = false;
	public static Boolean finished = false;

	@TestSetup
	public static void setup() {
		insert new Account(
			Name = 'TestAccount2',
			AccountNumber = 'A2',
			AnnualRevenue = 12345.67,
			Country__c = 'United States',
			BillingCountry = 'United States',
			Industry = 'Telecommunications'
		);
	}

	@IsTest
	public static void executesBatchAsExpected() {
		Test.startTest();
		Database.executeBatch(new BatchWithDeferredQueueableChainSample(), 1);
		Test.stopTest();

		System.assertEquals(
			true,
			!([SELECT Id FROM AsyncApexJob WHERE JobType = 'Queueable' LIMIT 1].isEmpty()),
			'Chained Queueable should be enqueued'
		);
		System.assertEquals(true, BatchWithDeferredQueueableChainTest.started);
		System.assertEquals(true, BatchWithDeferredQueueableChainTest.workDone);
		System.assertEquals(true, BatchWithDeferredQueueableChainTest.finished);
	}
}