@IsTest
public class BatchToAutoCloseCaseTest_SV {
  @testSetup
  static void createTestData() {
    Account ac1 = new Account();
    ac1.Name = 'Unassigned Account';
    ac1.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Customer').getRecordTypeId();
    ac1.BillingStreet = 'Test  Street';
    ac1.BillingCity = 'Test City';
    ac1.BillingPostalCode = '123abc';
    ac1.BillingCountry = 'United Kingdom';
    //ac1.Country__c = 'United Kingdom';
    ac1.Phone = '12345678';
    ac1.Industry = 'Others';
    insert ac1;

    Contact con = new Contact();
    con.AccountId = ac1.id;
    con.FirstName = 'Test';
    con.LastName = String.valueOf(System.now());
    con.Email = 'test123123asd@asdawe.com';
    con.Title = 'Title';
    con.Department__c = 'IT';
    insert con;

    Id incidentRecordTypeID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
      .get('Incident')
      .getRecordTypeId();

    List<Case> casenewList = new List<Case>();

    Case Case0 = new Case(
      Status = 'New',
      Origin = 'Web',
      Priority = 'Medium',
      Country__c = 'United States',
      Time_Zone__c = 'GMT-05:00  Eastern Standard Time',
      RecordTypeId = incidentRecordTypeID,
      AccountId = ac1.Id,
      ContactId = con.Id,
      Closure_Classification__c = 'Customer Abandoned',
      Related_To__c = 'Studio',
      Sub_Component__c = 'Others',
      Solution__c = 'test'
    );
    casenewList.add(Case0);

    insert casenewList;
  }

  @isTest
  static void testBatchToAutoCloseCase() {
    String CRON_EXP = '0 0 3 * * ?';
    Test.startTest();
    String jobId = System.schedule('BatchToAutoCloseCase_SV', CRON_EXP, new ScheduleBatchToAutoCloseCase_SV());
    CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
    System.assertEquals(0, ct.TimesTriggered);
    Test.stopTest();
  }
}