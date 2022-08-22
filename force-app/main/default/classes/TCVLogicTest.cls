@IsTest
/** SLALOM DEC 2018
* Story: SS-13
* Author: PB
* This test class tests the expected behaviour of the TCV Opportunity Product field and associated logic.
* v0.1 - 12-Dec initial version
* v0.2 - 15-Dec more cases added
* v0.3 - 16-Dec final set of cases added
* v0.4 - 17-Dec split some
**/

public class TCVLogicTest {

    Static final String PAYMENT_CYCLE_UPFRONT = 'Upfront';
    Static final String PAYMENT_CYCLE_ANNUAL = 'Annual';
    Static final String TERMINATION_CLAUSE_YES = 'Yes';
    Static final String TERMINATION_CLAUSE_NO = 'No';
    Static final Date CONTRACT_START_DATE = Date.newInstance(2020, 01, 01);
    Static final Date CONTRACT_END_DATE = Date.newInstance(2020, 12, 31);
    Static final Date MYD_CONTRACT_END_DATE = Date.newInstance(2023, 12, 31);
    Static final Integer CONTRACT_DURATION = 20;
    static final boolean INVOICED = true;
    static final String OPP_FINAL_STAGE = 'Closed Won Booked';
    Static final String COMP = 'Automation Anywhere';
    Static final String LED = 'Direct Led';


    //@TODO this should be converted to a CMT so it can be modified from the UI ONCE Process Builder supports CMT references
    static final String FINANCE_REVIEW_STATUS = 'Finance Review';

    @testSetup
    public static void testSetup(){

         //create Account
        Account a = new Account(Name='Test Account',
                                BillingStreet = 'Test',
                                BillingCity = 'Test',
                                PO_mandatory__c = 'Yes',
                                Courier__c = 'No',
                                Platform__c = 'No',
                                BillingCountry='United Kingdom',
                                BillingPostalCode='12345',
                                Industry = 'Retail',
                                Phone='1234567899',
                                VAT_Number__c = '123424243344334' );
        insert a;

        Contact c = new Contact(LastName = 'Test', AccountId = a.Id, Department__c = 'IT');

        insert c;

        //@TODO when this hardcode reference to this account record is resolved, this should be removed
        //create expected 'unassigned' account
        Account a1 = new Account(Name='Unassigned Account', BillingStreet = 'Test', BillingCity = 'Test', BillingCountry='United Kingdom', BillingPostalCode='12345', Industry = 'Retail', Phone='1234567899');
        insert a1;
        //

        Date d = Date.today();

        //create Opp
        Opportunity o = new Opportunity(AccountId=a.Id,
                Type = 'New Business',
                Name = 'Test',
                StageName = 'Discovery',
                CloseDate = d,
                CurrencyIsoCode='USD',
                LeadSource='Call Inbound');

        insert o;

        OpportunityContactRole opptyCR = new OpportunityContactRole();
        opptyCR.OpportunityId = o.Id;
        opptyCR.ContactId = c.Id;
        opptyCR.Role = 'Business User';

        insert opptyCR;

        Id stdPriceBookRecId = Test.getStandardPricebookId();


        Product2 newProduct = new Product2();
        newProduct.Name = 'testProductName';
        newProduct.Is_Add_On__c = false;
        newProduct.IsActive = true;
        newProduct.Add_On_Percent__c = 10;
        newProduct.License_Model__c = 'N/A';
        newProduct.Unit_of_measure__c = 'N/A';
        newProduct.Ext_Id__c='testProductName200';
        newProduct.ProductCode='testProductName200';
        newProduct.Family='Other';

        insert newProduct;



        PriceBookEntry stdPriceBookEntry = new PriceBookEntry();
        stdPriceBookEntry.Product2Id = newProduct.Id;
        stdPriceBookEntry.Pricebook2Id = stdPriceBookRecId;
        stdPriceBookEntry.UnitPrice = 2000;
        stdPriceBookEntry.IsActive = true;
        stdPriceBookEntry.CurrencyIsoCode = o.CurrencyIsoCode;
        insert stdPriceBookEntry;

        OpportunityLineItem oli = new OpportunityLineItem();
        oli.OpportunityId = o.Id;
        oli.UnitPrice = 700;
        oli.Quantity = 2;
        oli.PricebookEntryId = stdPriceBookEntry.Id;
        oli.Discount = 25;
        oli.Add_On_For__c = null;
        oli.Product_Version__c = '2017.1';
        insert oli;

        OpportunityLineItem oli2 = new OpportunityLineItem();
        oli2.OpportunityId = o.Id;
        oli2.UnitPrice = 5000;
        oli2.Quantity = 1;
        oli2.PricebookEntryId = stdPriceBookEntry.Id;
        oli2.Discount = 15;
        oli2.Add_On_For__c = oli.Id;
        oli.Product_Version__c = '2017.1';
        insert oli2;

        OpportunityLineItem oli3 = new OpportunityLineItem();
        oli3.OpportunityId = o.Id;
        oli3.UnitPrice = 4000;
        oli3.Quantity = 1;
        oli3.PricebookEntryId = stdPriceBookEntry.Id;
        oli3.Discount = 15;
        oli3.Add_On_For__c = oli.Id;
        oli.Product_Version__c = '2017.1';
        insert oli3;

        Id FinanceCaseRt = null;

        try{
            FinanceCaseRt = [SELECT Id FROM RecordType WHERE Name = 'Finance Request' AND SobjectType = 'Case' LIMIT 1].Id;
        }
        catch(Exception e){
            System.debug('Suspected prerequisite RT missing: ' +e.getMessage());
            throw(e);

        }

        //create case
        if(FinanceCaseRt != null){

            Case ca = new Case(AccountId = a.Id, RecordTypeId = FinanceCaseRt, Status = 'New', Opportunity__c = o.Id);

            insert ca;

        }

    }

