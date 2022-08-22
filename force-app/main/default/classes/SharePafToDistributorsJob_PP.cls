public without sharing class SharePafToDistributorsJob_PP implements System.Schedulable, Database.Batchable<SObject> {
  // default is to run every day at midnight; note that timezone is dependent on running user's settings
  // second minute hour day_of_month month day_of_week optional_year
  public static final String DEFAULT_SCHEDULE = '0 0 0 * * ?';

  public void execute(SchedulableContext context) {
    Database.executeBatch(new SharePafToDistributorsJob_PP());
  }

  public static String scheduleJob() {
    return scheduleJob(DEFAULT_SCHEDULE);
  }

  public static String scheduleJob(String scheduleString) {
    String name = SharePafToDistributorsJob_PP.class.getName() + System.now().format(' yyyy-MM-dd HH:mm:ss z');

    return scheduleJob(name, scheduleString);
  }

  public static String scheduleJob(String name, String scheduleString) {
    return System.schedule(name, scheduleString, new SharePafToDistributorsJob_PP());
  }

  public static void removeJobs() {
    List<CronTrigger> cronTriggers = [
      SELECT Id
      FROM CronTrigger
      WHERE CronJobDetail.JobType = '7' AND CronJobDetail.Name LIKE :SharePafToDistributorsJob_PP.class.getName() + '%'
    ];

    for (CronTrigger cronTrigger : cronTriggers)
      System.abortJob(cronTrigger.Id);
  }

  public Database.QueryLocator start(Database.BatchableContext context) {
    PartnerApplicationFormsSelector_PP selector = (PartnerApplicationFormsSelector_PP) Application_PP.Selector.newInstance(
      Partner_Application_Form__c.SObjectType
    );

    return selector.queryLocatorWithCountries();
  }

  public void execute(Database.BatchableContext context, List<Partner_Application_Form__c> records) {
    PartnerApplicationFormsService_PP.shareWithDistributors(records);
  }

  public void finish(Database.BatchableContext context) {
  }
}