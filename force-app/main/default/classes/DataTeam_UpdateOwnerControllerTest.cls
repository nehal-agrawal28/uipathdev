@isTest
public class DataTeam_UpdateOwnerControllerTest {
  private static final Id customerRT = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
    .get('Customer')
    .getRecordTypeId();

  @isTest
  public static void CustomUpdateTest() {
    // Data setup

    Account newAccount1 = new Account();
    newAccount1.Name = 'Test Account Name';
    newAccount1.BillingCountry = 'UNITED KINGDOM';
    newAccount1.BillingCountryCode = 'GB';
    newAccount1.BillingStreet = 'Test Street';
    newAccount1.BillingCity = 'Test City';
    newAccount1.BillingPostalCode = '123abc';
    newAccount1.Phone = '0721440001';
    newAccount1.Industry = 'Energy';
    insert newAccount1;

    Account newAccount2 = new Account();
    newAccount2.Name = 'Account Test';
    newAccount2.BillingCountry = 'UNITED KINGDOM';
    newAccount2.BillingCountryCode = 'GB';
    newAccount2.BillingStreet = 'Test Street';
    newAccount2.BillingCity = 'Test City';
    newAccount2.BillingPostalCode = '123abc';
    newAccount2.Phone = '0721004400';
    newAccount2.Industry = 'Communication';
    newAccount2.RecordTypeId = customerRT;
    insert newAccount2;

    Account newAccount3 = new Account();
    newAccount3.Name = 'TestAccount';
    newAccount3.BillingCountry = 'UNITED STATES';
    newAccount3.BillingCountryCode = 'US';
    newAccount3.BillingStreet = 'Welcom Street';
    newAccount3.BillingCity = 'Some City';
    newAccount3.BillingPostalCode = '43432';
    newAccount3.Phone = '3434333';
    newAccount3.Industry = 'Energy';
    insert newAccount3;

    User u2 = new User();
    u2.ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id;
    u2.Username = 'testother55666@uiath.com';
    u2.LastName = 'OtherTest';
    u2.Email = 'testother55666@uiath.com';
    u2.Alias = 'her55666';
    u2.TimeZoneSidKey = 'America/Los_Angeles';
    u2.LocaleSidKey = 'en_US';
    u2.EmailEncodingKey = 'UTF-8';
    u2.LanguageLocaleKey = 'en_US';
    insert u2;

    /*User u = new User();
    u.ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id;
    u.Username = 'test454366@uiath.com';
    u.LastName = 'Test';
    u.Email = 'test454366@uiath.com';
    u.Alias = 't4554556';
    u.TimeZoneSidKey = 'America/Los_Angeles';
    u.LocaleSidKey = 'en_US';
    u.EmailEncodingKey = 'UTF-8';
    u.LanguageLocaleKey = 'en_US';
    System.runAs(u) {
        insert newAccountParent;
    }*/

    List<Opportunity> oppsList = new List<Opportunity>();

    Opportunity newOpportunity1 = new Opportunity();
    newOpportunity1.Name = 'testOppName';
    newOpportunity1.LeadSource = 'Partner';
    newOpportunity1.Type = 'New Business';
    newOpportunity1.AccountId = newAccount1.Id;
    newOpportunity1.StageName = 'Discovery';
    newOpportunity1.CloseDate = Date.today();
    newOpportunity1.Discount_Approval_Status__c = 'In Approval';
    newOpportunity1.Managing_Director__c = UserInfo.getUserId();
    newOpportunity1.CurrencyIsoCode = 'USD';
    newOpportunity1.Onboard_customer_by_CS_Ops__c = 'No';
    newOpportunity1.Sold_to_Partner__c = newAccount1.Id;
    oppsList.add(newOpportunity1);

    Opportunity newOpportunity2 = new Opportunity();
    newOpportunity2.Name = 'testOppName';
    newOpportunity2.LeadSource = 'Partner';
    newOpportunity2.Type = 'New Business';
    newOpportunity2.AccountId = newAccount1.Id;
    newOpportunity2.StageName = 'Discovery';
    newOpportunity2.CloseDate = Date.today();
    newOpportunity2.Discount_Approval_Status__c = 'In Approval';
    newOpportunity2.Managing_Director__c = UserInfo.getUserId();
    newOpportunity2.CurrencyIsoCode = 'USD';
    newOpportunity2.Onboard_customer_by_CS_Ops__c = 'No';
    newOpportunity2.Sold_to_Partner__c = newAccount1.Id;
    oppsList.add(newOpportunity2);

    insert oppsList;

    String csvString = 'AccountID, UserId\r\n';
    csvString += newAccount1.Id + ',' + u2.Id + '\r\n';
    csvString += newAccount2.Id + ',' + u2.Id + '\r\n';
    csvString += newAccount3.Id + ',' + u2.Id + '\r\n';
    // Run code
    Test.startTest();

    DataTeam_UpdateOwnerController updateApp = new DataTeam_UpdateOwnerController();
    PageReference pageRef = Page.DataTeam_UpdateOwner;
    Test.setCurrentPage(pageRef);
    updateApp.getObjectOption();
    updateApp.selectedOption = 'AccountUserAll';
    updateApp.csvAsString = csvString;
    updateApp.csvFileBody = Blob.valueOf(csvString);
    updateApp.readCSVData();
    updateApp.updateOwner();
    updateApp.Cancel();

    Test.stopTest();
  }

