/**
 * --
 * @date 18/03/2019
 * @description Event listeners for Opty Trigger. This class should ideally delegate work to Domain/Service classes
 */

@isTest
private class CPQOptyTriggerHandlerTest {
  @isTest
  static void canCreateAndDeleteAnOpportunity() {
    Account account = new Account(Name = 'Test Account', BillingCountry = 'United Kingdom', Industry = 'Apparel');
    insert account;
    Opportunity opportunity = new Opportunity(
      Name = ' CPQ Opportunity',
      RecordTypeId = getRecordTypeId(),
      StageName = 'Discovery',
      Type = 'New Business',
      CloseDate = System.today().addMonths(1),
      LeadSource = 'Call Inbound',
      AccountId = account.Id
    );

    Test.startTest();
    Database.SaveResult insertResult = Database.insert(opportunity, false);
    Database.DeleteResult deleteResult = Database.delete(opportunity, false);
    Test.stopTest();

    System.assert(insertResult.isSuccess());
    System.assert(deleteResult.isSuccess());
  }

  /*
    @isTest static void setCustomerStageProveTest(){
        
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
        product1.Ext_Id__c='testProductName0220';
        product1.ProductCode='testProductName0220';
        insert product1;
        
        PricebookEntry pbe = new PricebookEntry();
        pbe.Product2Id = product1.Id;
        pbe.Pricebook2Id = Test.getStandardPricebookId();
        pbe.UnitPrice = 2000;
        pbe.IsActive = true;
        pbe.CurrencyIsoCode = 'USD';
        insert pbe;
        
        // Accounts ==============================================
        
        Account proveAccount = new Account();
        proveAccount.Name = 'Account Prove with opp';
        proveAccount.BillingCountry = 'UNITED KINGDOM';
        proveAccount.Industry = 'Energy';
        proveAccount.Overwrite_Classification__c = false;
        proveAccount.Customer_Stage__c = 'Prove';
        insert proveAccount;
        
        Contact newContact = new Contact(
            LastName = 'contRec1',
            AccountId = proveAccount.Id,
            Email = 'contRec.Test11@emailDomain.com'
        );
        insert newContact;
        
        // opps ==================================================    
        
        Opportunity newOpportunityProve = new Opportunity();
        newOpportunityProve.Name = 'Opportunity Prove';
        newOpportunityProve.Type = 'New Business';
        newOpportunityProve.Deal_Type__c = 'Direct';
        newOpportunityProve.LeadSource = 'Webinar';
        newOpportunityProve.AccountId = proveAccount.Id;
        newOpportunityProve.StageName = 'Discovery';
        newOpportunityProve.CloseDate = (Date.today()).addMonths(-2);
        newOpportunityProve.Discount_Approval_Status__c = 'In Approval';
        newOpportunityProve.Managing_Director__c = UserInfo.getUserId();
        newOpportunityProve.Pricebook2Id = Test.getStandardPricebookId();
        newOpportunityProve.CurrencyIsoCode = 'USD';
        newOpportunityProve.Total_Contact_Roles__c = 1;
        newOpportunityProve.Competition__c = 'Alibaba';
        newOpportunityProve.Won_Reasons__c = 'Product Roadmap';
        
        insert newOpportunityProve; 
        
        //create contact roles
        
        OpportunityContactRole ocrProve = new OpportunityContactRole();
        ocrProve.OpportunityId = newOpportunityProve.Id;
        ocrProve.ContactId = newContact.Id;
        ocrProve.Role = 'Business User';
        
        insert ocrProve;
        
        OpportunityLineItem oli = new OpportunityLineItem();
        oli.OpportunityId = newOpportunityProve.Id;
        oli.UnitPrice = 700;
        oli.Quantity = 1;
        oli.PricebookEntryId = pbe.Id;
        oli.Discount = 25;
        oli.Product_Version__c = '2019.4';
        oli.Add_On_For__c = null;
        oli.ServiceDate = Date.today().addMonths(-1);
        oli.End_Date__c = Date.today().addMonths(3);
        oli.Product2Id = product1.Id;
                                 
        insert oli;
        
        // update opps ======================================================================================
        
        newOpportunityProve.StageName = 'Closed Won Booked';
        newOpportunityProve.Contract_Start_Date__c = (Date.Today()).addMonths(-1);
        newOpportunityProve.Contract_End_Date__c = (Date.Today()).addMonths(9);  
        newOpportunityProve.Closeout_Reason__c = 'No reason, just wanted to close it.';
        newOpportunityProve.Features_the_customer_liked_didn_t_like__c = 'I didn\'t ask him, there is no client. This is a test.';
        newOpportunityProve.FinanceReviewReached__c = true;
        
        Test.startTest();
        update newOpportunityProve;
        system.debug('newOpportunityProve is: ' + newOpportunityProve);
        Test.stopTest();
        
        Account proveUpdatedAccount = [SELECT Customer_Stage__c from ACCOUNT where Id =: proveAccount.Id LIMIT 1];        
        System.assertEquals(proveUpdatedAccount.Customer_Stage__c, 'Establish');           
    }
    */

