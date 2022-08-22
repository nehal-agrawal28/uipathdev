@isTest
private with sharing class ContractTriggerHandlerTest {
	@TestSetup
	static void createData() {
		Account acc = new Account(Name = 'Abc Xyz', BillingCountry = 'United Kingdom', Industry = 'Apparel');
		insert acc;
	}

	@isTest
	static void contractRefTest() {
		Account acc = [SELECT Id FROM Account LIMIT 1];

		Test.startTest();

		Contract contract = new Contract(AccountId = acc.Id);
		insert contract;

        Test.stopTest();

        Contract contract2 = [SELECT Id, contract_ref__c FROM Contract WHERE Id = :contract.Id];
		System.assertEquals(
			contract2.contract_ref__c.startsWith('ABCX-'),
			true,
			'contract_ref__c is not populated correctly: ' + contract2.contract_ref__c
		);
	}
}