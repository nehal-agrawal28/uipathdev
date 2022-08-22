@isTest
private class EditProductsControllerTest 
{
    @isTest static void test_method_1()
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
        cnt.Email = 'test.contact545734@testemail.com';
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

        Product2 newProductSupport = new Product2();
        newProductSupport.Name = 'testProductName';
        newProductSupport.Apply_Premium_Percentage__c  = true;
        newProductSupport.IsActive = true;
        newProductSupport.Premium_Percentage__c = 15;
        newProductSupport.License_Model__c = 'N/A';
        newProductSupport.Unit_of_measure__c = 'N/A';
        newProductSupport.Ext_Id__c='testProductName011';
        newProductSupport.ProductCode='testProductName011';
        newProductSupport.Family='Other';
        insert newProductSupport;

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

        OpportunityLineItem oli2supp = new OpportunityLineItem();
        oli2supp.OpportunityId = newOpportunity.Id;
        oli2supp.UnitPrice = 700;
        oli2supp.Quantity = 1;
        oli2supp.PricebookEntryId = stdPriceBookEntry.Id;
        oli2supp.Discount = 25;
        oli2supp.Add_On_For__c = null;
        insert oli2supp;

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

        ApexPages.StandardController sc = new ApexPages.StandardController(newOpportunity);

        // Run Code
        Test.startTest();
            EditProductsController ctrl = new EditProductsController(sc);
            ctrl.opportunityLineItemList[0].compareTo(ctrl.opportunityLineItemList[0]);
            ctrl.SavePriceBook();
            ctrl.ShowNewProduct();
            ctrl.HideNewProduct();
            ctrl.NewProducts[0].selected = true;
            ctrl.AddNewProduct();
            ctrl.NewProducts[0].compareTo(ctrl.NewProducts[0]);
            ctrl.ShowAddOn();

            ctrl.selectedAddOn = stdPriceBookEntry.Id;
            ctrl.AddOnFor = oli.Id;
            system.debug(ctrl.AddOns);
            system.debug(ctrl.opportunityLineItemList[0].discountedPrice);
            system.debug(ctrl.opportunityLineItemList[0].totalPrice);
            system.debug(ctrl.opportunityLineItemList[0].editable);

            ctrl.HideAddOn();
            ctrl.AddAddOn();
            ctrl.DelOliId = oli.Id;
            ctrl.deleteRecordOnServer();
            ctrl.saveChanges();
            ctrl.cancel();
            ctrl.RecalculatePrices();
        Test.stopTest();

        // Data validation
        List<OpportunityLineItem> oliList =
            [
                SELECT Id
                FROM OpportunityLineItem
            ];

