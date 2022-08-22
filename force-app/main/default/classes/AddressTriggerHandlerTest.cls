/**
    * @DESCRIPTION: This is Test Class for AddressTriggerHandle class
    * @AUTHOR: Slalom Consulting
    * TODO: testAccountDNBAddress - need to be rewriten to encompass new Abstract Queueable
*/

@IsTest
private class AddressTriggerHandlerTest {
    /* Test data preparation */

    private static List<Account> CreateAccounts(Integer noOfAccounts){

        List<Account> accToInsertLst = new List<Account>();

        for(Integer i=0;i<noOfAccounts;i++){
            // To avoid the salesforce duplication detection it is necessary to create Accounts with unique names, hence the below logic
            String testAccName = 'TestAlphaAccount';
            String uniqueName = testAccName.substring(i)+(i+1*3)+testAccName.charAt(i)+testAccName.left(2)+(i*2);

            Account accRec = new Account(
                    Name = uniqueName,
                    BillingCountryCode = 'US',
                    BillingCountry = 'United States',
                    BillingStateCode = 'SD',
                    Industry = 'Others',
                    Country__c='United States',
                    Legal__c = 'Legal Name',
                    DNBoptimizer__DNB_D_U_N_S_Number__c = '1234567',
                    Default_Payment_Terms__c = '30 Days Net',
                    Primary_Subsidiary__c = 'UiPath SRL',
                    Channel_Tier__c = 'Reseller');

            accToInsertLst.add(accRec);
        }
        return accToInsertLst;
    }
    private static List<Address__c> CreateAddresses(Integer noOfAccounts, Integer noOfAddressEachAccount){

        List<Account> accLst = CreateAccounts(noOfAccounts);
        insert accLst;

        List<Address__c> addressToInsertLst = new List<Address__c>();

        for(Integer i=0;i<noOfAccounts;i++){
            for(Integer j=0;j<noOfAddressEachAccount;j++){
                Address__c addObj = new Address__c(
                        Street_Line_1__c='Test Street Line 1'+j,
                        Street_Line_2__c='Test Street Line 2'+j,
                        City__c='San Francisco',
                        State__c='California',
                        Country__c='United States',
                        Zip_Postal_Code__c='41677',
                        GSTIN_India_only__c = '29AAACC1206C2ZB',
                        Account__c=accLst.get(i).Id);

                addressToInsertLst.add(addObj);
            }
        }

        return addressToInsertLst;
    }

    private static User CreateUser(String profileName, Boolean assignIntegrationPermSet, Boolean insertUser){

        User u = new User();
        u.ProfileId = [SELECT Id FROM Profile WHERE Name = :profileName].Id;
        u.Username = 'test839734@uiath.com';
        u.LastName = 'Test';
        u.Email = 'test839734@uiath.com';
        u.Alias = 't839734';
        u.TimeZoneSidKey = 'America/Los_Angeles';
        u.LocaleSidKey = 'en_US';
        u.EmailEncodingKey = 'UTF-8';
        u.LanguageLocaleKey = 'en_US';

        if(insertUser) {
            insert u;
        }

        if(assignIntegrationPermSet){
            System.runAs(new User(Id = Userinfo.getUserId())) {
                PermissionSet permSet = [SELECT Id from PermissionSet where name = :Constants.BOOMI_INTEGRATION_PERMISSION_SET_NAME limit 1];
                PermissionSetAssignment psa = new PermissionSetAssignment();
                psa.AssigneeId = u.Id;
                psa.PermissionSetId = permSet.Id;
                insert psa;
            }
        }

        return u;
    }

    /* Method to test default values are set for Sync Status and Validation Status on new Address creation*/
    @IsTest
    static void testCreateAddress() {
        List<Address__c> addressInserttLst =  CreateAddresses(10,3);

        insert addressInserttLst;

        //Verify Results
        list<Address__c> addressLst = [select id, Sync_Status__c,Validation_Status__c from Address__c where id in :addressInserttLst];

        System.assertEquals(Constants.ADD_SYNC_STATUS_NOT_VALID,addressLst.get(0).Sync_Status__c,'By default the Sync Status is set to \'Not Valid\' on new Address');
        System.assertEquals(Constants.ADD_VALIDATION_STATUS_PENDING,addressLst.get(0).Validation_Status__c,'By default the Validation Status is set to \'Pending\' on new Address');
    }