  private static Id getRecordTypeId() {
    Id recordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
      .get('CPQ_Default')
      .getRecordTypeId();
    return recordTypeId;
  }

  /*@isTest
  public static void testValidationStatusIsChangedOnOpportunityAccounts() {
    Opportunity newOpportunity = createOpportunityTestData();

    Test.startTest();
    newOpportunity.StageName = 'Negotiation';
    update newOpportunity;
    Test.stopTest();

    Set<ID> idsToRetrieve = new Set<ID>();
    idsToRetrieve.add(newOpportunity.AccountId);

    if (newOpportunity.Sold_to_Partner__c != null) {
      idsToRetrieve.add(newOpportunity.Sold_to_Partner__c);
    }

    for (Account acct : [
      SELECT id, Validation_Status__c, (SELECT id, Validation_Status__c FROM Addresses__r)
      FROM Account
      WHERE Id = :newOpportunity.AccountId
    ]) {
      System.assertEquals(
        'Ready For Review',
        acct.Validation_Status__c,
        'Opportunity stage has changed to Negotiation, so the validation status of the account should be ready for review.'
      );
      for (Address__c a : acct.Addresses__r) {
        System.assertEquals(
          'Ready For Review',
          a.Validation_Status__c,
          'Opportunity stage has changed to Negotiation value, so the validation status of the account should be ready for review.'
        );
      }
    }
  }*/

  /*@isTest
  public static void testValidationStatusIsNotChangedOnOpportunityAccounts() {
    Opportunity newOpportunity = createOpportunityTestData();

    Test.startTest();
    newOpportunity.StageName = 'Proposal';
    update newOpportunity;
    Test.stopTest();

    Set<ID> idsToRetrieve = new Set<ID>();

    idsToRetrieve.add(newOpportunity.AccountId);

    if (newOpportunity.Sold_to_Partner__c != null) {
      idsToRetrieve.add(newOpportunity.Sold_to_Partner__c);
    }

    for (Account acct : [
      SELECT id, Validation_Status__c, (SELECT id, Validation_Status__c FROM Addresses__r)
      FROM Account
      WHERE Id = :newOpportunity.AccountId
    ]) {
      System.assertEquals(
        'Pending',
        acct.Validation_Status__c,
        'Even though Opportunity stage has changed, so the validation status of the account should not have changed.'
      );
      for (Address__c a : acct.Addresses__r) {
        System.assertEquals(
          'Pending',
          a.Validation_Status__c,
          'Even though Opportunity stage has changed, so the validation status of the account should not have changed.'
        );
      }
    }
  }*/

  /*private static Opportunity createOpportunityTestData() {
    Opportunity newOpportunity = new Opportunity();
    newOpportunity.Name = 'testOppName';
    newOpportunity.Type = 'Renewal';
    newOpportunity.AccountId = createNewAccount('OppAccount', true).ID;
    newOpportunity.StageName = 'Discovery';
    newOpportunity.CloseDate = Date.today();
    newOpportunity.Discount_Approval_Status__c = 'In Approval';
    newOpportunity.Managing_Director__c = UserInfo.getUserId();
    newOpportunity.Pricebook2Id = Test.getStandardPricebookId();
    newOpportunity.Probability = 0.5;
    newOpportunity.CurrencyIsoCode = 'USD';
    newOpportunity.Sold_to_Partner__c = createNewAccount('SoldToTest', false).ID;
    insert newOpportunity;

    Contact con = new Contact();
    con.LastName = 'Test545734';
    con.AccountId = newOpportunity.AccountId;
    insert con;

    OpportunityContactRole opptyCR = new OpportunityContactRole();
    opptyCR.OpportunityId = newOpportunity.Id;
    opptyCR.ContactId = con.Id;
    insert opptyCR;

    return newOpportunity;
  }*/

  /*private static Account createNewAccount(string name, boolean addAddresses) {
    Account newAccount = new Account();
    newAccount.Name = name;
    newAccount.BillingCountry = 'United Kingdom';
    newAccount.Country__c = 'United Kingdom';
    newAccount.Industry = 'Energy';
    newAccount.Validation_Status__c = 'Pending';
    insert newAccount;

    if (addAddresses) {
      DataFactory.createAddress(3, newAccount.id, true);
    }
    return newAccount;
  }*/

  /*@isTest
  private static void populateAmountFieldsPriorQuoteTest() {
    Opportunity newOpportunity = createOpportunityTestData();

    Test.startTest();

    newOpportunity.Amount = 10000;
    update newOpportunity;

    Opportunity opp = [
      SELECT Id, CPQ_OpportunityACV__c, CPQ_OpportunityARR__c, CPQ_OpportunityTCV__c
      FROM Opportunity
      WHERE Id = :newOpportunity.Id
    ];

    System.assertEquals(10000, opp.CPQ_OpportunityACV__c, 'TCV/ACV/ARR not populating as Amount');
    System.assertEquals(10000, opp.CPQ_OpportunityTCV__c, 'TCV/ACV/ARR not populating as Amount');

    Test.stopTest();
  }*/
}