/*******************************************************************************
* @author         :    Bharti Mewada
* @date           :    Sept 2019
* @description    :    Test class for OppProductEditOverrideExt class
* @Revisions      :
        #1        :   Created 
*******************************************************************************/
@isTest
private class OppProductEditOverrideExtTest{

    @isTest static void test_OpportunityOverride()
    {
        // Data setup
        Account newAccount = new Account();
        newAccount.Name = 'testAccName';
        newAccount.BillingCountry = 'UNITED STATES';
        newAccount.Industry = 'Energy';
        insert newAccount;

        Contact cnt = new Contact();
        cnt.LastName = 'Test545734';
        cnt.AccountId = newAccount.Id;
        cnt.Email = 'Test545734Cnt@testEmail.com';
        cnt.Department__c = 'IT';
        insert cnt;

        Id stdPriceBookRecId = Test.getStandardPricebookId();

        Product2 newProduct = new Product2();
        newProduct.Name = 'testProductName';
        newProduct.Is_Add_On__c = false;
        newProduct.IsActive = true;
        newProduct.Add_On_Percent__c = 10;
        newProduct.License_Model__c = 'N/A';
        newProduct.Unit_of_measure__c = 'N/A';
        newProduct.Ext_Id__c='testProductName010';
        newProduct.ProductCode='testProductName006';
        newProduct.Family='Other';
        insert newProduct;



        Opportunity newOpportunity = new Opportunity();
        newOpportunity.Name = 'testOppName';
        newOpportunity.Type = 'Renewal';
        newOpportunity.AccountId = newAccount.Id;
        newOpportunity.StageName = 'Discovery';
        newOpportunity.CloseDate = Date.today();
        newOpportunity.Discount_Approval_Status__c = 'In Approval';
        newOpportunity.Managing_Director__c = UserInfo.getUserId();
        newOpportunity.Pricebook2Id = stdPriceBookRecId;
        newOpportunity.CurrencyIsoCode = 'EUR';
        newOpportunity.Customer_Primary_Contact__c = cnt.Id;
        insert newOpportunity;

        PriceBookEntry stdPriceBookEntry = new PriceBookEntry();
        stdPriceBookEntry.Product2Id = newProduct.Id;
        stdPriceBookEntry.Pricebook2Id = stdPriceBookRecId;
        stdPriceBookEntry.UnitPrice = 2000;
        stdPriceBookEntry.IsActive = true;
        stdPriceBookEntry.CurrencyIsoCode = newOpportunity.CurrencyIsoCode;
        insert stdPriceBookEntry;

        OpportunityLineItem oli = new OpportunityLineItem();
        oli.OpportunityId = newOpportunity.Id;
        oli.UnitPrice = 700;
        oli.Quantity = 2;
        oli.PricebookEntryId = stdPriceBookEntry.Id;
        oli.Discount = 25;
        oli.Add_On_For__c = null;
        insert oli;

        ApexPages.StandardController controller = new ApexPages.StandardController(oli);


        // Run Code
        Test.startTest();
            OppProductEditOverrideExt ext = new OppProductEditOverrideExt(controller);
            Pagereference page = ext.redirect();
            //System.assertEquals(page,new pagereference('/'+oli.id+'/e?nooverride=1'));
        Test.stopTest();

    }
}