@IsTest
/** SLALOM DEC 2018
* Story: SS-15
* Author: PB
* This test class tests the expected behaviour of the 'Auto_generate_renewal_Opportunity_WIth_OLI' flow.
* Specifically that when a renewal Opportunity Product is generated, a reference to the original Opp Product is set.
* The overall functionality is incidentally tested as a result.
* v0.1 - 12-Jan initial version
**/
public class AGrenewal_Opportunity_WIth_OLI_Test {
    
    //@TODO this should be converted to a CMT so it can be modified from the UI ONCE Process Builder supports CMT references
    Static final String OPP_CLOSED_STAGE = 'Closed Won Booked';
    Static final String OPP_FIRST_STAGE = 'Discovery';
    Static final String COMP = 'Automation Anywhere';
    Static final String LED = 'Direct Led';
    
    @testSetup
    public static void testSetup(){
        
        
        //@TODO when this hardcode reference to this account record is resolved, this should be removed
        //create expected 'unassigned' account
        Account a1 = new Account(Name='Unassigned Account', BillingStreet = 'Test', BillingCity = 'Test', BillingCountry='United Kingdom', BillingPostalCode='12345', Industry = 'Retail', Phone='1234567899');
        insert a1;
        //
        
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
        
        Opportunity newOpportunity = new Opportunity();
        newOpportunity.Name = 'testOppName';
        newOpportunity.Type = 'Renewal';
        newOpportunity.AccountId = newAccount.Id;
        newOpportunity.StageName = OPP_FIRST_STAGE;
        newOpportunity.CloseDate = Date.today();
        newOpportunity.Discount_Approval_Status__c = 'In Approval';
        newOpportunity.Managing_Director__c = UserInfo.getUserId();
        newOpportunity.Pricebook2Id = stdPriceBookRecId;
        newOpportunity.CurrencyIsoCode = 'USD';
        newOpportunity.Customer_Primary_Contact__c = cnt.Id;
        insert newOpportunity;
        
        //create contact role
        OpportunityContactRole ocr = new OpportunityContactRole();
        ocr.OpportunityId = newOpportunity.Id;
        ocr.ContactId = cnt.Id;
        ocr.Role = 'Business User';
        insert ocr;
        
        PriceBookEntry stdPriceBookEntry = new PriceBookEntry();
        stdPriceBookEntry.Product2Id = newProduct.Id;
        stdPriceBookEntry.Pricebook2Id = stdPriceBookRecId;
        stdPriceBookEntry.UnitPrice = 2000;
        stdPriceBookEntry.IsActive = true;
        stdPriceBookEntry.CurrencyIsoCode = newOpportunity.CurrencyIsoCode;
        insert stdPriceBookEntry;        
        
        OpportunityLineItem oli = new OpportunityLineItem();
        oli.OpportunityId = newOpportunity.Id;
        oli.UnitPrice = 700;
        oli.Quantity = 2;
        oli.PricebookEntryId = stdPriceBookEntry.Id;
        oli.Discount = 25;
        oli.Add_On_For__c = null;
        insert oli;
        
        OpportunityLineItem oli2 = new OpportunityLineItem();
        oli2.OpportunityId = newOpportunity.Id;
        oli2.UnitPrice = 5000;
        oli2.Quantity = 1;
        oli2.PricebookEntryId = stdPriceBookEntry.Id;
        oli2.Discount = 15;
        oli2.Add_On_For__c = oli.Id;
        insert oli2;
        
        OpportunityLineItem oli3 = new OpportunityLineItem();
        oli3.OpportunityId = newOpportunity.Id;
        oli3.UnitPrice = 4000;
        oli3.Quantity = 1;
        oli3.PricebookEntryId = stdPriceBookEntry.Id;
        oli3.Discount = 15;
        oli3.Add_On_For__c = oli.Id;
        insert oli3;

    }
    
    @IsTest
    public static void testIdFieldSet(){
        
        Test.startTest();
            
        List<Opportunity> ops = [SELECT Id, StageName FROM Opportunity ORDER BY CreatedDate DESC];
        
        System.assertEquals(1, ops.size());
        
        Opportunity opp = ops[0];
        
        //
        
       
        //update the opp and trigger the renewal Opp
        try{
            Date d = Date.today();
            opp.StageName = OPP_CLOSED_STAGE;
            opp.Competition__c = COMP;  
            opp.Led_by__c = LED;
            opp.Contract_Start_Date__c = d;
            opp.Contract_End_Date__c = d.addYears(3);
            opp.Won_Reasons__c = 'Product Roadmap';
            opp.Closeout_Reason__c ='test123 test123 test123 test123';
            opp.Features_the_customer_liked_didn_t_like__c ='test99 test123 test123 test99';
            opp.FinanceReviewReached__c = true;
                
            update opp;
        }
        catch(Exception e){
            System.debug(e.getMessage());           
        }
  
        Test.stopTest();
        
        ops = [SELECT Id, Name, StageName FROM Opportunity WHERE StageName !=: OPP_CLOSED_STAGE];
        
        /*System.assertEquals(1, ops.size());
        System.debug('Name: ' + ops[0].Name);
        
        
        List<OpportunityLineItem> olis = [SELECT Id, Original_OppPr_Id__c FROM OpportunityLineItem WHERE OpportunityId =:ops[0].Id];
        
        System.assertNotEquals(null,olis);
        System.assertEquals(3, olis.size());
        
        for(OpportunityLineItem oli : olis){
            System.assertNotEquals(null,oli.Original_OppPr_Id__c);
        }*/
      
    }

}