    /* Method to test the Sync Status change when Address Validation Status is set to Validated and Address is NOT yet synced to NetSuite*/
    @IsTest
    static void testSetSyncStatusForValidatedAddress_notInNetSuite() {

        List<Address__c> addressLst = CreateAddresses(10,3);

        Test.startTest();

        insert addressLst;

        Address__c addObj1 =  addressLst.get(0);
        addObj1.Validation_Status__c=Constants.ADD_VALIDATION_STATUS_VALIDATED;

        Address__c addObj2 =  addressLst.get(2);
        addObj2.Validation_Status__c=Constants.ADD_VALIDATION_STATUS_VALIDATED;

        addressLst = new List<Address__c>();
        addressLst.add(addObj1);
        addressLst.add(addObj2);

        Update addressLst;

        Test.stopTest();

        //Verify Results
        list<Address__c> addListNew = [select id, Sync_Status__c,Validation_Status__c from Address__c where id in :addressLst];

        System.assertEquals(Constants.ADD_SYNC_STATUS_VALID,addListNew.get(0).Sync_Status__c,'if Validation Status is set to Validated, then Sync Status should be set to Valid');
        System.assertEquals(Constants.ADD_SYNC_STATUS_VALID,addListNew.get(1).Sync_Status__c,'if Validation Status is set to Validated, then Sync Status should be set to Valid');
    }

    /* Method to test the Sync Status change when Address Validation Status is set to Validated and Address is already synced to NetSuite*/
    @IsTest
    static void testSetSyncStatusForValidatedAddress_inNetSuite() {

        List<Address__c> addressLst = CreateAddresses(10,3);
        addressLst.get(0).NS_Address_Internal_ID__c='11112222';
        addressLst.get(1).NS_Address_Internal_ID__c='33334444';

        Test.startTest();

        insert addressLst;

        Address__c addObj1 =  addressLst.get(0);
        addObj1.Validation_Status__c=Constants.ADD_VALIDATION_STATUS_VALIDATED;

        Address__c addObj2 =  addressLst.get(1);
        addObj2.Validation_Status__c=Constants.ADD_VALIDATION_STATUS_VALIDATED;

        addressLst = new List<Address__c>();
        addressLst.add(addObj1);
        addressLst.add(addObj2);

        Update addressLst;

        Test.stopTest();

        //Verify Results
        list<Address__c> addListNew = [select id, Sync_Status__c,Validation_Status__c from Address__c where id in :addressLst];

        System.assertEquals(Constants.ADD_SYNC_STATUS_PENDING,addListNew.get(0).Sync_Status__c,'if Validation Status is set to Validated, then Sync Status should be set to Pending in this scenario');
        System.assertEquals(Constants.ADD_SYNC_STATUS_PENDING,addListNew.get(1).Sync_Status__c,'if Validation Status is set to Validated, then Sync Status should be set to Pending in this scenario');
    }

