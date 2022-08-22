public without sharing class SharePartnerUsersJob_PP implements System.Schedulable, Database.Batchable<SObject> {
  // default is to run every day at midnight; note that timezone is dependent on running user's settings
  // second minute hour day_of_month month day_of_week optional_year
  public static final String DEFAULT_SCHEDULE = '0 0 0 * * ?';

  public void execute(SchedulableContext context) {
    Database.executeBatch(new SharePartnerUsersJob_PP(), 2);
  }

  public static String scheduleJob() {
    return scheduleJob(DEFAULT_SCHEDULE);
  }

  public static String scheduleJob(String scheduleString) {
    String name = SharePartnerUsersJob_PP.class.getName() + System.now().format(' yyyy-MM-dd HH:mm:ss z');

    return scheduleJob(name, scheduleString);
  }

  public static String scheduleJob(String name, String scheduleString) {
    return System.schedule(name, scheduleString, new SharePartnerUsersJob_PP());
  }

  public static void removeJobs() {
    List<CronTrigger> cronTriggers = [
      SELECT Id
      FROM CronTrigger
      WHERE CronJobDetail.JobType = '7' AND CronJobDetail.Name LIKE :SharePartnerUsersJob_PP.class.getName() + '%'
    ];

    for (CronTrigger cronTrigger : cronTriggers)
      System.abortJob(cronTrigger.Id);
  }

  public Database.QueryLocator start(Database.BatchableContext context) {
    UsersSelector_PP selector = (UsersSelector_PP) Application_PP.Selector.newInstance(User.SObjectType);

    return selector.queryLocatorDistributorUsers();
  }

  public void execute(Database.BatchableContext context, List<User> records) {
    UserSharesService_PP service = (UserSharesService_PP) Application_PP.Service.newInstance(
      UserSharesService_PP.class
    );

    service.sharePartnerUsers(records);
  }

  public void finish(Database.BatchableContext context) {
  }
}