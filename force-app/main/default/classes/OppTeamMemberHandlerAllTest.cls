@isTest
private class OppTeamMemberHandlerAllTest 
{   
    @isTest static void test_method_one() 
    {
        // Data Setup
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
        User u = new User(Alias = 'stadeut', Email='deutoriatestusername@testorg.com', 
            EmailEncodingKey='UTF-8', LastName='deutLastName', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='deutoriatestusername@testorg.com');

        insert u;

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
        opp.LeadSource = 'Advertisement';
        insert opp;

        OpportunityTeamMember oppTeamMember1 = new OpportunityTeamMember();
        oppTeamMember1.UserId = u.Id;
        oppTeamMember1.OpportunityId = opp.Id;
        oppTeamMember1.TeamMemberRole = 'Sales Representative';
        insert oppTeamMember1;

        Opportunity_Split__c oppSplit = new Opportunity_Split__c();
        oppSplit.User__c = u.Id;
        oppSplit.Opportunity__c = opp.Id;
        insert oppSplit;

        // Check the current count of oppTeamMembers and oppSplits before running the after delete trigger
        List<OpportunityTeamMember> oppTeamMemberList =
            [
                SELECT Id
                FROM OpportunityTeamMember
                WHERE OpportunityId = :opp.Id
            ];

        List<Opportunity_Split__c> oppSplitList =
            [
                SELECT Id
                FROM Opportunity_Split__c
                WHERE Opportunity__c = :opp.Id
            ];

      
        // Run Code
        Test.startTest();            

            oppTeamMember1.TeamMemberRole = 'Partner Account Manager';
            update oppTeamMember1;

            delete oppTeamMember1;

        Test.stopTest();

        // Verify Results
        // Check the count of oppTeamMembers and oppSplits after running the after delete trigger
        oppTeamMemberList =
            [
                SELECT Id
                FROM OpportunityTeamMember
                WHERE OpportunityId = :opp.Id
            ];

        oppSplitList =
            [
                SELECT Id
                FROM Opportunity_Split__c
                WHERE Opportunity__c = :opp.Id
            ];

        //System.assertEquals(1, oppTeamMemberList.size());
        //System.assertEquals(0, oppSplitList.size());
    }
    
    @isTest static void test_method_two() 
    {
        // Data Setup
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
        User u = new User(Alias = 'stadeut', Email='deutoriatestusername@testorg.com', 
            EmailEncodingKey='UTF-8', LastName='deutLastName', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='deutoriatestusername@testorg.com');

        insert u;

        Account acc = new Account();
        acc.Name = 'testAccName';
        acc.Industry = 'Healthcare';
        acc.BillingCountry = 'India';
        insert acc;

        Opportunity opp = new Opportunity();
        opp.StageName = 'Close Won';
        opp.CloseDate = Date.today();
        opp.Type = 'Upsell';
        opp.AccountId = acc.Id;
        opp.Name = 'testOppName';
        opp.LeadSource = 'Advertisement';
        insert opp;

        OpportunityTeamMember oppTeamMember1 = new OpportunityTeamMember();
        oppTeamMember1.UserId = u.Id;
        oppTeamMember1.OpportunityId = opp.Id;
        oppTeamMember1.TeamMemberRole = 'Partner Account Manager';
        insert oppTeamMember1;
        
        List<OpportunityTeamMember> oppTeamMemberList =
            [
                SELECT Id, TeamMemberRole 
                FROM OpportunityTeamMember
                WHERE ID = :oppTeamMember1.Id
            ];
        
        Test.startTest();            

            oppTeamMemberList[0].TeamMemberRole = 'Sales Representative';
            update oppTeamMemberList;

        Test.stopTest();
        

        // Check the current count of oppTeamMembers and oppSplits before running the after delete trigger
        

        List<Opportunity_Split__c> oppSplitList =
            [
                SELECT Id
                FROM Opportunity_Split__c
                WHERE Opportunity__c = :opp.Id
            ];

        
        System.debug('oppSplitList ====> ' + oppSplitList );
        //System.assertEquals(1, oppTeamMemberList.size());
        //System.assertEquals(0, oppSplitList.size());
    }
    
