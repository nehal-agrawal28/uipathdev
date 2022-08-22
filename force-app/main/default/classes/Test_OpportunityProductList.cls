@isTest
private class Test_OpportunityProductList {

    @isTest static void test_method_1() 
    {
            
        // Data setup
        Account newAccount = new Account();
        newAccount.Name = 'testAccName';
        newAccount.BillingCountry = 'UNITED STATES';
        newAccount.BillingCountryCode ='US';
        newAccount.BillingState = 'California';
         newAccount.BillingStreet = 'Test Street';
        newAccount.BillingCity = 'Test City';
        newAccount.BillingPostalCode = '123abc';
        newAccount.Phone = '0721000000';
        newAccount.Industry = 'Energy';
        insert newAccount;
        
        Contact cnt = new Contact();
        cnt.LastName = 'Test545734';
        cnt.AccountId = newAccount.Id;
        cnt.Email ='test@test.com';
        cnt.Title = 'titlename';
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
        newProduct.Ext_Id__c='testProductName004';
        newProduct.ProductCode='testProductName004';
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

        OpportunityLineItem oli2 = new OpportunityLineItem();
        oli2.OpportunityId = newOpportunity.Id;
        oli2.UnitPrice = 5000;
        oli2.Quantity = 1;
        oli2.PricebookEntryId = stdPriceBookEntry.Id;
        oli2.Discount = 15;
        oli2.Add_On_For__c = oli.Id;
        insert oli2;

        OpportunityLineItem oli3 = new OpportunityLineItem();
        oli3.OpportunityId = newOpportunity.Id;
        oli3.UnitPrice = 4000;
        oli3.Quantity = 1;
        oli3.PricebookEntryId = stdPriceBookEntry.Id;
        oli3.Discount = 15;
        oli3.Add_On_For__c = oli.Id;
        insert oli3;

       Case newCase = new Case();
        
        newCase.AccountId = newAccount.id;
        newCase.ContactId = cnt.id;
        newCase.Opportunity__c = newOpportunity.id;
        newCase.UiPath_Inc_Signer__c = 'Mihai Faur';
        newCase.UiPath_Inc_Signer_Title__c = 'Chief Financial Officer';
        newCase.UiPath_Srl_Signer__c = 'Mihai Faur';
        newCase.UiPath_Srl_Signer_Title__c = 'Chief Financial Officer';
        insert newCase;
        
        ApexPages.StandardController sc = new ApexPages.StandardController(newCase);
       // Run Code
        Test.startTest();
        OpportunityProductList op = new OpportunityProductList (sc);
        test.stopTest();
        
    }
}