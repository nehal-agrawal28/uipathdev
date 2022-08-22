@isTest(SeeAllData=false)
public class OpportunityAccountCustomerStageTest {
  static testMethod void setCustomerStageTest() {
    // prerequisits

    Product2 product1 = new Product2();
    product1.Name = 'UIPath - Attended Robot - test Establish';
    product1.Is_Add_On__c = false;
    product1.IsActive = true;
    product1.Add_On_Percent__c = 10;
    product1.License_Model__c = 'N/A';
    product1.Unit_of_measure__c = 'N/A';
    product1.Family = 'Core Product';
    product1.CPQ_Exclusive__c = true;
    product1.Ext_Id__c = 'testProductName0220';
    product1.ProductCode = 'testProductName0220';
    insert product1;

    PricebookEntry pbe = new PricebookEntry();
    pbe.Product2Id = product1.Id;
    pbe.Pricebook2Id = Test.getStandardPricebookId();
    pbe.UnitPrice = 2000;
    pbe.IsActive = true;
    pbe.CurrencyIsoCode = 'USD';
    insert pbe;

    // Accounts ==============================================

    Account acct = new Account();
    acct.Name = 'Account Establish with opp';
    acct.BillingCountry = 'UNITED KINGDOM';
    acct.Industry = 'Energy';
    acct.Overwrite_Classification__c = false;

    insert acct;

    Contact newContact = new Contact(
      LastName = 'contRec1',
      AccountId = acct.Id,
      Email = 'contRec.Test11@emailDomain.com',
      Department__c = 'IT'
    );

    insert newContact;

    // opps ==================================================

    Opportunity opp = new Opportunity();
    opp.Name = 'Opportunity Customer Stage';
    opp.LeadSource = 'Webinar';
    opp.Deal_Type__c = 'Direct';
    opp.Type = 'New Business';
    opp.AccountId = acct.Id;
    opp.StageName = 'Discovery';
    opp.CloseDate = (Date.today()).addMonths(-2);
    opp.Discount_Approval_Status__c = 'In Approval';
    opp.Managing_Director__c = UserInfo.getUserId();
    opp.Pricebook2Id = Test.getStandardPricebookId();
    opp.CurrencyIsoCode = 'USD';
    opp.Total_Contact_Roles__c = 1;
    opp.Competition__c = 'Automation Anywhere';
    opp.Won_Reasons__c = 'Product Roadmap';

    insert opp;

    //create contact roles

    OpportunityContactRole ocr = new OpportunityContactRole();
    ocr.OpportunityId = opp.Id;
    ocr.ContactId = newContact.Id;
    ocr.Role = 'Business User';

    insert ocr;

    // create opp lines ====================================================

    List<OpportunityLineItem> olis = new List<OpportunityLineItem>();

    OpportunityLineItem oli = new OpportunityLineItem();
    oli.OpportunityId = opp.Id;
    oli.UnitPrice = 700;
    oli.Quantity = 3;
    oli.PricebookEntryId = pbe.Id;
    oli.Discount = 25;
    oli.Product_Version__c = '2019.4';
    oli.Add_On_For__c = null;
    oli.ServiceDate = Date.today().addMonths(-1);
    oli.End_Date__c = Date.today().addMonths(3);
    oli.Product2Id = product1.Id;
    olis.add(oli);

    OpportunityLineItem oli2 = new OpportunityLineItem();
    oli2.OpportunityId = opp.Id;
    oli2.UnitPrice = 700;
    oli2.Quantity = 1;
    oli2.PricebookEntryId = pbe.Id;
    oli2.Discount = 25;
    oli2.Product_Version__c = '2019.4';
    oli2.Add_On_For__c = null;
    oli2.ServiceDate = Date.today().addMonths(-1);
    oli2.End_Date__c = Date.today().addMonths(3);
    oli2.Product2Id = product1.Id;
    olis.add(oli2);

    insert olis;

    // update opps ======================================================================================
    Test.startTest();

    opp.StageName = 'Closed Won Booked';
    opp.Contract_Start_Date__c = (Date.Today()).addMonths(-1);
    opp.Contract_End_Date__c = (Date.Today()).addMonths(9);
    opp.Closeout_Reason__c = 'No reason, just wanted to close it.';
    opp.Features_the_customer_liked_didn_t_like__c = 'I didn\'t ask him, there is no client. This is a test.';
    opp.FinanceReviewReached__c = true;

    update opp;

    new OpportunityAccountCustomerStageQueueable(new List<Opportunity>{ opp }).work();
    Test.stopTest();

    Account establishUpdatedAccount = [SELECT Customer_Stage__c FROM ACCOUNT WHERE Id = :acct.Id LIMIT 1];
    System.assertEquals('Establish', establishUpdatedAccount.Customer_Stage__c);
  }
}