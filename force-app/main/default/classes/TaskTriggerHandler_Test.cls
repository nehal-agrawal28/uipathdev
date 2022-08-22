@isTest 
private class TaskTriggerHandler_Test {

    
    public static testMethod void CustomerOnboardedTestTask(){
        // Data setup
        Account newAccount = new Account();
        newAccount.Name = 'testAccName';
        newAccount.BillingCountry = 'UNITED STATES';
        newAccount.BillingCountryCode ='US';
        newAccount.BillingState = 'California';
        newAccount.BillingStreet = 'Test Street';
        newAccount.BillingCity = 'Test City';
        newAccount.BillingPostalCode = '123abc';
        newAccount.Phone = '0721000000';
        newAccount.Industry = 'Energy';
        insert newAccount;

        Contact cnt = new Contact();
        cnt.LastName = 'Test545734';
        cnt.AccountId = newAccount.Id;
        cnt.Email ='test@test.com';
        cnt.Title = 'titlename';
        cnt.Department__c = 'IT';
        insert cnt;

        Id stdPriceBookRecId = Test.getStandardPricebookId();

        Product2 newProduct = new Product2();
        newProduct.Name = 'testProductName';
        newProduct.Is_Add_On__c = false;
        newProduct.IsActive = true;
        newProduct.Add_On_Percent__c = 10;
        newProduct.License_Model__c = 'N/A';
        newProduct.Unit_of_measure__c = 'N/A';
        newProduct.Ext_Id__c='testProductName100';
        newProduct.ProductCode='testProductName100';
        newProduct.Family='Other';

        insert newProduct;
        
         Id recordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Deal Registration').getRecordTypeId();

        Opportunity newOpportunity = new Opportunity();
        newOpportunity.RecordTypeId = recordTypeId;
        newOpportunity.Name = 'testOppName';
        newOpportunity.Type = 'Renewal';
        newOpportunity.AccountId = newAccount.Id;
        newOpportunity.StageName = 'Discovery';
        newOpportunity.CloseDate = Date.today();
        newOpportunity.Discount_Approval_Status__c = 'In Approval';
        newOpportunity.Managing_Director__c = UserInfo.getUserId();
        newOpportunity.Pricebook2Id = stdPriceBookRecId;
        newOpportunity.CurrencyIsoCode = 'USD';
        newOpportunity.Customer_Primary_Contact__c = cnt.Id;
        newOpportunity.Onboard_customer_by_CS_Ops__c = 'No';
        insert newOpportunity;

        //create contact role
        OpportunityContactRole ocr = new OpportunityContactRole();
        ocr.OpportunityId = newOpportunity.Id;
        ocr.ContactId = cnt.Id;
        ocr.Role = 'Business User';
        insert ocr;
        
        Opportunity oppty = [SELECT Id, OwnerId, StageName, Competition__c, Led_by__c, Contract_Start_Date__c,Won_Reasons__c, Reason_1__c, Reason_2__c, Reason_3__c,
            Closeout_Reason__c, Features_the_customer_liked_didn_t_like__c, FinanceReviewReached__c, Customer_Onboarding__c 
            FROM Opportunity WHERE Id =: newOpportunity.Id LIMIT 1];
        
        
        try{
            Date d = Date.today();
            oppty.StageName  = 'Closed Won Booked';
            oppty.Competition__c = 'Automation Anywhere';
            oppty.Led_by__c = 'Direct Led';
            oppty.Contract_Start_Date__c = d;
            oppty.Contract_End_Date__c = d.addYears(3);
            oppty.Won_Reasons__c = 'Product Roadmap';
            oppty.Closeout_Reason__c ='test123 test123 test123 test123';
            oppty.Features_the_customer_liked_didn_t_like__c ='test99 test123 test123 test99';
            oppty.FinanceReviewReached__c = true;
            oppty.Customer_Onboarding__c = true;

            update oppty;
        }
        catch(Exception e){
            System.debug('OpportunityRenewalCreationTest - testCreateRenewalOpportunity: Closing opportunity failed: '
                             + e.getMessage());
        }
        
         Id onboardingPlaybookRT = SObjectType.Task.getRecordTypeInfosByName().get('Onboarding Playbook').getRecordTypeId();
        Task newTask = new Task(
            Subject = 'Onboarding 100 - Survey', 
            WhatId = oppty.Id, 
            ActivityDate = (Date.Today()).addDays(100), 
            Priority = 'Normal',
            Status = 'Open',
            RecordTypeId = onboardingPlaybookRT,
            Last_Onboarding_Task__c = true
        );
        insert newTask;
        
        List<Task> allTasks = [SELECT Id, Status FROM Task WHERE WhatId = :newOpportunity.Id AND Last_Onboarding_Task__c = true];
        system.debug('allTasks =====>' + allTasks);
        for(Task t: allTasks)
            t.Status = 'Completed';
            
        Test.startTest();
            update allTasks;
        Test.stopTest();
        
        List<Opportunity> OPPs = [SELECT Id, Customer_Onboarded__c, AccountId, Account.Customer_Onboarded__c FROM Opportunity];
        for(Opportunity opp: OPPs) {
            System.AssertEquals('Onboarding completed', opp.Customer_Onboarded__c);
            System.AssertEquals('Onboarding completed', opp.Account.Customer_Onboarded__c);
        }
        
    }
    
    public static testMethod void TestTask(){
    
 
        // create an account
List<Account> a = new List<Account>{  new account(
        Name = 'Test Account',
        BillingCountry ='United Kingdom',
        Industry = 'Manufacturing') };
        
        insert a;
        
        // create a task
List<task> t = new List<task>{  new task(        
        WhatID = a[0].id,
        Group_Task_Id__c = 'abcdefghij123',
        Primary_Group_Task__c = '',
        Subject = 'Test Task',
        Status = 'Open') };
        
        insert t;
 
List<task> taskstoupdate = New List<task>{ [select Id from task where Id in :t]};  
       for(task tOK:taskstoupdate)      
        tOK.status = 'Completed';
        
        try {
    Update taskstoupdate;
  } catch (system.Dmlexception e) {
    system.debug('***problem updating task***');
    System.assertEquals('',e.getMessage()+e.getStacktraceString());

  }
                 
        
    }
}