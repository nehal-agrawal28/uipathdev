@isTest
private class CommunityEditProductsControllerTest {

    @testSetup
    private static void createDate() {
        
        // Data setup
        Account newAccount = new Account();
        newAccount.Name = 'testAccName';
        newAccount.BillingCountry = 'UNITED STATES';
        newAccount.Industry = 'Energy';
        insert newAccount;
        
        Contact cnt = new Contact();
        cnt.LastName = 'Test545734';
        cnt.AccountId = newAccount.Id;
        cnt.Email = 'testCnt' + Date.today().format() + '@uipath.com.contact.testuser';
        cnt.Department__c = 'IT';
        insert cnt;

        Id stdPriceBookRecId = Test.getStandardPricebookId();

        List<Product2> productList = new List<Product2>();
        
        productList.add(new Product2(
            Name = 'UiPath - Orchestrator',
            Is_Add_On__c = false,
            IsActive = true,
            License_Model__c = 'N/A',
            Unit_of_measure__c = 'N/A',
            Ext_Id__c = 'UiPath - Orchestrator',
            ProductCode = 'UiPath - Orchestrator',
            Family = 'Other',
            CPQ_Exclusive__c = false,
            Use_Community__c = true
        ));

        productList.add(new Product2(
            Name = 'UiPath - test01',
            Is_Add_On__c = false,
            IsActive = true,
            License_Model__c = 'N/A',
            Unit_of_measure__c = 'N/A',
            Ext_Id__c = 'UiPath - test01',
            ProductCode = 'UiPath - test01',
            Family = 'Other',
            CPQ_Exclusive__c = false,
            Apply_Premium_Percentage__c = true,
            Premium_Percentage__c = 15,
            Use_Community__c = true
        ));

        productList.add(new Product2(
            Name = 'UiPath - test02',
            Is_Add_On__c = false,
            IsActive = true,
            License_Model__c = 'N/A',
            Unit_of_measure__c = 'N/A',
            Ext_Id__c = 'UiPath - test02',
            ProductCode = 'UiPath - test02',
            Family = 'Other',
            CPQ_Exclusive__c = false,
            Apply_Premium_Care__c = true,
            Premium_Care_Percentage__c = 15,
            Use_Community__c = true
        ));

        insert productList;

        List<Opportunity> oppList = new List<Opportunity>();
        oppList.add(new Opportunity(
            Name = 'Renewal Opportunity',
            Type = 'Renewal',
            AccountId = newAccount.Id,
            StageName = 'Discovery',
            CloseDate = Date.today(),
            Discount_Approval_Status__c = 'In Approval',
            Managing_Director__c = UserInfo.getUserId(),
            Pricebook2Id = stdPriceBookRecId,
            CurrencyIsoCode = 'EUR',
            Customer_Primary_Contact__c = cnt.Id
        ));
        insert oppList;

        List<PriceBookEntry> stdPriceBookEntryList = new List<PriceBookEntry>();
        for (Product2 p : productList) {
            stdPriceBookEntryList.add(new PriceBookEntry(
                Product2Id = p.Id,
                Pricebook2Id = stdPriceBookRecId,
                UnitPrice = 2000,
                IsActive = true,
                CurrencyIsoCode = 'EUR'
            ));
        }
        insert stdPriceBookEntryList;

        List<OpportunityLineItem> oliList = new List<OpportunityLineItem>();

        for (PriceBookEntry pb : stdPriceBookEntryList) {
            for (Opportunity opp : oppList) {
                oliList.add(new OpportunityLineItem(
                    OpportunityId = opp.Id,
                    UnitPrice = 25000,
                    Quantity = 3,
                    PricebookEntryId = pb.Id,
                    Discount = 0,
                    ServiceDate = Date.today(),
                    End_Date__c = Date.today().addYears(1),
                    Add_On_For__c = null
                ));
            }
        }
        insert oliList;
    }
    
    @isTest
    private static void test_method_1() {
        
        Opportunity opp = [SELECT Id, Pricebook2Id FROM Opportunity WHERE Type = 'Renewal' LIMIT 1];
        //OpportunityLineItem oli = [SELECT Id FROM OpportunityLineItem LIMIT 1];
        
        ApexPages.StandardController sc = new ApexPages.StandardController(opp);
        
        Test.startTest();
            CommunityEditProductsController ctrl = new CommunityEditProductsController(sc);
            ctrl.EditProductInit();

            ctrl.ShowNewProduct();
            for (CommunityEditProductsController.NewProductEntry en : ctrl.NewProducts) {
                en.selected = true;
            }
            ctrl.AddNewProduct();
            ctrl.HideNewProduct();

            Boolean profileCanEdit = ctrl.profileCanEdit;
            Boolean commentsVisible = ctrl.opportunityLineItemList[0].CommentsVisible;
            Integer quantity = ctrl.opportunityLineItemList[0].Quantity;
            Decimal totalPrice = ctrl.opportunityLineItemList[0].totalPrice;
            Boolean premiumCareDiscount = ctrl.opportunityLineItemList[0].PremiumCareDiscount;

            ctrl.DelOliId = ctrl.opportunityLineItemList[0].oli.Id;
            ctrl.deleteRecordOnServer();
            ctrl.saveChanges();
            ctrl.cancel();
            ctrl.RecalculatePrices();
            
        Test.stopTest();
        
        
    }
}