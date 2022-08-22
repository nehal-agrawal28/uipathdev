@IsTest(isParallel=false)
public class ScheduleBatchToSendReminderForSurveyTest {
  @testSetup
  static void createTestData() {
    Account ac1 = new Account();
    ac1.Name = 'Unassigned Account';
    ac1.RecordTypeId = Utilities.getRecordTypeId('Customer', 'Account');
    ac1.BillingStreet = 'Test  Street';
    ac1.BillingCity = 'Test City';
    ac1.BillingPostalCode = '123abc';
    ac1.BillingCountry = 'United Kingdom';
    ac1.Country__c = 'United Kingdom';
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
    Id japanIncidentRecordTypeID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
      .get('Japan_Incident')
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
      ContactId = con.Id
    );
    casenewList.add(Case0);

    //Inserting Case1
    Case Case1 = new Case(
      Status = 'New',
      Origin = 'Web',
      Priority = 'Medium',
      Country__c = 'United States',
      Time_Zone__c = 'GMT-08:00  Pacific Standard Time',
      RecordTypeId = japanIncidentRecordTypeID,
      AccountId = ac1.Id,
      ContactId = con.Id
    );
    casenewList.add(Case1);

    insert casenewList;
  }

  @isTest
  static void testScheduleBatchToSendReminderForSurvey() {
    String CRON_EXP = '0 0 3 * * ?';
    Test.startTest();
    String jobId = System.schedule('Send Survey Reminder', CRON_EXP, new ScheduleBatchToSendReminderForSurvey());
    CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
    System.assertEquals(0, ct.TimesTriggered);
    Test.stopTest();
  }
}