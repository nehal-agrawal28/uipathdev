@isTest
private class OpportunityProductListControllerTest {

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
                    Type = 'New Business',
                    CurrencyIsoCode = 'USD',
                    LeadSource = 'Call Inbound'

            ));
        }

        insert opps;

        // Set up 5 products
        List<Product2> products = new List<Product2>();

        for (Integer j = 0; j < 5; j++) {
            products.add(new Product2(
                    Name = 'Product ' + j,
                    Ext_Id__c = 'Product '+ j,
                    ProductCode='testProductName' +j,
                    Family='Other'
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
    @isTest static void getProductsForOpportunityTest() {
        // Get the first Opportunity from the test data
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'TestOpp 0' LIMIT 1];

        // Query for the OpportunityLineItems that belong to the same Opportunity as passed in
        List<OpportunityLineItem> olisThatBelongToTheOpp = OpportunityProductListController.getProductsForOpportunity(opp.Id);

        // Verify that all other opportunities were returned (excluding the one referenced by the passed Id)
        System.assertEquals(5, olisThatBelongToTheOpp.size());
    }

    // Bad argument scenario
    @isTest static void getProductsForOpportunityTest_BadArgument() {
        // Query for the OpportunityLineItems that belong to the same Opportunity as passed in (note the null argument)
        List<OpportunityLineItem> olisThatBelongToTheOpp = OpportunityProductListController.getProductsForOpportunity(null);

        // There should be nothing returned
        System.assertEquals(0, olisThatBelongToTheOpp.size());
    }
}