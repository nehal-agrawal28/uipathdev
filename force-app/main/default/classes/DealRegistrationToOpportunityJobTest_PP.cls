@IsTest
private class DealRegistrationToOpportunityJobTest_PP {
  @IsTest
  static void itShouldCreateOpportunitiesFromDealRegistrations() {
    // given
    TestFactory_PP.init();
    TestFactory_PP.initPortalUsers();

    User resellerUser = [SELECT Id, Contact_Account_Id__c FROM User WHERE Name LIKE 'reselleruser%' LIMIT 1];
    Account distributorAccount = [SELECT Id FROM Account WHERE Name LIKE 'distributoraccount%' LIMIT 1];

    DealRegistration__c dealRegistration = TestFactory_PP.buildDealRegistration(
      resellerUser,
      distributorAccount.Id,
      resellerUser.Contact_Account_Id__c,
      null,
      false, // bpo = false
      true // submitted record type
    );
    insert dealRegistration;

    List<Opportunity> opportunitiesBefore = [SELECT Id FROM Opportunity];

    System.assertEquals(true, opportunitiesBefore.isEmpty());

    DealRegistrationsSelector_PP selector = (DealRegistrationsSelector_PP) Application_PP.Selector.newInstance(
      DealRegistration__c.SObjectType
    );

    List<DealRegistration__c> dealRegistrationsBefore = selector.selectById(new Set<Id>{ dealRegistration.Id }, false);

    System.assertEquals(false, dealRegistrationsBefore.isEmpty());

    // when
    Test.startTest();
    Database.executeBatch(new DealRegistrationToOpportunityJob_PP());
    Test.stopTest();

    // then
    List<Opportunity> opportunitiesAfter = [SELECT Id FROM Opportunity];

    System.assertEquals(false, opportunitiesAfter.isEmpty());

    List<DealRegistration__c> dealRegistrationsAfter = selector.selectById(new Set<Id>{ dealRegistration.Id }, false);

    System.assertEquals(false, dealRegistrationsAfter.isEmpty());
    System.assert(String.isNotBlank(dealRegistrationsAfter.get(0).Opportunity__c));
  }

  @IsTest
  static void itShouldScheduleJobAndRemoveJob() {
    Test.startTest();
    // given

    // when
    String jobId = DealRegistrationToOpportunityJob_PP.scheduleJob();

    // then
    CronTrigger ctBefore = [SELECT Id, CronExpression, TimesTriggered, State FROM CronTrigger WHERE Id = :jobId];

    System.assertEquals(DealRegistrationToOpportunityJob_PP.DEFAULT_SCHEDULE, ctBefore.CronExpression);
    System.assertEquals(0, ctBefore.TimesTriggered);
    System.assertEquals('WAITING', ctBefore.State);

    // given

    // when
    DealRegistrationToOpportunityJob_PP.removeJobs();

    // then
    List<CronTrigger> ctAfter = [SELECT Id FROM CronTrigger WHERE Id = :jobId];

    System.assertEquals(true, ctAfter.isEmpty());

    Test.stopTest();
  }
}