    /* Method to test that Sync Status should not change when Address Validation Status is set to Validated and Address Sync Status is set as "Do Not Sync"*/
    @IsTest
    static void testSetSyncStatusForValidatedAddress_DoNotSync() {

        List<Address__c> addressLst = CreateAddresses(10,1);
        addressLst.get(0).Sync_Status__c=Constants.ADD_SYNC_STATUS_DO_NOT_SYNC;
        addressLst.get(1).Sync_Status__c=Constants.ADD_SYNC_STATUS_DO_NOT_SYNC;

        Test.startTest();

        insert addressLst;

        Address__c addObj1 =  addressLst.get(0);
        addObj1.Validation_Status__c=Constants.ADD_VALIDATION_STATUS_VALIDATED;

        Address__c addObj2 =  addressLst.get(1);
        addObj2.Validation_Status__c=Constants.ADD_VALIDATION_STATUS_VALIDATED;

        Address__c addObj3 =  addressLst.get(2);
        addObj3.Validation_Status__c=Constants.ADD_VALIDATION_STATUS_VALIDATED;

        addressLst = new List<Address__c>();
        addressLst.add(addObj1);
        addressLst.add(addObj2);
        addressLst.add(addObj3);

        Update addressLst;

        Test.stopTest();

        //Verify Results
        list<Address__c> addListNew = [select id, Sync_Status__c,Validation_Status__c from Address__c where id in :addressLst];

        System.assertEquals(Constants.ADD_SYNC_STATUS_DO_NOT_SYNC,addListNew.get(0).Sync_Status__c,'if Sync Status is Do Not Sync and Validation Status is set to Validated, then Sync Status should NOT change');
        System.assertEquals(Constants.ADD_SYNC_STATUS_DO_NOT_SYNC,addListNew.get(1).Sync_Status__c,'if Sync Status is Do Not Sync and Validation Status is set to Validated, then Sync Status should NOT change');
        System.assertEquals(Constants.ADD_SYNC_STATUS_VALID,addListNew.get(2).Sync_Status__c,'By default Sync Status is set to Not Valid and when Validation Status is updated to Validated, then Sync Status should change to Valid');
    }

    /* Method to test Address update made by integration user*/
    @isTest
    public static void testAddressUpdateForIntegrationUser(){

        User u = CreateUser(Constants.INTEGRATION_USER_PROFILE,true, true);
        List<Address__c> addressLst = CreateAddresses(10,3);

        //Set the Address Sync Status to "Synced"
        for(Address__c addObj: addressLst){
            addObj.Sync_Status__c=Constants.ADD_SYNC_STATUS_SYNCED;
        }
        insert addressLst;

        Test.startTest();

        System.runAs(u) {
            for(Integer i=0;i<addressLst.size();i++){
                addressLst.get(i).Street_Line_1__c= 'TestStreet Line'+(i*20);
            }

            update addressLst;
        }
        Test.stopTest();

        List<Address__c> addResultLst = [SELECT Id, Sync_Status__c FROM Address__c WHERE Id in :addressLst];
        System.assertEquals(Constants.ADD_SYNC_STATUS_SYNCED, addResultLst.get(0).Sync_Status__c, 'Status should not have changed as updates made by integration user should not change the Sync Status');
    }

    /* Method to test Address update made by data stewards with Boomi integration User Permission Set assigned to them*/
    @isTest
    public static void testAddressUpdateForDataSteward_WithPerSet(){

        User u = CreateUser(Constants.DATA_STEWARD_PROFILE,true, true);
        List<Address__c> addressLst = CreateAddresses(10,3);

        //Set the Address Sync Status to "Synced"
        for(Address__c addObj: addressLst){
            addObj.Sync_Status__c=Constants.ADD_SYNC_STATUS_SYNCED;
        }
        insert addressLst;

        Test.startTest();

        System.runAs(u) {
            for(Integer i=0;i<addressLst.size();i++){
                addressLst.get(i).Street_Line_1__c= 'TestStreet Line'+(i*20);
            }

            update addressLst;
        }
        Test.stopTest();

        List<Address__c> addResultLst = [SELECT Id, Sync_Status__c FROM Address__c WHERE Id in :addressLst];
        System.assertEquals(Constants.ADD_SYNC_STATUS_SYNCED, addResultLst.get(0).Sync_Status__c, 'Status should not have changed as user with Boomi Integration Permission Set should not be changing the sync status');
    }