    //@IsTest
    /**
* Tests conditions that should set TCV Alt Mode to True
**/
    /*public static void testTCVAltModeTrue(){



        //check intial record counts
        List<Account> accs = [SELECT Id FROM Account WHERE Name != 'Unassigned Account'];

        System.assertEquals(1, accs.size());

        List<Opportunity> ops = [SELECT Id, Invoiced__c, AccountId FROM Opportunity];

        System.assertEquals(1, ops.size());

        Opportunity opp = ops[0];

        List<Case> cases = [SELECT Id, RecordTypeId, Status, Opportunity__c, Invoiced__c FROM Case];

        System.assertEquals(1, cases.size());

        Case financeCase = cases[0];
        //


        //validate initial opp state
        System.assert(opp.Invoiced__c == false);

        System.assertEquals(opp.AccountId, accs[0].Id);
        //

        //validate initial case state
        Id FinanceCaseRt = null;

        try{
            FinanceCaseRt = [SELECT Id FROM RecordType WHERE Name = 'Finance Request' AND SobjectType = 'Case' LIMIT 1].Id;
        }
        catch(Exception e){
            System.debug('Suspected prerequisite RT missing: ' +e.getMessage());
        }

        if(FinanceCaseRt != null){
            System.assertEquals(FinanceCaseRt, financeCase.RecordTypeId);

        }

        System.assertEquals('New', financeCase.Status);

        System.assertEquals(opp.Id, financeCase.Opportunity__c);
        //
        //
        //opp.StageName = OPP_FINAL_STAGE;
        opp.Competition__c = COMP;
        opp.Led_by__c = LED;
        opp.Reason_1__c = 'Technical features';
        opp.Reason_2__c = 'CoE enablement strategy';
        opp.Reason_3__c = 'Product roadmap';
        opp.Closeout_Reason__c ='test123 test123 test123 test123';
        opp.Features_the_customer_liked_didn_t_like__c ='test99 test123 test123 test99';

        update opp;

        //Set case driver fields
        financeCase.Invoiced__c = INVOICED;
        financeCase.Invoice_Amount__c = 100;
        financeCase.Billing_Entity__c = accs[0].Id;
        financeCase.Status = FINANCE_REVIEW_STATUS;
        financeCase.Payment_Cycle__c = PAYMENT_CYCLE_ANNUAL;
        financeCase.Termination_Clause__c = TERMINATION_CLAUSE_NO;
        financeCase.Contract_Start_Date__c = CONTRACT_START_DATE;
        financeCase.Contract_End_Date__c = MYD_CONTRACT_END_DATE;

 		Test.startTest();
        update financeCase;
        Test.stopTest();

        //re-query opp
        ops = [SELECT Id, Invoiced__c, AccountId, Payment_Cycle__c, Termination_Clause__c, Contract_Start_Date__c, Contract_End_Date__c, StageName FROM Opportunity WHERE StageName =: OPP_FINAL_STAGE];

        System.assertEquals(1, ops.size());

        opp = ops[0];

        List<OpportunityLineItem> olis = [SELECT Id, Payment_Cycle__c, Contract_Start_Date__c, Contract_Duration_Days__c, TCV_Alt_Mode__c
                                   FROM OpportunityLineItem
                                   WHERE OpportunityId =: opp.Id];

        System.assertEquals(3, olis.size());

        //assert the legal case driver fields have populated the opp receiver fields
        //System.assertEquals(INVOICED, opp.Invoiced__c);
        System.assertEquals(OPP_FINAL_STAGE, opp.StageName);
        System.assertEquals(PAYMENT_CYCLE_ANNUAL, opp.Payment_Cycle__c);
        System.assertEquals(TERMINATION_CLAUSE_NO, opp.Termination_Clause__c);
        System.assertEquals(CONTRACT_START_DATE, opp.Contract_Start_Date__c);
        System.assertEquals(MYD_CONTRACT_END_DATE, opp.Contract_End_Date__c);
    }*/

