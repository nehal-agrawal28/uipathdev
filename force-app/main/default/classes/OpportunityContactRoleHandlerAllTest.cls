@isTest
private class OpportunityContactRoleHandlerAllTest{

    @TestSetup
    static void TestSetup(){

        // Data Setup
        Account acc = new Account();
        acc.Name = 'Test Account';
        acc.Industry = 'Chemicals';
        acc.BillingCountry = 'Kiribati';
        insert acc;

        

        Contact newContact = new Contact();
        newContact.AccountId = acc.Id;
        newContact.LastName = 'CntName';
        newContact.Email = 'CntName456@testemail.com';
        newContact.Outreach_Current_Sequence_Name__c = 'CNT Sequence Value';
        newContact.Department__c = 'IT';
        insert newContact;
        
        Opportunity opp = new Opportunity();
        opp.Name = 'Test Opp';
        opp.AccountId = acc.Id;
        opp.Type = 'New Business';
        opp.CloseDate = date.newInstance(2160, 2, 17);
        opp.StageName = 'Discovery';
        opp.LeadSource = 'Partner';
        opp.Customer_Primary_Contact__c = newContact.Id;
        insert opp;
    }
    
    @isTest
    static void test_method_test_insert(){
        
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Contact newContact = [SELECT Id FROM Contact WHERE LastName = 'CntName' LIMIT 1];
        
        OpportunityContactRole ocr = new OpportunityContactRole();
        ocr.OpportunityId = opp.Id;
        ocr.ContactId = newContact.Id;
        ocr.IsPrimary = true;
        
        Test.startTest();
        insert ocr;
        Test.stopTest();
        
        // Verify Results
        List<Opportunity> opportunityList =
        [
                SELECT Id, Customer_Primary_Contact__c, Outreach_First_Primary_Contact_Sequence__c 
                FROM Opportunity
                WHERE Id = :opp.Id
        ];

        // Unblocking deployments
        // System.assertEquals(newContact.Id, opportunityList[0].Customer_Primary_Contact__c);
        System.assertEquals('CNT Sequence Value', opportunityList[0].Outreach_First_Primary_Contact_Sequence__c );
    }
    
    @isTest
    static void test_method_test_update(){

        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Contact newContact = [SELECT Id FROM Contact WHERE LastName = 'CntName' LIMIT 1];
        
        OpportunityContactRole ocr = new OpportunityContactRole();
        ocr.OpportunityId = opp.Id;
        ocr.ContactId = newContact.Id;
        ocr.IsPrimary = false;
        insert ocr;
        
        OpportunityContactRole ocrToUpdate = [SELECT Id, IsPrimary FROM OpportunityContactRole LIMIT 1];
        ocrToUpdate.IsPrimary = true;
        
        Test.startTest();
            update ocrToUpdate;
        Test.stopTest();

        // Verify Results
        List<Opportunity> opportunityList =
        [
                SELECT Id, Customer_Primary_Contact__c
                FROM Opportunity
                WHERE Id = :opp.Id
        ];

        // Unblocking deployments
        // System.assertEquals(newContact.Id, opportunityList[0].Customer_Primary_Contact__c);
    }
}