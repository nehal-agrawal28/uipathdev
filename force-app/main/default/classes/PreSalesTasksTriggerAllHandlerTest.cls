@isTest
private class PreSalesTasksTriggerAllHandlerTest {
    static testMethod void setUsedEffortTest() {
        
        Account newAccount = new Account();
        newAccount.Name = 'Account New';
        newAccount.BillingCountry = 'UNITED KINGDOM';
        newAccount.Industry = 'Energy';
        insert newAccount;
        
        
        Opportunity newOpportunity = new Opportunity();
        newOpportunity.Name = 'Opportunity New';
        newOpportunity.LeadSource = 'Webinar';
        newOpportunity.Type = 'New Business';
        newOpportunity.AccountId = newAccount.Id;
        newOpportunity.StageName = 'Discovery';
        newOpportunity.CloseDate = (Date.today()).addMonths(-2);
        newOpportunity.Discount_Approval_Status__c = 'In Approval';
        newOpportunity.Managing_Director__c = UserInfo.getUserId();
        newOpportunity.Pricebook2Id = Test.getStandardPricebookId();
        newOpportunity.CurrencyIsoCode = 'USD';
        insert newOpportunity;
        
        
        List<Pre_Sales_Tasks__c> allPre_Sales_Tasks = new List<Pre_Sales_Tasks__c>();
        Id recordTypePST = Schema.SObjectType.Pre_Sales_Tasks__c.getRecordTypeInfosByName().get('Opportunity Tasks').getRecordTypeId();
        
        Pre_Sales_Tasks__c newPreSalesTask1 = new Pre_Sales_Tasks__c();
        newPreSalesTask1.Type__c = 'Workshop';
        newPreSalesTask1.Workshop_type__c = 'Process Directory';
        newPreSalesTask1.Delivery_Tag__c = 'UiPath Led - partner is absent';
        newPreSalesTask1.RecordTypeId = recordTypePST;
        newPreSalesTask1.Opportunity__c = newOpportunity.Id;
        newPreSalesTask1.Duration_in_hours__c = 1.5; 
        newPreSalesTask1.Customer_Contact_email__c = 'test1task@emailtask.com';
        newPreSalesTask1.Detailed_Description__c = 'description task 1';
        newPreSalesTask1.Due_Date__c = Date.Today().addDays(30);
        newPreSalesTask1.Products_in_Scope__c = 'Automation Cloud';
        newPreSalesTask1.Assignment_Type__c = 'Online';
        newPreSalesTask1.Has_an_NDA_been_signed__c = 'Yes';
        newPreSalesTask1.Customer_familiar_with_UiPath_tools_prod__c = 'Not familiar';
        newPreSalesTask1.Demo_Audience__c = 'Business';
        newPreSalesTask1.Request_Description__c = 'This is a test description';
        allPre_Sales_Tasks.add(newPreSalesTask1); 
        
        Pre_Sales_Tasks__c newPreSalesTask2 = new Pre_Sales_Tasks__c();
        newPreSalesTask2.Type__c = 'POC';
        newPreSalesTask2.Delivery_Tag__c = 'UiPath Led - partner is absent';
        newPreSalesTask2.RecordTypeId = recordTypePST;  
        newPreSalesTask2.Opportunity__c = newOpportunity.Id;
        newPreSalesTask2.Duration_in_hours__c = 5.2;
        newPreSalesTask2.Customer_Contact_email__c = 'test2task@emailtask.com'; 
        newPreSalesTask2.Detailed_Description__c = 'description task 2';
        newPreSalesTask2.Due_Date__c = Date.Today().addDays(20);
        newPreSalesTask2.Products_in_Scope__c = 'Automation Cloud';
        newPreSalesTask2.Assignment_Type__c = 'Online';
        newPreSalesTask2.Has_an_NDA_been_signed__c = 'Yes';
        newPreSalesTask2.Customer_familiar_with_UiPath_tools_prod__c = 'Not familiar';
        newPreSalesTask2.Demo_Audience__c = 'Business';
        newPreSalesTask2.Request_Description__c = 'This is a test description';
        allPre_Sales_Tasks.add(newPreSalesTask2); 
        
        Pre_Sales_Tasks__c newPreSalesTask3 = new Pre_Sales_Tasks__c();
        newPreSalesTask3.Type__c = 'Demo';
        newPreSalesTask3.Delivery_Tag__c = 'UiPath Led - partner is absent';
        newPreSalesTask3.RecordTypeId = recordTypePST;  
        newPreSalesTask3.Opportunity__c = newOpportunity.Id;
        newPreSalesTask3.Duration_in_hours__c = 3.1; 
        newPreSalesTask3.Customer_Contact_email__c = 'test3task@emailtask.com';
        newPreSalesTask3.Detailed_Description__c = 'description task 3';
        newPreSalesTask3.Due_Date__c = Date.Today().addDays(10);
        newPreSalesTask3.Products_in_Scope__c = 'Automation Cloud';
        newPreSalesTask3.Assignment_Type__c = 'Online';
        newPreSalesTask3.Has_an_NDA_been_signed__c = 'Yes';
        newPreSalesTask3.Customer_familiar_with_UiPath_tools_prod__c = 'Not familiar';
        newPreSalesTask3.Demo_Audience__c = 'Business';
        newPreSalesTask3.Request_Description__c = 'This is a test description';
        allPre_Sales_Tasks.add(newPreSalesTask3); 
        
        Test.setMock(HttpCalloutMock.class, new WrikeServiceMock());
        test.StartTest();
            
            insert allPre_Sales_Tasks; 
            List<Account> acc = [SELECT Id, Name, Used_Effort__c FROM Account WHERE Name = 'Account New' LIMIT 1];
            System.AssertEquals(9.80, acc[0].Used_Effort__c); 
            
            List<Pre_Sales_Tasks__c> allPreSales = [SELECT Id, Duration_in_hours__c FROM Pre_Sales_Tasks__c];
            for(Pre_Sales_Tasks__c pst: allPreSales) 
                pst.Duration_in_hours__c = 4.1;
            update allPreSales;
            
            List<Account> acc1 = [SELECT Id, Name, Used_Effort__c FROM Account WHERE Name = 'Account New' LIMIT 1];
            System.AssertEquals(12.3, acc1[0].Used_Effort__c); 
            
            List<Pre_Sales_Tasks__c> allPreSales1 = [SELECT Id, Duration_in_hours__c FROM Pre_Sales_Tasks__c];
            delete allPreSales1[0]; 
            
            List<Account> acc2 = [SELECT Id, Name, Used_Effort__c FROM Account WHERE Name = 'Account New' LIMIT 1];
            System.AssertEquals(8.2, acc2[0].Used_Effort__c);  
        test.StopTest();
        
        
            
    }
}