    /* Method to test Address update made by data stewards without Boomi integration User Permission Set assigned to them*/
    @isTest
    public static void testAddresstUpdateForDataSteward_WithoutPerSet(){

        User u = CreateUser(Constants.DATA_STEWARD_PROFILE,false, true);
        List<Address__c> addressLst = CreateAddresses(10,3);

        //For 0-14 Addresses, set the Address Validation Status to "Pending" and "Sync Status" to "Synced"
        for(Integer i=0;i<=14; i++){
            addressLst.get(i).Validation_Status__c=Constants.ADD_VALIDATION_STATUS_PENDING;
            addressLst.get(i).Sync_Status__c=Constants.ADD_SYNC_STATUS_SYNCED;
        }

        //For 15-29 Addresses, set the Address Validation Status to "Validated" and "Sync Status" to "Synced"
        for(Integer i=15;i<=29; i++){
            addressLst.get(i).Validation_Status__c=Constants.ADD_VALIDATION_STATUS_VALIDATED;
            addressLst.get(i).Sync_Status__c=Constants.ADD_SYNC_STATUS_SYNCED;
        }

        insert addressLst;

        Test.startTest();

        System.runAs(u) {
            for(Integer i=0;i<addressLst.size();i++){
                addressLst.get(i).Street_Line_1__c= 'TestStreet Line'+(i*20);
                addressLst.get(i).Street_Line_2__c= 'TestStreet Line'+(i*65);
            }

            update addressLst;
        }
        Test.stopTest();

        List<Address__c> addResultLst = [SELECT Id, Sync_Status__c FROM Address__c WHERE Id in :addressLst];
        System.assertEquals(Constants.ADD_SYNC_STATUS_SYNCED, addResultLst.get(0).Sync_Status__c, 'Sync Status should NOT be changed to \'Pending\' as Address is NOT Validated and so Sync Automation should not execute for such Addresses');
        System.assertEquals(Constants.ADD_SYNC_STATUS_SYNCED, addResultLst.get(14).Sync_Status__c, 'Sync Status should NOT be changed to \'Pending\' as Address is NOT Validated and so Sync Automation should not execute for such Addresses');
        System.assertEquals(Constants.ADD_SYNC_STATUS_PENDING, addResultLst.get(15).Sync_Status__c, 'Sync Status should change to \'Pending\' as Address is validated and Data Steward has updated the Address field from boomi field set');
        System.assertEquals(Constants.ADD_SYNC_STATUS_PENDING, addResultLst.get(29).Sync_Status__c, 'Sync Status should change to \'Pending\' as Address is validated and Data Steward has updated the Address field from boomi field set');
    }

    /* Method to test that a DML Exception is thrown when an address with Primary Billing = true is inserted to an account that already has Primary Billing Address.
    @isTest
    public static void testInsertingANewAddressWithPrimaryBillingFails() {

        User u = CreateUser(Constants.STANDARD_USER_PROFILE,false, true);

        List<Address__c> addressLst = CreateAddresses(1,1);
        addressLst.get(0).Validation_Status__c = Constants.ADD_VALIDATION_STATUS_VALIDATED;
        addressLst.get(0).Primary_Billing__c = true;
        addressLst.get(0).Primary_Shipping__c = true;

        insert addressLst;

        Address__c addObj = new Address__c(
                Street_Line_1__c='Test Street Line 13',
                Street_Line_2__c='Test Street Line 22',
                City__c='San Francisco',
                State__c='California',
                Country__c='United States',
                Zip_Postal_Code__c='41677',
                Account__c=addressLst.get(0).Account__c,
                Primary_Billing__c = true);


        System.runAs(U){

            Test.startTest();

            try {
                insert addObj;
            }
            catch(DmlException e) {
                Boolean expectedExceptionThrown =  (e.getMessage().contains('Primary Billing address is already set for this account')) ? true : false;
                System.AssertEquals(expectedExceptionThrown, true);
            }


            Test.stopTest();
        }

    } */

