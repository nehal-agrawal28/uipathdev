public class PafEmailReminderJob_PP implements System.Schedulable, Database.Batchable<SObject> {
  public static final String DEFAULT_SCHEDULE = '0 0 0 ? * MON *';

  public void execute(SchedulableContext context) {
    Database.executeBatch(new PafEmailReminderJob_PP());
  }

  public static String scheduleJob() {
    return scheduleJob(DEFAULT_SCHEDULE);
  }

  public static String scheduleJob(String scheduleString) {
    String name = PafEmailReminderJob_PP.class.getName() + System.now().format(' yyyy-MM-dd HH:mm:ss z');

    return scheduleJob(name, scheduleString);
  }

  public static String scheduleJob(String name, String scheduleString) {
    return System.schedule(name, scheduleString, new PafEmailReminderJob_PP());
  }

  public static void removeJobs() {
    List<CronTrigger> cronTriggers = [
      SELECT Id
      FROM CronTrigger
      WHERE CronJobDetail.JobType = '7' AND CronJobDetail.Name LIKE :PafEmailReminderJob_PP.class.getName() + '%'
    ];

    for (CronTrigger cronTrigger : cronTriggers)
      System.abortJob(cronTrigger.Id);
  }

  public Database.QueryLocator start(Database.BatchableContext context) {
    PartnerApplicationFormsSelector_PP selector = (PartnerApplicationFormsSelector_PP) Application_PP.Selector
      .newInstance(Schema.Partner_Application_Form__c.SObjectType);

    return selector.queryLocatorWithStatuses('Accept', 'New');
  }

  public void execute(Database.BatchableContext context, List<Partner_Application_Form__c> records) {
    EmailsService_PP.sendOpenFormReminder(records);
  }

  public void finish(Database.BatchableContext context) {
  }
}