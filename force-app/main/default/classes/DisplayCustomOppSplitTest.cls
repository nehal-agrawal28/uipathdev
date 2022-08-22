@isTest
private class DisplayCustomOppSplitTest {
	
	@isTest static void test_method_one() 
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

        Opportunity_Split__c oppSplit = new Opportunity_Split__c();
        oppSplit.User__c = oppTeamMember.UserId;
        oppSplit.Percentage__c = 75;
        oppSplit.Opportunity__c = opp.Id;
        oppSplit.Role__c = oppTeamMember.TeamMemberRole;
        insert oppSplit;

        Opportunity_Split__c oppSplit2 = new Opportunity_Split__c();
        oppSplit2.User__c = oppTeamMember2.UserId;
        oppSplit2.Percentage__c = 75;
        oppSplit2.Opportunity__c = opp.Id;
        oppSplit2.Role__c = oppTeamMember2.TeamMemberRole;
        insert oppSplit2;

        // Run Code
        Test.startTest();

            DisplayCustomOppSplitController ctrl = new DisplayCustomOppSplitController();

            ctrl.opportunityId = opp.Id;

            ctrl.DisplayCustomOppSplit();

            DisplayCustomOppSplitController.OppSplitWrapper wrapper = new DisplayCustomOppSplitController.OppSplitWrapper();

            ctrl.setOpportunityId(opp.Id);
            String oppIdString = ctrl.getOpportunityId();

        Test.stopTest();
        
	}		
}