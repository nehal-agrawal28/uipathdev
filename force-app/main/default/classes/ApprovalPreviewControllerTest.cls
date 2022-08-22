@isTest
private with sharing class ApprovalPreviewControllerTest {
	@TestSetup
	private static void makeData() {
		Account testAccount = DataFactory_CM.createAccount(Constants.ACCOUNT_RECORD_TYPE_1, true);
		Contact testContact = DataFactory_CM.createContact(testAccount.Id, true);

		Opportunity testOpportunity = DataFactory_SL.createOpportunity(testAccount.Id, false);
		testOpportunity.Deal_Type__c = 'Direct';
		insert testOpportunity;

		Product2 prod = DataFactory_SL.createProduct(true);
		DataFactory_SL.createStdPricebookEntry(prod.Id, 20000, true);

		SBQQ__Quote__c quote = DataFactory_SL.createCPQQuote(testAccount.Id, testOpportunity.Id, true);

		SBQQ__QuoteLine__c line = DataFactory_SL.createCPQQuoteLine(prod.Id, quote.Id, true);
	}

	@isTest
	private static void runPreview() {
		SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
		quote.Bill_To_Geo_New__c = 'AMER';
		quote.De_bill_Re_bill__c = false;
		quote.Approved_Discount__c = -1;
		quote.Total_Regular_Price_3rd_Party_Products__c = 40000;
		quote.Total_Discount_3rd_Party_Products_Curren__c = 30000;
		quote.Payment_Terms__c = '90 Days Net';
		quote.X1st_Level_Approver__c = UserInfo.getUserId();
		quote.Regional_Commercial_Finance_Leader__c = UserInfo.getUserId();
		update quote;

		Test.startTest();

		ApprovalPreviewHelper.ApprovalProcessWrapper result = ApprovalPreviewController.runPreview(quote.Id);
		System.assert(true, result.approvalSteps.size() > 0);

		Test.stopTest();
	}

	@isTest
	private static void submitApproval() {
		SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
		quote.De_bill_Re_bill__c = true;
		update quote;

		Test.startTest();

		ApprovalPreviewHelper.ApprovalProcessWrapper result = ApprovalPreviewController.submitForApproval(
			quote.Id,
			'Test Comment'
		);
		System.assert(true, result.approvalSteps.size() > 0);

		Test.stopTest();
	}

	@isTest
	private static void submitApprovalNegative() {
		SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
		quote.Approved_Discount__c = -1;
		update quote;

		Test.startTest();

		ApprovalPreviewHelper.ApprovalProcessWrapper result = ApprovalPreviewController.submitForApproval(
			quote.Id,
			'Test Comment'
		);
		System.assert(true, result.isError);

		Test.stopTest();
	}

	@isTest
	private static void alreadyInApprovalAndRecall() {
		SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
		quote.Bill_To_Geo_New__c = 'AMER';
		quote.De_bill_Re_bill__c = false;
		quote.Approved_Discount__c = -1;
		quote.Total_Regular_Price_3rd_Party_Products__c = 40000;
		quote.Total_Discount_3rd_Party_Products_Curren__c = 30000;
		quote.Payment_Terms__c = '90 Days Net';
		quote.X1st_Level_Approver__c = UserInfo.getUserId();
		quote.Regional_Commercial_Finance_Leader__c = UserInfo.getUserId();
		update quote;

		Test.startTest();

		ApprovalPreviewHelper.ApprovalProcessWrapper result = ApprovalPreviewController.submitForApproval(
			quote.Id,
			'Test'
		);
		ApprovalPreviewHelper.ApprovalProcessWrapper result2 = ApprovalPreviewController.runPreview(quote.Id);
		System.assert(true, result2.alreadyInApproval);

		ApprovalPreviewHelper.ApprovalProcessWrapper result3 = ApprovalPreviewController.recallApproval(
			quote.Id,
			'Recall'
		);
		System.assert(true, result2.isError != true);

		Test.stopTest();
	}
}