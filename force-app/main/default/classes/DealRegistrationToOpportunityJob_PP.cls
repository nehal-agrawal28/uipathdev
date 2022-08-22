public without sharing class DealRegistrationToOpportunityJob_PP implements System.Schedulable, Database.Batchable<SObject> {
  // default is to run every day at midnight; note that timezone is dependent on running user's settings
  // second minute hour day_of_month month day_of_week optional_year
  public static final String DEFAULT_SCHEDULE = '0 0 0 * * ?';

  public void execute(SchedulableContext context) {
    Database.executeBatch(new DealRegistrationToOpportunityJob_PP());
  }

  public static String scheduleJob() {
    return scheduleJob(DEFAULT_SCHEDULE);
  }

  public static String scheduleJob(String scheduleString) {
    String name = DealRegistrationToOpportunityJob_PP.class.getName() + System.now().format(' yyyy-MM-dd HH:mm:ss z');

    return scheduleJob(name, scheduleString);
  }

  public static String scheduleJob(String name, String scheduleString) {
    return System.schedule(name, scheduleString, new DealRegistrationToOpportunityJob_PP());
  }

  public static void removeJobs() {
    List<CronTrigger> cronTriggers = [
      SELECT Id
      FROM CronTrigger
      WHERE
        CronJobDetail.JobType = '7'
        AND CronJobDetail.Name LIKE :DealRegistrationToOpportunityJob_PP.class.getName() + '%'
    ];

    for (CronTrigger cronTrigger : cronTriggers)
      System.abortJob(cronTrigger.Id);
  }

  public Database.QueryLocator start(Database.BatchableContext context) {
    Set<Id> recordTypeIds = new Set<Id>{ DealRegistrations_PP.SUBMITTED_RECORDTYPE_ID };

    DealRegistrationsSelector_PP selector = (DealRegistrationsSelector_PP) Application_PP.Selector.newInstance(
      DealRegistration__c.SObjectType
    );

    return selector.queryLocatorWithoutOpportunityByRecordTypeIds(recordTypeIds);
  }

  public void execute(Database.BatchableContext context, List<DealRegistration__c> records) {
    DealRegistrationsService_PP service = (DealRegistrationsService_PP) Application_PP.Service.newInstance(
      DealRegistrationsService_PP.class
    );

    service.createOpportunitiesFromDealRegistrations(records);
  }

  public void finish(Database.BatchableContext context) {
  }
}