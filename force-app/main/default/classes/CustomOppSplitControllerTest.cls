@isTest
private class CustomOppSplitControllerTest 
{	
    @isTest static void newVersionTestMethod() 
    {
        // Data Setup
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 

        User u = new User(Alias = 'standt', Email='standarduser@testorg.com', 
            EmailEncodingKey='UTF-8', LastName='TestingDeutoria', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='standarduser@deutoria.com');

        insert u;
        
        Profile p1 = [SELECT Id FROM Profile WHERE Name='Lead Development']; 

        User u1 = new User(Alias = 'standt', Email='admin@testorg.com', 
            EmailEncodingKey='UTF-8', LastName='TestingDeutoria1', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='admin@deutoria.com');

        insert u1;

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

        // Run Code
        Test.startTest();

            ApexPages.StandardController sc = new ApexPages.StandardController(opp);
            CustomOppSplitController ctrl = new CustomOppSplitController(sc);

            ctrl.LoadTableData();        	
        
            OpportunityTeamMember oppTeamMember = new OpportunityTeamMember();
            oppTeamMember.UserId = u.Id;
            oppTeamMember.TeamMemberRole = 'Sales Representative';
            oppTeamMember.OpportunityId = opp.Id;
            insert oppTeamMember;

            OpportunityTeamMember oppTeamMember2 = new OpportunityTeamMember();
            oppTeamMember2.UserId = u1.Id;
            oppTeamMember2.OpportunityId = opp.Id;
            oppTeamMember2.TeamMemberRole = 'Sales Representative';
            insert oppTeamMember2;

            ctrl.LoadTableData();
            ctrl.RequestApproval();

            // in order to get the splits to pass the 125% warning logic
            List<Opportunity_Split__c> oppSplitList =
                [
                    SELECT Id, Percentage__c, User__c, Opportunity__c, User__r.Name
                    FROM Opportunity_Split__c
                    WHERE Opportunity__c = :opp.Id
                ];
			
            for(Opportunity_Split__c oppSplit : oppSplitList)
            {
                oppSplit.Percentage__c = 90;                
            }
			
            update oppSplitList;

            ctrl.LoadTableData();
            ctrl.UpdateFieldsInfo();        	


        Test.stopTest();

        // Verify Result
        oppSplitList =
            [
                SELECT Id, Percentage__c, User__c, Opportunity__c, User__r.Name
                FROM Opportunity_Split__c
                WHERE Opportunity__c = :opp.Id
            ];

        //System.assertEquals(3, oppSplitList.size());
    }
}