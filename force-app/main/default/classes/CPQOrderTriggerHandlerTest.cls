/**
* @author Slalom
* @date 10/08/2020
* @description Test class for CPQOrderTriggerHandler
*/
@IsTest
public class CPQOrderTriggerHandlerTest {
    Static User currentUser = [Select id, CurrencyIsoCode  from User where id=: UserInfo.getUserId()];

    @testSetup
    public static void testSetup() {
        Account testAccount = DataFactory_CM.createAccount(Constants.ACCOUNT_RECORD_TYPE_1, false);
        testAccount.NS_Customer_Internal_ID__c = '75586';
        testAccount.Country__c='United Kingdom';
        testAccount.Legal__c = 'Legal Name';
        testAccount.DNBoptimizer__DNB_D_U_N_S_Number__c = '1234567';
        testAccount.currencyIsoCode = currentUser.currencyIsoCode;
        testAccount.VAT_Number__c = '12345';
        insert testAccount;
        
        list <Address__c>  addressList = DataFactory_CM.createAddress(1, testAccount.Id, false);
        addressList[0].Primary_Billing__c = true;
        addressList[0].Primary_Shipping__c = true;
        addressList[0].NS_Address_Internal_ID__c = '6776';
        insert addressList;

        Contact testContact = DataFactory_CM.createContact(testAccount.Id, true);
        Opportunity testOpportunity = DataFactory_SL.createOpportunity(testAccount.Id, false);
        testOpportunity.currencyIsoCode = currentUser.currencyIsoCode;
        insert testOpportunity;

        SBQQ__Quote__c quote = DataFactory_SL.createCPQQuote(testAccount.Id,testOpportunity.Id,false);
        quote.currencyIsoCode = currentUser.currencyIsoCode;
        insert quote;

        Product2 product = DataFactory_SL.createProduct(true);

        PricebookEntry pbe = DataFactory_SL.createStdPricebookEntry(product.Id, 100, false);
        pbe.currencyIsoCode = currentUser.currencyIsoCode;
        insert pbe;

        SBQQ__QuoteLine__c quoteline = DataFactory_SL.createCPQQuoteLine(product.Id, quote.Id, true);

       
    }

    /**
    * Test valid Billing Frequency
    */
    @isTest static void testUpdateBillingFrequenciesOnOrderProdPositive() {
        Account account = getAccount();
        Opportunity opportunity = getOpportunity(account);
        SBQQ__Quote__c quote = getQuote(opportunity, account);
        PricebookEntry pbe = getPricebookEntry();
        
        Test.startTest();
            quote.SBQQ__Primary__c = true;
            update quote;

            Order order = DataFactory.createOrder(quote.Id, opportunity.Id, false);
            order.currencyIsoCode = currentUser.currencyIsoCode;
            insert order;
            OrderItem orderItem = DataFactory_SL.createOrderItem(order.Id, pbe.Id, true);

            order.Billing_Frequency__c = 'Annual';
            update order;

        Test.stopTest();
        
        orderItem = [SELECT Id, SBQQ__BillingFrequency__c FROM OrderItem];

        System.assertEquals(order.Billing_Frequency__c, orderItem.SBQQ__BillingFrequency__c);
    }

    /**
    * Test valid Payment Cycle
    */
    @isTest static void testUpdatePaymentCycleOnOppPositive() {
        Account account = getAccount();
        Opportunity opportunity = getOpportunity(account);
        SBQQ__Quote__c quote = getQuote(opportunity, account);
        PricebookEntry pbe = getPricebookEntry();
        
        Test.startTest();
            quote.SBQQ__Primary__c = true;
            update quote;

            Order order = DataFactory.createOrder(quote.Id, opportunity.Id, false);
            order.currencyIsoCode = currentUser.currencyIsoCode;
            insert order;
            OrderItem orderItem = DataFactory_SL.createOrderItem(order.Id, pbe.Id, true);

            order.Billing_Frequency__c = 'Annual';
            update order;

        Test.stopTest();
        
        orderItem = [SELECT Id, SBQQ__BillingFrequency__c FROM OrderItem];
        opportunity = getOpportunity(opportunity.Id);

        System.assertEquals(order.Billing_Frequency__c, orderItem.SBQQ__BillingFrequency__c);
    }

    /**
    * Test valid Order delete
    */
    @isTest static void testUncheckQuoteOrderedPositive() {
        Account account = getAccount();
        Opportunity opportunity = getOpportunity(account);
        SBQQ__Quote__c quote = getQuote(opportunity, account);
        PricebookEntry pbe = getPricebookEntry();
        
        Test.startTest();
            quote.SBQQ__Primary__c = true;
            update quote;

            Order order = DataFactory.createOrder(quote.Id, opportunity.Id, false);
            order.currencyIsoCode = currentUser.currencyIsoCode;
            insert order;
            OrderItem orderItem = DataFactory_SL.createOrderItem(order.Id, pbe.Id, true);

            delete order;
        Test.stopTest();

        quote = getQuote(opportunity, account);

        System.assertEquals(false, quote.SBQQ__Ordered__c);
    }