  @isTest
  public static void CustomUpdateTest1() {
    // Data setup

    Account newAccount1 = new Account();
    newAccount1.Name = 'Test Account Name';
    newAccount1.BillingCountry = 'UNITED KINGDOM';
    newAccount1.BillingCountryCode = 'GB';
    newAccount1.BillingStreet = 'Test Street';
    newAccount1.BillingCity = 'Test City';
    newAccount1.BillingPostalCode = '123abc';
    newAccount1.Phone = '0721440001';
    newAccount1.Industry = 'Energy';
    insert newAccount1;

    Account newAccount2 = new Account();
    newAccount2.Name = 'Account Test';
    newAccount2.BillingCountry = 'UNITED KINGDOM';
    newAccount2.BillingCountryCode = 'GB';
    newAccount2.BillingStreet = 'Test Street';
    newAccount2.BillingCity = 'Test City';
    newAccount2.BillingPostalCode = '123abc';
    newAccount2.Phone = '0721004400';
    newAccount2.Industry = 'Communication';
    newAccount2.RecordTypeId = customerRT;
    insert newAccount2;

    Account newAccount3 = new Account();
    newAccount3.Name = 'TestAccount';
    newAccount3.BillingCountry = 'UNITED STATES';
    newAccount3.BillingCountryCode = 'US';
    newAccount3.BillingStreet = 'Welcom Street';
    newAccount3.BillingCity = 'Some City';
    newAccount3.BillingPostalCode = '43432';
    newAccount3.Phone = '3434333';
    newAccount3.Industry = 'Energy';
    insert newAccount3;

    User u2 = new User();
    u2.ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id;
    u2.Username = 'testother55666@uiath.com';
    u2.LastName = 'OtherTest';
    u2.Email = 'testother55666@uiath.com';
    u2.Alias = 'her55666';
    u2.TimeZoneSidKey = 'America/Los_Angeles';
    u2.LocaleSidKey = 'en_US';
    u2.EmailEncodingKey = 'UTF-8';
    u2.LanguageLocaleKey = 'en_US';
    insert u2;

    Opportunity newOpportunity1 = new Opportunity();
    newOpportunity1.Name = 'testOppName';
    newOpportunity1.LeadSource = 'Partner';
    newOpportunity1.Type = 'New Business';
    newOpportunity1.AccountId = newAccount1.Id;
    newOpportunity1.StageName = 'Discovery';
    newOpportunity1.CloseDate = Date.today();
    newOpportunity1.Discount_Approval_Status__c = 'In Approval';
    newOpportunity1.Managing_Director__c = UserInfo.getUserId();
    newOpportunity1.CurrencyIsoCode = 'USD';
    newOpportunity1.Onboard_customer_by_CS_Ops__c = 'No';
    newOpportunity1.Sold_to_Partner__c = newAccount1.Id;
    insert newOpportunity1;

    Lead lead = new Lead(
      LastName = 'Test',
      Company = 'Google',
      Country = 'United States',
      CountryCode = 'US',
      Industry = 'Insurance',
      Status = 'New',
      Email = 'joe@NOT.com',
      Tier__c = '1'
    );

    insert lead;

    // Run code
    Test.startTest();

    DataTeam_UpdateOwnerController updateApp = new DataTeam_UpdateOwnerController();
    PageReference pageRef = Page.DataTeam_UpdateOwner;
    Test.setCurrentPage(pageRef);
    String csvStringAccount = 'AccountID, UserId\r\n';
    csvStringAccount += newAccount1.Id + ',' + u2.Id + '\r\n';
    csvStringAccount += newAccount2.Id + ',' + u2.Id + '\r\n';
    csvStringAccount += newAccount3.Id + ',' + u2.Id + '\r\n';

    updateApp.getObjectOption();
    updateApp.selectedOption = 'AccountUser';
    updateApp.csvAsString = csvStringAccount;
    updateApp.csvFileBody = Blob.valueOf(csvStringAccount);
    updateApp.readCSVData();
    updateApp.updateAccountOwner();
    updateApp.Cancel();

    String csvStringOpp = 'OpportunityID, UserId\r\n';
    csvStringOpp += newOpportunity1.Id + ',' + u2.Id + '\r\n';

    updateApp.selectedOption = 'OpportunityUser';
    updateApp.csvAsString = csvStringOpp;
    updateApp.csvFileBody = Blob.valueOf(csvStringOpp);
    updateApp.readCSVData();
    updateApp.updateOpportunityOwner();
    updateApp.Cancel();

    String csvStringLead = 'LeadID, UserId\r\n';
    csvStringLead += lead.Id + ',' + u2.Id + '\r\n';

    updateApp.selectedOption = 'LeadUser';
    updateApp.csvAsString = csvStringLead;
    updateApp.csvFileBody = Blob.valueOf(csvStringLead);
    updateApp.readCSVData();
    updateApp.updateLeadOwner();
    updateApp.Cancel();

    DataTeam_ShowBatchProgressCmp UpdateShowBatches = new DataTeam_ShowBatchProgressCmp();
    Map<String, String> a = UpdateShowBatches.apexClassMap;
    UpdateShowBatches.getBatchJobs();

    Test.stopTest();
  }
}