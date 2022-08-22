@isTest
private class ApproveDiscountsTest
{	
    @isTest static void test_method_3() 
    {
        // Data setup
        Account newAccount = new Account();
        newAccount.Name = 'testAccName';
        newAccount.BillingCountry = 'UNITED STATES';
        newAccount.Industry = 'Energy';
        insert newAccount;

        Id stdPriceBookRecId = Test.getStandardPricebookId();

        Product2 newProduct = new Product2();
        newProduct.Name = 'testProductName';
        newProduct.License_Model__c = 'N/A';
        newProduct.Unit_of_measure__c = 'N/A';
        newProduct.Ext_Id__c = 'testProductName003';
        newProduct.ProductCode = 'testProductName003';
        newProduct.Family = 'Other';
        insert newProduct;

        Opportunity newOpportunity = new Opportunity();
        newOpportunity.Name = 'testOppName';
        newOpportunity.Type = 'Renewal';
        newOpportunity.AccountId = newAccount.Id;
        newOpportunity.StageName = 'Discovery';
        newOpportunity.CloseDate = Date.today();
        newOpportunity.Discount_Approval_Status__c = 'In Approval';
        newOpportunity.Managing_Director__c = UserInfo.getUserId();
        insert newOpportunity;

        PriceBookEntry stdPriceBookEntry = new PriceBookEntry();
        stdPriceBookEntry.Product2Id = newProduct.Id;
        stdPriceBookEntry.Pricebook2Id = stdPriceBookRecId;
        stdPriceBookEntry.UnitPrice = 2000;
        stdPriceBookEntry.IsActive = true;
        insert stdPriceBookEntry;        

        OpportunityLineItem oli = new OpportunityLineItem();
        oli.OpportunityId = newOpportunity.Id;
        oli.UnitPrice = 7000;
        oli.Quantity = 5;
        oli.PricebookEntryId = stdPriceBookEntry.Id;
        oli.Discount = 25;
        insert oli;

        ApexPages.StandardController sc = new ApexPages.StandardController(newOpportunity);

        // Run Code
        Test.startTest();
            ApproveDiscounts ctrl = new ApproveDiscounts(sc);
            ctrl.GoBack();
            ctrl.StartApprovalProcess();
        Test.stopTest();

        // Data validation
        System.assertEquals(true, ctrl.errors);
    }

    @isTest static void test_method_2() 
    {
        // Data setup
        Account newAccount = new Account();
        newAccount.Name = 'testAccName';
        newAccount.BillingCountry = 'UNITED STATES';
        newAccount.Industry = 'Energy';
        insert newAccount;

        Opportunity newOpportunity = new Opportunity();
        newOpportunity.Name = 'testOppName';
        newOpportunity.Type = 'Renewal';
        newOpportunity.AccountId = newAccount.Id;
        newOpportunity.StageName = 'Discovery';
        newOpportunity.CloseDate = Date.today();
        newOpportunity.Discount_Approval_Status__c = 'In Approval';
        insert newOpportunity;

        ApexPages.StandardController sc = new ApexPages.StandardController(newOpportunity);

        // Run Code
        Test.startTest();
            ApproveDiscounts ctrl = new ApproveDiscounts(sc);
        Test.stopTest();

        // Data validation
        System.assertEquals(true, ctrl.errors);
    }

	@isTest static void test_method_1() 
    {
        // Data setup
        Account newAccount = new Account();
        newAccount.Name = 'testAccName';
        newAccount.BillingCountry = 'UNITED STATES';
        newAccount.Industry = 'Energy';
        insert newAccount;

        Opportunity newOpportunity = new Opportunity();
        newOpportunity.Name = 'testOppName';
        newOpportunity.Type = 'Renewal';
        newOpportunity.AccountId = newAccount.Id;
        newOpportunity.StageName = 'Discovery';
        newOpportunity.CloseDate = Date.today();
        newOpportunity.Discount_Approval_Status__c = 'Approved';
        insert newOpportunity;

		ApexPages.StandardController sc = new ApexPages.StandardController(newOpportunity);

        // Run Code
        Test.startTest();
            ApproveDiscounts ctrl = new ApproveDiscounts(sc);
        Test.stopTest();

        // Data validation
        System.assertEquals(true, ctrl.errors);
	}    
}