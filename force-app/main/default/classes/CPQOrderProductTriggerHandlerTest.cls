/**
* @author Slalom
* @date 24/08/2020
* @description Test class for CPQOrderProductTriggerHandler class
* @revision #1: Initial Version
*/

@IsTest
public class CPQOrderProductTriggerHandlerTest {
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
        
        List<Address__c>  addressList = DataFactory_CM.createAddress(1, testAccount.Id, false);
        addressList[0].Primary_Billing__c = true;
        addressList[0].Primary_Shipping__c = true;
        addressList[0].NS_Address_Internal_ID__c = '6776';
        insert addressList;
        
        Contact testContact = DataFactory_CM.createContact(testAccount.Id, true);
        
        Opportunity testOpportunity = DataFactory_SL.createOpportunity(testAccount.Id, false);
        testOpportunity.currencyIsoCode = currentUser.CurrencyIsoCode;
        insert testOpportunity;

        SBQQ__Quote__c quote = DataFactory_SL.createCPQQuote(testAccount.Id,testOpportunity.Id,false);
        quote.SBQQ__Primary__c = true;
        quote.currencyIsoCode = currentUser.CurrencyIsoCode;
        insert quote;
        
        Product2 product = DataFactory_SL.createProduct(true);
        
        PricebookEntry pbe = DataFactory_SL.createStdPricebookEntry(product.Id, 100, false);
        pbe.currencyIsoCode = currentUser.CurrencyIsoCode;
        insert pbe;
        
