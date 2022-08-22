@isTest
private class TaskTriggerAllHandlerTest {
    /*static testMethod void setUpContactStatusTest() {
        Account accRec = new Account(
                Name = 'Account name',
                BillingCountryCode = 'US',
                BillingCountry = 'United States',
                BillingStateCode = 'SD',
                Industry = 'Others',
                Legal__c = 'Legal Name',
                DNBoptimizer__DNB_D_U_N_S_Number__c = '1234567',
                Default_Payment_Terms__c = '30 Days Net',
                Primary_Subsidiary__c = 'UiPath SRL',
                Channel_Tier__c = 'Reseller');
        insert accRec;
        
        
        
        // create a Lead
        Lead lead=new Lead(LastName='Doe', FirstName='John', Country='United States', Company='Test', Status='New', Email='john.doe@testwjoe.com');
        insert lead;                
        
        Database.LeadConvert lc = new database.LeadConvert();
        lc.setLeadId(lead.id);
        lc.setAccountId(accRec.Id);
        lc.setDoNotCreateOpportunity(false);
        lc.setConvertedStatus('Qualified');
        
        Database.LeadConvertResult lcr = Database.convertLead(lc);
        System.assert(lcr.isSuccess());
        
        // create a Lead
        Lead lead1 = new Lead(LastName='Doe1', FirstName='John1', Country='United States', Company='Test', Status='New', Email='john.doe@testjoe.com');
        insert lead1;                
        
        Database.LeadConvert lc1 = new database.LeadConvert();
        lc1.setLeadId(lead1.id);
        lc1.setAccountId(accRec.Id);
        lc1.setDoNotCreateOpportunity(false);
        lc1.setConvertedStatus('Qualified');
        
        Database.LeadConvertResult lcr1 = Database.convertLead(lc1);
        System.assert(lcr1.isSuccess());
        
        Task t = new Task();
        t.OwnerId = UserInfo.getUserId();
        t.WhoId = lead.Id;
        t.Subject='Donni';
        t.Status='Not Started';
        t.Priority='Normal';
     
       
        test.StartTest();
            insert t;  
            
            Contact c = [SELECT Id, Contact_Status__c  FROM Contact WHERE LastName='Doe' LIMIT 1];
            System.AssertEquals('Actively Engaged', c.Contact_Status__c); 
            
            Task t1 = [SELECT Id, WhoId FROM Task LIMIT 1];
            t1.WhoId = lead1.Id;
            update t1;
            
            Contact c1 = [SELECT Id, Contact_Status__c  FROM Contact WHERE LastName='Doe1' LIMIT 1];
            System.AssertEquals('Actively Engaged', c1.Contact_Status__c);
            
            delete t;   
        test.StopTest();
        
        Contact c2 = [SELECT Id, Contact_Status__c  FROM Contact WHERE LastName='Doe' LIMIT 1];
        System.AssertEquals('Converted from Lead', c2.Contact_Status__c);
         
    }*/
}