    @isTest static void test_method_three() 
    {
        // Data Setup
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
        User u = new User(Alias = 'stadeut', Email='deutoriatestusername@testorg.com', 
            EmailEncodingKey='UTF-8', LastName='deutLastName', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='deutoriatestusername@testorg.com');

        insert u;

        Account acc = new Account();
        acc.Name = 'testAccName';
        acc.Industry = 'Healthcare';
        acc.BillingCountry = 'Japan';
        acc.BillingState = 'Aichi';
        insert acc;

        Opportunity opp = new Opportunity();
        opp.StageName = 'Close Won';
        opp.CloseDate = Date.today();
        opp.Type = 'Upsell';
        opp.AccountId = acc.Id;
        opp.Name = 'testOppName';
        opp.LeadSource = 'Advertisement';
        insert opp;

        OpportunityTeamMember oppTeamMember1 = new OpportunityTeamMember();
        oppTeamMember1.UserId = u.Id;
        oppTeamMember1.OpportunityId = opp.Id;
        oppTeamMember1.TeamMemberRole = 'Sales Representative';
        insert oppTeamMember1;
        
        List<OpportunityTeamMember> oppTeamMemberList =
            [
                SELECT Id, TeamMemberRole, Opportunity.Account_Geo__c
                FROM OpportunityTeamMember
                WHERE Id = :oppTeamMember1.Id
            ];
        
        Test.startTest();            

            oppTeamMemberList[0].TeamMemberRole = 'Partner Account Manager';
            update oppTeamMemberList;

        Test.stopTest();
    }
    
     @isTest static void test_method_four() 
    {
        // Data Setup
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
        User u = new User(Alias = 'stadeut', Email='deutoriatestusername@testorg.com', 
            EmailEncodingKey='UTF-8', LastName='deutLastName', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='deutoriatestusername@testorg.com');

        insert u;

        Account acc = new Account();
        acc.Name = 'testAccName';
        acc.Industry = 'Healthcare';
        acc.BillingCountry = 'Japan';
        acc.BillingState = 'Aichi';
        insert acc;

        Opportunity opp = new Opportunity();
        opp.StageName = 'Close Won';
        opp.CloseDate = Date.today();
        opp.Type = 'Upsell';
        opp.AccountId = acc.Id;
        opp.Name = 'testOppName';
        opp.LeadSource = 'Advertisement';
        insert opp;

        OpportunityTeamMemberQueueable q1 = new OpportunityTeamMemberQueueable(
                new List<SObject>{ opp }, null
        );
        q1.execute(null);
        
        List<OpportunityTeamMember> oppTeamMemberList =
            [
                SELECT Id, TeamMemberRole, Opportunity.Account_Geo__c
                FROM OpportunityTeamMember
                WHERE TeamMemberRole = 'Opportunity owner'
            ];
        
        Test.startTest();            

            delete oppTeamMemberList;

        Test.stopTest();
    }
    
    @isTest static void test_method_five() 
    {
        // Data Setup
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
        User u = new User(Alias = 'stadeut', Email='deutoriatestusername@testorg.com', 
            EmailEncodingKey='UTF-8', LastName='deutLastName', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='deutoriatestusername@testorg.com');

        insert u;

        Account acc = new Account();
        acc.Name = 'testAccName';
        acc.Industry = 'Healthcare';
        acc.BillingCountry = 'India';
        insert acc;

        Opportunity opp = new Opportunity();
        opp.StageName = 'Close Won';
        opp.CloseDate = Date.today();
        opp.Type = 'Upsell';
        opp.AccountId = acc.Id;
        opp.Name = 'testOppName';
        opp.LeadSource = 'Advertisement';
        insert opp;

        OpportunityTeamMember oppTeamMember1 = new OpportunityTeamMember();
        oppTeamMember1.UserId = u.Id;
        oppTeamMember1.OpportunityId = opp.Id;
        oppTeamMember1.TeamMemberRole = 'Partner Account Manager';
        insert oppTeamMember1;

        List<Opportunity> opps = new List<Opportunity>();
        Map<Id, Opportunity> oppsMap = new  Map<Id, Opportunity>([SELECT Id, OwnerId FROM Opportunity WHERE Id =: opp.Id LIMIT 1]);
        
        Opportunity o2 = new Opportunity();
        o2.Id = opp.Id;
        o2.OwnerId = u.id;
        update o2;
        
        OpportunityTeamMemberQueueable q1 = new OpportunityTeamMemberQueueable(
                new List<SObject>{ o2 }, oppsMap
        );
        q1.execute(null);
    }
}