        SBQQ__QuoteLine__c quoteline = DataFactory_SL.createCPQQuoteLine(product.Id, quote.Id, true);
    }  

    /**
    * Test SyncStatus field on Order
    */
    @isTest static void processContractedOrderProducts_test(){
        Test.startTest();
            SBQQ__Quote__c quote = [SELECT Id ,CurrencyIsoCode FROM SBQQ__Quote__c Limit 1];
            
            Opportunity testOpportunity = [SELECT Id,CurrencyIsoCode  FROM Opportunity Limit 1];
            
            PricebookEntry pbe = [SELECT Id FROM PricebookEntry Limit 1];
            
            Order order = DataFactory.createOrder(quote.Id, testOpportunity.Id, false);
            order.currencyIsoCode = currentUser.CurrencyIsoCode;
            insert order;

            OrderItem orderItem = DataFactory_SL.createOrderItem(order.Id, pbe.Id, false);
            
            orderItem.SBQQ__SubscriptionPricing__c= 'Fixed Price';
            insert orderItem;
            
            order.status = Constants.ACTIVATED_ORDER_STATUS;
            update order;
            
            SBQQ__Subscription__c subscription = new SBQQ__Subscription__c(SBQQ__OrderProduct__c = orderItem.id,SBQQ__Quantity__c= 1);
            insert subscription;
            
            orderItem.SBQQ__Subscription__c = subscription.id;
            orderItem.SBQQ__Contracted__c = true;
            update orderItem;

        Test.stopTest();
        
        Order orderAfterUpdate = [SELECT Id,Sync_Status__c FROM order WHERE  Id =: order.Id];
        System.assertEquals(Constants.ORDER_SYNC_STATUS_VALID, orderAfterUpdate.Sync_Status__c);
    }
    @isTest static void testSyncStatusDoNotSyncManual(){
        Test.startTest();
            
            SBQQ__Quote__c quote = [SELECT Id ,CurrencyIsoCode FROM SBQQ__Quote__c Limit 1];
            Opportunity testOpportunity = [SELECT Id,CurrencyIsoCode  FROM Opportunity Limit 1];
            PricebookEntry pbe = [SELECT Id FROM PricebookEntry Limit 1];
            
            Order order = DataFactory.createOrder(quote.Id, testOpportunity.Id, false);
            order.currencyIsoCode = currentUser.CurrencyIsoCode;
            order.Sync_Status__c = Constants.ORDER_SYNC_STATUS_DO_NOT_SYNC;
            insert order;

            OrderItem orderItem = DataFactory_SL.createOrderItem(order.Id, pbe.Id, false);
            
            orderItem.SBQQ__SubscriptionPricing__c= 'Fixed Price';
            insert orderItem;
            
            order.status = Constants.ACTIVATED_ORDER_STATUS;
            update order;
            
            SBQQ__Subscription__c subscription = new SBQQ__Subscription__c(SBQQ__OrderProduct__c = orderItem.id,SBQQ__Quantity__c= 1);
            insert subscription;
            
            orderItem.SBQQ__Subscription__c = subscription.id;
            orderItem.SBQQ__Contracted__c = true;
            update orderItem;

        Test.stopTest();
        
        Order orderAfterUpdate = [SELECT Id,Sync_Status__c FROM order WHERE  Id =: order.Id];
        System.assertEquals(Constants.ORDER_SYNC_STATUS_DO_NOT_SYNC, orderAfterUpdate.Sync_Status__c);
    }
    @isTest static void testSyncStatusDoNotSyncFlow(){
        Test.startTest();
            
            SBQQ__Quote__c quote = [SELECT Id ,CurrencyIsoCode FROM SBQQ__Quote__c Limit 1];
            Opportunity testOpportunity = [SELECT Id,CurrencyIsoCode  FROM Opportunity Limit 1];
            PricebookEntry pbe = [SELECT Id FROM PricebookEntry Limit 1];
            SBQQ__QuoteLine__c quoteline = [SELECT Id FROM SBQQ__QuoteLine__c Limit 1];

            quoteline.SBQQ__ListPrice__c = 0;
            update quoteline;

            Order order = DataFactory.createOrder(quote.Id, testOpportunity.Id, false);
            order.currencyIsoCode = currentUser.CurrencyIsoCode;
            //order.Sync_Status__c = Constants.ORDER_SYNC_STATUS_DO_NOT_SYNC;
            insert order;

            OrderItem orderItem = DataFactory_SL.createOrderItem(order.Id, pbe.Id, false);
            
            orderItem.SBQQ__SubscriptionPricing__c= 'Fixed Price';
            insert orderItem;
            
            order.status = Constants.ACTIVATED_ORDER_STATUS;
            update order;
            
            SBQQ__Subscription__c subscription = new SBQQ__Subscription__c(SBQQ__OrderProduct__c = orderItem.id,SBQQ__Quantity__c= 1);
            insert subscription;
            
            orderItem.SBQQ__Subscription__c = subscription.id;
            orderItem.SBQQ__Contracted__c = true;
            update orderItem;

        Test.stopTest();
        
        Order orderAfterUpdate = [SELECT Id,Sync_Status__c FROM order WHERE  Id =: order.Id];
        System.assertEquals(Constants.ORDER_SYNC_STATUS_DO_NOT_SYNC, orderAfterUpdate.Sync_Status__c);
    }
    @isTest static void testCopyBillingFrequencyOrderToOrderProducts(){
        Test.startTest();
            
            SBQQ__Quote__c quote = [SELECT Id ,CurrencyIsoCode FROM SBQQ__Quote__c Limit 1];
            Opportunity testOpportunity = [SELECT Id,CurrencyIsoCode  FROM Opportunity Limit 1];
            PricebookEntry pbe = [SELECT Id FROM PricebookEntry Limit 1];
            SBQQ__QuoteLine__c quoteline = [SELECT Id FROM SBQQ__QuoteLine__c Limit 1];

            quoteline.SBQQ__ListPrice__c = 0;
            update quoteline;

            Order order = DataFactory.createOrder(quote.Id, testOpportunity.Id, false);
            order.Billing_Frequency__c = 'Upfront';
            order.currencyIsoCode = currentUser.CurrencyIsoCode;
            insert order;
            

            OrderItem orderItem = DataFactory_SL.createOrderItem(order.Id, pbe.Id, false);
            insert orderItem;

        Test.stopTest();
        
        OrderItem orderItemOnCreate = [SELECT Id,SBQQ__BillingFrequency__c FROM OrderItem WHERE  Id =: orderItem.Id];
        System.assertEquals('Upfront' ,orderItemOnCreate.SBQQ__BillingFrequency__c);
    }
    @isTest static void testBillingFrequencyNotCopyFronQuoteToOrderProducts(){
        Test.startTest();
            
            SBQQ__Quote__c quote = [SELECT Id ,CurrencyIsoCode FROM SBQQ__Quote__c Limit 1];
            Opportunity testOpportunity = [SELECT Id,CurrencyIsoCode  FROM Opportunity Limit 1];
            PricebookEntry pbe = [SELECT Id FROM PricebookEntry Limit 1];
            SBQQ__QuoteLine__c quoteline = [SELECT Id FROM SBQQ__QuoteLine__c Limit 1];

            quoteline.SBQQ__ListPrice__c = 0;
            quoteline.SBQQ__BillingFrequency__c = 'Annual';
            update quoteline;

            Order order = DataFactory.createOrder(quote.Id, testOpportunity.Id, false);
            order.Billing_Frequency__c = 'Upfront';
            order.currencyIsoCode = currentUser.CurrencyIsoCode;
            insert order;
            

            OrderItem orderItem = DataFactory_SL.createOrderItem(order.Id, pbe.Id, false);
            insert orderItem;

        Test.stopTest();
        SBQQ__QuoteLine__c quotelineAfterUpdate = [SELECT Id,SBQQ__BillingFrequency__c FROM SBQQ__QuoteLine__c WHERE  Id =: quoteline.Id];
        OrderItem orderItemOnCreate = [SELECT Id,SBQQ__BillingFrequency__c FROM OrderItem WHERE  Id =: orderItem.Id];
        System.assertEquals('Annual' ,quotelineAfterUpdate.SBQQ__BillingFrequency__c);
        System.assertEquals('Upfront' ,orderItemOnCreate.SBQQ__BillingFrequency__c);
    }
}