    //@IsTest
    /**
    * Tests conditions that should leave TCV Alt Mode false
    **/
    /*public static void testTCVAltModeFalse1_Single_Year_Deal(){
        //check intial record counts
        List<Account> accs = [SELECT Id FROM Account WHERE Name != 'Unassigned Account'];
        System.assertEquals(1, accs.size());

        List<Opportunity> ops = [SELECT Id, Invoiced__c, AccountId FROM Opportunity];
        System.assertEquals(1, ops.size());

        Opportunity opp = ops[0];
        List<Case> cases = [SELECT Id, RecordTypeId, Status, Opportunity__c, Invoiced__c FROM Case];
        System.assertEquals(1, cases.size());

        Case financeCase = cases[0];

        System.assert(opp.Invoiced__c == false);
        System.assertEquals(opp.AccountId, accs[0].Id);

        //validate initial case state
        Id FinanceCaseRt = null;

        try{
            FinanceCaseRt = [SELECT Id FROM RecordType WHERE Name = 'Finance Request' AND SobjectType = 'Case' LIMIT 1].Id;
        }
        catch(Exception e){
            System.debug('Suspected prerequisite RT missing: ' +e.getMessage());
        }

        if(FinanceCaseRt != null){
            System.assertEquals(FinanceCaseRt, financeCase.RecordTypeId);

        }

        System.assertEquals('New', financeCase.Status);
        System.assertEquals(opp.Id, financeCase.Opportunity__c);

        opp.Competition__c = COMP;
        opp.Led_by__c = LED;
        opp.Reason_1__c = 'Technical features';
        opp.Reason_2__c = 'CoE enablement strategy';
        opp.Reason_3__c = 'Product roadmap';
        opp.Closeout_Reason__c ='test123 test123 test123 test123';
        opp.Features_the_customer_liked_didn_t_like__c ='test99 test123 test123 test99';

        update opp;

        //Set case driver fields
        financeCase.Invoiced__c = INVOICED;
        financeCase.Invoice_Amount__c = 100;
        financeCase.Billing_Entity__c = accs[0].Id;
        financeCase.Status = FINANCE_REVIEW_STATUS;
        financeCase.Payment_Cycle__c = PAYMENT_CYCLE_ANNUAL;
        financeCase.Termination_Clause__c = TERMINATION_CLAUSE_NO;
        financeCase.Contract_Start_Date__c = CONTRACT_START_DATE;
        financeCase.Contract_End_Date__c = CONTRACT_END_DATE;

 		Test.startTest();
        update financeCase;
        Test.stopTest();

        //re-query opp
        ops = [SELECT Id, Invoiced__c, AccountId, Payment_Cycle__c, Termination_Clause__c, Contract_Start_Date__c, Contract_End_Date__c, StageName FROM Opportunity WHERE StageName =: OPP_FINAL_STAGE];

        System.assertEquals(1, ops.size());

        opp = ops[0];

        List<OpportunityLineItem> olis = [SELECT Id, Payment_Cycle__c, Contract_Start_Date__c, Contract_Duration_Days__c, TCV_Alt_Mode__c
                                   FROM OpportunityLineItem
                                   WHERE OpportunityId =: opp.Id];

        System.assertEquals(3, olis.size());
        //assert the legal case driver fields have populated the opp receiver fields
        System.assertEquals(OPP_FINAL_STAGE, opp.StageName);
        System.assertEquals(PAYMENT_CYCLE_ANNUAL, opp.Payment_Cycle__c);
        System.assertEquals(TERMINATION_CLAUSE_NO, opp.Termination_Clause__c);
        System.assertEquals(CONTRACT_START_DATE, opp.Contract_Start_Date__c);
        System.assertEquals(CONTRACT_END_DATE, opp.Contract_End_Date__c);
    }*/

