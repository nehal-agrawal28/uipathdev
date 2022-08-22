@isTest
private class OpportunitySplitHandlerAllTest 
{   

   @isTest static void testOpportunitySplitUpdate() 
    {
        // Data Setup
        User u = DataFactory_SL.createUser('test1First1', 'Test1Last1', 'Standard User', true);
        User u1 = DataFactory_SL.createUser('test2First2', 'Test2Last2', 'Standard User', true);

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
        oppTeamMember1.TeamMemberRole = 'Partner Account Manager';
        insert oppTeamMember1;
        
        Opportunity_Split__c os1 = new Opportunity_Split__c();
        os1.User__c = u.Id;
        os1.Opportunity__c = opp.Id;
        os1.TeamMemberRole__c = 'Partner Account Manager';
        
        
        OpportunityTeamMember oppTeamMember2 = new OpportunityTeamMember();
        oppTeamMember2.UserId = u1.Id;
        oppTeamMember2.OpportunityId = opp.Id;
        oppTeamMember2.TeamMemberRole = 'Partner Account Manager';
        insert oppTeamMember2;
        
        Opportunity_Split__c os2 = new Opportunity_Split__c();
        os2.User__c = u1.Id;
        os2.Opportunity__c = opp.Id;
        os2.TeamMemberRole__c = 'Partner Account Manager';
        
        
        
        test.startTest();
            
            insert os1;
            List<Opportunity_Split__c> oppSplitList =
            [
                SELECT Id, Percentage__c
                FROM Opportunity_Split__c
                WHERE Opportunity__c = :opp.Id AND TeamMemberRole__c = 'Partner Account Manager' 
            ];
            system.debug('oppSplitList  =====>' + oppSplitList );
            System.assertEquals(100.0, oppSplitList[0].Percentage__c);
            
            insert os2;
            List<Opportunity_Split__c> oppSplitList2 =
            [
                SELECT Id, Percentage__c
                FROM Opportunity_Split__c
                WHERE Opportunity__c = :opp.Id AND TeamMemberRole__c = 'Partner Account Manager' AND  Percentage__c != 100.0
            ];
            system.debug('oppSplitList2  =====>' + oppSplitList2);
        test.stopTest();
         
    }
}