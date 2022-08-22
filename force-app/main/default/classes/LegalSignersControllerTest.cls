@isTest
private class LegalSignersControllerTest {
  @TestSetup
  private static void makeData() {
    //create Account
    Account a = new Account(
      Name = 'Test Account',
      BillingStreet = 'Test',
      BillingCity = 'Test',
      PO_mandatory__c = 'Yes',
      Courier__c = 'No',
      Platform__c = 'No',
      BillingCountry = 'United Kingdom',
      BillingPostalCode = '12345',
      Industry = 'Retail',
      Phone = '1234567899',
      VAT_Number__c = '123424243344334'
    );
    insert a;

    Date d = Date.today();
    //create Opp
    Opportunity o = new Opportunity(
      AccountId = a.Id,
      Type = 'New Business',
      Name = 'Test',
      StageName = 'Discovery',
      CloseDate = d,
      CurrencyIsoCode = 'USD',
      LeadSource = 'Call Inbound'
    );

    insert o;

    Case ca = new Case(
      AccountId = a.Id,
      RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Legal_Request').getRecordTypeId(),
      Status = 'New',
      Opportunity__c = o.Id
    );
    insert ca;
  }

  @isTest
  private static void getSignerDataTest() {
    Case cs = [SELECT Id FROM Case LIMIT 1];
    Test.startTest();
    LegalSignersController.LegalSignersWrapper wrapper = LegalSignersController.getSignerData(cs.Id);
    System.assertEquals(wrapper != null, true, 'Wrapper is null');
    Test.stopTest();
  }

  @isTest
  private static void saveSignerDataTest() {
    Case cs = [SELECT Id FROM Case LIMIT 1];
    Legal_Signers__mdt mdt = [SELECT Id FROM Legal_Signers__mdt LIMIT 1];
    Test.startTest();
    try {
      LegalSignersController.saveSignerData(cs.Id, 'Uipath SRL', mdt.Id);
    } catch (Exception ex) {
      System.debug(ex.getMessage());
    }
    Test.stopTest();
  }
}