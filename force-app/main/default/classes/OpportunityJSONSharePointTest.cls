@isTest 
private class OpportunityJSONSharePointTest {    

    @isTest
    static void testHttpPost() {
        // prepare test-data
        Account newAccount = new Account();
        newAccount.Name = 'Account  ';
        newAccount.BillingCountry = 'UNITED STATES';
        newAccount.Industry = 'Energy';
        
        insert newAccount;
        
        Contact newContact = new Contact(
                LastName = 'contRec1',
                AccountId = newAccount.Id,
                Email = 'contRec.Test11@emailDomain.com',
                Department__c = 'IT'
                );
        insert newContact;
        
        Opportunity newOpportunity = new Opportunity();
        newOpportunity.Name = 'Opportunity  ';
        newOpportunity.Type = 'New Business';
        newOpportunity.Deal_Type__c = 'Direct';
        newOpportunity.LeadSource = 'Webinar';
        newOpportunity.AccountId = newAccount .Id;
        newOpportunity.StageName = 'Discovery';
        newOpportunity.CloseDate = (Date.today()).addMonths(-2);
        newOpportunity.Discount_Approval_Status__c = 'In Approval';
        newOpportunity.Managing_Director__c = UserInfo.getUserId();
        newOpportunity.Pricebook2Id = Test.getStandardPricebookId();
        newOpportunity.CurrencyIsoCode = 'USD';
        newOpportunity.Total_Contact_Roles__c = 1;
        insert newOpportunity;
        
        //create contact role
        OpportunityContactRole ocr = new OpportunityContactRole();
        ocr.OpportunityId = newOpportunity.Id;
        ocr.ContactId = newContact.Id;
        ocr.Role = 'Business User';
        insert ocr;

        Product2 product= new Product2();
        product.Name = 'UIPath - Attended Robot - test 2';
        product.Is_Add_On__c = false;
        product.IsActive = true;
        product.Add_On_Percent__c = 10;
        product.License_Model__c = 'N/A';
        product.Unit_of_measure__c = 'N/A';
        product.Family = 'Core Product';
        product.CPQ_Exclusive__c = true;
        product.Ext_Id__c='testProductName0220';
        product.ProductCode='testProductName0220';
        insert product;
        
        Product2 producta = new Product2();
        producta.Name = 'UIPath - Unattended Robot - test 3';
        producta.Is_Add_On__c = false;
        producta.IsActive = true;
        producta.Add_On_Percent__c = 10;
        producta.License_Model__c = 'N/A';
        producta.Unit_of_measure__c = 'N/A';
        producta.Family = 'Core Product';
        producta.CPQ_Exclusive__c = true;
        producta.Ext_Id__c='testProductName0240';
        producta.ProductCode='testProductName0220';
        insert producta;
        
        PricebookEntry pbe = new PricebookEntry();
        pbe.Product2Id = product.Id;
        pbe.Pricebook2Id = Test.getStandardPricebookId();
        pbe.UnitPrice = 2000;
        pbe.IsActive = true;
        pbe.CurrencyIsoCode = 'USD';
        insert pbe;
        
        List<OpportunityLineItem> allOLI = new List<OpportunityLineItem>();  
        
        OpportunityLineItem oli  = new OpportunityLineItem();
        oli.OpportunityId = newOpportunity.Id;
        oli.UnitPrice = 700;
        oli.Quantity = 10;
        oli.PricebookEntryId = pbe.Id;
        oli.Discount = 25;
        oli.Add_On_For__c = null;
        oli.ServiceDate = Date.today().addMonths(-1);
        oli.Effective_Start_Date__c = Date.today().addMonths(-1);
        oli.End_Date__c = Date.today().addMonths(3);
        oli.Product2Id = product.Id;
        oli.Product_Version__c = '2019.4';
        insert oli;

          
        List<Opportunity> updateOpp1 = new List<Opportunity>();
        List<Opportunity> updateOpp = [SELECT Id, CloseDate, StageName FROM Opportunity];
        for(Opportunity o: updateOpp){
            Date d = Date.today();
            o.StageName = 'Closed Won Booked';
            o.Contract_Start_Date__c = (Date.Today()).addMonths(-1);
            o.Contract_End_Date__c = (Date.Today()).addMonths(9);
            o.Competition__c = 'Blue Prism';
            o.Reason_1__c = 'Technical features';
            o.Reason_2__c = 'CoE enablement strategy';
            o.Reason_3__c = 'Product roadmap';
            o.Closeout_Reason__c ='test123 test123 test123 test123';
            o.Features_the_customer_liked_didn_t_like__c ='test99 test123 test123 test99';
            o.Total_Contact_Roles__c = 1;
            o.FinanceReviewReached__c = true;
            
            updateOpp1.add(o);
        }
        update updateOpp1;
        
        //As Per Best Practice it is important to instantiate the Rest Context
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/SharePointOpportunityData'; //Request URL
        req.httpMethod = 'POST';
        
        RestContext.request = req;
        RestContext.request.addParameter('opportunityid',newOpportunity.Id);
        RestContext.response= res;
    
        Test.startTest();
            OpportunityJSONSharePoint.ProductsWrapper prod = new OpportunityJSONSharePoint.ProductsWrapper();
            prod.Name = 'Test';
            prod.quantity = '3';
            OpportunityJSONSharePoint.OpportunityWrapper actual = new OpportunityJSONSharePoint.OpportunityWrapper();
            actual.id = '222';
            actual.accountName = 'ascacas';
            actual.revenue = 344;
            actual.acccurrency = 'USD';
            actual.revenueScore = 44;
            actual.customerStage = 'aaa';
            actual.customerScore = 3;
            actual.usedEffort = 4;
            actual.recommendedEffort = 3;
            actual.industry = 'cadsfvsfv';
            actual.industryScore = 6;
            actual.employeeScore = 4;
            actual.orders = 3;
            actual.ordersize = 2;
            actual.lastOrderDate = '1243443';
        
            OpportunityJSONSharePoint.OpportunityWrapper actual1 = OpportunityJSONSharePoint.getOpportunityJSONSharePoint();
        Test.stopTest();
        System.debug('actual ' + actual);
    
        //System.assertEquals('expected value', actual, 'Value is incorrect');
    }
}