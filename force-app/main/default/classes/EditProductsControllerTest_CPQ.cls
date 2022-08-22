@isTest
private class EditProductsControllerTest_CPQ{

    static final String CURRENCY_CODE = 'USD';

    @TestSetup
    static void test_setup(){

        Account newAccount = new Account();
        newAccount.Name = 'testAccName';
        newAccount.BillingCountry = 'UNITED STATES';
        newAccount.Industry = 'Energy';
        insert newAccount;

        Contact cnt = new Contact();
        cnt.LastName = 'Test545735';
        cnt.AccountId = newAccount.Id;
        cnt.Email = 'test.contact545735@testemail.com';
        cnt.Department__c = 'IT';
        insert cnt;

        Id stdPriceBookRecId = Test.getStandardPricebookId();

        Opportunity newOpportunity = new Opportunity();
        newOpportunity.Name = 'testOppName';
        newOpportunity.Type = 'Renewal';
        newOpportunity.AccountId = newAccount.Id;
        newOpportunity.StageName = 'Discovery';
        newOpportunity.CloseDate = Date.today();
        newOpportunity.Discount_Approval_Status__c = 'In Approval';
        newOpportunity.Managing_Director__c = UserInfo.getUserId();
        newOpportunity.Pricebook2Id = stdPriceBookRecId;
        newOpportunity.CurrencyIsoCode = CURRENCY_CODE;
        newOpportunity.Customer_Primary_Contact__c = cnt.Id;
        insert newOpportunity;



        Product2 newProduct = new Product2();
        newProduct.Name = 'testProductName';
        newProduct.Is_Add_On__c = false;
        newProduct.IsActive = true;
        newProduct.Add_On_Percent__c = 10;
        newProduct.License_Model__c = 'N/A';
        newProduct.Unit_of_measure__c = 'N/A';
        newProduct.Ext_Id__c='testProductName500';
        newProduct.ProductCode='testProductName500';
        newProduct.Family='Other';

        insert newProduct;

        Product2 newProductSupport = new Product2();
        newProductSupport.Name = 'testProductName';
        newProductSupport.Apply_Premium_Percentage__c  = true;
        newProductSupport.IsActive = true;
        newProductSupport.Premium_Percentage__c = 15;
        newProductSupport.License_Model__c = 'N/A';
        newProductSupport.Unit_of_measure__c = 'N/A';
        newProductSupport.Ext_Id__c='testProductName501';
        newProductSupport.ProductCode='testProductName501';
        newProductSupport.Family='Other';

        insert newProductSupport;



        PriceBookEntry stdPriceBookEntry = new PriceBookEntry();
        stdPriceBookEntry.Product2Id = newProduct.Id;
        stdPriceBookEntry.Pricebook2Id = stdPriceBookRecId;
        stdPriceBookEntry.UnitPrice = 2000;
        stdPriceBookEntry.IsActive = true;
        stdPriceBookEntry.CurrencyIsoCode = CURRENCY_CODE;
        insert stdPriceBookEntry;



    }

    /**Create a CPQ Product and assert it is NOT returned by EditProductController.NewProducts
    * Any product with a true CPQ_Exclusive__c flag is assumed to be a CPQ product
    **/
    @isTest
    static void CPQ_Products_Excluded_From_Product_Selection(){

        Opportunity newOpportunity = [SELECT Id FROM Opportunity LIMIT 1];

        ApexPages.StandardController sc = new ApexPages.StandardController(newOpportunity);

        //Create CPQ Product
        Product2 cpqProduct = new Product2();
        cpqProduct.Name = 'testCPQProduct';
        cpqProduct.Is_Add_On__c = false;
        cpqProduct.IsActive = true;
        cpqProduct.Add_On_Percent__c = 10;
        cpqProduct.License_Model__c = 'N/A';
        cpqProduct.Unit_of_measure__c = 'N/A';
        cpqProduct.CPQ_Exclusive__c = true;
        cpqProduct.Ext_Id__c='testProductName400';
        cpqProduct.ProductCode='testProductName400';
        cpqProduct.Family='Other';

        insert cpqProduct;

        Id stdPriceBookRecId = Test.getStandardPricebookId();

        PriceBookEntry stdPriceBookEntry2 = new PriceBookEntry();
        stdPriceBookEntry2.Product2Id = cpqProduct.Id;
        stdPriceBookEntry2.Pricebook2Id = stdPriceBookRecId;
        stdPriceBookEntry2.UnitPrice = 2000;
        stdPriceBookEntry2.IsActive = true;
        stdPriceBookEntry2.CurrencyIsoCode = CURRENCY_CODE;
        insert stdPriceBookEntry2;


        Test.startTest();
        EditProductsController ctrl = new EditProductsController(sc);
        ctrl.ShowNewProduct();
        System.assertEquals(1, ctrl.NewProducts.size(), 'The CPQ product should not be included in the NewProducts list');


        Test.stopTest();
    }
}