    /* Method to test that an address can DML Exception is thrown when an address with Primary Shipping = true is inserted to an account that already has Primary Shipping Address.
    @isTest
    public static void testInsertingANewAddressWithPrimaryShippingFails() {

        User u = CreateUser(Constants.STANDARD_USER_PROFILE,false, true);

        List<Address__c> addressLst = CreateAddresses(1,1);
        addressLst.get(0).Validation_Status__c = Constants.ADD_VALIDATION_STATUS_VALIDATED;
        addressLst.get(0).Primary_Billing__c = true;
        addressLst.get(0).Primary_Shipping__c = true;

        insert addressLst;

        Address__c addObj = new Address__c(
                Street_Line_1__c='Test Street Line 13',
                Street_Line_2__c='Test Street Line 22',
                City__c='San Francisco',
                State__c='California',
                Country__c='United States',
                Zip_Postal_Code__c='41677',
                Account__c=addressLst.get(0).Account__c,
                Primary_Shipping__c = true);


        System.runAs(U){

            Test.startTest();

            try {
                insert addObj;
            }
            catch(DmlException e) {
                Boolean expectedExceptionThrown =  (e.getMessage().contains('Primary Shipping address is already set for this account')) ? true : false;
                System.AssertEquals(expectedExceptionThrown, true);
            }


            Test.stopTest();
        }

    } */

    /* Method to test that an address with Primary Billing = true is inserted to an account that already has Primary Billing Address. This is only valid for a data steward  */
    @isTest
    public static void testInsertingANewAddressWithPrimaryBillingForDataSteward() {

        User u = CreateUser(Constants.DATA_STEWARD_PROFILE,false, true);

        List<Address__c> addressLst = CreateAddresses(1,1);
        addressLst.get(0).Validation_Status__c = Constants.ADD_VALIDATION_STATUS_VALIDATED;
        addressLst.get(0).Primary_Billing__c = true;
        addressLst.get(0).Primary_Shipping__c = true;

        insert addressLst;

        Address__c addObj = new Address__c(
                Street_Line_1__c='Test Street Line 13',
                Street_Line_2__c='Test Street Line 22',
                City__c='San Francisco',
                State__c='California',
                Country__c='United States',
                Zip_Postal_Code__c='41677',
                Account__c=addressLst.get(0).Account__c,
                Primary_Billing__c = true);


        System.runAs(U){

            Test.startTest();

                insert addObj;


            Test.stopTest();
        }

        Address__c oldAddress = [SELECT Id, Primary_Billing__c FROM Address__c where id =:addressLst.get(0).id];
        Address__c newAddress = [SELECT Id, Primary_Billing__c FROM Address__c where id =:addObj.id];

        System.assertEquals(false, oldAddress.Primary_Billing__c);
        System.assertEquals(true, newAddress.Primary_Billing__c);
    }

    /* Method to test that updating an address will throw a DML Exception when an address with Primary Shipping = true is inserted to an account that already has Primary Shipping or Billing Address.  */
    @isTest
    public static void testUpdatingAnAddressWithPrimaryShippingAndBillingFails() {

        User standardUser = CreateUser(Constants.STANDARD_USER_PROFILE,false, true);
        List<Address__c> addressLst;

        System.runAs(standardUser) {
            addressLst = CreateAddresses( 1, 2 );
            addressLst.get( 0 ).Primary_Billing__c = true;
            addressLst.get( 0 ).Primary_Shipping__c = true;

            insert addressLst;
        }

        Address__c addObj = addressLst.get(0);
        addObj.Validation_Status__c = Constants.ADD_VALIDATION_STATUS_VALIDATED;

        update addObj;


        System.runAs(standardUser){

            addObj = addressLst.get(1);
            addObj.Primary_Billing__c = true;
            addObj.Primary_Shipping__c = true;

            Test.startTest();

            try {
                update addObj;
            }
            catch(DmlException e) {

                Boolean expectedExceptionThrown =  (e.getMessage().contains(Label.Address_Primary_Billing_Already_Set)) ? true : false;
                System.AssertEquals(expectedExceptionThrown, true);

            }

            Test.stopTest();
        }

    }