        System.assertEquals(5, oliList.size());
    }

    @isTest static void test_method_2()
    {
        // Data setup
        Account newAccount = new Account();
        newAccount.Name = 'testAccName';
        newAccount.BillingCountry = 'UNITED STATES';
        newAccount.Industry = 'Energy';
        insert newAccount;

        Contact cnt = new Contact();
        cnt.LastName = 'Test545733';
        cnt.AccountId = newAccount.Id;
        cnt.Email = 'test.contact545733@testemail.com';
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
        newProduct.Ext_Id__c='testProductName020';
        newProduct.ProductCode='testProductName006';
        newProduct.Family='Other';
        insert newProduct;

        Product2 newProductCare = new Product2();
        newProductCare.Name = 'testProductName';
        newProductCare.Is_Add_On__c = false;
        newProductCare.IsActive = true;
        newProductCare.License_Model__c = 'N/A';
        newProductCare.Unit_of_measure__c = 'N/A';
        newProductCare.Apply_Premium_Care__c = true;
        newProductCare.Ext_Id__c='testProductName021';
        newProductCare.ProductCode='testProductName021';
        newProductCare.Family='Other';
        insert newProductCare;

        Product2 newProductSupport = new Product2();
        newProductSupport.Name = 'testProductName';
        newProductSupport.Apply_Premium_Percentage__c  = true;
        newProductSupport.IsActive = true;
        newProductSupport.Premium_Percentage__c = 15;
        newProductSupport.License_Model__c = 'N/A';
        newProductSupport.Unit_of_measure__c = 'N/A';
        newProductSupport.Ext_Id__c='testProductName022';
        newProductSupport.ProductCode='testProductName022';
        newProductSupport.Family='Other';
        insert newProductSupport;

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

        PriceBookEntry stdPriceBookEntryCare = new PriceBookEntry();
        stdPriceBookEntryCare.Product2Id = newProductCare.Id;
        stdPriceBookEntryCare.Pricebook2Id = stdPriceBookRecId;
        stdPriceBookEntryCare.IsActive = true;
        stdPriceBookEntryCare.UnitPrice = 1;
        stdPriceBookEntryCare.CurrencyIsoCode = newOpportunity.CurrencyIsoCode;
        insert stdPriceBookEntryCare;

        PriceBookEntry stdPriceBookEntrySuport = new PriceBookEntry();
        stdPriceBookEntrySuport.Product2Id = newProductSupport.Id;
        stdPriceBookEntrySuport.Pricebook2Id = stdPriceBookRecId;
        stdPriceBookEntrySuport.IsActive = true;
        stdPriceBookEntrySuport.UnitPrice = 1;
        stdPriceBookEntrySuport.CurrencyIsoCode = newOpportunity.CurrencyIsoCode;
        insert stdPriceBookEntrySuport;

        OpportunityLineItem oli = new OpportunityLineItem();
        oli.OpportunityId = newOpportunity.Id;
        oli.UnitPrice = 700;
        oli.Quantity = 2;
        oli.PricebookEntryId = stdPriceBookEntry.Id;
        oli.Discount = 25;
        oli.Add_On_For__c = null;
        insert oli;

        OpportunityLineItem oli2supp = new OpportunityLineItem();
        oli2supp.OpportunityId = newOpportunity.Id;
        oli2supp.UnitPrice = 700;
        oli2supp.Quantity = 1;
        oli2supp.PricebookEntryId = stdPriceBookEntry.Id;
        oli2supp.Discount = 25;
        oli2supp.Add_On_For__c = null;
        insert oli2supp;

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

        ApexPages.StandardController sc = new ApexPages.StandardController(newOpportunity);

        // Run Code
        Test.startTest();
            EditProductsController ctrl = new EditProductsController(sc);
            ctrl.opportunityLineItemList[0].compareTo(ctrl.opportunityLineItemList[0]);
            ctrl.SavePriceBook();
            ctrl.ShowNewProduct();
            ctrl.HideNewProduct();
            ctrl.NewProducts[0].selected = true;
            ctrl.NewProducts[1].selected = true;
            ctrl.NewProducts[2].selected = true;
            ctrl.AddNewProduct();
            ctrl.NewProducts[0].compareTo(ctrl.NewProducts[0]);
            ctrl.ShowAddOn();

            ctrl.selectedAddOn = stdPriceBookEntry.Id;
            ctrl.AddOnFor = oli.Id;
            system.debug(ctrl.AddOns);
            system.debug(ctrl.opportunityLineItemList[0].discountedPrice);
            system.debug(ctrl.opportunityLineItemList[0].totalPrice);
            system.debug(ctrl.opportunityLineItemList[0].editable);

            ctrl.HideAddOn();
            ctrl.AddAddOn();
            ctrl.DelOliId = oli.Id;
            ctrl.deleteRecordOnServer();
            ctrl.saveChanges();
            ctrl.cancel();
            ctrl.RecalculatePrices();
        Test.stopTest();

        // Data validation
        List<OpportunityLineItem> oliList =
            [
                SELECT Id
                FROM OpportunityLineItem
            ];

        System.assertEquals(6, oliList.size());
    }


    @isTest static void test_method_3()
    {
        // Data setup
        Account newAccount = new Account();
        newAccount.Name = 'testAccName';
        newAccount.BillingCountry = 'UNITED STATES';
        newAccount.Industry = 'Energy';
        newAccount.Sum_of_Open_Opportunities__c = 10000;
        newAccount.Maintenance_Flag__c = 'Premium';
        insert newAccount;

        Contact cnt = new Contact();
        cnt.LastName = 'Test545732';
        cnt.AccountId = newAccount.Id;
        cnt.Email = 'test.contact545732@testemail.com';
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
        newProduct.Ext_Id__c='testProductName023';
        newProduct.ProductCode='testProductName006';
        newProduct.Family='Other';
        insert newProduct;

        Product2 newProductCare = new Product2();
        newProductCare.Name = 'testProductName';
        newProductCare.Is_Add_On__c = false;
        newProductCare.IsActive = true;
        newProductCare.License_Model__c = 'N/A';
        newProductCare.Unit_of_measure__c = 'N/A';
        newProductCare.Apply_Premium_Care__c = true;
        newProductCare.Premium_Care_Percentage__c = 12;
        newProductCare.Ext_Id__c='testProductName024';
        newProductCare.ProductCode='testProductName024';
        newProductCare.Family='Other';
        insert newProductCare;

        Product2 newProductSupport = new Product2();
        newProductSupport.Name = 'testProductName';
        newProductSupport.Apply_Premium_Percentage__c  = true;
        newProductSupport.IsActive = true;
        newProductSupport.Premium_Percentage__c = 15;
        newProductSupport.License_Model__c = 'N/A';
        newProductSupport.Unit_of_measure__c = 'N/A';
        newProductSupport.Ext_Id__c='testProductName025';
        newProductSupport.ProductCode='testProductName025';
        newProductSupport.Family='Other';
        insert newProductSupport;

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

        PriceBookEntry stdPriceBookEntryCare = new PriceBookEntry();
        stdPriceBookEntryCare.Product2Id = newProductCare.Id;
        stdPriceBookEntryCare.Pricebook2Id = stdPriceBookRecId;
        stdPriceBookEntryCare.IsActive = true;
        stdPriceBookEntryCare.UnitPrice = 1;

        stdPriceBookEntryCare.CurrencyIsoCode = newOpportunity.CurrencyIsoCode;
        insert stdPriceBookEntryCare;

        PriceBookEntry stdPriceBookEntrySuport = new PriceBookEntry();
        stdPriceBookEntrySuport.Product2Id = newProductSupport.Id;
        stdPriceBookEntrySuport.Pricebook2Id = stdPriceBookRecId;
        stdPriceBookEntrySuport.IsActive = true;
        stdPriceBookEntrySuport.UnitPrice = 1;
        stdPriceBookEntrySuport.CurrencyIsoCode = newOpportunity.CurrencyIsoCode;
        insert stdPriceBookEntrySuport;

        OpportunityLineItem oli = new OpportunityLineItem();
        oli.OpportunityId = newOpportunity.Id;
        oli.UnitPrice = 700;
        oli.Quantity = 2;
        oli.PricebookEntryId = stdPriceBookEntry.Id;
        oli.Discount = 25;
        oli.Add_On_For__c = null;
        insert oli;

        OpportunityLineItem oli2supp = new OpportunityLineItem();
        oli2supp.OpportunityId = newOpportunity.Id;
        oli2supp.UnitPrice = 700;
        oli2supp.Quantity = 1;
        oli2supp.PricebookEntryId = stdPriceBookEntryCare.Id;
        oli2supp.Discount = 25;
        oli2supp.Add_On_For__c = null;
        insert oli2supp;

        OpportunityLineItem oli2 = new OpportunityLineItem();
        oli2.OpportunityId = newOpportunity.Id;
        oli2.UnitPrice = 5000;
        oli2.Quantity = 1;
        oli2.PricebookEntryId = stdPriceBookEntrySuport.Id;
        oli2.Discount = 15;
        oli2.Add_On_For__c = null;
        insert oli2;

        OpportunityLineItem oli3 = new OpportunityLineItem();
        oli3.OpportunityId = newOpportunity.Id;
        oli3.UnitPrice = 4000;
        oli3.Quantity = 1;
        oli3.PricebookEntryId = stdPriceBookEntry.Id;
        oli3.Discount = 15;
        oli3.Add_On_For__c = oli.Id;
        insert oli3;

        ApexPages.StandardController sc = new ApexPages.StandardController(newOpportunity);

        // Run Code
        Test.startTest();
            EditProductsController ctrl = new EditProductsController(sc);
            ctrl.opportunityLineItemList[0].compareTo(ctrl.opportunityLineItemList[0]);
            ctrl.SavePriceBook();
            ctrl.ShowNewProduct();
            ctrl.HideNewProduct();
            ctrl.NewProducts[0].selected = true;
            ctrl.NewProducts[1].selected = true;
            ctrl.NewProducts[2].selected = true;
            ctrl.AddNewProduct();
            ctrl.NewProducts[0].compareTo(ctrl.NewProducts[0]);
            ctrl.ShowAddOn();

            ctrl.selectedAddOn = stdPriceBookEntry.Id;
            ctrl.AddOnFor = oli.Id;
            system.debug(ctrl.AddOns);
            system.debug(ctrl.opportunityLineItemList[0].discountedPrice);
            system.debug(ctrl.opportunityLineItemList[0].totalPrice);
            system.debug(ctrl.opportunityLineItemList[0].editable);

            ctrl.HideAddOn();
            ctrl.AddAddOn();
            ctrl.DelOliId = oli.Id;
            ctrl.deleteRecordOnServer();
            ctrl.saveChanges();
            ctrl.cancel();
            ctrl.RecalculatePrices();
        Test.stopTest();

        // Data validation
        List<OpportunityLineItem> oliList =
            [
                SELECT Id
                FROM OpportunityLineItem
            ];

        System.assertEquals(6, oliList.size());
    }


    @isTest static void test_method_4()
    {
        // Data setup
        Account newAccount = new Account();
        newAccount.Name = 'testAccName';
        newAccount.BillingCountry = 'UNITED STATES';
        newAccount.Industry = 'Energy';
        newAccount.Sum_of_Open_Opportunities__c = 400000;
        newAccount.Maintenance_Flag__c = 'Standard';

        insert newAccount;

        Contact cnt = new Contact();
        cnt.LastName = 'Test545731';
        cnt.AccountId = newAccount.Id;
        cnt.Email = 'test.contact545731@testemail.com';
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
        newProduct.Ext_Id__c='testProductName026';
        newProduct.ProductCode='testProductName006';
        newProduct.Family='Other';



        Product2 newProductCare = new Product2();
        newProductCare.Name = 'testProductName';
        newProductCare.Is_Add_On__c = false;
        newProductCare.IsActive = true;
        newProductCare.License_Model__c = 'N/A';
        newProductCare.Unit_of_measure__c = 'N/A';
        newProductCare.Apply_Premium_Care__c = true;
        newProductCare.Premium_Care_Percentage__c = 12;
        newProductCare.Ext_Id__c='testProductName027';
        newProductCare.ProductCode='testProductName027';
        newProductCare.Family='Other';


        Product2 newProductSupport = new Product2();
        newProductSupport.Name = 'testProductName';
        newProductSupport.Apply_Premium_Percentage__c  = true;
        newProductSupport.IsActive = true;
        newProductSupport.Premium_Percentage__c = 15;
        newProductSupport.License_Model__c = 'N/A';
        newProductSupport.Unit_of_measure__c = 'N/A';
        newProductSupport.Ext_Id__c='testProductName028';
        newProductSupport.ProductCode='testProductName028';
        newProductSupport.Family='Other';

        insert new List<Product2> { newProduct, newProductCare, newProductSupport };
 
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

        PriceBookEntry stdPriceBookEntryCare = new PriceBookEntry();
        stdPriceBookEntryCare.Product2Id = newProductCare.Id;
        stdPriceBookEntryCare.Pricebook2Id = stdPriceBookRecId;
        stdPriceBookEntryCare.IsActive = true;
        stdPriceBookEntryCare.UnitPrice = 1;
        stdPriceBookEntryCare.CurrencyIsoCode = newOpportunity.CurrencyIsoCode;

        PriceBookEntry stdPriceBookEntrySuport = new PriceBookEntry();
        stdPriceBookEntrySuport.Product2Id = newProductSupport.Id;
        stdPriceBookEntrySuport.Pricebook2Id = stdPriceBookRecId;
        stdPriceBookEntrySuport.IsActive = true;
        stdPriceBookEntrySuport.UnitPrice = 1;
        stdPriceBookEntrySuport.CurrencyIsoCode = newOpportunity.CurrencyIsoCode;
        insert new List<PriceBookEntry> { stdPriceBookEntry, stdPriceBookEntryCare, stdPriceBookEntrySuport };

        OpportunityLineItem oli = new OpportunityLineItem();
        oli.OpportunityId = newOpportunity.Id;
        oli.UnitPrice = 700;
        oli.Quantity = 2;
        oli.PricebookEntryId = stdPriceBookEntry.Id;
        oli.Discount = 25;
        oli.Add_On_For__c = null;

        OpportunityLineItem oli2supp = new OpportunityLineItem();
        oli2supp.OpportunityId = newOpportunity.Id;
        oli2supp.UnitPrice = 700;
        oli2supp.Quantity = 1;
        oli2supp.PricebookEntryId = stdPriceBookEntryCare.Id;
        oli2supp.Discount = 25;
        oli2supp.Add_On_For__c = null;

        OpportunityLineItem oli2 = new OpportunityLineItem();
        oli2.OpportunityId = newOpportunity.Id;
        oli2.UnitPrice = 5000;
        oli2.Quantity = 1;
        oli2.PricebookEntryId = stdPriceBookEntrySuport.Id;
        oli2.Discount = 15;
        oli2.Add_On_For__c = null;

        OpportunityLineItem oli3 = new OpportunityLineItem();
        oli3.OpportunityId = newOpportunity.Id;
        oli3.UnitPrice = 4000;
        oli3.Quantity = 1;
        oli3.PricebookEntryId = stdPriceBookEntry.Id;
        oli3.Discount = 15;
        oli3.Add_On_For__c = oli.Id;
        insert new List<OpportunityLineItem> { oli, oli2supp, oli2, oli3 };

        ApexPages.StandardController sc = new ApexPages.StandardController(newOpportunity);

        // Run Code
        Test.startTest();
            EditProductsController ctrl = new EditProductsController(sc);
            ctrl.opportunityLineItemList[0].compareTo(ctrl.opportunityLineItemList[0]);
            ctrl.SavePriceBook();
            ctrl.ShowNewProduct();
            ctrl.HideNewProduct();
            ctrl.NewProducts[0].selected = true;
            ctrl.NewProducts[1].selected = true;
            ctrl.NewProducts[2].selected = true;
            ctrl.AddNewProduct();
            ctrl.NewProducts[0].compareTo(ctrl.NewProducts[0]);
            ctrl.ShowAddOn();

            ctrl.selectedAddOn = stdPriceBookEntry.Id;
            ctrl.AddOnFor = oli.Id;
            system.debug(ctrl.AddOns);
            system.debug(ctrl.opportunityLineItemList[0].discountedPrice);
            system.debug(ctrl.opportunityLineItemList[0].totalPrice);
            system.debug(ctrl.opportunityLineItemList[0].editable);

            ctrl.HideAddOn();
            ctrl.AddAddOn();
            ctrl.DelOliId = oli.Id;
            ctrl.deleteRecordOnServer();
            //ctrl.saveChanges();
            //ctrl.cancel();
            //ctrl.RecalculatePrices();
        Test.stopTest();

        // Data validation
        List<OpportunityLineItem> oliList =
            [
                SELECT Id
                FROM OpportunityLineItem
            ];

        System.assertEquals(6, oliList.size());
    }
}