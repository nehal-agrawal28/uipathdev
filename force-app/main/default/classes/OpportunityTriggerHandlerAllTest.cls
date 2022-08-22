@isTest(SeeAllData=false)
public class OpportunityTriggerHandlerAllTest {
    private static final Id customerRT = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Customer').getRecordTypeId();
  
    static testMethod void TestAccountUpdate()
    {
        Account acc = new Account (
        Name = 'newAcc1',
        BillingCountry ='United Kingdom',
        Industry = 'Others',
        Geo__c = 'EMEA'
        );
        insert acc;
        
        Contact con = new Contact (
        AccountId = acc.id,
        LastName = 'portalTestUser',
        Email = 'portal.testUser@testemail.com',
        Department__c = 'IT'
        );
        insert con;
        
         Contact conEconomic = new Contact (
        AccountId = acc.id,
        LastName = 'BEconomic Buyer',
        Email = 'economic.contact12@testemail.com',
        Department__c = 'IT'
        );
        insert conEconomic ;
        
         Contact conhampion = new Contact (
        AccountId = acc.id,
        LastName = 'BChampion Actual',
        Email = 'champion.contact123@testemail.com',
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
        
        Account acc2 = new Account (
        Name = 'Acc2',
        BillingCountry ='India',
        BillingState ='Goa',
        Industry = 'Others',
        Geo__c = 'APJ',
        Area__c = 'India',
        Region_Specific__c = 'India Business - Top Strategic Accounts'
        );
        System.runAs(u)
        {
            insert acc2;
        }
        
        Opportunity o = new Opportunity();
        o.accountid = acc.id;
        o.StageName = 'Proposal';
        o.CloseDate = system.today();
        o.name = 'Test Op';
        o.Type = 'Upsell';
        o.Sold_to_Partner__c = acc.id;
        o.Tier_2_Partner__c = acc.id;
        o.Influencers__c = String.valueOf(acc.id);
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
        
        System.runAs(u)
        {
            insert o;
        }
        
        
         //OpportunityTeamMemberQueueable.createOTM(opps);
        OpportunityTeamMemberQueueable q1 = new OpportunityTeamMemberQueueable(
                new List<SObject>{ o }, null
        );
        q1.execute(null);
        
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
        insert u2;
        
        
        OpportunityTeamMember otm = new OpportunityTeamMember();
        otm.UserId = u2.Id;
        otm.OpportunityId = o.Id;
        otm.TeamMemberRole = 'Partner Account Manager';
        insert otm;
        
        
        Map<Id, Opportunity> oppsMap = new  Map<Id, Opportunity>([SELECT Id, OwnerId, AccountId, Account.Geo__c, Account.Area__c, Sold_to_Partner__c, Tier_2_Partner__c, Influencers__c FROM Opportunity WHERE Id =: o.Id LIMIT 1]);
        
        Opportunity o2 = new Opportunity();
        o2.Id = o.Id;
        o2.OwnerId = u.Id;
        o2.AccountId = acc2.id;
        
        update o2;
        
        OpportunityTeamMemberQueueable q2 = new OpportunityTeamMemberQueueable(
                new List<Opportunity> { o2 }, oppsMap
        );
        q2.execute(null);

        List<OpportunityTeamMember> otm1 = [SELECT Id, UserId FROM OpportunityTeamMember WHERE OpportunityId =: o2.Id];
        system.debug('otm1======>'+ otm1);
    }
    
    static testMethod void TestOpportunityTeamMemebers1()
    {
        Account acc = new Account (
        Name = 'newAcc1',
        BillingCountry ='United Kingdom',
        Industry = 'Others'
        );
        insert acc;

        Contact con = new Contact (
        AccountId = acc.id,
        LastName = 'portalTestUser',
        Email = 'portalTestUser123@testemail.com',
        Department__c = 'IT'
        );
        insert con;
        
         Contact conEconomic = new Contact (
        AccountId = acc.id,
        LastName = 'CEconomic Buyer',
        Email = 'EconomicBuyer123@testemail.com',
        Department__c = 'IT'
        );
        insert conEconomic ;
        
         Contact conhampion = new Contact (
        AccountId = acc.id,
        LastName = 'DChampion Actual',
        Email = 'ChampionActual123@testemail.com',
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
        
        Account acc2 = new Account (
        Name = 'Acc2',
        BillingCountry ='United Kingdom',
        Industry = 'Others'
        );
        System.runAs(u)
        {
            insert acc2;
        }

        
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
        insert u2;
        
        Opportunity o = new Opportunity();

        System.runAs(u)
        {
            o.accountid = acc.id;
            o.StageName = 'Proposal';
            o.CloseDate = system.today();
            o.name = 'Test Op';
            o.Type = 'Upsell';
            o.Sold_to_Partner__c = acc.id;
            o.Tier_2_Partner__c = acc.id;
            o.Influencers__c = String.valueOf(acc.id);
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
        //CreateOppTeamMemberFuture.createOppTeamMemberOnInsert(oppSet);
        
        //OpportunityTeamMemberQueueable.createOTM(opps);
        OpportunityTeamMemberQueueable q1 = new OpportunityTeamMemberQueueable(
                new List<SObject>{ o }, null
        );
        q1.execute(null);
        
        
        //List<Opportunity> opp = [SELECT Id, OwnerId, AccountId, Sold_to_Partner__c, Tier_2_Partner__c, Influencers__c FROM Opportunity WHERE Id =: o.Id LIMIT 1];
        //oppsMap.put(opp[0].Id, opp[0]);
        Opportunity o2 = new Opportunity();
        o2.Id = o.Id;
        o2.OwnerId = u2.id;
        o2.Sold_to_Partner__c = null;
        o2.Tier_2_Partner__c = acc2.id;
        o2.Influencers__c = String.valueOf(acc.id) + '; ' + String.valueOf(acc2.id);
        update o2;

       
        OpportunityTeamMemberQueueable q2 = new OpportunityTeamMemberQueueable(
                new List<Opportunity> { o2 }, oppsMap
        );
        q2.execute(null);
        
        List<OpportunityTeamMember> otm = [SELECT Id, UserId FROM OpportunityTeamMember WHERE OpportunityId =: o2.Id];
        system.debug('otm======>'+ otm);
    }
    
    static testMethod void TestOpportunityTeamMemebers2()
    {
        Account acc = new Account (
        Name = 'newAcc1',
        BillingCountry ='United Kingdom',
        Industry = 'Others'
        );
        insert acc;

        Contact con = new Contact (
        AccountId = acc.id,
        LastName = 'portalTestUser',
        Email = 'portalTestUser876@testemail.com',
        Department__c = 'IT'
        );
        insert con;
        
         Contact conEconomic = new Contact (
        AccountId = acc.id,
        LastName = 'DEconomic Buyer',
        Email = 'EconomicBuyer444@testemail.com',
        Department__c = 'IT'
        );
        insert conEconomic ;
        
         Contact conhampion = new Contact (
        AccountId = acc.id,
        LastName = 'EChampion Actual',
        Email = 'Champion_Actual44@testemail.com',
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
        insert u2;
        
        Account acc2 = new Account (
        Name = 'Acc2',
        BillingCountry ='United Kingdom',
        Industry = 'Others'
        );
        System.runAs(u2)
        {
            insert acc2;
        }
        
        Opportunity o = new Opportunity();

        System.runAs(u)
        {
            o.accountid = acc.id;
            o.StageName = 'Proposal';
            o.CloseDate = system.today();
            o.name = 'Test Op';
            o.Type = 'Upsell';
            o.Sold_to_Partner__c = acc.id;
            o.Tier_2_Partner__c = acc.id;
            o.Influencers__c = String.valueOf(acc.id);
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
        Map<Id, Opportunity> oppsMap = new  Map<Id, Opportunity>([SELECT Id, OwnerId, AccountId, Sold_to_Partner__c, Tier_2_Partner__c, Influencers__c, Account_Geo__c FROM Opportunity WHERE Id =: o.Id LIMIT 1]);
        
        opps.add(o);
        //CreateOppTeamMemberFuture.createOppTeamMemberOnInsert(oppSet);
        
        //OpportunityTeamMemberQueueable.createOTM(opps);
        OpportunityTeamMemberQueueable q1 = new OpportunityTeamMemberQueueable(
                new List<SObject>{ o }, null
        );
        q1.execute(null);

        Opportunity o2 = new Opportunity();
        o2.Id = o.Id;
        o2.OwnerId = u.Id;
        o2.Sold_to_Partner__c = null;
        o2.Tier_2_Partner__c = acc2.id;
        o2.Influencers__c = String.valueOf(acc.id) + '; ' + String.valueOf(acc2.id);
        update o2;

       
        OpportunityTeamMemberQueueable q2 = new OpportunityTeamMemberQueueable(
                new List<Opportunity> { o2 }, oppsMap
        );
        q2.execute(null);
        
        List<OpportunityTeamMember> otm = [SELECT Id, UserId FROM OpportunityTeamMember WHERE OpportunityId =: o2.Id];
        system.debug('otm======>'+ otm);
    }

    // static testMethod void TestCopyOpportunityType() {

    //     // Data setup
    //     Account newAccount = new Account();
    //     newAccount.Name = 'testAccName';
    //     newAccount.BillingCountry = 'UNITED STATES';
    //     newAccount.BillingCountryCode ='US';
    //     newAccount.BillingState = 'California';
    //     newAccount.BillingStreet = 'ATest Street';
    //     newAccount.BillingCity = 'ATest City';
    //     newAccount.BillingPostalCode = '123abc';
    //     newAccount.Phone = '0721000000';
    //     newAccount.Industry = 'Energy';
    //     insert newAccount;

    //     Contact cnt = new Contact();
    //     cnt.LastName = 'Test545734';
    //     cnt.AccountId = newAccount.Id;
    //     cnt.Email ='Test545733333@test.com';
    //     cnt.Title = 'titlename';
    //     cnt.Department__c = 'IT';
    //     insert cnt;

    //     Id stdPriceBookRecId = Test.getStandardPricebookId();

    //     Product2 newProduct = new Product2();
    //     newProduct.Name = 'testProductName';
    //     newProduct.Is_Add_On__c = false;
    //     newProduct.IsActive = true;
    //     newProduct.Add_On_Percent__c = 10;
    //     newProduct.License_Model__c = 'N/A';
    //     newProduct.Unit_of_measure__c = 'N/A';
    //     newProduct.Ext_Id__c='testProductName100';
    //     newProduct.ProductCode='testProductName100';
    //     newProduct.Family='Other';

    //     insert newProduct;

    //     Opportunity newOpportunity = new Opportunity();
    //     newOpportunity.Name = 'testOppName';
    //     newOpportunity.Type = '';
    //     newOpportunity.AccountId = newAccount.Id;
    //     newOpportunity.StageName = 'Discovery';
    //     newOpportunity.CloseDate = Date.today();
    //     newOpportunity.Discount_Approval_Status__c = 'In Approval';
    //     newOpportunity.Managing_Director__c = UserInfo.getUserId();
    //     newOpportunity.Pricebook2Id = stdPriceBookRecId;
    //     newOpportunity.CurrencyIsoCode = 'USD';
    //     newOpportunity.Customer_Primary_Contact__c = cnt.Id;
    //     newOpportunity.Onboard_customer_by_CS_Ops__c = 'No';
    //     insert newOpportunity;

    //     PriceBookEntry stdPriceBookEntry = new PriceBookEntry();
    //     stdPriceBookEntry.Product2Id = newProduct.Id;
    //     stdPriceBookEntry.Pricebook2Id = stdPriceBookRecId;
    //     stdPriceBookEntry.UnitPrice = 100;
    //     stdPriceBookEntry.IsActive = true;
    //     stdPriceBookEntry.CurrencyIsoCode = newOpportunity.CurrencyIsoCode;
    //     insert stdPriceBookEntry;

    //     OpportunityLineItem oli = new OpportunityLineItem();
    //     oli.OpportunityId = newOpportunity.Id;
    //     oli.UnitPrice = 100;
    //     oli.Quantity = 1;
    //     oli.PricebookEntryId = stdPriceBookEntry.Id;
    //     oli.Discount = 25;
    //     oli.Add_On_For__c = null;
    //     insert oli;

    //     // Run code
    //     Test.startTest();

    //     Opportunity oppToUpdate = [SELECT Id, Type FROM Opportunity LIMIT 1];
    //     oppToUpdate.Type = 'Upsell';
    //     update oppToUpdate;

    //     Test.stopTest();

    //     // Verify results
    //     List<OpportunityLineItem> oliUpdated = [SELECT Id, Business_Type__c FROM OpportunityLineItem WHERE OpportunityId = :oppToUpdate.Id];
    //     //System.assertEquals('Upsell', oliUpdated[0].Business_Type__c);
    // }
    
    static testMethod void TestCreateOTM1() {
        // Data setup
        Account newAccountParent1 = new Account();
        newAccountParent1.Name = 'Parent1 testAccName';
        newAccountParent1.BillingCountry = 'UNITED KINGDOM';
        newAccountParent1.BillingCountryCode ='GB';
        //newAccountParent1.BillingState = 'Cambridgeshire';
        newAccountParent1.BillingStreet = 'Test Street';
        newAccountParent1.BillingCity = 'Test City';
        newAccountParent1.BillingPostalCode = '123abc';
        newAccountParent1.Phone = '0721440003';
        newAccountParent1.Industry = 'Energy';
        insert newAccountParent1;
        
        Account newAccount1 = new Account();
        newAccount1.Name = 'testAccName1';
        newAccount1.RecordTypeId = customerRT;
        newAccount1.BillingCountry = 'UNITED KINGDOM';
        newAccount1.BillingCountryCode ='GB';
        //newAccount1.BillingState = 'Cambridgeshire';
        newAccount1.BillingStreet = 'Test Street';
        newAccount1.BillingCity = 'Test City';
        newAccount1.BillingPostalCode = '123abc';
        newAccount1.Phone = '0721004400';
        newAccount1.Industry = 'Energy';
        newAccount1.Classification__c = 'KAP';
        newAccount1.Overwrite_Classification__c = true;
        newAccount1.ParentId = newAccountParent1.Id;
        insert newAccount1;
        
        Account newAccountParent = new Account();
        newAccountParent.Name = 'Parent testAccName';
        newAccountParent.BillingCountry = 'UNITED STATES';
        newAccountParent.BillingCountryCode ='US';
        //newAccountParent.BillingState = 'California';
        newAccountParent.BillingStreet = 'Some Street';
        newAccountParent.BillingCity = 'Ran City';
        newAccountParent.BillingPostalCode = '84747';
        newAccountParent.Phone = '765552';
        newAccountParent.Industry = 'Energy';
        
        User u2 = new User();
        u2.ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id;
        u2.Username = 'testother55666@uiath.com';
        u2.LastName = 'OtherTest';
        u2.Email = 'testother55666@uiath.com';
        u2.Alias = 'her55666';
        u2.TimeZoneSidKey = 'America/Los_Angeles';
        u2.LocaleSidKey = 'en_US';
        u2.EmailEncodingKey = 'UTF-8';
        u2.LanguageLocaleKey = 'en_US';
        insert u2;
        
        User u = new User();
        u.ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id;
        u.Username = 'test455455666@uiath.com';
        u.LastName = 'Test';
        u.Email = 'test455455666@uiath.com';
        u.Alias = 't4554556';
        u.TimeZoneSidKey = 'America/Los_Angeles';
        u.LocaleSidKey = 'en_US';
        u.EmailEncodingKey = 'UTF-8';
        u.LanguageLocaleKey = 'en_US';
        System.runAs(u) {
            insert newAccountParent;
        }
        
        Account newAccount = new Account();
        newAccount.Name = 'New Account';
        newAccount.BillingCountry = 'UNITED STATES';
        newAccount.BillingCountryCode ='US';
        newAccount.BillingState = 'California';
        newAccount.BillingStreet = 'High Street';
        newAccount.BillingCity = 'New City';
        newAccount.BillingPostalCode = '23233';
        newAccount.Phone = '847474666';
        newAccount.Industry = 'Energy';
        newAccount.Classification__c = 'KAP';
        newAccount.ParentId = newAccountParent.Id;
        System.runAs(u2) {
            insert newAccount;
        }

        Opportunity newOpportunity = new Opportunity();
        newOpportunity.Name = 'testOppName';
        newOpportunity.LeadSource = 'Partner';
        newOpportunity.Type = 'New Business';
        newOpportunity.AccountId = newAccount1.Id;
        newOpportunity.StageName = 'Discovery';
        newOpportunity.CloseDate = Date.today();
        newOpportunity.Discount_Approval_Status__c = 'In Approval';
        newOpportunity.Managing_Director__c = UserInfo.getUserId();
        //newOpportunity.Pricebook2Id = stdPriceBookRecId;
        newOpportunity.CurrencyIsoCode = 'USD';
        //newOpportunity.Customer_Primary_Contact__c = cnt.Id;
        newOpportunity.Onboard_customer_by_CS_Ops__c = 'No';

        // Run code
        Test.startTest();
            insert newOpportunity;
            
            Opportunity oppToUpdate = [SELECT Id, OwnerId FROM Opportunity WHERE Id =: newOpportunity.Id];
            oppToUpdate.OwnerId = u2.Id;
            update oppToUpdate;
            system.debug('oppToUpdate ======> ' + oppToUpdate);
        Test.stopTest();
        
        
    }
    
    static testMethod void TestCreateOTM2() {
        // Data setup
        Account newAccountParent1 = new Account();
        newAccountParent1.Name = 'Parent1 testAccName';
        newAccountParent1.BillingCountry = 'UNITED KINGDOM';
        newAccountParent1.BillingCountryCode ='GB';
        //newAccountParent1.BillingState = 'Cambridgeshire';
        newAccountParent1.BillingStreet = 'Test Street';
        newAccountParent1.BillingCity = 'Test City';
        newAccountParent1.BillingPostalCode = '123abc';
        newAccountParent1.Phone = '0721440000';
        newAccountParent1.Industry = 'Energy';
        insert newAccountParent1;
        
        Account newAccount1 = new Account();
        newAccount1.Name = 'testAccName1';
        newAccount1.BillingCountry = 'UNITED KINGDOM';
        newAccount1.BillingCountryCode ='GB';
        //newAccount1.BillingState = 'Cambridgeshire';
        newAccount1.BillingStreet = 'Test Street';
        newAccount1.BillingCity = 'Test City';
        newAccount1.BillingPostalCode = '123abc';
        newAccount1.Phone = '0721004400';
        newAccount1.Industry = 'Energy';
        newAccount1.Classification__c = 'KAP';
        newAccount1.Overwrite_Classification__c = true;
        newAccount1.RecordTypeId = customerRT;
        newAccount1.ParentId = newAccountParent1.Id;
        insert newAccount1;
        
        Account newAccountParent = new Account();
        newAccountParent.Name = 'Parent testAccName';
        newAccountParent.BillingCountry = 'UNITED STATES';
        newAccountParent.BillingCountryCode ='US';
        ////newAccountParent.BillingState = 'California';
        newAccountParent.BillingStreet = 'California Street';
        newAccountParent.BillingCity = 'CA';
        newAccountParent.BillingPostalCode = '299382';
        newAccountParent.Phone = '4847666';
        newAccountParent.Industry = 'Energy';
        
        User u2 = new User();
        u2.ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id;
        u2.Username = 'testother55666@uiath.com';
        u2.LastName = 'OtherTest';
        u2.Email = 'testother55666@uiath.com';
        u2.Alias = 'her55666';
        u2.TimeZoneSidKey = 'America/Los_Angeles';
        u2.LocaleSidKey = 'en_US';
        u2.EmailEncodingKey = 'UTF-8';
        u2.LanguageLocaleKey = 'en_US';
        insert u2;
        
        User u = new User();
        u.ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id;
        u.Username = 'test455455666@uiath.com';
        u.LastName = 'Test';
        u.Email = 'test455455666@uiath.com';
        u.Alias = 't4554556';
        u.TimeZoneSidKey = 'America/Los_Angeles';
        u.LocaleSidKey = 'en_US';
        u.EmailEncodingKey = 'UTF-8';
        u.LanguageLocaleKey = 'en_US';
        System.runAs(u) {
            insert newAccountParent;
        }
        
        Account newAccount = new Account();
        newAccount.Name = 'Random childRec';
        newAccount.BillingCountry = 'UNITED STATES';
        newAccount.BillingCountryCode ='US';
        newAccount.BillingState = 'California';
        newAccount.BillingStreet = 'Dunde Ave';
        newAccount.BillingCity = 'Wilkon';
        newAccount.BillingPostalCode = '332222';
        newAccount.Phone = '4412122';
        newAccount.Industry = 'Energy';
        newAccount.Classification__c = 'KAP';
        newAccount.ParentId = newAccountParent.Id;
        System.runAs(u2) {
            insert newAccount;
        }

        Opportunity newOpportunity = new Opportunity();
        newOpportunity.Name = 'testOppName';
        newOpportunity.LeadSource = 'Partner';
        newOpportunity.Type = 'New Business';
        newOpportunity.AccountId = newAccount1.Id;
        newOpportunity.StageName = 'Discovery';
        newOpportunity.CloseDate = Date.today();
        newOpportunity.Discount_Approval_Status__c = 'In Approval';
        newOpportunity.Managing_Director__c = UserInfo.getUserId();
        //newOpportunity.Pricebook2Id = stdPriceBookRecId;
        newOpportunity.CurrencyIsoCode = 'USD';
        //newOpportunity.Customer_Primary_Contact__c = cnt.Id;
        newOpportunity.Onboard_customer_by_CS_Ops__c = 'No';

        // Run code
        Test.startTest();
            insert newOpportunity;
            
            
            Opportunity oppToUpdate1 = [SELECT Id, OwnerId, Sold_to_Partner__c  FROM Opportunity WHERE Id =: newOpportunity.Id];
            oppToUpdate1.Sold_to_Partner__c = newAccount.Id;
            update oppToUpdate1;
            system.debug('oppToUpdate1 ======> ' + oppToUpdate1);
       Test.stopTest();
      

        
    }
    
    static testMethod void TestCreateOTM3() {
        // Data setup
        Account newAccountParent1 = new Account();
        newAccountParent1.Name = 'Parent1 testAccName';
        newAccountParent1.BillingCountry = 'UNITED KINGDOM';
        newAccountParent1.BillingCountryCode ='GB';
        //newAccountParent1.BillingState = 'Cambridgeshire';
        newAccountParent1.BillingStreet = 'Test Street';
        newAccountParent1.BillingCity = 'Test City';
        newAccountParent1.BillingPostalCode = '123abc';
        newAccountParent1.Phone = '0721440001';
        newAccountParent1.Industry = 'Energy';
        insert newAccountParent1;
        
        Account newAccount1 = new Account();
        newAccount1.Name = 'testAccName1';
        newAccount1.BillingCountry = 'UNITED KINGDOM';
        newAccount1.BillingCountryCode ='GB';
        //newAccount1.BillingState = 'Cambridgeshire';
        newAccount1.BillingStreet = 'Test Street';
        newAccount1.BillingCity = 'Test City';
        newAccount1.BillingPostalCode = '123abc';
        newAccount1.Phone = '0721004400';
        newAccount1.Industry = 'Energy';
        newAccount1.Classification__c = 'KAP';
        newAccount1.Overwrite_Classification__c = true;
        newAccount1.RecordTypeId = customerRT;
        newAccount1.ParentId = newAccountParent1.Id;
        insert newAccount1;
        
        Account newAccountParent = new Account();
        newAccountParent.Name = 'Parent testAccName';
        newAccountParent.BillingCountry = 'UNITED STATES';
        newAccountParent.BillingCountryCode ='US';
        ////newAccountParent.BillingState = 'California';
        newAccountParent.BillingStreet = 'Welcom Street';
        newAccountParent.BillingCity = 'Some City';
        newAccountParent.BillingPostalCode = '43432';
        newAccountParent.Phone = '3434333';
        newAccountParent.Industry = 'Energy';
        
        User u2 = new User();
        u2.ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id;
        u2.Username = 'testother55666@uiath.com';
        u2.LastName = 'OtherTest';
        u2.Email = 'testother55666@uiath.com';
        u2.Alias = 'her55666';
        u2.TimeZoneSidKey = 'America/Los_Angeles';
        u2.LocaleSidKey = 'en_US';
        u2.EmailEncodingKey = 'UTF-8';
        u2.LanguageLocaleKey = 'en_US';
        insert u2;
        
        User u = new User();
        u.ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id;
        u.Username = 'test454366@uiath.com';
        u.LastName = 'Test';
        u.Email = 'test454366@uiath.com';
        u.Alias = 't4554556';
        u.TimeZoneSidKey = 'America/Los_Angeles';
        u.LocaleSidKey = 'en_US';
        u.EmailEncodingKey = 'UTF-8';
        u.LanguageLocaleKey = 'en_US';
        System.runAs(u) {
            insert newAccountParent;
        }
        
        Account newAccount = new Account();
        newAccount.Name = 'testAccName';
        newAccount.BillingCountry = 'UNITED STATES';
        newAccount.BillingCountryCode ='US';
        newAccount.BillingState = 'California';
        newAccount.BillingStreet = 'Old Street';
        newAccount.BillingCity = 'Old City';
        newAccount.BillingPostalCode = '44433';
        newAccount.Phone = '454543334';
        newAccount.Industry = 'Energy';
        newAccount.Classification__c = 'KAP';
        newAccount.ParentId = newAccountParent.Id;
        System.runAs(u2) {
            insert newAccount;
        }

        Opportunity newOpportunity = new Opportunity();
        newOpportunity.Name = 'testOppName';
        newOpportunity.LeadSource = 'Partner';
        newOpportunity.Type = 'New Business';
        newOpportunity.AccountId = newAccount1.Id;
        newOpportunity.StageName = 'Discovery';
        newOpportunity.CloseDate = Date.today();
        newOpportunity.Discount_Approval_Status__c = 'In Approval';
        newOpportunity.Managing_Director__c = UserInfo.getUserId();
        //newOpportunity.Pricebook2Id = stdPriceBookRecId;
        newOpportunity.CurrencyIsoCode = 'USD';
        //newOpportunity.Customer_Primary_Contact__c = cnt.Id;
        newOpportunity.Onboard_customer_by_CS_Ops__c = 'No';
        newOpportunity.Sold_to_Partner__c = newAccount.Id;

        // Run code
        Test.startTest();
            insert newOpportunity;
            
             
            Opportunity oppToUpdate2 = [SELECT Id, OwnerId, Sold_to_Partner__c, Tier_2_Partner__c FROM Opportunity WHERE Id =: newOpportunity.Id];
            oppToUpdate2.Sold_to_Partner__c = null;
            oppToUpdate2.Tier_2_Partner__c  = newAccount.Id;
            update oppToUpdate2;
           
       Test.stopTest();
       
        
    }
    
    static testMethod void TestCreateOTM4() {
        // Data setup
        Account newAccountParent1 = new Account();
        newAccountParent1.Name = 'Parent1 fadf';
        newAccountParent1.BillingCountry = 'UNITED KINGDOM';
        newAccountParent1.BillingCountryCode ='GB';
        //newAccountParent1.BillingState = 'Cambridgeshire';
        newAccountParent1.BillingStreet = 'Main Street';
        newAccountParent1.BillingCity = 'Some City';
        newAccountParent1.BillingPostalCode = '123abc';
        newAccountParent1.Phone = '07214433001';
        newAccountParent1.Industry = 'Energy';
        insert newAccountParent1;
        
        Account newAccount1 = new Account();
        newAccount1.Name = 'testAccName1';
        newAccount1.BillingCountry = 'UNITED KINGDOM';
        newAccount1.BillingCountryCode ='GB';
        //newAccount1.BillingState = 'Cambridgeshire';
        newAccount1.BillingStreet = 'Test Street';
        newAccount1.BillingCity = 'Test City';
        newAccount1.BillingPostalCode = '123abc';
        newAccount1.Phone = '0721004400';
        newAccount1.Industry = 'Energy';
        newAccount1.Classification__c = 'KAP';
        newAccount1.Overwrite_Classification__c = true;
        newAccount1.RecordTypeId = customerRT;
        newAccount1.ParentId = newAccountParent1.Id;
        insert newAccount1;
        
        Account newAccountParent = new Account();
        newAccountParent.Name = 'Parent testAccName';
        newAccountParent.BillingCountry = 'UNITED STATES';
        newAccountParent.BillingCountryCode ='US';
        ////newAccountParent.BillingState = 'California';
        newAccountParent.BillingStreet = 'Test Street';
        newAccountParent.BillingCity = 'Test City';
        newAccountParent.BillingPostalCode = '123abc';
        newAccountParent.Phone = '0721000000';
        newAccountParent.Industry = 'Energy';
        
        User u2 = new User();
        u2.ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id;
        u2.Username = 'testother55666@uiath.com';
        u2.LastName = 'OtherTest';
        u2.Email = 'testother55666@uiath.com';
        u2.Alias = 'her55666';
        u2.TimeZoneSidKey = 'America/Los_Angeles';
        u2.LocaleSidKey = 'en_US';
        u2.EmailEncodingKey = 'UTF-8';
        u2.LanguageLocaleKey = 'en_US';
        insert u2;
        
        User u = new User();
        u.ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id;
        u.Username = 'test455455666@uiath.com';
        u.LastName = 'Test';
        u.Email = 'test455455666@uiath.com';
        u.Alias = 't4554556';
        u.TimeZoneSidKey = 'America/Los_Angeles';
        u.LocaleSidKey = 'en_US';
        u.EmailEncodingKey = 'UTF-8';
        u.LanguageLocaleKey = 'en_US';
        System.runAs(u) {
            insert newAccountParent;
        }
        
        Account newAccount = new Account();
        newAccount.Name = 'random thing';
        newAccount.BillingCountry = 'UNITED STATES';
        newAccount.BillingCountryCode ='US';
        newAccount.BillingState = 'California';
        newAccount.BillingStreet = 'TE Street';
        newAccount.BillingCity = 'N City';
        newAccount.BillingPostalCode = '123abc';
        newAccount.Phone = '838383';
        newAccount.Industry = 'Energy';
        newAccount.Classification__c = 'KAP';
        newAccount.ParentId = newAccountParent.Id;
        System.runAs(u2) {
            insert newAccount;
        }

        Opportunity newOpportunity = new Opportunity();
        newOpportunity.Name = 'testOppName';
        newOpportunity.LeadSource = 'Partner';
        newOpportunity.Type = 'New Business';
        newOpportunity.AccountId = newAccount1.Id;
        newOpportunity.StageName = 'Discovery';
        newOpportunity.CloseDate = Date.today();
        newOpportunity.Discount_Approval_Status__c = 'In Approval';
        newOpportunity.Managing_Director__c = UserInfo.getUserId();
        //newOpportunity.Pricebook2Id = stdPriceBookRecId;
        newOpportunity.CurrencyIsoCode = 'USD';
        //newOpportunity.Customer_Primary_Contact__c = cnt.Id;
        newOpportunity.Onboard_customer_by_CS_Ops__c = 'No';
        newOpportunity.Tier_2_Partner__c  = newAccount.Id;

        // Run code
        Test.startTest();
            insert newOpportunity;
    
            Opportunity oppToUpdate3 = [SELECT Id, OwnerId, Sold_to_Partner__c, Tier_2_Partner__c, Influencers__c FROM Opportunity WHERE Id =: newOpportunity.Id];
            oppToUpdate3.Influencers__c = String.valueOf(newAccount.Id);
            oppToUpdate3.Tier_2_Partner__c  = null;
            update oppToUpdate3;
            system.debug('oppToUpdate3 ======> ' + oppToUpdate3);
        
        Test.stopTest();
    }
    
 

    @isTest
    public static void testPartnerReseller()
    {
        Account acc1 = new Account (Name = 'AccName',
                                   BillingCountry ='France',
                                   BillingCity ='Paris',
                                   Industry = 'Others'
                                  );
        Account acc2 = new Account (Name = 'newAcc2',
                                   BillingCountry ='United States',
                                   Industry = 'Others'
                                  );
        Account acc3 = new Account (Name = 'newAcc3',
                                    BillingCountry ='Romania',
                                    Industry = 'Others'
                                   );
        Account acc4 = new Account (Name = 'newAcc4',
                                    BillingCountry ='China',
                                    Industry = 'Others'
                                   );
        insert new List<Account> { acc1, acc2 };

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
        System.runAs(u) {
            insert new List<Account> { acc3, acc4 };
        }

        Contact con = new Contact (AccountId = acc1.id,
                                   LastName = 'Test', Email = 'Test545734333@testemail.com',
                                   Department__c = 'IT'
                                  );
        insert con;

        Opportunity o = new Opportunity(Accountid = acc2.id,
                                        StageName = 'Discovery',
                                        CloseDate = system.today(),
                                        Name = 'Test Op',
                                        Type = 'Upsell',
                                        CurrencyIsoCode = 'EUR',
                                        Led_by__c = 'Direct',
                                        LeadSource = 'Partner',
                                        Tier_2_Partner__c = acc4.Id,
                                        Sold_To_Partner__c = acc3.Id,
                                        Influencers__c = String.valueOf(acc2.Id),
                                        Account_Name__c = 'AccName',
                                        Account_Country__c = 'France',
                                        Account_City__c = 'Paris'
                                        
                                       );
        insert o;
        
        
        
        Opportunity oppTest = [Select Id, Tier_2_Partner__c, Sold_To_Partner__c, Influencers__c 
                               From Opportunity
                               Where Id = :o.Id];
        System.debug('update Sold_to_Partner__c ======> ' + oppTest.Sold_to_Partner__c);
        System.debug('update Tier_2_Partner__c ======> ' + oppTest.Tier_2_Partner__c);
        System.debug('update Influencers__c ======> ' + oppTest.Influencers__c);
        

        oppTest.Tier_2_Partner__c = acc1.Id;
        oppTest.Sold_To_Partner__c = acc2.Id;
        oppTest.Influencers__c = String.valueOf(acc3.Id) + '; ' + String.valueOf(acc1.Id);
        
        test.startTest();
        update oppTest;
        
        
        System.debug('update Sold_to_Partner__c ======> ' + oppTest.Sold_to_Partner__c);
        System.debug('update Tier_2_Partner__c ======> ' + oppTest.Tier_2_Partner__c);
        System.debug('update Influencers__c ======> ' + oppTest.Influencers__c);
        test.stopTest();

      
    }
            
//    @isTest
//    public static void testSetDefaultValue4JP() {
//        //user
//         UserRole r;
//         try {
//             r = [SELECT Id FROM UserRole WHERE DeveloperName = 'Operations'];
//         } catch(Exception e) {
//             r = new UserRole();
//         }
//         User u1 = new User();
//         u1.ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id;
//         u1.Username = 'test839734@uiath.com';
//         u1.LastName = 'Test';
//         u1.Email = 'test839734@uiath.com';
//         u1.Alias = 't839734';
//         u1.TimeZoneSidKey = 'America/Los_Angeles';
//         u1.LocaleSidKey = 'en_US';
//         u1.EmailEncodingKey = 'UTF-8';
//         u1.LanguageLocaleKey = 'en_US';
//         u1.UserRoleId = r.Id;
//         insert u1;
       
//        String nowStr1 = String.valueOf(Datetime.now()).remove(':').remove(' ').remove('-') + '1';
       
//            Account u_acc = new Account(
//                Name = 'u_hogeAccount' + nowStr1,
//                Country__c = 'Japan',
//                ShippingCountry = 'Japan',
//                ShippingCountryCode = 'JP',
//                //ShippingState = 'Hiroshima',
//                //ShippingStateCode = 'HS',
//                NumberOfEmployees = 100,
//                Industry = 'Chemicals'
//            );
//        System.runAs(u1) {
//            insert u_acc;
       
//            u_acc.IsPartner = true;
//            update u_acc;
//        } 
//        Contact u_con = new Contact(
//            LastName = 'u_hogeContact' + nowStr1,
//            AccountId = u_acc.id,
//            Email = 'testemailcontact876@emailtest.com',
//            Department__c = 'IT'
//        );
//        System.runAs(u1) {
//            insert u_con;
//        }
//        String profileId;
//        String contactId;
//        try {
//         profileId = [SELECT Id, Name FROM Profile WHERE Name = 'UiPath Japan Partner Community' LIMIT 1].Id;
//         contactId = u_con.Id;
//        } catch(Exception e) {
//         profileId = UserInfo.getProfileId();
//        }
 
//        User u = new User(
//            Email = 'testCreByJP' + nowStr1 + '@example.com',
//            ProfileId = profileId,
//            UserName = 'testCreByJP' + nowStr1 + '@example.com',
//            Alias = 'testJP',
//            TimeZoneSidKey='Asia/Tokyo',
//            EmailEncodingKey='UTF-8',
//            LocaleSidKey='ja_JP',
//            LanguageLocaleKey='ja',
//            ContactId = contactId,
//            PortalRole = 'Manager',
//            FirstName = 'FirstName',
//            LastName = 'LastName'
//        );
//        insert u;
        
//        System.runAs(u) {
//            List<RecordType> rtList = [SELECT Id, DeveloperName FROM RecordType WHERE SObjectType = 'Opportunity' and DeveloperName = 'UiPath_Japan_Partner_standard' LIMIT 1];
//            if(!rtList.isEmpty()){
//                List<Opportunity> newList = new List<Opportunity>();
//                newList.add(new Opportunity(RecordTypeId = rtList.get(0).Id, Deal_Type__c = 'Managed Services'));
            
//                OpportunityTriggerHandlerAll handler = new OpportunityTriggerHandlerAll(newList, new Map<ID, Opportunity>());
            
//                handler.setDefaultValue4JP(newList);    
//            }
//        }
//     } 
    
    
    @isTest
    public static void OppRenewalSpecialistTest () {
        Account acc = new Account (
        Name = 'newAcc1',
        BillingCountry ='United Kingdom',
        Industry = 'Others'
        );
        insert acc;

        Contact con = new Contact (
        AccountId = acc.id,
        LastName = 'portalTestUser',
        Email = 'portalTestUser7777@testemail.com',
        Department__c = 'IT'
        );
        insert con;
        
         Contact conEconomic = new Contact (
        AccountId = acc.id,
        LastName = 'AEconomic Buyer',
        Email = 'EconomicBuyer7777@testemail.com',
        Department__c = 'IT'
        );
        insert conEconomic ;
        
         Contact conhampion = new Contact (
        AccountId = acc.id,
        LastName = 'AChampion Actual',
        Email = 'ChampionActual7777@testemail.com',
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
		u.Rev_Tech_Team__c = true;
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
		u2.Rev_Tech_Team__c = true;
        u2.LanguageLocaleKey = 'en_US';
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
        }

        List<Opportunity> opps = new List<Opportunity>();
        Map<Id, Opportunity> oppsMap = new  Map<Id, Opportunity>([SELECT Id, OwnerId, AccountId, Renewal_Specialist__c  FROM Opportunity WHERE Id =: o.Id LIMIT 1]);
        
        opps.add(o);
        
		System.runAs(u2){
        OppRenewalSpecialistQueueable q1 = new OppRenewalSpecialistQueueable(
                new List<SObject>{ o }, null
        );
        q1.execute(null);
        }
        List<OpportunityTeamMember> otm = [SELECT Id, UserId FROM OpportunityTeamMember WHERE OpportunityId =: o.Id AND TeamMemberRole = 'Renewal Specialist'];
        system.assertEquals(1, otm.size());
       
        Opportunity o2 = new Opportunity();
        o2.Id = o.Id;
        o2.Renewal_Specialist__c = null;
        update o2;

        System.runAs(u2){
        OppRenewalSpecialistQueueable q2 = new OppRenewalSpecialistQueueable(
                new List<Opportunity> { o2 }, oppsMap
        );
        q2.execute(null);
		}
        
        List<OpportunityTeamMember> otm2 = [SELECT Id, UserId FROM OpportunityTeamMember WHERE OpportunityId =: o.Id AND TeamMemberRole = 'Renewal Specialist'];
        system.assertEquals(0, otm2.size());
    }
}