@IsTest
public class RHX_TEST_OpportunityLineItem {
    static testMethod void RHX_Testmethod() {
        
        Account acc = new Account();
        acc.Name = 'testAccName';
        acc.Industry = 'Healthcare';
        acc.BillingCountry = 'Algeria';
        insert acc;

        Opportunity opp = new Opportunity();
        opp.StageName = 'Close Won';
        opp.CloseDate = Date.today();
        opp.Type = 'Upsell';
        opp.AccountId = acc.Id;
        opp.Name = 'testOppName';
        opp.LeadSource = 'Partner';
        opp.Pricebook2Id = Test.getStandardPricebookId();
        insert opp;
        
        Product2 p = new Product2();
        p.Name = 'Product 346343';
        p.Ext_Id__c='testProductName100';
        p.ProductCode='testProductName100';
        p.Family='Other';
        insert p;
        
        PricebookEntry pe = new PricebookEntry();
        pe.Product2Id = p.Id;
        pe.Pricebook2Id = Test.getStandardPricebookId();
        pe.UnitPrice = 100;
        pe.IsActive = true;
        insert pe;
        
        OpportunityLineItem oli = new OpportunityLineItem();
        oli.PricebookEntryId = pe.Id;
        oli.OpportunityId = opp.Id;
        oli.Quantity = 1;
        oli.TotalPrice = 100;
        insert oli;
        
        rh2.ParentUtil.UpsertRollupTestRecords(new List<OpportunityLineItem> { oli });
    }
}