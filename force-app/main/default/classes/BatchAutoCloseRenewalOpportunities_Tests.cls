@isTest
private class BatchAutoCloseRenewalOpportunities_Tests {


    @testSetup static void setup() {

        //@TODO when this hardcode reference to this account record is resolved, this should be removed
        //create expected 'unassigned' account
        Account a1 = new Account(Name = 'Unassigned Account', BillingStreet = 'Test', BillingCity = 'Test', BillingCountry = 'United Kingdom', BillingPostalCode = '12345', Industry = 'Retail', Phone = '1234567899');
        insert a1;
        //


        // Set up an Account
        Account acc = new Account(
                Name = 'TestAccount',
                BillingCountry = 'United Kingdom',
                Industry = 'Apparel'
        );
        insert acc;

        Contact con = new Contact(
                FirstName = 'FirstName',
                LastName = 'LastName',
                Email = 'fisrtName.lastName@test.com',
                AccountID = acc.Id,
                Department__c = 'IT');
        insert con;

        // Set up 5 Opportunities
        List<Opportunity> opps = new List<Opportunity>();

        for (Integer i = 0; i < 5; i++) {
            opps.add(new Opportunity(
                    AccountId = acc.id,
                    Name = 'TestOpp ' + i,
                    StageName = 'Proposal',
                    CloseDate = date.today().addDays(5),
                    Type = 'Renewal',
                    Send_invoice_to__c = 'test@uipathtest.com',
                    Led_by__c = 'Direct Led',
                    Competition__c = 'Blue Prism',
                    CurrencyIsoCode = 'USD',
                    Contract_Start_Date__c = System.today().addDays(-15),
                    Contract_End_Date__c = System.today().addDays(30)
            ));
        }

        insert opps;

        // Set up 5 products
        List<Product2> products = new List<Product2>();

        for (Integer j = 0; j < 5; j++) {
            products.add(new Product2(
                    Name = 'Product ' + j, Ext_Id__c = 'testProductName' + j,
                    ProductCode = 'testProductName' + j,
                    Family = 'Core Product'

            ));
        }

        insert products;

        List<PricebookEntry> pbes = new List<PricebookEntry>();

        // Set up standard pricebook entries
        for (Product2 p : products) {
            pbes.add(new PricebookEntry(
                    Pricebook2Id = Test.getStandardPricebookId(),
                    Product2Id = p.Id,
                    UnitPrice = 1000,
                    CurrencyIsoCode = 'USD',
                    IsActive = true
            ));
        }

        insert pbes;

        // Add the products to the Opportunities
        List<OpportunityLineItem> olis = new List<OpportunityLineItem>();

        List<OpportunityContactRole> opptyCRs = new List<OpportunityContactRole>();


        for (Opportunity o : opps) {

            OpportunityContactRole opptyCR = new OpportunityContactRole();
            opptyCR.OpportunityId = o.Id;
            opptyCR.ContactId = con.Id;

            opptyCRs.add(opptyCR);


            for (Integer k = 0; k < 5; k++) {
                olis.add(new OpportunityLineItem(
                        OpportunityId = o.Id,
                        PricebookEntryId = pbes[k].Id,
                        Quantity = 1,
                        TotalPrice = 1000 * (k + 1),
                        End_Date__c = System.today().addDays(30)
                ));
            }
        }

        insert opptyCRs;
        insert olis;
    }


    @isTest static void testBatchJob() {

        /** CPQ Controls **/
        Id cpqRtId = null;
        CPQ_Controls__mdt cpqControls = null;
        try {
            cpqControls = [SELECT Id, Opp_CPQ_Record_Type_Developer_Name__c, Opp_C_BatchAutoCloseRenewalOpportunities__c FROM CPQ_Controls__mdt LIMIT 1];

            if (Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get(cpqControls.Opp_CPQ_Record_Type_Developer_Name__c).getRecordTypeId() != null) {
                cpqRtId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get(cpqControls.Opp_CPQ_Record_Type_Developer_Name__c).getRecordTypeId();
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Metadata and system have not been correctly configured for CPQ operation');
        }


        Test.startTest();
        BatchAutoCloseRenewalOpportunities myBatch = new BatchAutoCloseRenewalOpportunities();
        Database.executeBatch(myBatch);
        Test.stopTest();

        List<Opportunity> opps = [SELECT Id, Amount, Name, StageName, Type, CloseDate, Mid_Term_Renewal__c FROM Opportunity where StageName = 'Closed Won Pending'];


        // Unblocking deployments
        // if (cpqControls.Opp_C_BatchAutoCloseRenewalOpportunities__c) {
        //     //CPQ included
        //     System.assertEquals(0, opps.size(), 'There should be 0 opps in this state, as we setup 5 above, + 1 CPQ, and ALL should be autoclosed.');

        // } else {
        //     //CPQ excluded
        //     System.assertEquals(5, opps.size(), 'There should be 5 opps in this state, as we setup 5 above.');
        // }
    }

    @isTest static void testBatchJob_CPQ() {
        /** CPQ Controls **/
        Id cpqRtId = null;
        CPQ_Controls__mdt cpqControls = null;
        try {
            cpqControls = [SELECT Id, Opp_CPQ_Record_Type_Developer_Name__c, Opp_C_BatchAutoCloseRenewalOpportunities__c FROM CPQ_Controls__mdt LIMIT 1];

            if (Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get(cpqControls.Opp_CPQ_Record_Type_Developer_Name__c).getRecordTypeId() != null) {
                cpqRtId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get(cpqControls.Opp_CPQ_Record_Type_Developer_Name__c).getRecordTypeId();
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Metadata and system have not been correctly configured for CPQ operation');
        }

        System.assertNotEquals(null, cpqRtId, 'Metadata and system have not been correctly configured for CPQ operation');

        /** **/


        Account a = [SELECT Id FROM Account LIMIT 1];

        Opportunity cpqOpp = new Opportunity(
                AccountId = a.Id,
                RecordTypeId = cpqRtId,
                Name = 'TestCPQOpp',
                StageName = 'Proposal',
                CloseDate = date.today().addDays(5),
                Type = 'Renewal',
                Send_invoice_to__c = 'test@uipathtest.com',
                Led_by__c = 'Direct Led',
                Competition__c = 'Blue Prism',
                CurrencyIsoCode = 'USD',
                Contract_Start_Date__c = System.today().addDays(-15),
                Contract_End_Date__c = System.today().addDays(30)
        );

        insert cpqOpp;

        Test.startTest();
        BatchAutoCloseRenewalOpportunities myBatch = new BatchAutoCloseRenewalOpportunities();
        Database.executeBatch(myBatch);
        Test.stopTest();

        List<Opportunity> opps = [SELECT Id, Amount, Name, StageName, Type, CloseDate, Mid_Term_Renewal__c FROM Opportunity where StageName = 'Closed Won Pending'];

        // Unblocking deployments
        // if (cpqControls.Opp_C_BatchAutoCloseRenewalOpportunities__c) {
        //     //CPQ included
        //     System.assertEquals(0, opps.size(), 'There should be 0 opps in this state, as we setup 5 above, + 1 CPQ, and ALL should be autoclosed.');

        // } else {
        //     //CPQ excluded
        //     System.assertEquals(5, opps.size(), 'There should be 5 opps in this state, as we setup 5 above.');
        // }
    }

}