    //@IsTest
    /**
* Tests conditions that should leave TCV Alt Mode false
**/
   /* public static void testTCVAltModeFalse2_PaymentCycleUpfront(){
        //check intial record counts
        List<Account> accs = [SELECT Id FROM Account WHERE Name != 'Unassigned Account'];

        System.assertEquals(1, accs.size());

        List<Opportunity> ops = [SELECT Id, Invoiced__c, AccountId FROM Opportunity];

        System.assertEquals(1, ops.size());

        Opportunity opp = ops[0];

        List<Case> cases = [SELECT Id, RecordTypeId, Status, Opportunity__c, Invoiced__c FROM Case];

        System.assertEquals(1, cases.size());

        Case financeCase = cases[0];
        //


        //validate initial opp state
        System.assert(opp.Invoiced__c == false);

        System.assertEquals(opp.AccountId, accs[0].Id);
        //

        //validate initial case state
        Id FinanceCaseRt = null;

        try{
            FinanceCaseRt = [SELECT Id FROM RecordType WHERE Name = 'Finance Request' AND SobjectType = 'Case' LIMIT 1].Id;
        }
        catch(Exception e){
            System.debug('Suspected prerequisite RT missing: ' +e.getMessage());
        }

        if(FinanceCaseRt != null){
            System.assertEquals(FinanceCaseRt, financeCase.RecordTypeId);

        }

        System.assertEquals('New', financeCase.Status);

        System.assertEquals(opp.Id, financeCase.Opportunity__c);
        //
        //
        //opp.StageName = OPP_FINAL_STAGE;
        opp.Competition__c = COMP;
        opp.Led_by__c = LED;
        opp.Reason_1__c = 'Technical features';
        opp.Reason_2__c = 'CoE enablement strategy';
        opp.Reason_3__c = 'Product roadmap';
        opp.Closeout_Reason__c ='test123 test123 test123 test123';
        opp.Features_the_customer_liked_didn_t_like__c ='test99 test123 test123 test99';

        update opp;

        //Set case driver fields
        financeCase.Invoiced__c = INVOICED;
        financeCase.Invoice_Amount__c = 100;
        financeCase.Billing_Entity__c = accs[0].Id;
        financeCase.Status = FINANCE_REVIEW_STATUS;
        financeCase.Payment_Cycle__c = PAYMENT_CYCLE_UPFRONT;
        financeCase.Termination_Clause__c = TERMINATION_CLAUSE_NO;
        financeCase.Contract_Start_Date__c = CONTRACT_START_DATE;
        financeCase.Contract_End_Date__c = MYD_CONTRACT_END_DATE;

 		Test.startTest();
        update financeCase;
        Test.stopTest();

        //re-query opp
        ops = [SELECT Id, Invoiced__c, AccountId, Payment_Cycle__c, Termination_Clause__c, Contract_Start_Date__c, Contract_End_Date__c, StageName FROM Opportunity WHERE StageName =: OPP_FINAL_STAGE];

        System.assertEquals(1, ops.size());

        opp = ops[0];

        List<OpportunityLineItem> olis = [SELECT Id, Payment_Cycle__c, Contract_Start_Date__c, Contract_Duration_Days__c, TCV_Alt_Mode__c
                                   FROM OpportunityLineItem
                                   WHERE OpportunityId =: opp.Id];

        System.assertEquals(3, olis.size());

        //assert the legal case driver fields have populated the opp receiver fields
        //System.assertEquals(INVOICED, opp.Invoiced__c);
        System.assertEquals(OPP_FINAL_STAGE, opp.StageName);
        System.assertEquals(PAYMENT_CYCLE_UPFRONT, opp.Payment_Cycle__c);
        System.assertEquals(TERMINATION_CLAUSE_NO, opp.Termination_Clause__c);
        System.assertEquals(CONTRACT_START_DATE, opp.Contract_Start_Date__c);
        System.assertEquals(MYD_CONTRACT_END_DATE, opp.Contract_End_Date__c);
    }*/