    /**
    * Test Handle Error
    */
    @isTest static void testHandleError() {
        Account account = getAccount();
        Opportunity opportunity = getOpportunity(account);
        SBQQ__Quote__c quote = getQuote(opportunity, account);
        
        Test.startTest();
        	List<Database.SaveResult> results;
            quote.SBQQ__Primary__c = true;
            update quote;

            Order order = DataFactory.createOrder(quote.Id, opportunity.Id, false);
            order.currencyIsoCode = currentUser.currencyIsoCode;
            results = Database.insert(new List<Order>{order});
        
        	CPQOrderTriggerHandler handler = new CPQOrderTriggerHandler();
        	handler.handleError(results, new List<Order>{order}, 'Test ErrorMessage');
        Test.stopTest();
    }
    /**
    * Test update SyncStatus field on Order for nonSubscription Order Item
    */
    @isTest static void testContractActivatedOrdersNonSubsOrderItem() {
        Account account = getAccount();
        Opportunity opportunity = getOpportunity(account);
        SBQQ__Quote__c quote = getQuote(opportunity, account);
        PricebookEntry pbe = getPricebookEntry();
        
        Test.startTest();
            quote.SBQQ__Primary__c = true;
            update quote;

            Order order = DataFactory.createOrder(quote.Id, opportunity.Id, false);
            order.currencyIsoCode = currentUser.currencyIsoCode;
            insert order;

            OrderItem orderItem = DataFactory_SL.createOrderItem(order.Id, pbe.Id, false);
            orderItem.SBQQ__SubscriptionPricing__c= '';
            insert orderItem;
            
            order.status = Constants.ACTIVATED_ORDER_STATUS;
            update order;
        Test.stopTest();
        Order orderAfterUpdate = [SELECT Id,Sync_Status__c ,Posting_Date__c,Zero_List_Price_Deal__c FROM order WHERE  Id =: order.Id];
        
        System.assertEquals(Constants.ORDER_SYNC_STATUS_VALID, orderAfterUpdate.Sync_Status__c);
        System.assertEquals(false, orderAfterUpdate.Zero_List_Price_Deal__c);
        
    }
    
    /**
    * Test update SyncStatus field on Order for Subscription Order Item
    */
    @isTest static void testContractActivatedOrdersSubsOrderItem() {
        Account account = getAccount();
        Opportunity opportunity = getOpportunity(account);
        SBQQ__Quote__c quote = getQuote(opportunity, account);
        PricebookEntry pbe = getPricebookEntry();
        
        Test.startTest();
            quote.SBQQ__Primary__c = true;
            update quote;

            Order order = DataFactory.createOrder(quote.Id, opportunity.Id, false);
            order.currencyIsoCode = currentUser.currencyIsoCode;
            insert order;
            OrderItem orderItem = DataFactory_SL.createOrderItem(order.Id, pbe.Id, false);
            orderItem.SBQQ__SubscriptionPricing__c= 'Fixed Price';
            insert orderItem;
            order.status = Constants.ACTIVATED_ORDER_STATUS;
            update order;
        Test.stopTest();
        Order orderAfterUpdate = [SELECT Id,Sync_Status__c FROM  Order WHERE Id =: order.Id];
        System.assertNotEquals(Constants.ORDER_SYNC_STATUS_VALID, orderAfterUpdate.Sync_Status__c);
    }
    /**
    *  posting date entered manually entered  hence it should not be defaulted
    */
    @isTest static void testDefaultPostingDateOnOrderActivation_ManualEntry() {
        Account account = getAccount();
        Opportunity opportunity = getOpportunity(account);
        SBQQ__Quote__c quote = getQuote(opportunity, account);
        PricebookEntry pbe = getPricebookEntry();
        
        Test.startTest();
            quote.SBQQ__Primary__c = true;
            update quote;

            Order order = DataFactory.createOrder(quote.Id, opportunity.Id, false);
            order.currencyIsoCode = currentUser.currencyIsoCode;
            order.Posting_Date__c = system.today()+1; //setting the posting date at insert so that it get value at time of order activation
            insert order;

            OrderItem orderItem = DataFactory_SL.createOrderItem(order.Id, pbe.Id, false);
            orderItem.SBQQ__SubscriptionPricing__c= '';
            insert orderItem;
            
            order.status = Constants.ACTIVATED_ORDER_STATUS;
            update order;
        Test.stopTest();

        Order orderAfterUpdate = [SELECT Id ,Posting_Date__c FROM order WHERE  Id =: order.Id];
        System.assertEquals(system.today()+1,orderAfterUpdate.Posting_Date__c); // posting date remains the same 
        
    }
    /**
    * Posting date left blank, hence it should be defaulted to order activation date 
    */
    @isTest static void testDefaultPostingDateOnOrderActivation_Default() {
        Account account = getAccount();
        Opportunity opportunity = getOpportunity(account);
        SBQQ__Quote__c quote = getQuote(opportunity, account);
        PricebookEntry pbe = getPricebookEntry();
        
        Test.startTest();
            quote.SBQQ__Primary__c = true;
            update quote;

            Order order = DataFactory.createOrder(quote.Id, opportunity.Id, false);
            order.currencyIsoCode = currentUser.currencyIsoCode;
            insert order;

            OrderItem orderItem = DataFactory_SL.createOrderItem(order.Id, pbe.Id, false);
            orderItem.SBQQ__SubscriptionPricing__c= '';
            insert orderItem;
            
            order.status = Constants.ACTIVATED_ORDER_STATUS;
            update order;
        Test.stopTest();
        SBQQ__Quote__c quoteAfter = [SELECT Id , SBQQ__ListAmount__c FROM SBQQ__Quote__c WHERE Id =: quote.Id];
        Order orderAfterUpdate = [SELECT Id ,Posting_Date__c,Zero_List_Price_Deal__c FROM order WHERE  Id =: order.Id];
        System.assertEquals(system.today(),orderAfterUpdate.Posting_Date__c); //Posting date set to todays date 
        System.assertEquals(false, orderAfterUpdate.Zero_List_Price_Deal__c); //check Order Zero list price deal ceckbox
        
    }
    
