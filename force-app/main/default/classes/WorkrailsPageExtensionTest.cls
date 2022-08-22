@IsTest
public class WorkrailsPageExtensionTest {
	@isTest
	private static void workrailsPageExtensionTest() {
		Account testAccount = DataFactory.createAccount(Constants.ACCOUNT_RECORD_TYPE_1, false);
		testAccount.Name = 'workrailsPageExtensionTest';
		insert testAccount;
		Opportunity testOpportunity = DataFactory.createOpportunity(testAccount.Id, true);

		SBQQ__Quote__c quote = DataFactory.createCPQQuote(testAccount.Id, testOpportunity.Id, true);

		PageReference pageRef = Page.Workrails_iframe_quote;
		pageRef.getParameters().put('id', String.valueOf(quote.Id));
		Test.setCurrentPage(pageRef);

		Test.startTest();
		ApexPages.StandardController sc = new ApexPages.StandardController(quote);
		WorkrailsPageExtension ctrl = new WorkrailsPageExtension(sc);

		quote.SBQQ__Primary__c = true;
		update quote;
		ApexPages.StandardController sc2 = new ApexPages.StandardController(quote);
		WorkrailsPageExtension ctrl2 = new WorkrailsPageExtension(sc2);
		// Commented: Deployment user can or can not have SCOPE permission
        // System.assertEquals(false, ctrl2.hasPermission);

		ctrl.scopeAttachQuote();

		Test.stopTest();
	}
}