@isTest
private class OpportunitySplitsBatchTest
{   

   @isTest static void testOpportunitySplitInsert() 
    {
        User u = DataFactory_SL.createUser('testFirst1', 'TestLast1', 'Standard User', true);
        User u1 = DataFactory_SL.createUser('testFirst2', 'TestLast2', 'Standard User', true);

        Account acc = new Account();
        acc.Name = 'testAccName';
        acc.Industry = 'Healthcare';
        acc.BillingCountry = 'Algeria';
        insert acc;

        Opportunity opp = new Opportunity();
        opp.StageName = 'Discovery';
        opp.CloseDate = Date.today();
        opp.Type = 'Upsell';
        opp.AccountId = acc.Id;
        opp.Name = 'testOppName';
        opp.LeadSource = 'Advertisement';
        insert opp;
        
        List<OpportunityTeamMember> insertOTM = new List<OpportunityTeamMember>();
        
        OpportunityTeamMember oppTeamMember1 = new OpportunityTeamMember();
        oppTeamMember1.UserId = u.Id;
        oppTeamMember1.OpportunityId = opp.Id;
        oppTeamMember1.TeamMemberRole = 'Inside Sales Representative';
        insertOTM.add(oppTeamMember1);

        OpportunityTeamMember oppTeamMember2 = new OpportunityTeamMember();
        oppTeamMember2.UserId = u1.Id;
        oppTeamMember2.OpportunityId = opp.Id;
        oppTeamMember2.TeamMemberRole = 'Sales Representative';
        insertOTM.add(oppTeamMember2);
        
        insert insertOTM;
        
        List<Opportunity_Split__c> oppSplitList =
            [
                SELECT Id, Percentage__c, TeamMemberRole__c
                FROM Opportunity_Split__c
                WHERE Opportunity__c = :opp.Id AND TeamMemberRole__c != 'Opportunity Owner'
            ];
        
        delete oppSplitList;

        test.startTest();
            OpportunitySplitsBatch  osBatchObject = new OpportunitySplitsBatch(); 
            Id batchId = Database.executeBatch(osBatchObject, 1);            
        test.stopTest();
        
        List<Opportunity_Split__c> oppSplitList2 =
            [
                SELECT Id, Percentage__c, TeamMemberRole__c
                FROM Opportunity_Split__c
                WHERE Opportunity__c = :opp.Id AND TeamMemberRole__c != 'Opportunity Owner'
            ];
        
        system.assertEquals(2, oppSplitList2.size()); 
    }
}