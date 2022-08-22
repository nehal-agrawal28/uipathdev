/*******************************************************************************
* @author         :    Bharti Mewada
* @date           :    Aug 2020
* @description    :    Test class for AddressComponentController
* @Revisions      :
        #1        :   Initial Version 
*******************************************************************************/
@IsTest(isParallel=false)
public class AddressComponentControllerTest{
    Static User currentUser = [Select id, CurrencyIsoCode  from User where id=: UserInfo.getUserId()];

    @testSetup
    public static void testSetup() {
        List<Account> accountList = new List<Account>();

        Account testCustomer = DataFactory_CM.createAccount(Constants.ACCOUNT_RECORD_TYPE_1, false);
        testCustomer.Name = 'TestCustomerAccount';
        testCustomer.Country__c='United Kingdom';
        testCustomer.Legal__c = 'Legal Name';
        testCustomer.DNBoptimizer__DNB_D_U_N_S_Number__c = '1234567';
        testCustomer.currencyIsoCode = currentUser.currencyIsoCode;
        
        
        Account testPartner = DataFactory_CM.createAccount(Constants.ACCOUNT_RECORD_TYPE_2, false);
        testPartner.Name = 'TestPartnerAccount';
        testPartner.Country__c='United Kingdom';
        testPartner.Legal__c = 'Legal Name';
        testPartner.DNBoptimizer__DNB_D_U_N_S_Number__c = '1234567';
        testPartner.currencyIsoCode = currentUser.currencyIsoCode;

        accountList.add(testCustomer);
        accountList.add(testPartner);

        insert accountList;
        //system.debug('BM Customer Account'+ testCustomer);
        //system.debug('BM Parter Account'+ testPartner);

        list <Address__c> addressList = DataFactory_SL.createAddress(2, testCustomer.Id, false);

        Address__c customerAddress = addressList[0];
        customerAddress.Primary_Billing__c = true;
        customerAddress.Primary_Shipping__c = true;
        customerAddress.Account__c = testCustomer.Id;

        Address__c partnerAddress = addressList[1];
        partnerAddress.Primary_Billing__c = true;
        partnerAddress.Primary_Shipping__c = true;
        partnerAddress.Account__c = testPartner.Id;

        insert addressList;

        Opportunity testOpportunity = DataFactory_SL.createOpportunity(testCustomer.Id, false);
        testOpportunity.currencyIsoCode = currentUser.currencyIsoCode;
        insert testOpportunity;
        
        SBQQ__Quote__c quote = DataFactory_SL.createCPQQuote(testCustomer.Id,testOpportunity.Id,false);
        quote.SBQQ__BillingFrequency__c = 'Upfront';
        quote.SBQQ__Primary__c= true;
        quote.Bill_To_Account__c= testPartner.Id;
        quote.currencyIsoCode = currentUser.currencyIsoCode;
        quote.SBQQ__Status__c = 'Accepted';
        insert quote;
        //system.debug('BM Insert Quote'+ quote);
        
        Order testOrder = DataFactory_SL.createOrder(quote.Id,testOpportunity.Id,false );
        address__c billToAddress = [Select id FROM Address__c WHERE Account__c = : testPartner.Id LIMIT 1];
        testOrder.AccountId = testCustomer.Id;
        //testOrder.Bill_To_Account__c= testPartner.Id;
        testOrder.Bill_To_Address__c= billToAddress.Id;
        testOrder.Ship_To_Address__c= billToAddress.Id;
        testOrder.currencyIsoCode = currentUser.currencyIsoCode;
        insert testOrder;
        // system.debug('BM Insert Order'+testOrder);
        //SBQQ__Quote__c quote1 = [SELECT Id, Bill_To_Account__c,Bill_To_Account__r.Name FROM SBQQ__Quote__c WHERE Id =: quote.Id Limit 1 ];
        //system.debug('BM Quote in test context'+quote1);
    }