    /* Method to test that when changing a primary billing and shipping address will throw a DML Exception when the associated account has no primary billing or shipping address.  */
    @isTest
    public static void testAccountMustHavePrimaryShippingAndBilling() {

        User standardUser = CreateUser(Constants.STANDARD_USER_PROFILE,false, true);
        List<Address__c> addressLst;

        System.runAs(standardUser) {
            addressLst = CreateAddresses( 1, 2 );
            addressLst.get( 0 ).Primary_Billing__c = true;
            addressLst.get( 0 ).Primary_Shipping__c = true;

            insert addressLst;
        }

        Address__c addObj = addressLst.get(0);
        addObj.Validation_Status__c = Constants.ADD_VALIDATION_STATUS_VALIDATED;

        update addObj;


        System.runAs(standardUser){

            addObj = addressLst.get(1);
            addObj.Primary_Billing__c = false;
            addObj.Primary_Shipping__c = false;

            Test.startTest();

            try {
                update addObj;
            }
            catch(DmlException e) {

                Boolean expectedExceptionThrown =  (e.getMessage().contains(Label.Address_Account_Has_No_Primary_Billing)) ? true : false;
                System.AssertEquals(expectedExceptionThrown, true);

            }

            Test.stopTest();
        }

    }

    /* Method to test that an address with Primary Shipping = true is inserted to an account that already has Primary Shipping Address. This is only valid for a data steward  */
    @isTest
    public static void testInsertingANewAddressWithPrimaryShippingForDataSteward() {

        User u = CreateUser(Constants.DATA_STEWARD_PROFILE,false, true);

        List<Address__c> addressLst = CreateAddresses(1,1);
        addressLst.get(0).Validation_Status__c = Constants.ADD_VALIDATION_STATUS_VALIDATED;
        addressLst.get(0).Primary_Billing__c = true;
        addressLst.get(0).Primary_Shipping__c = true;

        insert addressLst;

        Address__c addObj = new Address__c(
                Street_Line_1__c='Test Street Line 13',
                Street_Line_2__c='Test Street Line 22',
                City__c='San Francisco',
                State__c='California',
                Country__c='United States',
                Zip_Postal_Code__c='41677',
                Account__c=addressLst.get(0).Account__c,
                Primary_Shipping__c = true);


        System.runAs(U){

            Test.startTest();

                insert addObj;

            Test.stopTest();
        }

        Address__c oldAddress = [SELECT Id, Primary_Shipping__c FROM Address__c where id =:addressLst.get(0).id];
        Address__c newAddress = [SELECT Id, Primary_Shipping__c FROM Address__c where id =:addObj.id];

        System.assertEquals(false, oldAddress.Primary_Shipping__c);
        System.assertEquals(true, newAddress.Primary_Shipping__c);
    }

    /* Method to test Address update made by data stewards updating the Address with Sync Status= Not Valid. It should NOT change the Sync Status and trigger the integration*/
    @isTest
    public static void testAddressUpdateForExcludedSyncStatus_NotValid(){

        User u = CreateUser(Constants.DATA_STEWARD_PROFILE,false, true);
        List<Address__c> addressLst = CreateAddresses(10,3);

        insert addressLst;

        Test.startTest();

        System.runAs(u) {
            for(Integer i=0;i<addressLst.size();i++){
                addressLst.get(i).Street_Line_1__c= 'TestStreet Line'+(i*20);
                addressLst.get(i).Street_Line_2__c= 'TestStreet Line'+(i*65);
            }

            update addressLst;
        }
        Test.stopTest();

        List<Address__c> addResultLst = [SELECT Id, Sync_Status__c FROM Address__c WHERE Id in :addressLst];
        System.assertEquals(Constants.ADD_SYNC_STATUS_NOT_VALID, addResultLst.get(0).Sync_Status__c, 'If Sync_Status is set to \'Not Valid\' and any user updates any field from boomi_field_set on Address, status should NOT change');
    }

