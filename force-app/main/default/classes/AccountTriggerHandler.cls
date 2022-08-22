/**
    * @DESCRIPTION: Account Trigger Handle will hold all the trigger logic on the AccountTrigger
    * @AUTHOR: Slalom Consulting
*/

public with sharing class AccountTriggerHandler extends TriggerHandler {

    public class DnBMatchException extends Exception {}

    private static Set<Id> addressHasBeenAddedFor = new Set<Id>();

    private static List<USA_Industry__mdt> IndustriesCached;
    private static List<USA_States__mdt> StatesCached;
    private static List<ROW_Country__mdt> CountriesCached;

    private static List<String> AvailableCountryStatesCached;


    public static List<String> AvailableCountryStates {
        get {

            if(AvailableCountryStatesCached == null){
                AvailableCountryStatesCached = new List<String>();

                Schema.DescribeFieldResult stateResult = Address__c.State__c.getDescribe();
                List<Schema.PicklistEntry> statePLE = stateResult.getPicklistValues();

                for( Schema.PicklistEntry entry : statePLE){
                    AvailableCountryStatesCached.add(entry.getValue());
                }
            }
            return AvailableCountryStatesCached;
        }
    }


    public static List<USA_Industry__mdt> Industries {
        get {
            if (IndustriesCached == null) {
                IndustriesCached = [Select Region__c, Industry__c, Area__c, Territory__c from USA_Industry__mdt];
            }
            return IndustriesCached;
        }
    }

    public static list<USA_States__mdt> States {
        get {
            if (StatesCached == null) {
                StatesCached = [Select Label, DeveloperName, Region__c, Billing_State_Code__c, Area__c, Territory__c, Country__c from USA_States__mdt];
            }
            return StatesCached;
        }
    }
    public static list<ROW_Country__mdt> Countries {
        get {
            if (CountriesCached == null) {
                CountriesCached = [Select Country_Code__c, Region__c, Area__c, Territory__c from ROW_Country__mdt];
            }
            return CountriesCached;
        }
    }
    public static List<Country_Subsidiary_Mapping__mdt> subsidiaryMappingList = [   SELECT MasterLabel, Country_Code__c, Subsidiary__c
                                                                                    FROM Country_Subsidiary_Mapping__mdt];


    /* Trigger Methods */
    public override void beforeInsert() {
        this.madeStatusRequiredChinaAustralia(trigger.new);
        this.setAddressRelatedFields(null, trigger.new);
        this.setRegion(trigger.new);
        this.setSubsidiary(trigger.new);
    }

    public override void afterInsert() {


        this.GrantPermissionToParentOwner(Trigger.new, null);
        this.createAddress(trigger.new);
    }

    public override void beforeUpdate() {

        this.setAddressRelatedFields(trigger.oldMap, trigger.new);
        this.setRegion(trigger.new);
        //this.setCustomerStage(trigger.new, trigger.oldMap);
        //Check Account Validation Status and set the Sync Status accordingly
        this.setSyncStatusForValidatedAccount(trigger.oldMap, trigger.new);

        //SyncStatusAutomationProcess method should always be called last in the Account "beforeUpdate" trigger
        this.callSyncStatusAutomationProcess();
    }


    public override void afterUpdate() {
        this.GrantPermissionToParentOwner(Trigger.new, Trigger.oldMap);
        this.processDNBCompany(trigger.oldMap, trigger.new);
        this.setUpContactOwner(Trigger.new, Trigger.oldMap);
    }
    
        // ============================================================================
    // added by Mirela Chituc - 05/15/2020 ========================================
    // If Country is China or Australia State field is required - before insert
    // if State is not empty set BillingState with the value fron State__c field
    // ============================================================================
    public void MadeStatusRequiredChinaAustralia(List<Account> accList) {
        for (Account acc : accList) {
            if ((acc.Country__c == 'China' || acc.Country__c == 'Australia' || acc.Country__c == 'India') && acc.State__c == null) {
                acc.addError('State is required if Country is ' + acc.Country__c);
            } else {
                if(acc.State__c != null)
                    acc.BillingState = acc.State__c;
            }
        }
    }

    // ============================================================================
    // added by Mirela Chituc - 5/26/2020 ========================================
    // Set up Account Owner as Contact Owner to all Conatcts - after update
    // ============================================================================
    private void setUpContactOwner(List<Account> accountList, Map<Id, SObject> oldAccountMap) {
        
        Set<Id> accIds = new Set<Id>();
        for(Account acc: accountList) {
            Account oldAcc = (Account)oldAccountMap.get(acc.Id);
            if(acc.OwnerId != oldAcc.OwnerId && acc.PG_Legacy__c == false)
                accIds.add(acc.Id); 
        }
        
        if(accIds.size() > 0) {
            List<Account> allAccounts = [SELECT Id, OwnerId, GAM_Id__c, EDR__c, (SELECT Id, OwnerId FROM Contacts) FROM Account WHERE Id IN: accIds AND PG_Legacy__c = false AND Country__c != 'Japan'];
            
            List<Contact> cntToUpdate = new List<Contact>();
            for(Account acc: allAccounts) {
                for(contact cnt: acc.Contacts) {
                    String cntOwner = String.valueOf(cnt.OwnerId);
                    cntOwner  = cntOwner.substring(0,15);
                    if(cntOwner != acc.GAM_Id__c && cnt.OwnerId != acc.EDR__c && cnt.OwnerId != acc.OwnerId) {
                        cnt.OwnerId = acc.OwnerId;
                        cntToUpdate.add(cnt);
                    }
                }
            }
            if(cntToUpdate.size() > 0)
                update cntToUpdate;
        }
    }
    
    
    // ============================================================================
    // added by Mirela Chituc - 10/21/2019 ========================================
    // Set up Customer Status - updated 10/28/2019
    // moved to the Opportunity trigger and made Queueable
    // ============================================================================
    
    /*private void setCustomerStage(List<Account> accountList, Map<Id, SObject> oldAccountMap) {
        
        Set<Id> accIds = new Set<Id>();
        for(Account acc: accountList) {
            if(acc.Overwrite_Customer_Stage__c == false)
                accIds.add(acc.Id);
        }
        
        if(accIds.size() > 0) {
            List<Opportunity> allOpps = [SELECT Id, AccountId, CloseDate,
                            (SELECT Id, Name, Quantity, OpportunityId, Opportunity.AccountId FROM OpportunityLineItems  WHERE Name LIKE: '% Attended Robot %' OR Name LIKE: '% Unattended Robot %')
                             FROM Opportunity 
                            WHERE AccountId IN: accIds AND StageName = 'Closed Won Booked'
                            AND Type != 'Renewal'];
            Map<Id, List<Opportunity>> allOppsMap = new Map<Id, List<Opportunity>>();
            Map<Id, List<OpportunityLineItem>> allOliMap = new Map<Id, List<OpportunityLineItem >>();
            
            for(Opportunity opp: allOpps) {
                
                if(!allOppsMap.containsKey(opp.AccountId)) {
                    List<Opportunity> newOppList = new List<Opportunity>();
                    newOppList.add(opp);
                    allOppsMap.put(opp.AccountId, newOppList);
                } else {
                    List<Opportunity> exOppList = allOppsMap.get(opp.AccountId);
                    exOppList.add(opp);
                    allOppsMap.put(opp.AccountId, exOppList);
                }
                for(OpportunityLineItem oli: opp.OpportunityLineItems) {
                    if(!allOliMap.containsKey(oli.Opportunity.AccountId)) {
                        List<OpportunityLineItem> newOliList = new List<OpportunityLineItem>();
                        newOliList.add(oli);
                        allOliMap.put(oli.Opportunity.AccountId, newOliList);
                    } else {
                        List<OpportunityLineItem> exliList = allOliMap.get(oli.Opportunity.AccountId); 
                        exliList.add(oli);
                        allOliMap.put(oli.Opportunity.AccountId, exliList);
                    }
                }
            }
            
            
            for(Account acc: accountList) {
                if(allOppsMap.containsKey(acc.Id)) {
                    
                    // get total no. of Robots (both attended & unattended)
                    Integer noOfRobots = 0;
                    if(allOliMap.containsKey(acc.Id)) {
                        List<OpportunityLineItem> oliRobots = allOliMap.get(acc.Id);
                        for(OpportunityLineItem orobot: oliRobots)
                            noOfRobots += Integer.valueOf(orobot.Quantity);
                    }
                    
                   
                    if(noOfRobots == 0)
                        acc.Customer_Stage__c = 'Prove';
                        
                    if(noOfRobots > 0 && noOfRobots <= 5)
                        acc.Customer_Stage__c = 'Establish';
                        
                    if(noOfRobots > 5 && noOfRobots <= 20)
                        acc.Customer_Stage__c = 'Expand';
                    
                    if(noOfRobots > 20)
                        acc.Customer_Stage__c = 'Scale';    
                    
                } else {
                    acc.Customer_Stage__c = 'Prove';
                }
            }
        }
    }*/
    
    /**
    * @DESCRIPTION: This method will populate address fields when an account is created from D&B or when a D&B company is matched with an existing account
    * @AUTHOR: SV - Slalom Consulting
    */
    private void setAddressRelatedFields(Map<Id, SObject> oldAccountMap, List<Account> accountList) {

        Map<String,String> codeAndCountryMap = new Map<String,String>();

        if(oldAccountMap == null){
            //Retrieve Country Codes
            Schema.DescribeFieldResult countryCodeResult = User.Countrycode.getDescribe();
            List<Schema.PicklistEntry> countryPLE = countryCodeResult.getPicklistValues();
            for( Schema.PicklistEntry entry : countryPLE){
                codeAndCountryMap.put(entry.getValue(),entry.getLabel());
            }
        }


        for(Account acc : accountList) {
            Account oldAcc = null;
            if(oldAccountMap != null){
                oldAcc = (Account) oldAccountMap.get(acc.Id);
            }
            else{
                if(String.IsBlank(acc.BillingCountry) && String.IsNotBlank(acc.Country__c) ){
                    acc.BillingCountry = acc.Country__c;
                }

                //on insert only
                if(String.IsBlank(acc.BillingCountry) && String.IsNotBlank(acc.BillingCountryCode) ){
                    //In case of lead conversion, country code is available on before insert, but country is not available until after insert
                    //Fix that here, so that we can use country for address logic
                    acc.BillingCountry = codeAndCountryMap.get(acc.BillingCountryCode);
                }
            }


            //If account is created from D&B or account is matched with address, populate the standard address
            if (String.IsNotBlank(acc.DnB_Country__c) && (oldAcc==null || String.IsBlank(oldAcc.DnB_Country__c))) {


                //Insert only
                if(oldAcc==null){
                    //Account was created through D&B Hoovers insert scenario
                    acc.Country__c = acc.DnB_Country__c;
                    acc.BillingCountry = acc.DnB_Country__c;
                }
                //Update only
                else{
                    //Don't allow D&B matching with company in other country
                    if(acc.DnB_Country__c != acc.Country__c){
                        throw new DnBMatchException('You cannot select a D&B Company from a different country.');
                    }
                }


                acc.BillingStreet = acc.DnB_Street__c;
                acc.BillingCity = acc.DnB_City__c;

                if( acc.BillingCountry == 'United States' ){
                    acc.DnB_Zip_Postal_Code__c = acc.DnB_Zip_Postal_Code__c.left(5);
                }
                acc.BillingPostalCode =  acc.DnB_Zip_Postal_Code__c;



                /*
                    Replicate logic for wf 'Populate State from D&B'
                    Only populate state for supported states, otherwise clear out the D&B state
                 */
                if( AvailableCountryStates.Contains(acc.DnB_State_Province__c) &&
                        (acc.BillingCountry == 'United States' ||
                        acc.BillingCountry == 'China' ||
                        acc.BillingCountry == 'Australia' ||
                        acc.BillingCountry == 'Brazil' ||
                        acc.BillingCountry == 'Canada' ||
                        acc.BillingCountry == 'United Kingdom' ||
                        acc.BillingCountry == 'Ireland' ||
                        acc.BillingCountry == 'India' ||
                        acc.BillingCountry == 'Italy'||
                        acc.BillingCountry == 'Mexico')){


                    acc.BillingState = acc.DnB_State_Province__c;
                }
                else{
                    acc.DnB_State_Province__c = '';
                }

                //Default shipping address to billing address on insert
                acc.ShippingCountry = acc.BillingCountry;
                acc.ShippingState = acc.BillingState;
                acc.ShippingStreet = acc.BillingStreet;
                acc.ShippingCity = acc.BillingCity;
                acc.ShippingPostalCode = acc.BillingPostalCode;
            }

            if (oldAcc == null){
                if(String.IsBlank(acc.DnB_Country__c) && String.IsNotBlank(acc.BillingCountry)) {
                    //Support for pre-golive scenario
                    acc.Country__c = acc.BillingCountry;
                }

                //Default shipping address to billing address on insert
                acc.ShippingCountry = acc.BillingCountry;
                acc.ShippingState = acc.BillingState;
                acc.ShippingStreet = acc.BillingStreet;
                acc.ShippingCity = acc.BillingCity;
                acc.ShippingPostalCode = acc.BillingPostalCode;
            }
        }
    }


    /**
    * @Description: This method checks the Account Validation Status. If the Validation status is changed to "Validated" and Sync Status not equal to "Do Not Sync",
    *               only then sets the Sync Status on that account to "Valid" if the account is not yet synced to NetSuite. If the Account is already synced to NetSuite then
    *               it sets the Account Sync Status to "Pending". There is a workflow rule which triggers the outbound message to Boomi if Sync Status is Valid or Pending
    */
    private void setSyncStatusForValidatedAccount(Map<Id,SObject> oldAccountMap, List<SObject> newAccountLst){
        for(Account newAcc: (List<Account>) newAccountLst){

            Account oldAcc = (Account) oldAccountMap.get(newAcc.Id);
            if((oldAcc.Sync_Status__c != Constants.ACC_SYNC_STATUS_DO_NOT_SYNC) && (oldAcc.Validation_Status__c != newAcc.Validation_Status__c) && (newAcc.Validation_Status__c == Constants.ACC_VALIDATION_STATUS_VALIDATED)  ){
                if(null!=newAcc.NS_Customer_Internal_ID__c){
                    newAcc.Sync_Status__c = Constants.ACC_SYNC_STATUS_PENDING;
                }else{
                    newAcc.Sync_Status__c = Constants.ACC_SYNC_STATUS_VALID;
                }

            }
        }
    }


    /**
    * @Description: This is call to Sync Status Automation process only for the Account where Validation Status = "Validated",
    *               i.e they are Validated by Data Stewards and synced to NetSuite
    */
    private void callSyncStatusAutomationProcess() {

        Map<Id, SObject> oldAccountMap = new Map<Id, SObject>();
        List<SObject> newAccountLst = new List<SObject>();

        for (Account oldAccObj : (List<Account>) trigger.old) {
            if (oldAccObj.Validation_Status__c == Constants.ACC_VALIDATION_STATUS_VALIDATED) {
                oldAccountMap.put(oldAccObj.Id, oldAccObj);
                newAccountLst.add(trigger.newMap.get(oldAccObj.Id));
            }
        }
        // Call the SyncStatusAutomation Process to check if the Account Updates can be flagged ready to sync to NetSuite
        if (!newAccountLst.isEmpty()) {
            IntegrationHandler.syncStatusAutomationProcess(oldAccountMap, newAccountLst);
        }
    }

    /**
    * @Description: This method is created by UiPath.
    */
    private void GrantPermissionToParentOwner(List<SObject> accountsLst, Map<Id, SObject> oldAccountsMap){

        //Type casted to the Account list from SObject
        List<Account> accounts = (List<Account>) accountsLst;
        Account accOldObj;

        Map<Id, Account> topHAccounts = new Map<Id, Account>();
        Set<Id> accChildrenIds = new Set<Id>();
        if(accounts != null && accounts.size() > 0){
            for(Account acc: accounts){
                //check was inserted or was updated and the owner/account_parent were changed
                if(null!=oldAccountsMap){
                     accOldObj = (Account)oldAccountsMap.get(acc.Id);
                }
                if(acc.Classification__c == 'Global' && (oldAccountsMap != null
                        && (accOldObj.OwnerId != acc.OwnerId || accOldObj.ParentId != acc.ParentId) || oldAccountsMap == null)){
                    if(acc.ParentId != null)
                        accChildrenIds.add(acc.ParentId);
                    else topHAccounts.put(acc.ID, acc);
                }
            }//end for
        }

        if(accChildrenIds != null && accChildrenIds.size() > 0){
            //get top hierarchy accounts
            do{
                List<Account> parents = [Select Id, ParentId, OwnerId FROM Account Where ID IN :accChildrenIds];
                accChildrenIds = new Set<Id>(); //remove all ids from list to add new children

                for(Account acc: parents){
                    if(acc.ParentId != null)
                        accChildrenIds.add(acc.ParentId);
                    else topHAccounts.put(acc.Id, acc);
                }//end for
            }while(accChildrenIds.size() > 0);
        }

        //get top parent owner
        Map<Id, Id> accParentIdOwnerId = new Map<Id, Id>();
        for(Account acc: topHAccounts.values()){
            accParentIdOwnerId.put(acc.Id, acc.OwnerId);
        }//end for

        this.GrantPermissions(accParentIdOwnerId);
    }

    /**
    * @Description: This method is created by UiPath.
    */
    private void GrantPermissions(Map<Id, Id> accParentIdOwnerId) {
        //Generate Account Share records
        List<AccountShare> accShareToInsert = new List<AccountShare>();
        List<Account> children = new List<Account>();
        do{
            children = [Select Id, ParentId, OwnerId from Account Where ParentId IN :accParentIdOwnerId.keySet()];
            Set<Id> usedIds = new Set<Id>();
            usedIds.addAll(accParentIdOwnerId.keySet());

            if(children != null && children.size() > 0){
                for(Account acc: children){
                    if(acc.OwnerId != accParentIdOwnerId.get(acc.ParentId)){
                        AccountShare accShare = new AccountShare();
                        accShare.AccountAccessLevel = 'Edit';
                        accShare.AccountId = acc.Id;
                        //accShare.ContactAccessLevel = 'Edit'; // Contact org-wide default is set to "Controlled by Parent"
                        accShare.OpportunityAccessLevel = 'Edit';
                        accShare.UserOrGroupId = accParentIdOwnerId.get(acc.ParentId);

                        accShareToInsert.add(accShare);

                        //relate ownerId to children - keeping it through hirarchi
                        accParentIdOwnerId.put(acc.Id, accParentIdOwnerId.get(acc.ParentId));
                    }
                }//end for
            }
            //remove existing record to carry on just the useful information
            for(Id parentId: usedIds){
                accParentIdOwnerId.remove(parentId);
            }//end for
        } while (children.size() > 0);

        if(accShareToInsert != null && accShareToInsert.size() > 0)
            insert accShareToInsert;
    }

    /**
    * @Description: This method is created by UiPath. It sets the region on Account
    */
    private void setRegion(List<Account> accList)
    {
        //generate maps of metadata
        list<USA_Industry__mdt> uimList = Industries;
        map<string, USA_Industry__mdt> uimMap = new map<string, USA_Industry__mdt>();
        
        for(USA_Industry__mdt uimTmp : uimList)
        {
            uimMap.put(uimTmp.Industry__c, uimTmp);
        }
        
        list<USA_States__mdt> usmList = States;
        map<string, USA_States__mdt> usmMap = new map<string, USA_States__mdt>();
        
        for(USA_States__mdt usmTmp : usmList)
        {
            usmMap.put(usmTmp.Billing_State_Code__c + '-' + usmTmp.Country__c, usmTmp);
        }
        
        list<String> zipCodeList = new list<String>();
        
        for(Account accTmp : accList)
        {
            if(string.isNotBlank(accTmp.BillingPostalCode))
            {
                zipCodeList.add(accTmp.BillingPostalCode);
            }
        }
        
        list<UsaZipCodes__mdt> uzmList = [Select Postal_Code__c, Region__c, Area__c, Territory__c from UsaZipCodes__mdt 
                                          where Postal_Code__c in :zipCodeList];
        map<string, UsaZipCodes__mdt> uzmMap = new map<string, UsaZipCodes__mdt>();
        
        for(UsaZipCodes__mdt uzmTmp : uzmList)
        {
            uzmMap.put(uzmTmp.Postal_Code__c, uzmTmp);
        }
        
        list<ROW_Country__mdt> rcmList = Countries;
        map<string, ROW_Country__mdt> rcmMap = new map<string, ROW_Country__mdt>();
        
        for(ROW_Country__mdt rcmTmp : rcmList)
        {
            rcmMap.put(rcmTmp.Country_Code__c, rcmTmp);
        }
        
        //set account fields
        for(Account accTmp : accList)
        {
            
            if(!accTmp.Ignore_Territory_Assignment__c)
            {                
                accTmp.Geo__c = null;
                accTmp.Region__c = null;
                accTmp.Area__c = null;
                
                if(accTmp.BillingCountryCode != null)
                {                
                    if(accTmp.BillingCountryCode == 'US')
                    {
                        accTmp.Geo__c = 'AMER';
                        
                        if(uimMap.containsKey(accTmp.Industry))
                        {
                            accTmp.Geo__c = uimMap.get(accTmp.Industry).Region__c;
                            accTmp.Region__c = uimMap.get(accTmp.Industry).Territory__c;
                            accTmp.Area__c = uimMap.get(accTmp.Industry).Area__c;                                                   
                        } 
                        else if(usmMap.containsKey(accTmp.BillingStateCode + '-' + accTmp.BillingCountryCode))
                        {
                            accTmp.Geo__c = usmMap.get(accTmp.BillingStateCode + '-' + accTmp.BillingCountryCode).Region__c;
                            accTmp.Region__c = usmMap.get(accTmp.BillingStateCode + '-' + accTmp.BillingCountryCode).Territory__c;
                            accTmp.Area__c = usmMap.get(accTmp.BillingStateCode + '-' + accTmp.BillingCountryCode).Area__c;
                                                    
                        } 
                        else if(uzmMap.containsKey(accTmp.BillingPostalCode))
                        {
                            accTmp.Geo__c = uzmMap.get(accTmp.BillingPostalCode).Region__c;
                            accTmp.Region__c = uzmMap.get(accTmp.BillingPostalCode).Territory__c;
                            accTmp.Area__c = uzmMap.get(accTmp.BillingPostalCode).Area__c;  
                        }                                               
                    }
                    else
                    {
                        if(accTmp.BillingCountryCode == 'JP' || accTmp.BillingCountryCode == 'IN')
                        {
                            if(usmMap.containsKey(accTmp.BillingStateCode + '-' + accTmp.BillingCountryCode))
                            {
                                accTmp.Geo__c = usmMap.get(accTmp.BillingStateCode + '-' + accTmp.BillingCountryCode).Region__c;
                                accTmp.Region__c = usmMap.get(accTmp.BillingStateCode + '-' + accTmp.BillingCountryCode).Territory__c;
                                                        
                            } else {
                                if(rcmMap.containsKey(accTmp.BillingCountryCode))
                                {
                                    accTmp.Geo__c = rcmMap.get(accTmp.BillingCountryCode).Region__c;
                                    accTmp.Region__c = rcmMap.get(accTmp.BillingCountryCode).Territory__c;
                                    accTmp.Area__c = rcmMap.get(accTmp.BillingCountryCode).Area__c;
                                }  
                            } 
                        } else {
                            if(rcmMap.containsKey(accTmp.BillingCountryCode))
                            {
                                accTmp.Geo__c = rcmMap.get(accTmp.BillingCountryCode).Region__c;
                                accTmp.Region__c = rcmMap.get(accTmp.BillingCountryCode).Territory__c;
                                accTmp.Area__c = rcmMap.get(accTmp.BillingCountryCode).Area__c;
                            }
                        }
                    }
                }
            }
        }
    }

    /**
    * @DESCRIPTION: This method will set the UiPath Subsidiary based on the account's country on creation of the account.
    * @AUTHOR: SV - Slalom Consulting
    */
    private void setSubsidiary(List<Account> accountList) {
        
        Map<String,String> countrySubsidiaryMap = new Map<String,String>();
        Map<String,String> countryCodeSubsidiaryMap = new Map<String,String>();
        for(Country_Subsidiary_Mapping__mdt mapping : subsidiaryMappingList){
            countrySubsidiaryMap.put(mapping.MasterLabel.toLowerCase(),mapping.Subsidiary__c);
            countryCodeSubsidiaryMap.put(mapping.Country_Code__c,mapping.Subsidiary__c);
        }

        for(Account acc : accountList){

            //take the first 40 characters as the label field has a max 40 chars
            string accountCountryToFind = acc.Country__c.left(40).toLowerCase();

            String countrySubsidiary = countrySubsidiaryMap.get(accountCountryToFind);

            if(String.IsNotBlank(countrySubsidiary)){
                acc.Primary_Subsidiary__c = countrySubsidiaryMap.get(accountCountryToFind);
            }
        }
    }


    /**
    * @DESCRIPTION: This method will create an address record with the country set based on the account country, on account creation.
    * @AUTHOR: SV - Slalom Consulting
    */
    private void createAddress(List<Account> accountList) {

        List<Address__c> addressList = new List<Address__c>();

        for(Account acc : accountList){
            Address__c address = new Address__c();
            address.Account__c = acc.Id;
            address.Primary_Billing__c = true;
            address.Primary_Shipping__c = true;
            address.Created_From_Account__c = true;

            //Account was created through D&B Hoovers
            if(acc.DnB_Country__c != null){

                address.D_B_Address__c = true;
                address.Country__c = acc.DnB_Country__c;

                //D&B street is 255 characters. On address object we have street 1 (150 characters) and street 2 (105 characters)
                if(String.IsNotBlank(acc.DnB_Street__c)){
                    address.Street_Line_1__c = acc.DnB_Street__c.left(150);
                    if(acc.DnB_Street__c.length() > 150){
                        address.Street_Line_2__c = acc.DnB_Street__c.substring(150,acc.DnB_Street__c.length());
                    }
                }
                address.City__c = acc.DnB_City__c;
                address.Zip_Postal_Code__c = acc.DnB_Zip_Postal_Code__c;

                if(AvailableCountryStates.Contains(acc.DnB_State_Province__c)){
                    address.State__c = acc.DnB_State_Province__c;
                }

                address.RecordTypeId = Utilities.getRecordTypeId(Constants.ADDRESS_RECORD_TYPE_LOCKDOWN, 'Address__c');
            }
            else{
                //Not created through D&B Hoovers

                // The following below is necessary in the interim period, where we move to production, but before the changes are rolled out to users
                // Country__c should be available on account, but some test classes are failing because they only set billing country code on creation.
                // Because of that, billing country is not available during before insert and Country__c can't be populated accordingly.
                //We have to prevent that address.Country__c is populated with an empty value
                if(String.IsNotBlank(acc.Country__c)){
                    address.Country__c = acc.Country__c;
                    // =================================================
                    // complete Address State added from new State field
                    if(String.IsNotBlank(acc.State__c))
                        address.State__c = acc.State__c;
                }
                else{
                    address.Country__c = acc.BillingCountry;
                }


                //Account might be created through lead conversion. Pick up any lead address details that might be available.
                if( String.IsNotBlank(acc.BillingCountry) ){
                    //Lead street is 255 characters. On address we have street 1 (150 characters) and street 2 (105 characters)
                    if(String.IsNotBlank(acc.BillingStreet)){
                        address.Street_Line_1__c = acc.BillingStreet.left(150);
                        if(acc.BillingStreet.length() > 150){
                            address.Street_Line_2__c = acc.BillingStreet.substring(150,acc.BillingStreet.length());
                        }
                    }
                    address.City__c = acc.BillingCity;
                    address.Zip_Postal_Code__c = acc.BillingPostalCode;
                    // ==================================================================================================
                    // complete Address State added from billing address completed on account insert from new field State 
                    address.State__c = acc.BillingState;
                }
            }
            addressList.add(address);
        }
        insert addressList;
    }


    /**
    * @DESCRIPTION: Process mapped D&B Company, create an address record for D&B address
    * @AUTHOR: SV - Slalom Consulting
    */
    private void processDNBCompany(Map<Id, SObject> oldAccountsMap, List<SObject> accountList) {

        List<Address__c> addressList = new List<Address__c>();

        for(Account acc : (List<Account>) accountList){
            Account oldAccount = (Account) oldAccountsMap.get(acc.Id);

            //Only run the first time the D&B account/address is set
            if(String.IsNotBlank(acc.DnB_Country__c) && String.IsBlank(oldAccount.DnB_Country__c)){

                if(addressHasBeenAddedFor.contains(acc.Id)){
                    //SFSL-827
                    continue;
                }

                //Mapped D&B Company has changed. Create an address record based on D&B details and mark it as primary billing
                Address__c address = new Address__c();
                address.Account__c = acc.Id;
                address.Primary_Billing__c = true;
                address.Primary_Shipping__c = true;

                address.D_B_Address__c = true;

                //if D&B country is different from Country__c, data steward needs to fix data manually
                address.Country__c = acc.DnB_Country__c;

                //D&B street is 255 characters. On address object we have street 1 (150 characters) and street 2 (105 characters)
                if(String.IsNotBlank(acc.DnB_Street__c)){
                    address.Street_Line_1__c = acc.DnB_Street__c.left(150);
                    if(acc.DnB_Street__c.length() > 150){
                        address.Street_Line_2__c = acc.DnB_Street__c.substring(150,acc.DnB_Street__c.length());
                    }
                }
                address.City__c = acc.DnB_City__c;
                address.Zip_Postal_Code__c = acc.DnB_Zip_Postal_Code__c;

                if(AvailableCountryStates.Contains(acc.DnB_State_Province__c)){
                    address.State__c = acc.DnB_State_Province__c;
                }

                address.RecordTypeId = Utilities.getRecordTypeId(Constants.ADDRESS_RECORD_TYPE_LOCKDOWN, 'Address__c');

                addressList.add(address);
                addressHasBeenAddedFor.add(acc.Id);
            }
        }
        insert addressList;
    }

}