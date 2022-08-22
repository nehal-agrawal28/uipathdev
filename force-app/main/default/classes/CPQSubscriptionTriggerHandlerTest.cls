/**
* @author Slalom
* @date 14/09/2020
* @description Test class for CPQOrderProductTriggerHandler class
* @revision #1: Initial Version
*/
@IsTest
public class CPQSubscriptionTriggerHandlerTest {
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
    * Test license code  field update on  subscription
    */
     @isTest static void processSubscriptionsOnOrderActivationTest(){
        Test.startTest();
            
            SBQQ__Quote__c quote = [SELECT Id ,CurrencyIsoCode FROM SBQQ__Quote__c Limit 1];
            Opportunity testOpportunity = [SELECT Id,CurrencyIsoCode  FROM Opportunity Limit 1];
            PricebookEntry pbe = [SELECT Id FROM PricebookEntry Limit 1];
            
            Order order = DataFactory.createOrder(quote.Id, testOpportunity.Id, false);
            order.currencyIsoCode = currentUser.CurrencyIsoCode;
            insert order;

            OrderItem orderItem = DataFactory_SL.createOrderItem(order.Id, pbe.Id, false);
            orderItem.SBQQ__SubscriptionPricing__c= 'Fixed Price';
            orderItem.License_Codes__c = '674545464';
            insert orderItem;

            order.status = Constants.ACTIVATED_ORDER_STATUS;
            update order;
            
            SBQQ__Subscription__c subscription = new SBQQ__Subscription__c(SBQQ__Quantity__c= 1);
            insert subscription;

            subscription.SBQQ__OrderProduct__c =  orderItem.id;
            update subscription;

        Test.stopTest();
        
        SBQQ__Subscription__c  subscriptionAfterUpdate = [SELECT Id, License_Codes__c FROM SBQQ__Subscription__c WHERE  Id =: subscription.Id];
        System.assertEquals(orderItem.License_Codes__c, subscriptionAfterUpdate.License_Codes__c);
    }
    
    @isTest static void processAdditionalDiscountPercentTest(){
        Test.startTest();
            
            SBQQ__Quote__c quote = [SELECT Id ,CurrencyIsoCode FROM SBQQ__Quote__c Limit 1];
            Opportunity testOpportunity = [SELECT Id,CurrencyIsoCode  FROM Opportunity Limit 1];
            PricebookEntry pbe = [SELECT Id FROM PricebookEntry Limit 1];
            
            Order order = DataFactory.createOrder(quote.Id, testOpportunity.Id, false);
            order.currencyIsoCode = currentUser.CurrencyIsoCode;
            insert order;

            OrderItem orderItem = DataFactory_SL.createOrderItem(order.Id, pbe.Id, false);
            orderItem.SBQQ__SubscriptionPricing__c= 'Fixed Price';
            orderItem.License_Codes__c = '674545464';
            insert orderItem;

            order.status = Constants.ACTIVATED_ORDER_STATUS;
            update order;
            
            SBQQ__Subscription__c subscription = new SBQQ__Subscription__c(
                SBQQ__Quantity__c = 1.00,
                SBQQ__ProrateMultiplier__c = 2.00,
                SBQQ__ListPrice__c = 800.00,
                SBQQ__SpecialPrice__c = 350.00,
                SBQQ__RegularPrice__c = 350.00,
                SBQQ__CustomerPrice__c = 300.00,
                SBQQ__AdditionalDiscountAmount__c = 7.14,
                SBQQ__Discount__c = null,
                SBQQ__OrderProduct__c = orderItem.Id
            );
            insert subscription;

        Test.stopTest();

        SBQQ__Subscription__c insertedSub = [
            SELECT Id, SBQQ__Discount__c 
            FROM SBQQ__Subscription__c 
            WHERE Id = :subscription.Id
        ];
        System.assertEquals(
            7.14, 
            insertedSub.SBQQ__Discount__c.setScale(2), 
            'Amount discount coversion to percent is incorrect'
        );
    }
}