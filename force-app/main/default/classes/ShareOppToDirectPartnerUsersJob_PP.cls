public without sharing class ShareOppToDirectPartnerUsersJob_PP implements System.Schedulable, Database.Batchable<SObject> {
  public static final String DEFAULT_SCHEDULE = '0 0 0 * * ?';

  public void execute(SchedulableContext context) {
    Database.executeBatch(new ShareOppToDirectPartnerUsersJob_PP(), 10);
  }

  public static String scheduleJob() {
    return scheduleJob(DEFAULT_SCHEDULE);
  }

  public static String scheduleJob(String scheduleString) {
    String name = ShareOppToDirectPartnerUsersJob_PP.class.getName() + System.now().format(' yyyy-MM-dd HH:mm:ss z');
    return scheduleJob(name, scheduleString);
  }

  public static String scheduleJob(String name, String scheduleString) {
    return System.schedule(name, scheduleString, new ShareOppToDirectPartnerUsersJob_PP());
  }

  public static void removeJobs() {
    List<CronTrigger> cronTriggers = [
      SELECT Id
      FROM CronTrigger
      WHERE
        CronJobDetail.JobType = '7'
        AND CronJobDetail.Name LIKE :ShareOppToDirectPartnerUsersJob_PP.class.getName() + '%'
    ];

    for (CronTrigger cronTrigger : cronTriggers) {
      System.abortJob(cronTrigger.Id);
    }
  }

  public Database.QueryLocator start(Database.BatchableContext context) {
    UsersSelector_PP selector = (UsersSelector_PP) Application_PP.Selector.newInstance(User.SObjectType);

    return selector.getUsersByAccountBusinessPartnerType();
  }

  public void execute(Database.BatchableContext context, List<User> records) {
    OpportunitySharesService_PP service = (OpportunitySharesService_PP) Application_PP.Service.newInstance(
      OpportunitySharesService_PP.class
    );

    service.createOpportunityShares(records);
  }

  public void finish(Database.BatchableContext context) {
  }
}