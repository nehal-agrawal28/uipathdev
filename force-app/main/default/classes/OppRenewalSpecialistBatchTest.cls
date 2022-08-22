@isTest(SeeAllData=false)
public class OppRenewalSpecialistBatchTest {    
    @isTest
    public static void OppRenewalSpecialistTest1 () {
        Account acc = new Account (
        Name = 'newAcc1',
        BillingCountry ='United Kingdom',
        Industry = 'Others'
        );
        insert acc;

        Contact con = new Contact (
        AccountId = acc.id,
        LastName = 'portalTestUser',
        Email = 'portalTestUser321321@emailtest.com',
        Department__c = 'IT'
        );
        insert con;
        
         Contact conEconomic = new Contact (
        AccountId = acc.id,
        LastName = 'Economic Buyer',
        Email = 'Economic321321@emailtest.com',
        Department__c = 'IT'
        );
        insert conEconomic ;
        
         Contact conhampion = new Contact (
        AccountId = acc.id,
        LastName = 'Champion Actual',
        Email = 'Champion321321@emailtest.com',
        Department__c = 'IT'
        );
        insert conhampion;

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
        
         User u2 = new User();
        u2.ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id;
        u2.Username = 'test832734@uiath.com';
        u2.LastName = 'Test2';
        u2.Email = 'test832734@uiath.com';
        u2.Alias = 't832734';
        u2.TimeZoneSidKey = 'America/Los_Angeles';
        u2.LocaleSidKey = 'en_US';
        u2.EmailEncodingKey = 'UTF-8';
        u2.LanguageLocaleKey = 'en_US';
        u2.Rev_Tech_Team__c = true;
        insert u2;
        
        Opportunity o = new Opportunity();

        System.runAs(u)
        {
            o.accountid = acc.id;
            o.StageName = 'Proposal';
            o.CloseDate = system.today();
            o.name = 'Test Op';
            o.Type = 'Upsell';
            o.Renewal_Specialist__c = u2.id;
            o.Economic_Buyer__c = conEconomic.Id;
            o.Champion_Actual__c = conhampion.Id;
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
            system.debug('opportunity 1 = '+o);
        }

        System.runas(u2) {            
            Test.startTest();
            OppRenewalSpecialistBatch b = new OppRenewalSpecialistBatch();
            Database.executeBatch(b);
            Test.stopTest();
        }
        List<OpportunityTeamMember> otm = [SELECT Id, UserId FROM OpportunityTeamMember WHERE OpportunityId =: o.Id AND TeamMemberRole = 'Renewal Specialist'];
        system.assertEquals(1, otm.size());
       
        List<AccountTeamMember> atm = [SELECT Id FROM AccountTeamMember WHERE AccountId =: o.AccountId AND TeamMemberRole = 'Renewal Specialist'];
        system.assertEquals(1, atm.size());
      
    }
    
     @isTest
    public static void OppRenewalSpecialistTest2 () {
        Account acc = new Account (
        Name = 'newAcc1',
        BillingCountry ='United Kingdom',
        Industry = 'Others'
        );
        insert acc;

        Contact con = new Contact (
        AccountId = acc.id,
        LastName = 'portalTestUser',
        Email = 'portalTestUser3421@emailtest.com',
        Department__c = 'IT'
        );
        insert con;
        
         Contact conEconomic = new Contact (
        AccountId = acc.id,
        LastName = 'Economic Buyer',
        Email = 'Economic654654@emailtest.com',
        Department__c = 'IT'
        );
        insert conEconomic ;
        
         Contact conhampion = new Contact (
        AccountId = acc.id,
        LastName = 'Champion Actual',
        Email = 'ChampionActual321256@emailtest.com',
        Department__c = 'IT'
        );
        insert conhampion;

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
        
        User u2 = new User();
        u2.ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id;
        u2.Username = 'test832734@uiath.com';
        u2.LastName = 'Test2';
        u2.Email = 'test832734@uiath.com';
        u2.Alias = 't832734';
        u2.TimeZoneSidKey = 'America/Los_Angeles';
        u2.LocaleSidKey = 'en_US';
        u2.EmailEncodingKey = 'UTF-8';
        u2.LanguageLocaleKey = 'en_US';
        u2.Rev_Tech_Team__c = true;
        insert u2;
        
        System.runAs(u2)
        {
            Account acc1 = new Account (
            Name = 'Sold To Partner',
            BillingCountry ='United Kingdom',
            Industry = 'Others'
            );
            insert acc1;
        }
        
        Opportunity o = new Opportunity();

        System.runAs(u)
        {
            o.accountid = acc.id;
            o.StageName = 'Proposal';
            o.Sold_to_Partner__c = acc.id;
            o.CloseDate = system.today();
            o.name = 'Test Op';
            o.Type = 'Upsell';
            o.Renewal_Specialist__c = u.id;
            o.Economic_Buyer__c = conEconomic.Id;
            o.Champion_Actual__c = conhampion.Id;
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
        }

         List<Opportunity> opps = new List<Opportunity>();
        Map<Id, Opportunity> oppsMap = new  Map<Id, Opportunity>([SELECT Id, OwnerId, AccountId, Sold_to_Partner__c, Tier_2_Partner__c, Influencers__c FROM Opportunity WHERE Id =: o.Id LIMIT 1]);
        
        opps.add(o);

        System.runAs(u2){
            OpportunityTeamMemberQueueable q1 = new OpportunityTeamMemberQueueable(
                new List<SObject>{ o }, null
            );
            q1.execute(null);
            
            Test.startTest();
                OppRenewalSpecialistBatch b = new OppRenewalSpecialistBatch();
                Database.executeBatch(b);
            Test.stopTest();
        }
        List<OpportunityTeamMember> otm = [SELECT Id FROM OpportunityTeamMember WHERE OpportunityId =: o.Id AND TeamMemberRole = 'Renewal Specialist'];
        system.assertEquals(0, otm.size());
        
        List<AccountTeamMember> atm = [SELECT Id FROM AccountTeamMember WHERE AccountId =: o.AccountId AND TeamMemberRole = 'Renewal Specialist'];
        system.assertEquals(1, atm.size());
       
        List<OpportunityTeamMember> otm1 = [SELECT Id, UserId FROM OpportunityTeamMember WHERE OpportunityId =: o.Id AND TeamMemberRole = 'Opportunity Owner'];
        system.assertEquals(1, otm1.size());
        
    }
}