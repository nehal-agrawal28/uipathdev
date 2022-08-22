@IsTest
private class ShareOppToDirectPartnerUsersJobTest_PP {
  @testSetup
  static void setupTestData() {
    Id partnerRecordTypeId = [SELECT Id FROM RecordType WHERE Name = 'Partner' AND SobjectType = 'Account'].Id;
    Id opportunityRecordTypeId = [
      SELECT Id
      FROM RecordType
      WHERE Name = 'Deal Registration' AND SobjectType = 'Opportunity'
    ]
    .Id;
    Account account = new Account();
    account.Name = 'Test Partner Account';
    account.RecordTypeId = partnerRecordTypeId;
    account.Type = 'Business Partner';
    account.Business_Partner_Type__c = 'VAR';
    account.Business_Partner_Status__c = 'Good Standing';
    account.Country__c = 'United States';
    account.Industry = 'Healthcare';
    account.AccountNumber = '1232344423';
    insert account;

    Opportunity opps = new Opportunity();
    opps.Name = 'test Opportunity';
    opps.AccountId = account.Id;
    opps.RecordTypeId = opportunityRecordTypeId;
    opps.Deal_Type__c = 'Resale';
    opps.CloseDate = Date.today();
    opps.StageName = 'Open';
    insert opps;

    Contact con = new Contact();
    con.LastName = 'Test ln';
    con.Email = 'testPartner@gmail.coom';
    con.AccountId = account.Id;
    insert con;

    User usr = new User();
    usr.Firstname = 'Test FN';
    usr.Lastname = con.LastName;
    usr.Email = con.Email;
    usr.Username = con.Email;
    usr.ProfileId = [SELECT Id FROM Profile WHERE Name = 'Global Partner Portal Login User'].Id;
    usr.EmailEncodingKey = 'UTF-8';
    usr.LanguageLocaleKey = 'en_US';
    usr.LocaleSidKey = 'en_US';
    usr.TimeZoneSidKey = 'America/Los_Angeles';
    usr.Alias = 'abcce3';
    usr.ContactId = con.Id;
    insert usr;
  }

  @IsTest
  static void itShouldCreateOpportunityShare() {
    Test.startTest();
    String jobId = ShareOppToDirectPartnerUsersJob_PP.scheduleJob();

    CronTrigger ctBefore = [SELECT Id, CronExpression, TimesTriggered, State FROM CronTrigger WHERE Id = :jobId];
    System.assertEquals(ShareOppToDirectPartnerUsersJob_PP.DEFAULT_SCHEDULE, ctBefore.CronExpression);

    ShareOppToDirectPartnerUsersJob_PP.removeJobs();
    List<CronTrigger> ctAfter = [SELECT Id FROM CronTrigger WHERE Id = :jobId];
    System.assertEquals(true, ctAfter.isEmpty());

    Database.executeBatch(new ShareOppToDirectPartnerUsersJob_PP(), 10);
    Test.stopTest();
  }
}