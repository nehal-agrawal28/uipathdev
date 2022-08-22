@isTest
private class CPQQuoteMatrixApprovalsTest {
    
    @TestSetup
    private static void createData(){
        Map<String, User> userMap = new Map<String, User>();
        User u1 = DataFactory_CM.createUser('Test', 'User 1', 'System Administrator', false);
        u1.UserRoleId = [SELECT Id FROM UserRole WHERE Name = 'AMER Inside Sales Director I'].Id;
        userMap.put('21-30% Approver', u1);

        User u2 = DataFactory_CM.createUser('Test', 'User 2', 'System Administrator', false);
        userMap.put('RCF Leader', u2);

        insert userMap.values();

        System.runAs(userMap.get('21-30% Approver')){

            Account testAccount = DataFactory_CM.createAccount(Constants.ACCOUNT_RECORD_TYPE_1, true);

            Opportunity testOpportunity = DataFactory_SL.createOpportunity(testAccount.Id, false);
            testOpportunity.Deal_Type__c = 'Direct';
            insert testOpportunity;

            Product2 prod = DataFactory_SL.createProduct(true);
            DataFactory_SL.createStdPricebookEntry(prod.Id, 20000, true);

            SBQQ__Quote__c quote = DataFactory_SL.createCPQQuote(testAccount.Id, testOpportunity.Id, true);
            SBQQ__QuoteLine__c line = DataFactory_SL.createCPQQuoteLine(prod.Id, quote.Id, true);

            List<Quote_Approval_Matrix__c> matrixList = new List<Quote_Approval_Matrix__c>();
            matrixList.add(
                DataFactory_SL.createQuoteApprovalMatrix('AMER', userMap.get('21-30% Approver').Id, 'Discount', 'AMER Inside Sales Director I', '', false)
            );
            matrixList.add(
                DataFactory_SL.createQuoteApprovalMatrix('AMER', userMap.get('RCF Leader').Id, 'Regional Commercial Finance Leader', '', '', false)
            );
            insert matrixList;
        }
    }

    //@isTest
    private static void testAutoApprovals(){
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        
        Test.startTest();

        quote.Total_List_Price_UiPath_Products__c  = 50000;
        quote.Total_Discount_UiPath_Products_List_Pric__c  = 5000;
        update quote;

        //* Submitted to CPQ Auto Approval v5
        // ( Deal Type=Direct, Total Discount UiPath Products < 20%)
        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
        req.setComments('Submitting request for approval.');
        req.setObjectId(quote.Id);
        
        //* Assign to step : Auto Approval 
        Approval.ProcessResult result = Approval.process(req);
        System.assertEquals(true, result.isSuccess(), 'Approval action failed');

        SBQQ__Quote__c approvedQuote = [SELECT Id, SBQQ__Status__c FROM SBQQ__Quote__c WHERE Id = :quote.Id];
        System.assertEquals('Approved', approvedQuote.SBQQ__Status__c, 'Quote status is not approved');
        
        Test.stopTest();
    }

    //@isTest
    private static void testAutoResaleApprovals(){
        SBQQ__Quote__c quote = [SELECT Id, SBQQ__Opportunity2__c FROM SBQQ__Quote__c LIMIT 1];
        Opportunity opp = new Opportunity(
            Id = quote.SBQQ__Opportunity2__c,
            Deal_Type__c = 'Resale'
        );
        update opp;
        
        Test.startTest();

        quote.De_bill_Re_bill__c = true;
        update quote;

        //* Submitted to CPQ Auto Approval Resale v1
        // ( Deal Type=Resale, De-bill/Re-bill=TRUE)
        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
        req.setComments('Submitting request for approval.');
        req.setObjectId(quote.Id);
        
        //* Assign to step : Auto Approval 
        Approval.ProcessResult result = Approval.process(req);
        System.assertEquals(true, result.isSuccess(), 'Approval action failed');

        SBQQ__Quote__c approvedQuote = [SELECT Id, SBQQ__Status__c FROM SBQQ__Quote__c WHERE Id = :quote.Id];
        System.assertEquals('Approved', approvedQuote.SBQQ__Status__c, 'Quote status is not approved');
        
        Test.stopTest();
    }

