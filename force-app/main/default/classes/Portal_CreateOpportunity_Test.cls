@isTest
private class Portal_CreateOpportunity_Test {
	

	
	@isTest static void test_InitOpportunity() {

		Opportunity opp = Portal_CreateOpportunity.InitOpportunity();

		System.assertNotEquals(null, opp, 'This should not be null as we\'ve just initialised one.');
		
	}

	@isTest static void test_SaveOpportunityFail() {
		Opportunity opp = Portal_CreateOpportunity.InitOpportunity();
		Portal_CreateOpportunity.SaveResult result = Portal_CreateOpportunity.SaveOpportunity(opp);
		System.assertEquals(false, result.success, 'Should be false as we\'ve not set any values' );
	}

	@isTest static void test_SaveOpportunitySuccsess() {


		// Set up an Account
        Account acc = new Account(
            Name = 'TestAccount',
            BillingCountry = 'United Kingdom',
            Industry = 'Apparel'
        );
        insert acc;

		Opportunity opp = Portal_CreateOpportunity.InitOpportunity();

		opp.AccountId = acc.id; 
        opp.Name = 'TestOpp';
        opp.CloseDate = date.today();
        opp.Type = 'Renewal';
        opp.CurrencyIsoCode = 'USD';

		Portal_CreateOpportunity.SaveResult result = Portal_CreateOpportunity.SaveOpportunity(opp);

		System.assertEquals(true, result.success, 'Should be false as we\'ve not set any values' );

	}
	
}