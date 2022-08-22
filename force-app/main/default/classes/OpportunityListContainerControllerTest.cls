@isTest
private class OpportunityListContainerControllerTest {

    static final String COMP = 'Automation Anywhere';

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
                    StageName = 'Discovery',
                    CloseDate = date.today(),
                    Type = 'New Business',
                    Led_by__c = 'Co-Led',
                    //VR HELL
                    Competition__c = COMP,
                    Closeout_Reason__c = '5346786547855576564576567467645546645',
                    Features_the_customer_liked_didn_t_like__c = '785557656457656778555765645765677855576564576567',
                    CurrencyIsoCode = 'USD',
                    LeadSource = 'Call Inbound'
            ));
        }

        insert opps;

        // Set up 5 products
        List<Product2> products = new List<Product2>();

        for (Integer j = 0; j < 5; j++) {
            products.add(new Product2(
                    Name = 'Product ' + j
                    , Ext_Id__c = 'testProductName051' + j
                    , ProductCode = 'testProductName051' +j
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
    @isTest static void mergeOpportunitiesTest() {

        Test.startTest();
        // Get the list of Opportunities
        List<Id> oppsToMergeFrom = new List<Id>(new Map<Id, Opportunity>([SELECT Id FROM Opportunity]).keyset());

        // Remove ther first element (as this is what we use as the opp to merge other opps in to)
        Id destOpp = oppsToMergeFrom.remove(0);


        // Ensure that we have an OppProduct ciount of 5 for the desination Opportunity before we start testing
        List<OpportunityLineItem> olisBefore = [SELECT Id FROM OpportunityLineItem WHERE OpportunityId = :destOpp];

        // Verify a cortrect OpportunityLineItem count
        System.assertEquals(5, olisBefore.size());

        // Call the merge Apex
        String response = OpportunityListContainerController.mergeOpportunities(destOpp, oppsToMergeFrom);

        // Verify the mergo operation was reported ass successful
        System.assertEquals('Success', response);

        // Query for a count of opportunity products that belong to the desination opportunity
        List<OpportunityLineItem> olisAfter = [SELECT Id FROM OpportunityLineItem WHERE OpportunityId = :destOpp];
        // Verify a cortrect OpportunityLineItem count
        System.assertEquals(25, olisAfter.size());
        Test.stopTest();
    }

    // Null pointer of first argument
    @isTest static void mergeOpportunitiesTest_BadFirstArgument() {
        // Get the list of Opportunities
        List<Id> oppsToMergeFrom = new List<Id>(new Map<Id, Opportunity>([SELECT Id FROM Opportunity]).keyset());

        // Remove ther first element (as this is what we use as the opp to merge other opps in to)
        Id destOpp = oppsToMergeFrom.remove(0);

        // Ensure that we have an OppProduct ciount of 5 for the desination Opportunity before we start testing
        List<OpportunityLineItem> olisBefore = [SELECT Id FROM OpportunityLineItem WHERE OpportunityId = :destOpp];
        // Verify a cortrect OpportunityLineItem count
        System.assertEquals(5, olisBefore.size());

        // Call the merge Apex
        String response = OpportunityListContainerController.mergeOpportunities(null, oppsToMergeFrom);

        // Query for a count of opportunity products that belong to the desination opportunity
        List<OpportunityLineItem> olisAfter = [SELECT Id FROM OpportunityLineItem WHERE OpportunityId = :destOpp];
        // Verify a cortrect OpportunityLineItem count
        System.assertEquals(5, olisAfter.size());
    }

    // Null pointer of second argument
    @isTest static void mergeOpportunitiesTest_BadSecondArgument() {
        // Get the list of Opportunities
        List<Id> oppsToMergeFrom = new List<Id>(new Map<Id, Opportunity>([SELECT Id FROM Opportunity]).keyset());

        // Remove ther first element (as this is what we use as the opp to merge other opps in to)
        Id destOpp = oppsToMergeFrom.remove(0);

        // Ensure that we have an OppProduct ciount of 5 for the desination Opportunity before we start testing
        List<OpportunityLineItem> olisBefore = [SELECT Id FROM OpportunityLineItem WHERE OpportunityId = :destOpp];
        // Verify a cortrect OpportunityLineItem count
        System.assertEquals(5, olisBefore.size());

        // Call the merge Apex
        String response = OpportunityListContainerController.mergeOpportunities(destOpp, null);

        // Query for a count of opportunity products that belong to the desination opportunity
        List<OpportunityLineItem> olisAfter = [SELECT Id FROM OpportunityLineItem WHERE OpportunityId = :destOpp];
        // Verify a cortrect OpportunityLineItem count
        System.assertEquals(5, olisAfter.size());
    }

    // Null pointer of both arguments
    @isTest static void mergeOpportunitiesTest_BadArgumentList() {
        // Get the list of Opportunities
        List<Id> oppsToMergeFrom = new List<Id>(new Map<Id, Opportunity>([SELECT Id FROM Opportunity]).keyset());

        // Remove ther first element (as this is what we use as the opp to merge other opps in to)
        Id destOpp = oppsToMergeFrom.remove(0);

        // Ensure that we have an OppProduct ciount of 5 for the desination Opportunity before we start testing
        List<OpportunityLineItem> olisBefore = [SELECT Id FROM OpportunityLineItem WHERE OpportunityId = :destOpp];
        // Verify a cortrect OpportunityLineItem count
        System.assertEquals(5, olisBefore.size());

        // Call the merge Apex
        String response = OpportunityListContainerController.mergeOpportunities(null, null);

        // Query for a count of opportunity products that belong to the desination opportunity
        List<OpportunityLineItem> olisAfter = [SELECT Id FROM OpportunityLineItem WHERE OpportunityId = :destOpp];
        // Verify a cortrect OpportunityLineItem count
        System.assertEquals(5, olisAfter.size());
    }
}