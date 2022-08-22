@IsTest
public inherited sharing class DealBuilderControllerTest {
	@TestSetup
	private static void makeData() {
		Account testAccount = DataFactory_CM.createAccount('Customer', true);
		Opportunity testOpportunity = DataFactory_SL.createOpportunity(testAccount.Id, true);
		Contract testContract = DataFactory_SL.createContract(testAccount.Id, false);
		testContract.EndDate = System.today();
		insert testContract;
	}

    @isTest
	private static void getInitialDataTest() {
		Account acc = [SELECT Id FROM Account LIMIT 1];

		Test.startTest();
		DealBuilderController.DealBuilderWrapper wrapper = DealBuilderController.getInitialData(acc.Id);
		System.assertEquals(true, wrapper.contractList.size() > 0, 'No contract found');
		Test.stopTest();
	}
}