    /* Method to test Address update made by data stewards updating the Accounts with Sync Status= Do Not Sync. It should NOT change the Sync Status and trigger the integration
   * Also the Address that should be deprecated from syncing to NetSuite will be set as Do Not Sync t*/
    @isTest
    public static void testAddressUpdateForExcludedSyncStatus_DoNotSync(){

        User u = CreateUser(Constants.DATA_STEWARD_PROFILE,false, true);
        List<Address__c> addressLst = CreateAddresses(10,3);

        //Set the Address Sync Status to "Do Not Sync"
        for(Address__c addObj: addressLst){
            addObj.Sync_Status__c=Constants.ADD_SYNC_STATUS_DO_NOT_SYNC;
        }
        insert addressLst;

        Test.startTest();

        System.runAs(u) {
            for(Integer i=0;i<addressLst.size();i++){
                addressLst.get(i).Street_Line_1__c= 'TestStreet Line'+(i*20);
                addressLst.get(i).Street_Line_2__c= 'TestStreet Line'+(i*65);
            }

            update addressLst;
        }
        Test.stopTest();

        List<Address__c> addResultLst = [SELECT Id, Sync_Status__c FROM Address__c WHERE Id in :addressLst];
        System.assertEquals(Constants.ADD_SYNC_STATUS_DO_NOT_SYNC, addResultLst.get(0).Sync_Status__c, 'If Sync_Status is set to \'Do Not Sync\' and any user updates any field from Address boomi_field_set, status should NOT change');
    }

    /* Method to test that old primary flags are unchecked once primary flags are checked on new address and that the account is updated with the new addresss*/
    /*@isTest
    public static void testAccountDNBAddress(){

        User u = CreateUser(Constants.SYS_ADMIN_PROFILE, true, true);

        //Set street > 150 characters to test 2nd street line
        Account ukAccount = new Account(
                Name = 'TestAccountUK',
                Country__c = 'United Kingdom',
                Industry = 'Others');

        insert ukAccount;

        ukAccount.DnB_Country__c = 'United Kingdom';
        ukAccount.DnB_Street__c = '01234556789012345567890123455678901234556789012345567890123455678901234556789012345567890123455678901234556789012345567890123455678901234556789012345567890123455678901234556789';
        ukAccount.DnB_City__c = 'London';
        ukAccount.DnB_Zip_Postal_Code__c = 'W44 444';

        Test.startTest();

        System.runAs(u) {
            update ukAccount;
        }
        Test.stopTest();

        ukAccount = [   SELECT Id, Name, Country__c, BillingCountry, BillingPostalCode, Industry
                        FROM Account
                        WHERE Id = :ukAccount.Id];
        System.assertEquals('W44 444',ukAccount.BillingPostalCode);

        List<Address__c> addressList = [SELECT Id, Account__c, Primary_Billing__c, Primary_Shipping__c, Country__c, Street_Line_1__c, Street_Line_2__c, City__c,  Zip_Postal_Code__c
                                        FROM Address__c
                                        WHERE Account__c =: ukAccount.Id];
        system.debug('Addresses are: '+ addressList);
        System.assertEquals(2,addressList.size());

        addressList = [SELECT Id, Account__c, Primary_Billing__c, Primary_Shipping__c, Country__c, Street_Line_1__c, Street_Line_2__c, City__c,  Zip_Postal_Code__c
                                        FROM Address__c
                                        WHERE Account__c =: ukAccount.Id AND
                                        Zip_Postal_Code__c = 'W44 444'];
        System.assertEquals(1,addressList.size());
        System.assert(addressList[0].Primary_Billing__c);
        System.assert(addressList[0].Primary_Shipping__c);

        //check that address that was created on account creation no longer is marked as primary
        addressList = [SELECT Id, Account__c, Primary_Billing__c, Primary_Shipping__c, Country__c, Street_Line_1__c, Street_Line_2__c, City__c,  Zip_Postal_Code__c
                                        FROM Address__c
                                        WHERE Account__c =: ukAccount.Id AND
                                        Zip_Postal_Code__c = ''];
        System.assert(!addressList[0].Primary_Billing__c);
        System.assert(!addressList[0].Primary_Shipping__c);
    }*/
}