@IsTest
public class PSAssignmentOverrideResetTest {
  @IsTest
    public static void makeData() {
    Account acc = new Account(Name = 'newAcc1', BillingCountry = 'United Kingdom', Industry = 'Others');
    insert acc;
    contact con = new Contact(LastName = 'Test contact 101',Email = 'test.contact01@testemail.com', Department__c = 'IT',AccountId=acc.Id,pse__Is_Resource_Active__c=true,pse__Is_Resource__c=true);
            insert con;
    Opportunity o = new Opportunity();
    o.accountid = acc.id;
    o.StageName = 'Discovery';
    o.CloseDate = system.today();
    o.name = 'Test Op';
    o.Type = 'Upsell';
    o.CurrencyIsoCode = 'EUR';
    o.Led_by__c = 'Direct Led';
    o.Won_Reasons__c = 'Product Roadmap';
    o.Features_the_customer_liked_didn_t_like__c = 'The best products are here';
    o.Name_of_competition_last_round__c = 'We are our own competition';
    o.Name_of_our_partner__c = 'The best partner';
    o.UiPath_team_part_of_the_bid_process__c = 'The whole company';
    o.Closeout_Reason__c = 'We Won the account today!';
    o.LeadSource = 'Partner';
    insert o;

    User u = new User();
    u.ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id;
    u.Username = 'test839734@uiath.com';
    u.LastName = 'Test';
    u.Email = 'test839734@uiath.com';
    u.Alias = 't839734';
    u.TimeZoneSidKey = 'America/Los_Angeles';
    u.LocaleSidKey = 'en_US';
    u.EmailEncodingKey = 'UTF-8';
    u.LanguageLocaleKey = 'en_US';
    insert u;

    pse__Practice__c practice = new pse__Practice__c(Name = 'Test Practice');
    insert practice;

    pse__Proj__c testProj = new Pse__Proj__c(
      Name = 'test_Project_123456',
      CurrencyIsoCode = 'USD',
      pse__Account__c = acc.id,
      pse__Practice__c = practice.Id,
      pse__Is_Active__c = true,
      pse__Start_Date__c = Date.newInstance(2019, 12, 1),
      pse__End_Date__c = Date.newInstance(2019, 12, 31)
    );
    insert testProj;

    pse__Assignment__c assignment = new pse__Assignment__c(Name='test',pse__Bill_Rate__c =0,pse__Cost_Rate_Amount__c=80.0,CurrencyIsoCode='USD',pse__Project__c=testProj.Id,pse__Resource__c=con.Id,SubK_PO__c='testing');
    insert assignment;
    List<pse__Assignment__c> ast =[select id from pse__Assignment__c];
      system.debug('test'+ast.size());
      system.assertEquals(1, ast.size());
  }
}