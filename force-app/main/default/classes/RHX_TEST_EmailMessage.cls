@isTest(SeeAllData=true)
public class RHX_TEST_EmailMessage {
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
        insert opp;
        
        EmailMessage em = new EmailMessage();
        insert em;
        
        rh2.ParentUtil.UpsertRollupTestRecords(new List<EmailMessage> { em });
    }
}