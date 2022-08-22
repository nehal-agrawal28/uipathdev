/**
    * @DESCRIPTION: Address Trigger Handle will hold all the trigger logic on the AddressTrigger
    * @AUTHOR: Slalom Consulting
*/

public with sharing class AddressTriggerHandler extends TriggerHandler{

    public class FieldIntegrityException extends Exception {}
    public Static Boolean syncAddressFromObject = false;


    /* Trigger Methods */
    public override void beforeInsert(){
       // this.checkToSeeIfPrimaryAddressesAreSet(null, trigger.new);
    }

    public override void afterInsert() {

        this.updateAccountAddress(null,trigger.new);
        this.uncheckOtherPrimaryAddresses(null,trigger.new);
    }

    public override void beforeUpdate( ) {

       // this.checkToSeeIfPrimaryAddressesAreSet(trigger.oldMap,trigger.new);

        //Check Address Validation Status and set the Sync Status accordingly
        this.setSyncStatusForValidateAddress(trigger.oldMap,trigger.new);

        //SyncStatusAutomationProcess method should always be called last in the Address "beforeUpdate" trigger
        this.callSyncStatusAutomationProcess();
    }

    public override void afterUpdate() {

        this.updateAccountAddress(trigger.oldMap,trigger.new);
        this.uncheckOtherPrimaryAddresses(trigger.oldMap,trigger.new);
        this.ErrorWhenNoPrimaryShippingOrBillingOnAccount(trigger.oldMap,trigger.new);

    }
    /* Private Methods */

    /**
    * @DESCRIPTION: This method checks that the when a new address is inserted or updated with Primary Shipping or billing set to
    * true, it is rejected when the associated account already has an address with Primary Shipping or billing set to
    * true and the address has been validated. If a Data Steward is making the insert then the check will be skipped.
    * @RETURN: Nothing
    * @PARAM: oldAddressMap
    * @PARAM: newAddressList
    * @AUTHOR: Slalom Consulting
    * Commented by Roxana A. on 12/14/2020, as per SLTECH-9377
    */
   /* private void checkToSeeIfPrimaryAddressesAreSet(Map<Id,SObject> oldAddressMap, List<SObject> newAddressList) {

        Boolean dataSteward = isDataStewardUser( UserInfo.getProfileId() );

        if (!dataSteward) {
            Set<Id> accountsToRetrieve = new Set<Id>();

            Map<ID, Address__c> accountsForWhichShippingIsChanging = new Map<ID, Address__c>();
            Map<ID, Address__c> accountsForWhichBillingIsChanging = new Map<ID, Address__c>();
            Set<ID> idsNotToRetrieve = new Set<ID>();

            for (Address__c address : (List<Address__c>) newAddressList) {
                Boolean addAccount = false;
                Address__c oldAdd;

                if(oldAddressMap != null ){
                    oldAdd = (Address__c) oldAddressMap.get(address.Id);
                }


                if( trigger.isInsert ||
                        ( trigger.isUpdate &&
                          ( oldAdd.Primary_Billing__c != address.Primary_Billing__c ||
                            oldAdd.Primary_Shipping__c != address.Primary_Shipping__c ) ) ){

                    if (address.Primary_Billing__c) {
                        accountsForWhichBillingIsChanging.put( address.Account__c, address );
                        addAccount = true;
                    }
                    if (address.Primary_Shipping__c) {
                        accountsForWhichShippingIsChanging.put( address.Account__c, address );
                        addAccount = true;
                    }

                    if (addAccount) {
                        accountsToRetrieve.add( address.Account__c );

                        if(trigger.isUpdate){
                            idsNotToRetrieve.Add(address.id);
                        }
                    }
                }
            }

            for (Account acc : [
                    SELECT Id, (
                            SELECT Id, Primary_Shipping__c, Primary_Billing__c, Validation_Status__c
                            FROM Addresses__r
                            WHERE (Primary_Shipping__c = TRUE OR Primary_Billing__c = TRUE)
                                    AND Validation_Status__c = :Constants.ADD_VALIDATION_STATUS_VALIDATED
                                    AND ID not in :idsNotToRetrieve
                    )
                    FROM Account
                    WHERE Id in :accountsToRetrieve
            ]) {

                for (Address__c address : acc.Addresses__r) {

                    if (address.Primary_Billing__c && accountsForWhichBillingIsChanging.containsKey( acc.id )) {
                        Address__c addToError = accountsForWhichBillingIsChanging.get( acc.id );
                        addToError.Primary_Billing__c.addError( Label.Address_Primary_Billing_Already_Set );
                    }

                    if (address.Primary_Shipping__c && accountsForWhichShippingIsChanging.containsKey( acc.id )) {
                        Address__c addToError = accountsForWhichShippingIsChanging.get( acc.id );
                        addToError.Primary_Shipping__c.addError( Label.Address_Primary_Shipping_Already_Set );
                    }
                }
            }
        }
    } */


    /**
    * @DESCRIPTION: This method checks the Account Validation Status. If the Validation status is changed to "Validated" and Sync Status not equal to "Do Not Sync",
    *               only then sets the Sync Status on that account to "Valid" if the account is not yet synced to NetSuite. If the Account is already synced to NetSuite then
    *               it sets the Account Sync Status to "Pending". There is a workflow rule which triggers the outbound message to Boomi if Sync Status is Valid or Pending
    * @RETURN: Nothing
    * @PARAM: Old Map, New List
    * @AUTHOR: Slalom Consulting
    */
    private void setSyncStatusForValidateAddress(Map<Id,SObject> oldAddressMap, List<SObject> newAddressLst){
        for(Address__c newAdd: (List<Address__c>) newAddressLst){

            Address__c oldAdd = (Address__c) oldAddressMap.get(newAdd.Id);
            if((oldAdd.Sync_Status__c != Constants.ADD_SYNC_STATUS_DO_NOT_SYNC) && (oldAdd.Validation_Status__c != newAdd.Validation_Status__c) && (newAdd.Validation_Status__c == Constants.ADD_VALIDATION_STATUS_VALIDATED)){
                if(null!=newAdd.NS_Address_Internal_ID__c){
                    newAdd.Sync_Status__c = Constants.ADD_SYNC_STATUS_PENDING;
                }else{
                    newAdd.Sync_Status__c = Constants.ADD_SYNC_STATUS_VALID;
                }
            }
        }
    }

    /**
    * @DESCRIPTION: Call the Sync Status Automation process only for the Addresses where Validation Status = "Validated",
    *               i.e they are Validated by Data Stewards and synced to NetSuite
    * @AUTHOR: Slalom Consulting
    */
    private void callSyncStatusAutomationProcess() {
        Map<Id, SObject> oldAddressMap = new Map<Id, SObject>();
        List<SObject> newAddressLst = new List<SObject>();

        for (Address__c oldAddObj : (List<Address__c>) trigger.old) {
            if (oldAddObj.Validation_Status__c == Constants.ADD_VALIDATION_STATUS_VALIDATED) {
                oldAddressMap.put(oldAddObj.Id, oldAddObj);
                newAddressLst.add(trigger.newMap.get(oldAddObj.Id));
            }
        }
        // Call the SyncStatusAutomation Process to check if the Address Updates can be flagged ready to sync to NetSuite
        if (!newAddressLst.isEmpty()) {
            IntegrationHandler.syncStatusAutomationProcess(oldAddressMap, newAddressLst);
        }
    }
    
    /**
    * @DESCRIPTION: This method updates the corresponding account address (biling or shipping) if an address is updated
    *               and the address is marked as primary billing or primary shipping.
    * @RETURN: Nothing
    * @PARAM: New List
    * @AUTHOR: Slalom Consulting
    */
    private void updateAccountAddress(Map<Id,SObject> oldAddressMap, List<SObject> addressList){

        Set<Id> accountsToUpdateSet = new Set<Id>();
        Map<Id,Address__c> accountBillingAddressMap = new Map<Id,Address__c>();
        Map<Id,Address__c> accountShippingAddressMap = new Map<Id,Address__c>();
        
        Map<String, String> CountryNameAndCodes = new Map<String, String>();
        Schema.DescribeFieldResult countryCodeResult = User.Countrycode.getDescribe();
        List<Schema.PicklistEntry> countryPLE = countryCodeResult.getPicklistValues();
        for (Schema.PicklistEntry entry : countryPLE) {
          CountryNameAndCodes.put(entry.getLabel(), entry.getValue());
        }
        
        Map<String, String> StateNameAndCodes = new Map<String, String>();
        Schema.DescribeFieldResult stateCodeResult = User.statecode.getDescribe();
        List<Schema.PicklistEntry> statePLE = stateCodeResult.getPicklistValues();
        for (Schema.PicklistEntry entry : statePLE) {
          StateNameAndCodes.put(entry.getLabel(), entry.getValue());
        }

        for(Address__c address: (List<Address__c>) addressList) {

            Address__c oldAddress = null;
            if(oldAddressMap != null){
                oldAddress = (Address__c) oldAddressMap.get(address.Id);
            }

            //Ignore addresses that are inserted after account creation. Account address is already set in account trigger
            if(address.Created_From_Account__c && oldAddress == null){
                continue;
            }


            if( oldAddress == null ||
                (address.Primary_Billing__c && !oldAddress.Primary_Billing__c) ||
                (address.Primary_Shipping__c && !oldAddress.Primary_Shipping__c) ||
                (address.Street_Line_1__c != oldAddress.Street_Line_1__c) ||
                (address.Street_Line_2__c != oldAddress.Street_Line_2__c) ||
                (address.City__c != oldAddress.City__c) ||
                (address.Zip_Postal_Code__c != oldAddress.Zip_Postal_Code__c) ||
                (address.State__c != oldAddress.State__c) ||
                (address.Country__c != oldAddress.Country__c) ||
                (address.GSTIN_India_only__c != oldAddress.GSTIN_India_only__c)){
                //track which primary addresses have been updated
                if (address.Primary_Billing__c) {
                    accountsToUpdateSet.add(address.Account__c);
                    accountBillingAddressMap.put(address.Account__c, address);
                }
                if (address.Primary_Shipping__c) {
                    accountsToUpdateSet.add(address.Account__c);
                    accountShippingAddressMap.put(address.Account__c, address);
                }
            }

            // SLTCHIN-1573: Sync Account Static Address fields when new Address record is created or existing Address Postal Code or State is updated first time
            if(oldAddress == null ||
               (oldAddress != null &&
                ((oldAddress.State__c == null && address.State__c != null) ||
                 (oldAddress.Zip_Postal_Code__c == null && address.Zip_Postal_Code__c != null)
                )
               )
              )
            {
                syncAddressFromObject = true;
            }
        }


        List<Account> accountsToUpdateList = new List<Account>();
        if(!accountsToUpdateSet.IsEmpty()){
            accountsToUpdateList = [SELECT Id FROM Account WHERE Id in :accountsToUpdateSet AND Area__c != 'Japan'];
        }


        for(Account account : accountsToUpdateList){

            if(accountBillingAddressMap.containsKey(account.Id)){
                Address__c billingAddress = accountBillingAddressMap.get(account.Id);

                account.BillingStreet = billingAddress.Street_Line_1__c;
                if( String.isNotEmpty( billingAddress.Street_Line_2__c )){

                    //add carriage return if first line wasn't empty;
                    if( String.isNotEmpty( billingAddress.Street_Line_1__c )){
                        account.BillingStreet += '\r\n';
                    }

                    account.BillingStreet += billingAddress.Street_Line_2__c;

                    //Make sure adding carriage return didn't push string over the size limit
                    if(account.BillingStreet.length() > 255) {
                        account.BillingStreet = account.BillingStreet.left(255);
                    }
                }
                account.BillingCity = billingAddress.City__c;
                account.BillingPostalCode = billingAddress.Zip_Postal_Code__c;
                account.BillingStateCode = StateNameAndCodes.get(billingAddress.State__c);
                account.State__c = billingAddress.State__c;
                account.BillingCountryCode = CountryNameAndCodes.get(billingAddress.Country__c);
                account.GSTIN_India_only__c = billingAddress.GSTIN_India_only__c;
            }

            if(accountShippingAddressMap.containsKey(account.Id)){
                Address__c shippingAddress = accountShippingAddressMap.get(account.Id);

                account.ShippingStreet = shippingAddress.Street_Line_1__c;
                if( String.isNotEmpty( shippingAddress.Street_Line_2__c )){

                    //add carriage return if first line wasn't empty;
                    if( String.isNotEmpty( shippingAddress.Street_Line_1__c )){
                        account.ShippingStreet += '\r\n';
                    }

                    account.ShippingStreet += shippingAddress.Street_Line_2__c;

                    //Make sure adding carriage return didn't push string over the size limit
                    if(account.ShippingStreet.length() > 255){
                        account.ShippingStreet = account.ShippingStreet.left(255);
                    }
                }
                account.ShippingCity = shippingAddress.City__c;
                account.ShippingPostalCode = shippingAddress.Zip_Postal_Code__c;
                account.ShippingState = shippingAddress.State__c;
                account.ShippingCountry = shippingAddress.Country__c;
            }
        }


        //Don't block account update when duplicate rule fires
        Database.DMLOptions dml = new Database.DMLOptions();
        dml.DuplicateRuleHeader.AllowSave = true;
        List<Database.SaveResult> srList = Database.update(accountsToUpdateList, dml);
        
        system.debug('Updated Accounts: '+accountsToUpdateList);
        system.debug('srList: '+srList);

        //If other issues come up while saving, throw an exception
        for(Database.SaveResult sr : srList){
            if (!sr.isSuccess()) {
                System.debug('Account save failed');
                for(Database.Error err : sr.getErrors()){
                    System.debug('The following error has occurred.');
                    System.debug(err.getStatusCode() + ': ' + err.getMessage());
                    System.debug('Contact fields that affected this error: ' + err.getFields());
                    throw new FieldIntegrityException('Issue while updating account after address change: ' + err.getMessage());
                }
            }
        }
    }

    /**
    * @DESCRIPTION: When an address is marked as primary, uncheck the primary flag on other account's addresses
    * @RETURN: Nothing
    * @PARAM: New List
    * @AUTHOR: Slalom Consulting
    */
    private void uncheckOtherPrimaryAddresses(Map<Id,SObject> oldAddressMap, List<SObject> newAddressList) {

        Set<Id> newPrimaryBillingAddrSet = new Set<Id>();
        Set<Id> newPrimaryShippingAddrSet = new Set<Id>();
        Set<Id> accountBillingSet = new Set<Id>();
        Set<Id> accountShippingSet = new Set<Id>();

        for(Address__c newAddress: (List<Address__c>) newAddressList) {
            Address__c oldAddress = null;
            if(oldAddressMap != null){
                oldAddress = (Address__c) oldAddressMap.get(newAddress.Id);
            }
            if(newAddress.Primary_Billing__c &&
               ((oldAddress == null && !newAddress.Created_From_Account__c) ||
                (oldAddress != null && !oldAddress.Primary_Billing__c))){
                newPrimaryBillingAddrSet.add(newAddress.Id);
                accountBillingSet.add(newAddress.Account__c);
            }
            if(newAddress.Primary_Shipping__c &&
               ((oldAddress == null && !newAddress.Created_From_Account__c) ||
                (oldAddress != null && !oldAddress.Primary_Shipping__c))){
                newPrimaryShippingAddrSet.add(newAddress.Id);
                accountShippingSet.add(newAddress.Account__c);
            }
        }


        List<Address__c> primaryAddrList = new List<Address__c>();
        if( !accountBillingSet.IsEmpty() || !accountShippingSet.IsEmpty()){
            primaryAddrList = [ SELECT Id, Account__c, Primary_Billing__c, Primary_Shipping__c
                                FROM Address__c
                                WHERE (Account__c in :accountBillingSet
                                OR Account__c in :accountShippingSet)
                                AND (Primary_Billing__c = true
                                OR Primary_Shipping__c = true)];
        }


        List<Address__c> addressUpdateList = new List<Address__c>();

        for(Address__c primaryAddress: primaryAddrList) {
            Boolean addressChanged = false;
            if(primaryAddress.Primary_Billing__c &&
               accountBillingSet.contains(primaryAddress.Account__c) &&
               !newPrimaryBillingAddrSet.contains(primaryAddress.Id)){
                primaryAddress.Primary_Billing__c = false;
                addressChanged = true;
            }
            if(primaryAddress.Primary_Shipping__c &&
               accountShippingSet.contains(primaryAddress.Account__c) &&
               !newPrimaryShippingAddrSet.contains(primaryAddress.Id)){
                primaryAddress.Primary_Shipping__c = false;
                addressChanged = true;
            }
            if(addressChanged){
                addressUpdateList.add(primaryAddress);
            }
        }

        update addressUpdateList;
    }


    private void ErrorWhenNoPrimaryShippingOrBillingOnAccount(Map<Id,SObject> oldAddressMap, List<SObject> newAddressList){
        Set<Id> accountsToRetrieve = new Set<Id>();

        Map<ID, Address__c> accountsForWhichShippingIsChanging = new Map<ID, Address__c>();
        Map<ID, Address__c> accountsForWhichBillingIsChanging = new Map<ID, Address__c>();

        for (Address__c address : (List<Address__c>) newAddressList) {
            Boolean addAccount = false;
            Address__c oldAdd = (Address__c) oldAddressMap.get(address.Id);


            if( ( !address.Primary_Billing__c && oldAdd.Primary_Billing__c) ||
                    ( !address.Primary_Shipping__c && oldAdd.Primary_Shipping__c )) {

                if (!address.Primary_Billing__c) {
                    accountsForWhichBillingIsChanging.put( address.Account__c, address );
                    accountsToRetrieve.add( address.Account__c );
                }
                if (!address.Primary_Shipping__c) {
                    accountsForWhichShippingIsChanging.put( address.Account__c, address );
                    accountsToRetrieve.add( address.Account__c );
                }
            }
        }

        for (Account acc : [
                SELECT Id, (
                        SELECT Id, Primary_Shipping__c, Primary_Billing__c
                        FROM Addresses__r
                        WHERE (Primary_Shipping__c = TRUE OR Primary_Billing__c = TRUE)
                )
                FROM Account
                WHERE Id in :accountsToRetrieve
        ]) {

            Boolean primaryShippingFound = false;
            Boolean primaryBillingFound = false;

            for (Address__c address : acc.Addresses__r) {
                if (accountsForWhichBillingIsChanging.containsKey( acc.id ) && address.Primary_Billing__c && !primaryBillingFound) {
                    primaryBillingFound = true;
                }

                if (accountsForWhichShippingIsChanging.containsKey( acc.id ) && address.Primary_Shipping__c && !primaryShippingFound) {

                    primaryShippingFound = true;
                }

                if(primaryBillingFound && primaryShippingFound){
                    break;
                }
            }

            if(!primaryBillingFound && accountsForWhichBillingIsChanging.containsKey( acc.id )){
                Address__c addressWithError = accountsForWhichBillingIsChanging.get( acc.id );
                addressWithError.Primary_Billing__c.addError( Label.Address_Account_Has_No_Primary_Billing );

            }

            if(!primaryShippingFound && accountsForWhichShippingIsChanging.containsKey( acc.id )){
                Address__c addressWithError = accountsForWhichShippingIsChanging.get( acc.id );
                addressWithError.Primary_Shipping__c.addError( Label.Address_Account_Has_No_Primary_Shipping );
            }
        }
    }

    /**
    * @Description: Returns true if the user either has an Super Admin profile or the System Administrator profile
    */
    private static Boolean isDataStewardUser(ID userProfileId){

        Boolean isDataStewardProfilePresent = false;
        Boolean isSystemAdminProfilePresent = false;
        Boolean isSuperAdminProfilePresent = false;
        Boolean isSalesOpsGeoLeadsProfilePresent = false;
        Boolean isFinanceUserProfilePresent = false;

        Profile currentUserProfile = [SELECT Id, Name FROM Profile WHERE Id=:userProfileId LIMIT 1];

        if(currentUserProfile!=null && currentUserProfile.Name == Constants.DATA_STEWARD_PROFILE){
            isDataStewardProfilePresent=true;
        }

        if(currentUserProfile!=null && currentUserProfile.Name == Constants.SYS_ADMIN_PROFILE){
            isSystemAdminProfilePresent=true;
        }
        if(currentUserProfile!=null && currentUserProfile.Name == Constants.SUPER_ADMIN_PROFILE){
            isSuperAdminProfilePresent=true;
        }
        if(currentUserProfile!=null && currentUserProfile.Name == Constants.GEO_LEADS_PROFILE){
            isSalesOpsGeoLeadsProfilePresent=true;
        }
        if(currentUserProfile!=null && currentUserProfile.Name == Constants.FINANCE_USER_PROFILE){
            isFinanceUserProfilePresent = true;
        }

        return (isDataStewardProfilePresent || isSystemAdminProfilePresent || isSalesOpsGeoLeadsProfilePresent || isSuperAdminProfilePresent || isFinanceUserProfilePresent)? true:false;
    }

}