    //@isTest // for old approvals before FY22
    private static void testCOVIDFreeOfferApprovals(){
        SBQQ__Quote__c quote = [SELECT Id, SBQQ__Opportunity2__c, 
                                        (SELECT Id, SBQQ__ListPrice__c FROM SBQQ__LineItems__r) 
                                    FROM SBQQ__Quote__c LIMIT 1];
        for(SBQQ__QuoteLine__c line : quote.SBQQ__LineItems__r){
            line.SBQQ__Discount__c = 100;
        }
        update quote.SBQQ__LineItems__r;
        
        Opportunity opp = new Opportunity(
            Id = quote.SBQQ__Opportunity2__c,
            Deal_Type__c = 'COVID-19 Solidarity'
        );
        update opp;
        
        Test.startTest();

        quote.Bill_To_Geo_New__c = 'AMER';
        update quote;

        //* Submitted to COVID-19 Free Offer
        // ( Deal Type=COVID-19 Solidarity, Net Amount=0)
        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
        req.setComments('Submitting request for approval.');
        req.setObjectId(quote.Id);
        
        //* Assign to step : AMER Sales Geo Leaders Discount Approval 
        Approval.ProcessResult result = Approval.process(req);
        System.assertEquals(true, result.isSuccess(), 'Approval action failed');

        // Final approval
        Approval.ProcessResult result1 = approvalAction(quote.Id, 'Approve', 'Request approved.', result.getNewWorkitemIds());
        System.assertEquals(true, result1.isSuccess(), 'Approval action failed');

        SBQQ__Quote__c approvedQuote = [SELECT Id, SBQQ__Status__c FROM SBQQ__Quote__c WHERE Id = :quote.Id];
        System.assertEquals('Approved', approvedQuote.SBQQ__Status__c, 'Quote status is not approved');
        
        Test.stopTest();
    }

    //@isTest // for old approvals before FY22
    private static void testAMERApprovals(){
        Map<String, User> userMap = new Map<String, User>();
        for(User u : [SELECT Id, Name FROM User WHERE Name LIKE 'Test%']){
            if(u.Name == 'Test User 1'){
                userMap.put('21-30% Approver', u);
            }
            else if(u.Name == 'Test User 2'){
                userMap.put('RCF Leader', u);
            }
            
        }
        System.debug('userMap ==> ' + userMap);
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        
        Test.startTest();

        quote.Bill_To_Geo_New__c = 'AMER';
        quote.De_bill_Re_bill__c  = false;
        quote.Approved_Discount__c  = -1;
        // quote.Total_List_Price_UiPath_Products__c  = 50000;
        // quote.Total_Discount_UiPath_Products_List_Pric__c  = 40000;
        // quote.Total_Regular_Price_3rd_Party_Products__c   = 40000;
        // quote.Total_Discount_3rd_Party_Products_Curren__c   = 30000;
        quote.Total_List_Price_3rd_Party_Products__c   = 40000;
        quote.Total_Discount_3rd_Party_List_Price__c   = 30000;
        quote.Payment_Terms__c  = '90 Days Net';
        quote.SBQQ__SalesRep__c = userMap.get('21-30% Approver').Id;
        update quote;

        //* Submitted to AMER Approval Process v1
        // ( Geo=AMER, Total Discount UiPath Products > 20%, Total Discount 3rd Party Products (Reg) > 50% )
        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
        req.setComments('Submitting request for approval.');
        req.setObjectId(quote.Id);
        
        //* Assign to step : AMER Finance Payment Terms
        Approval.ProcessResult result = Approval.process(req);

        //* Assign to step : AVP Approval
        Approval.ProcessResult result1 = approvalAction(quote.Id, 'Approve', 'Request approved.', result.getNewWorkitemIds());
        System.assertEquals(true, result1.isSuccess(), 'Approval action failed');
        System.assertEquals(result1.getActorIds()[0], userMap.get('21-30% Approver').Id, '21-30% Approver is incorrect');

        //* Geo Leaders Discount Approval
        Approval.ProcessResult result2 = approvalAction(quote.Id, 'Approve', 'Request approved.', null);
        System.assertEquals(true, result2.isSuccess(), 'Approval action failed');

        //* CRO Discount Approval
        Approval.ProcessResult result3 = approvalAction(quote.Id, 'Approve', 'Request approved.', null);
        System.assertEquals(true, result3.isSuccess(), 'Approval action failed');

        //* Assign to step : Regional Commercial Finance Leader Pre Approval
        Approval.ProcessResult result4 = approvalAction(quote.Id, 'Approve', 'Request approved.', null);
        System.assertEquals(true, result4.isSuccess(), 'Approval action failed');
        System.assertEquals(result4.getActorIds()[0], userMap.get('RCF Leader').Id, 'Regional Commercial Finance Leader is incorrect');

        Approval.ProcessResult result5 = approvalAction(quote.Id, 'Approve', 'Request approved.', null);
        System.assertEquals(true, result5.isSuccess(), 'Approval action failed');

        // Final approval
        Approval.ProcessResult result6 = approvalAction(quote.Id, 'Approve', 'Request approved.', null);
        System.assertEquals(true, result6.isSuccess(), 'Approval action failed');

        SBQQ__Quote__c approvedQuote = [SELECT Id, SBQQ__Status__c FROM SBQQ__Quote__c WHERE Id = :quote.Id];
        System.assertEquals('Approved', approvedQuote.SBQQ__Status__c, 'Quote status is not approved');
        
        Test.stopTest();
    }

