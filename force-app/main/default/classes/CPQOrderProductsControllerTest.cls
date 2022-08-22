@IsTest
public with sharing class CPQOrderProductsControllerTest {
    
    @TestSetup
    static void makeData(){
        Account testAccount = DataFactory_CM.createAccount(Constants.ACCOUNT_RECORD_TYPE_1, false);
        testAccount.NS_Customer_Internal_ID__c = '75586';
        testAccount.Country__c='United Kingdom';
        testAccount.Legal__c = 'Legal Name';
        testAccount.DNBoptimizer__DNB_D_U_N_S_Number__c = '1234567';
        insert testAccount;
        
        list <Address__c>  addressList = DataFactory_CM.createAddress(1, testAccount.Id, false);
        addressList[0].Primary_Billing__c = true;
        addressList[0].Primary_Shipping__c = true;
        addressList[0].NS_Address_Internal_ID__c = '6776';
        insert addressList;

        Contact testContact = DataFactory_CM.createContact(testAccount.Id, true);
        Opportunity testOpportunity = DataFactory_SL.createOpportunity(testAccount.Id, false);
        insert testOpportunity;

        SBQQ__Quote__c quote = DataFactory_SL.createCPQQuote(testAccount.Id,testOpportunity.Id,false);
        quote.SBQQ__Primary__c = true;
        insert quote;

        Product2 product = DataFactory_SL.createProduct(true);

        PricebookEntry pbe = DataFactory_SL.createStdPricebookEntry(product.Id, 100, false);
        insert pbe;

        SBQQ__QuoteLine__c quoteline = DataFactory_SL.createCPQQuoteLine(product.Id, quote.Id, true);

        Order order = DataFactory.createOrder(quote.Id, testOpportunity.Id, false);
        insert order;
        OrderItem orderItem = DataFactory_SL.createOrderItem(order.Id, pbe.Id, true);
    }

    @isTest
    private static void getInitialDataTest(){
        Order o = [SELECT Id FROM Order LIMIT 1];
        Test.startTest();
            CPQOrderProductsController.CPQOrderProductsWrapper wrapper = CPQOrderProductsController.getInitialData(o.Id);
            System.assert(wrapper.orderItems.size() > 0, true);

            CPQOrderProductsController.saveOrderProducts(wrapper.orderItems);
        Test.stopTest();
    }
}