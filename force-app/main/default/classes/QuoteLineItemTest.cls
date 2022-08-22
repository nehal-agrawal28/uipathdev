@isTest
public class QuoteLineItemTest {

    @isTest
    public static void TestPrePopulateEndDate() {

        // Data setup
        Account acc = new Account (
                Name = 'newAcc1',
                BillingCountry = 'United Kingdom',
                Industry = 'Others'
        );
        insert acc;

        Opportunity o = new Opportunity();

        {
            o.accountid = acc.id;
            o.StageName = 'Discovery';
            o.CloseDate = system.today();
            o.name = 'Test Op';
            o.Type = 'Upsell';
            //o.CurrencyIsoCode = 'USD';
            o.Led_by__c = 'Direct Led';
            o.Won_Reasons__c = 'Product Roadmap';
            o.Features_the_customer_liked_didn_t_like__c = 'The best products are here';
            o.Name_of_competition_last_round__c = 'We are our own competition';
            o.Name_of_our_partner__c = 'The best partner';
            o.UiPath_team_part_of_the_bid_process__c = 'The whole company';
            o.Closeout_Reason__c = 'We Won the account today!';
            o.LeadSource = 'Partner';
            insert o;
        }


        Id pricebookId = Test.getStandardPricebookId();

        //Create your product
        Product2 prod = new Product2(
                Name = 'Product X',
                ProductCode = 'Pro-X',
                isActive = true,
                License_Model__c = 'N/A',
                Unit_of_measure__c = 'N/A',
                Ext_Id__c = 'Product X 002',
                Family='Other'
        );
        insert prod;

        //Create your pricebook entry
        PricebookEntry pbEntry = new PricebookEntry(
                Pricebook2Id = pricebookId,
                Product2Id = prod.Id,
                UnitPrice = 100.00,
                IsActive = true
        );
        insert pbEntry;

        //create your opportunity line item.  This assumes you already have an opportunity created, called o
        OpportunityLineItem oli = new OpportunityLineItem(
                OpportunityId = o.Id,
                Quantity = 5,
                PricebookEntryId = pbEntry.Id,
                //TotalPrice =  500,
                UnitPrice = 200,
                End_Date__c = Date.today().addMonths(3)
        );
        insert oli;

        Quote q = new Quote();
        q.Pricebook2Id = pricebookId;
        q.Name = 'Test Op - Q';
        q.OpportunityId = o.Id;
        insert q;

        QuoteLineItem qli = new QuoteLineItem();
        qli.OpportunityLineItemId = oli.Id;
        qli.QuoteId = q.Id;
        qli.PricebookEntryId = pbEntry.Id;
        qli.Quantity = 5;
        qli.UnitPrice = 100.0;
        qli.Product2Id = prod.Id;
        qli.Sales_Price_Edited__c = oli.UnitPrice;
        // Run the code
        Test.startTest();
        insert qli;
        Test.stopTest();

        // Verify Results
        qli = [SELECT Sales_Price_Edited__c,End_Date__c FROM QuoteLineItem WHERE Id = :qli.Id];
        System.assertEquals(Date.today().addMonths(3), qli.End_Date__c);
    }

}