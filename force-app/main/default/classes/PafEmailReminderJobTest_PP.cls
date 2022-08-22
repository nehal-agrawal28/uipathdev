@IsTest(IsParallel=false)
private class PafEmailReminderJobTest_PP {
  @IsTest
  static void itShouldsendEmailsForOpenPafs() {
    //given
    User manager = new User(
      Alias = 'mng',
      Email = 'TestAdmin@UiPath.com',
      EmailEncodingKey = 'UTF-8',
      LanguageLocaleKey = 'en_US',
      LastName = 'Test Apex',
      LocaleSidKey = 'en_US',
      TimeZoneSidKey = 'America/Los_Angeles',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator']
      .Id,
      Username = 'TestAdminMng_c@UiPath.com'
    );
    insert manager;

    User userWithManager = new User(
      Alias = 'usr1',
      ManagerId = manager.Id,
      Email = 'TestAdmin@UiPath.com',
      EmailEncodingKey = 'UTF-8',
      LanguageLocaleKey = 'en_US',
      LastName = 'Test Apex',
      LocaleSidKey = 'en_US',
      TimeZoneSidKey = 'America/Los_Angeles',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator']
      .Id,
      Username = 'TestAdminUsr1@UiPath.com'
    );
    insert userWithManager;

    Lead lead1 = new Lead(
      FirstName = 'test1',
      LastName = 'Lead',
      Company = 'test1 lead',
      Country = 'United States',
      Email = 'test1Lead@uipath.com',
      OwnerId = userWithManager.Id
    );
    insert lead1;
    Lead lead2 = new Lead(
      FirstName = 'test2',
      LastName = 'Lead',
      Company = 'test2 lead',
      Country = 'Belgium',
      Email = 'test2Lead@uipath.com',
      OwnerId = userWithManager.Id
    );
    insert lead2;

    Partner_Application_Form__c paf1 = new Partner_Application_Form__c(
      OwnerId = userWithManager.Id,
      Lead__c = lead1.Id,
      Application_Status__c = 'Accept',
      Authorized_Signatory_Email__c = 'test_authSignatory@test.uipath.com',
      Authorized_Signatory_Name__c = 'Test Auth Signatory',
      Authorized_Signatory_Phone__c = '+32111111111',
      Authorized_Signatory_Title__c = 'Mr.',
      UiPath_Status__c = 'New'
    );
    insert paf1;
    paf1.Application_Status_Date__c = System.today().addDays(-15);
    update paf1;
    Partner_Application_Form__c paf2 = new Partner_Application_Form__c(
      OwnerId = userWithManager.Id,
      Lead__c = lead2.Id,
      Application_Status__c = 'Accept',
      Authorized_Signatory_Email__c = 'test_authSignatory2@test.uipath.com',
      Authorized_Signatory_Name__c = 'Test Auth Signatory 2',
      Authorized_Signatory_Phone__c = '+32111111112',
      Authorized_Signatory_Title__c = 'Mr.',
      UiPath_Status__c = 'New'
    );
    insert paf2;
    paf2.Application_Status_Date__c = System.today().addDays(-7);
    update paf2;
    List<Partner_Application_Form__c> pafs = new List<Partner_Application_Form__c>();
    pafs.add(paf1);
    pafs.add(paf2);

    // when
    Test.startTest();
    ID batchprocessid = Database.executeBatch(new PafEmailReminderJob_PP());
    Test.stopTest();

    // then
    AsyncApexJob aaj = [
      SELECT Id, Status, JobItemsProcessed, TotalJobItems, NumberOfErrors
      FROM AsyncApexJob
      WHERE ID = :batchprocessid
    ];
    System.assertNotEquals(null, aaj.Id);
  }

  @IsTest
  static void itShouldScheduleJobAndRemoveJob() {
    Test.startTest();
    // given

    // when
    String jobId = PafEmailReminderJob_PP.scheduleJob();

    // then
    CronTrigger ctBefore = [SELECT Id, CronExpression, TimesTriggered, State FROM CronTrigger WHERE Id = :jobId];

    System.assertEquals(PafEmailReminderJob_PP.DEFAULT_SCHEDULE, ctBefore.CronExpression);
    System.assertEquals(0, ctBefore.TimesTriggered);
    System.assertEquals('WAITING', ctBefore.State);

    // given

    // when
    PafEmailReminderJob_PP.removeJobs();

    // then
    List<CronTrigger> ctAfter = [SELECT Id FROM CronTrigger WHERE Id = :jobId];

    System.assertEquals(true, ctAfter.isEmpty());

    Test.stopTest();
  }
}