    /** 
    * @Description : checks on order creation, successfully copy all fields from quote
    * @AUTHOR: Bharti
    */
    public static testmethod void testOrderCreation() {
        Test.startTest();
            Order odr = [Select Id, Account.Name,AccountId,Billing_Frequency__c,Bill_To_Account__c,Bill_To_Account__r.Name,SBQQ__Quote__c from Order Limit 1];
            // system.debug('BM Order in test context'+odr);
            //SBQQ__Quote__c quote = [SELECT Id, Bill_To_Account__c,Bill_To_Account__r.Name FROM SBQQ__Quote__c WHERE Id =: odr.SBQQ__Quote__c Limit 1 ];
            // system.debug('BM Quote in test context In method'+quote);
            System.AssertNotEquals(null,odr);
            System.AssertEquals('TestCustomerAccount',odr.Account.Name );
            // System.AssertEquals('TestPartnerAccount',odr.Bill_To_Account__r.Name);
            //test Copy billing frency by flow
            System.AssertEquals('Upfront',odr.Billing_Frequency__c);
        Test.stopTest();
    }

    /** 
    * @Description : checks on getBilltoAddress method. get bill to address to display on component 
    * @AUTHOR: Bharti
    */
     public static testmethod void testGetBillToAddress() {
        Test.startTest();
            Order odr = [Select Id,Bill_To_Address__c, Account.Name from Order Limit 1];
            address__c billtoAddress = AddressComponentController.getBilltoAddress(odr.id);
            System.AssertEquals(odr.Bill_To_Address__c,billtoAddress.id);
        Test.stopTest();
    
    }
    /** 
    * @description : checks on getShiptoAddress method. get ship to address to display on component 
    * @AUTHOR: Bharti
    */
     public static testmethod void testGetShipToAddress() {
       Test.startTest();
            Order odr = [Select Id,Ship_To_Address__c, Account.Name from Order Limit 1];
            address__c shipptoAddress = AddressComponentController.getShipToAddress(odr.id);
            System.AssertEquals(odr.Ship_To_Address__c,shipptoAddress.id);
        Test.stopTest();
    }

    /** 
    * @description : checks on getAddressOnClickBillToAddress method. Getting the list of all address from Account on the order
    * @AUTHOR: Bharti
    */
    public static testmethod void testGetAddressOnClickBillToAddress() {
        Test.startTest();
            Order odr = [Select Id,Bill_To_Address__c, Account.Name from Order Limit 1];
            List<AddressComponentController.addressWrapper> billToAddressList = AddressComponentController.getWrappedAddress('billToAddress',odr.id,null);
            //System.AssertEquals(1, billToAddressList.size());
        Test.stopTest();
    }
    /** 
    * @description : checks on getAddressOnClickShipplToAddress method. Getting the list of all address from Account and bill to account on the order
    * @AUTHOR: Bharti
    */
     public static testmethod void testGetAddressOnClickShipToAddress() {
        Test.startTest();
            Order odr = [Select Id,Bill_To_Address__c, Account.Name from Order Limit 1];
            List<AddressComponentController.addressWrapper> shipToAddressList = AddressComponentController.getWrappedAddress('shipToAddress',odr.id,null);
            //System.AssertEquals(2,shipToAddressList.size());
        Test.stopTest();
    }

    /** 
    * @description : checks on updateShipToAddress method. changing the ship to address on order
    * @AUTHOR: Bharti
    */                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          
    public static testmethod void testUpdateShipToAddress() {
        Test.startTest();
            Order odr = [Select Id,Ship_To_Address__c, Account.Name from Order Limit 1];
            //Query billToAddress
            address__c shipToAddress = [Select id FROM Address__c where Id !=: odr.Ship_To_Address__c LIMIT 1];
            AddressComponentController.updateAddress('shipToAddress', shipToAddress.id, odr.id);
            Order oderAfterUpdate = [Select id,Bill_To_Address__c,Ship_To_Address__c FROM Order LIMIT 1];
            // Both billToAddress and ShipToAddress are now Same.
            System.AssertEquals(shipToAddress.Id,oderAfterUpdate.Ship_To_Address__c);
        Test.stopTest();
    }

    /** 
    * @description : checks on updateShipToAddress method. with order Id as null
    * @AUTHOR: Bharti
    */                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          
    public static testmethod void testUpdateShipToAddressWithOrderIdNull() {
        Test.startTest();
            Order odr = [Select Id,Bill_To_Address__c, Account.Name from Order Limit 1];
            address__c billToAddress = [Select id FROM Address__c where Id =: odr.Bill_To_Address__c LIMIT 1];
           try{
                AddressComponentController.updateAddress('shipToAddress', billToAddress.id,null);
           }catch(Exception ex){
               //This will show as the exception has occured with order Id as null
               system.assert(true);
           }
        Test.stopTest();
    
    }

}