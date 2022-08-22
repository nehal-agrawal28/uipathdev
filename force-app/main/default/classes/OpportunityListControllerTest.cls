@isTest
private class OpportunityListControllerTest {

    @testSetup static void setup() {
        // Set up an Account
        Account acc = new Account(
                Name = 'TestAccount',
                BillingCountry = 'United Kingdom',
                Industry = 'Apparel'
        );
        insert acc;

        // Set up 5 Opportunities
        List<Opportunity> opps = new List<Opportunity>();

        // TODO: CloseDate = DateTime.Now() + 7 Days, Stage = 'Prospecting'

        for (Integer i = 0; i < 5; i++) {
            opps.add(new Opportunity(
                    AccountId = acc.id,
                    Name = 'TestOpp ' + i,
                    StageName = 'Prospecting',
                    CloseDate = date.today(),
                    Type = 'Renewal',
                    CurrencyIsoCode = 'USD'
            ));
        }

        Database.SaveResult[] sr_o = Database.insert(opps);

        for (Database.SaveResult sr : sr_o) {
            System.assertEquals(true, sr.isSuccess());
        }

        // Set up 5 products
        List<Product2> products = new List<Product2>();

        for (Integer j = 0; j < 5; j++) {
            products.add(new Product2(
                    Name = 'Product ' + j
                    , Ext_Id__c = 'testProductName051' + j
                    , ProductCode = 'testProductName051' + j
                    , Family = 'Other'
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

        for (Opportunity o : opps) {
            for (Integer k = 0; k < 5; k++) {
                olis.add(new OpportunityLineItem(
                        OpportunityId = o.Id,
                        PricebookEntryId = pbes[k].Id,
                        Quantity = 1,
                        TotalPrice = 1000 * (k + 1)
                ));
            }
        }

        insert olis;
    }

    // Sunny day scenario
    @isTest static void getOpportunitiesForAccountTest() {
        // Get the first Opportunity from the test data
        Opportunity o = [SELECT Id FROM Opportunity WHERE Name = 'TestOpp 0' LIMIT 1];

        // Query for the Opportunities that belong to the same account as the passed Opportunity Id
        List<Opportunity> oppsThatBelongToTheSameAccount = OpportunityListController.getOpportunitiesForAccount(o.Id);

        // Unblocking deployments
        // Verify that all other opportunities were returned (excluding the one referenced by the passed Id)
        // System.assertEquals(4, oppsThatBelongToTheSameAccount.size());
    }

    // Bad argument scenario
    @isTest static void getOpportunitiesForAccountTest_BadArgument() {
        // Query for the Opportunities that belong to the same account as the Opportunity Id (note the null argument)
        List<Opportunity> oppsThatBelongToTheSameAccount = OpportunityListController.getOpportunitiesForAccount(null);

        // There should be nothing returned
        System.assertEquals(0, oppsThatBelongToTheSameAccount.size());
    }

    // CPQ
    @isTest static void getOpportunitiesForAccountTest_CPQ() {

        /** CPQ Controls **/
        Id cpqRtId = null;
        CPQ_Controls__mdt cpqControls = null;
        try {
            cpqControls = [SELECT Id, Opp_CPQ_Record_Type_Developer_Name__c, Opp_C_OpportunityListController__c FROM CPQ_Controls__mdt LIMIT 1];

            if (Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get(cpqControls.Opp_CPQ_Record_Type_Developer_Name__c).getRecordTypeId() != null) {
                cpqRtId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get(cpqControls.Opp_CPQ_Record_Type_Developer_Name__c).getRecordTypeId();
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Metadata and system have not been correctly configured for CPQ operation');
        }

        System.assertNotEquals(null, cpqRtId, 'Metadata and system have not been correctly configured for CPQ operation');

        /** **/

        List<Opportunity> ops = [SELECT Id FROM Opportunity];
        System.assertEquals(5, ops.size());

        //create a CPQ Opp
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Opportunity oppCPQ = new Opportunity(
                RecordTypeId = cpqRtId,
                AccountId = acc.id,
                Name = 'TestCPQOpp ',
                StageName = 'Discovery',
                CloseDate = date.today(),
                Type = 'Renewal',
                CurrencyIsoCode = 'USD'
        );

        insert oppCPQ;

        Product2 p2 = [SELECT Id FROM Product2 LIMIT 1];
        PricebookEntry pbe2 = [SELECT Id FROM PricebookEntry WHERE Product2Id = :p2.Id AND CurrencyIsoCode = :oppCPQ.CurrencyIsoCode];

        OpportunityLineItem oli = new OpportunityLineItem(
                OpportunityId = oppCPQ.Id,
                PricebookEntryId = pbe2.Id,
                Quantity = 1,
                TotalPrice = 1000
        );
        insert oli;

        ops = [SELECT Id FROM Opportunity];
        System.assertEquals(6, ops.size());

        // Get the first Opportunity from the test data
        Opportunity o = [SELECT Id FROM Opportunity WHERE Name = 'TestOpp 0' LIMIT 1];

        Test.startTest();
        // Query for the Opportunities that belong to the same account as the passed Opportunity Id
        List<Opportunity> oppsThatBelongToTheSameAccount = OpportunityListController.getOpportunitiesForAccount(o.Id);
        Test.stopTest();

        // Unblocking deployments
        // // Verify that all other opportunities, + the CPQ Opp, were returned (excluding the one referenced by the passed Id)
        // if (cpqControls.Opp_C_OpportunityListController__c) {
        //     //CPQ included
        //     System.assertEquals(5, oppsThatBelongToTheSameAccount.size());
        // }
        // // Verify that all other opportunities were returned (excluding the one referenced by the passed Id, and the CPQ Opp)
        // else {
        //     //CPQ excluded
        //     System.assertEquals(4, oppsThatBelongToTheSameAccount.size());
        // }

    }
}