    //    @IsTest
    /**
* Tests conditions that should leave TCV Alt Mode false
**/
    /*public static void testTCVAltModeFalse3_TermClauseYes(){
        //check intial record counts
        List<Account> accs = [SELECT Id FROM Account WHERE Name != 'Unassigned Account'];

        System.assertEquals(1, accs.size());

        List<Opportunity> ops = [SELECT Id, Invoiced__c, AccountId FROM Opportunity];

        System.assertEquals(1, ops.size());

        Opportunity opp = ops[0];

        List<Case> cases = [SELECT Id, RecordTypeId, Status, Opportunity__c, Invoiced__c FROM Case];

        System.assertEquals(1, cases.size());

        Case financeCase = cases[0];
        //


        //validate initial opp state
        System.assert(opp.Invoiced__c == false);

        System.assertEquals(opp.AccountId, accs[0].Id);
        //

        //validate initial case state
        Id FinanceCaseRt = null;

        try{
            FinanceCaseRt = [SELECT Id FROM RecordType WHERE Name = 'Finance Request' AND SobjectType = 'Case' LIMIT 1].Id;
        }
        catch(Exception e){
            System.debug('Suspected prerequisite RT missing: ' +e.getMessage());
        }

        if(FinanceCaseRt != null){
            System.assertEquals(FinanceCaseRt, financeCase.RecordTypeId);

        }

        System.assertEquals('New', financeCase.Status);

        System.assertEquals(opp.Id, financeCase.Opportunity__c);
        //
        //
        //opp.StageName = OPP_FINAL_STAGE;
        opp.Competition__c = COMP;
        opp.Led_by__c = LED;
        opp.Reason_1__c = 'Technical features';
        opp.Reason_2__c = 'CoE enablement strategy';
        opp.Reason_3__c = 'Product roadmap';
        opp.Closeout_Reason__c ='test123 test123 test123 test123';
        opp.Features_the_customer_liked_didn_t_like__c ='test99 test123 test123 test99';

        update opp;

        //Set case driver fields
        financeCase.Invoiced__c = INVOICED;
        financeCase.Invoice_Amount__c = 100;
        financeCase.Billing_Entity__c = accs[0].Id;
        financeCase.Status = FINANCE_REVIEW_STATUS;
        financeCase.Payment_Cycle__c = PAYMENT_CYCLE_ANNUAL;
        financeCase.Termination_Clause__c = TERMINATION_CLAUSE_YES;
        financeCase.Contract_Start_Date__c = CONTRACT_START_DATE;
        financeCase.Contract_End_Date__c = MYD_CONTRACT_END_DATE;

 		Test.startTest();
        update financeCase;
        Test.stopTest();

        //re-query opp
        ops = [SELECT Id, Invoiced__c, AccountId, Payment_Cycle__c, Termination_Clause__c, Contract_Start_Date__c, Contract_End_Date__c, StageName FROM Opportunity WHERE StageName =: OPP_FINAL_STAGE];

        System.assertEquals(1, ops.size());

        opp = ops[0];

        List<OpportunityLineItem> olis = [SELECT Id, Payment_Cycle__c, Contract_Start_Date__c, Contract_Duration_Days__c, TCV_Alt_Mode__c
                                   FROM OpportunityLineItem
                                   WHERE OpportunityId =: opp.Id];

        System.assertEquals(3, olis.size());

        //assert the legal case driver fields have populated the opp receiver fields
        //System.assertEquals(INVOICED, opp.Invoiced__c);
        System.assertEquals(OPP_FINAL_STAGE, opp.StageName);
        System.assertEquals(PAYMENT_CYCLE_ANNUAL, opp.Payment_Cycle__c);
        System.assertEquals(TERMINATION_CLAUSE_YES, opp.Termination_Clause__c);
        System.assertEquals(CONTRACT_START_DATE, opp.Contract_Start_Date__c);
        System.assertEquals(MYD_CONTRACT_END_DATE, opp.Contract_End_Date__c);
    }*/
}