    @isTest static void testZeroDollarDeal() {
        Account account = getAccount();
        Opportunity opportunity = getOpportunity(account);
        SBQQ__Quote__c quote = getQuote(opportunity, account);
        SBQQ__QuoteLine__c quoteline = getQuoteLine();
        PricebookEntry pbe = getPricebookEntry();
        
        Test.startTest();
            pbe.unitPrice = 0;
            update pbe;

            quote.SBQQ__Primary__c = true;
            update quote;

            quoteline.SBQQ__ListPrice__c = 0;
            update quoteline; 
 
            Order order = DataFactory.createOrder(quote.Id, opportunity.Id, false);
            order.currencyIsoCode = currentUser.currencyIsoCode;
            insert order;

            OrderItem orderItem = DataFactory_SL.createOrderItem(order.Id, pbe.Id, false);
            insert orderItem;
            

            order.status = Constants.ACTIVATED_ORDER_STATUS;
            update order;

        Test.stopTest();

        Order orderAfterUpdate = [SELECT Id ,Sync_Status__c, Zero_List_Price_Deal__c , status FROM order WHERE  Id =: order.Id];
        System.assertEquals(Constants.ORDER_SYNC_STATUS_DO_NOT_SYNC,orderAfterUpdate.Sync_Status__c); //Flow Test- Sync status set to Do Not Sync
        System.assertEquals(true, orderAfterUpdate.Zero_List_Price_Deal__c);                          //Formula Field Test
        System.assertEquals(Constants.ACTIVATED_ORDER_STATUS, orderAfterUpdate.status);               // Order SYnc Status Test
        
    }

    
    private static Account getAccount() {
        return [SELECT Id ,CurrencyIsoCode FROM Account LIMIT 1];
    }

    private static Opportunity getOpportunity(Account account) {
        return [SELECT Id ,CurrencyIsoCode FROM Opportunity WHERE AccountId = :account.Id];
    }

    private static SBQQ__Quote__c getQuote(Opportunity opportunity, Account account) {
        return [SELECT Id, SBQQ__Ordered__c,CurrencyIsoCode FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__c = :opportunity.Id AND SBQQ__Account__c = :account.Id];
    }

    private static PricebookEntry getPricebookEntry(){
        return [SELECT Id, Product2Id,UnitPrice FROM PricebookEntry LIMIT 1];
    }

    private static Opportunity getOpportunity(Id oppId){
        return [SELECT Payment_Cycle__c FROM Opportunity WHERE Id = :oppId];
    }
    private static SBQQ__QuoteLine__c getQuoteLine(){
        return [SELECT Id FROM SBQQ__QuoteLine__c LIMIT 1];
    }
    private static User getUser(String userLastname){
        return [SELECT Id,Name FROM User WHERE Lastname =:userLastname ];
    }

}