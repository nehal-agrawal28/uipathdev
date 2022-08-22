/********************************************************************************************************
*    Name:  LeadChangeStatusTest.cls
*    Author: Mirela Chituc 
*    Date:  9/16/2019
*    
*    Test for ApexClass: LeadChangeStatus.cls
*
*    // Update status to Disqualified/Recycled and complete Reason for all selected leads      
********************************************************************************************************/
@IsTest(isParallel=true)
public class LeadChangeStatusTest {
    @testSetup
    private static void setup()
    {
        Profile standard = [Select Id from profile where Name = 'Standard User' LIMIT 1];
        User newUser = new User(profileId = standard.Id,username = 'testUser0@mail.com', email = 'pb@ff.com',
        emailencodingkey = 'UTF-8',localesidkey = 'en_US', languagelocalekey = 'en_US',
        timezonesidkey = 'America/Los_Angeles',alias='nuser',lastname='lastname', isactive = true);
        insert newUser;

        // create accounts
        List<Account> accounts = new List<Account>{
        new account(
                Name = 'Google',
                Website = 'www.google.com',
                BillingCountry ='United States',
                Industry = 'Technology', 
                ownerId = newUser.Id),
        new account(
                Name = 'Apple',
                Website = 'www.apple.com',
                BillingCountry ='Canada',
                Industry = 'Technology'),
        new account(
                Name = 'Facebook',
                BillingCountry ='United States',
                Industry = 'Technology') };
        insert accounts;

        //create leads
        List<Lead> leads = new List<Lead>{
            new Lead(
                LastName = 'Test',
                Company = 'Google',
                Country = 'United States',
                Industry = 'Insurance',
                Status='New',
                Email = 'joe@NOT.com'),
            new Lead(
                LastName = 'Test',
                Company = 'Apple',
                Country = 'United States',
                Industry = 'Insurance',
                Email = 'joe@apple.com',
                Status='New'),
            new Lead(
                LastName = 'Test',
                Company = 'Dummy',
                Country = 'United States',
                Industry = 'Insurance',
                Email = 'joe.test@test.com',
                Status='New')};


        //inserting three at a time to check bulk logic
        insert leads;
    }
    
    @isTest
    public static void testChangeStatus()
    {
        List<Lead> allNewLeads = [SELECT Id, Status FROM Lead];
        
        Test.startTest();
            ApexPages.StandardSetController setCon = new ApexPages.StandardSetController(allNewLeads);
            setCon.setSelected(allNewLeads);
            LeadChangeStatus changeStatusExtension  = new LeadChangeStatus(setCon);
            List<SelectOption> StatusValues = changeStatusExtension.getStatusPickListValues();
            List<SelectOption> DisqualifiedReasonValues = changeStatusExtension.getDisqualifiedPickListValues();
            List<SelectOption> RecycledReasonValues = changeStatusExtension.getRecycledPickListValues();
            changeStatusExtension.redirectToList();
            changeStatusExtension.leadStatus = 'Disqualified';
            changeStatusExtension.leadDisqualifiedReason = 'Student';
            changeStatusExtension.ChangeStatus();
            
            List<Lead> allChangedLeads = [SELECT Id, Status, Disqualified_Reason__c FROM Lead];
            for(Lead ld: allChangedLeads)
            {
                System.assertEquals('Disqualified', ld.Status);
                System.assertEquals('Student', ld.Disqualified_Reason__c);
            }
        Test.stopTest();
    }
}