    //@isTest // for old approvals before FY22
    private static void testAMERResaleApprovals(){
        Map<String, User> userMap = new Map<String, User>();
        for(User u : [SELECT Id, Name FROM User WHERE Name LIKE 'Test%']){
            if(u.Name == 'Test User 1'){
                userMap.put('21-30% Approver', u);
            }
            else if(u.Name == 'Test User 2'){
                userMap.put('RCF Leader', u);
            }
            
        }
        System.debug('userMap ==> ' + userMap);
        SBQQ__Quote__c quote = [SELECT Id, SBQQ__Opportunity2__c, SBQQ__Account__c FROM SBQQ__Quote__c LIMIT 1];
        Opportunity opp = new Opportunity(
            Id = quote.SBQQ__Opportunity2__c,
            Deal_Type__c = 'Resale'
        );
        update opp;
        Account acc = new Account(
            Id = quote.SBQQ__Account__c,
            Geo__c = 'AMER'
        );
        update acc; 
        
        Test.startTest();

        quote.Bill_To_Geo_New__c = 'AMER';
        quote.De_bill_Re_bill__c  = false;
        quote.Approved_Discount__c  = -1;
        quote.Total_Discount_Premium_Care__c = 50;
        quote.Payment_Terms__c  = '90 Days Net';
        // quote.Total_Regular_Price_3rd_Party_Products__c   = 40000;
        // quote.Total_Discount_3rd_Party_Products_Curren__c   = 30000;
        quote.Total_List_Price_3rd_Party_Products__c   = 40000;
        quote.Total_Discount_3rd_Party_List_Price__c   = 30000;
        quote.SBQQ__SalesRep__c = userMap.get('21-30% Approver').Id;
        update quote;

        //* Submitted to AMER Resale Approval Process v1
        // ( Geo=AMER, Deal Type=Resale, Total Discount 3rd Party Products (Reg) > 50% )
        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
        req.setComments('Submitting request for approval.');
        req.setObjectId(quote.Id);
        
        //* Assign to step : AMER Finance Payment Terms
        Approval.ProcessResult result = Approval.process(req);

        //* Assign to step : AVP Approval
        Approval.ProcessResult result1 = approvalAction(quote.Id, 'Approve', 'Request approved.', result.getNewWorkitemIds());
        System.assertEquals(true, result1.isSuccess(), 'Approval action failed');
        System.assertEquals(result1.getActorIds()[0], userMap.get('21-30% Approver').Id, '21-30% Approver is incorrect');

        // Final Rejection
        Approval.ProcessResult result2 = approvalAction(quote.Id, 'Reject', 'Request Rejected.', null);
        System.assertEquals(true, result2.isSuccess(), 'Approval action failed');

        SBQQ__Quote__c rejectedQuote = [SELECT Id, SBQQ__Status__c FROM SBQQ__Quote__c WHERE Id = :quote.Id];
        System.assertEquals('Rejected', rejectedQuote.SBQQ__Status__c, 'Quote status is not rejected');
        
        Test.stopTest();
    }

    private static Approval.ProcessResult approvalAction(Id recId, String action, String comment, List<Id> workItemIds){
        System.debug('StepsAndWorkitems ==> ' + [SELECT Id, (SELECT Id, StepStatus, Comments FROM StepsAndWorkitems) FROM ProcessInstance]);
        System.debug('ProcessInstanceStep ==> ' + [SELECT Id, ActorId, StepNodeId, ProcessInstanceId, StepStatus FROM ProcessInstanceStep]);

        Approval.ProcessWorkitemRequest pReq =  new Approval.ProcessWorkitemRequest();
        pReq.setComments(comment);
        pReq.setAction(action);
        if(workItemIds == null){
            List<ProcessInstanceWorkitem> pItems = [SELECT Id FROM ProcessInstanceWorkitem 
                                                    WHERE ProcessInstance.TargetObjectId =:recId];
            System.debug('ProcessInstanceWorkitem ==> ' + pItems);
            pReq.setWorkitemId(pItems[0].Id);
        }
        else{
            pReq.setWorkitemId(workItemIds[0]);
        }
        Approval.ProcessResult pResult =  Approval.process(pReq);
        System.debug('pResult ==> ' + pResult);
        
        return pResult;
    }
}