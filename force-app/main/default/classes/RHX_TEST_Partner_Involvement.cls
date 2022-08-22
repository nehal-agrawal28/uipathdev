@isTest(SeeAllData=true)
public class RHX_TEST_Partner_Involvement {
    static testMethod void RHX_Testmethod() {
        
        Account acc = new Account();
        acc.Name = 'testAccName';
        acc.Industry = 'Healthcare';
        acc.BillingCountry = 'Austria';
        acc.RecordTypeId = '01236000000OGv1';
        insert acc;

        Account acc1 = new Account();
        acc1.Name = 'testAccName1';
        acc1.Industry = 'Healthcare';
        acc1.BillingCountry = 'Algeria';
        acc1.RecordTypeId = '01236000000OGv1';
        insert acc1;

        Opportunity opp = new Opportunity();
        opp.StageName = 'Discovery';
        opp.CloseDate = Date.today();
        opp.Type = 'Upsell';
        opp.AccountId = acc.Id;
        opp.Name = 'testOppName';
        opp.LeadSource = 'Partner';
        insert opp;
        
        Partner_Involvement__c pic = new Partner_Involvement__c();
        pic.Partner_Role__c = 'System Integrator & Reseller';
        pic.Partner_Account_Name__c = acc1.Id;                                                               
        pic.CurrencyIsoCode = 'USD';
        pic.PartnerOpp_Name__c = opp.Id;
        pic.Selection_Status__c = 'preferred';
        insert pic;
        
        rh2.ParentUtil.UpsertRollupTestRecords(new List<Partner_Involvement__c> { pic });
    }
}