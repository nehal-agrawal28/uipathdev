public without sharing class SetDistributionRelationshipJob_PP implements System.Schedulable, Database.Batchable<SObject> {
  // default is to run every day at midnight; note that timezone is dependent on running user's settings
  // second minute hour day_of_month month day_of_week optional_year
  public static final String DEFAULT_SCHEDULE = '0 0 0 * * ?';

  public SetDistributionRelationshipJob_PP() {
    // Empty constructor - no fields required to instantiate.
  }

  public void execute(SchedulableContext context) {
    Database.executeBatch(new SetDistributionRelationshipJob_PP());
  }

  public static String scheduleJob() {
    return scheduleJob(DEFAULT_SCHEDULE);
  }

  public static String scheduleJob(String scheduleString) {
    String name = SetDistributionRelationshipJob_PP.class.getName() + System.now().format(' yyyy-MM-dd HH:mm:ss z');

    return scheduleJob(name, scheduleString);
  }

  public static String scheduleJob(String name, String scheduleString) {
    return System.schedule(name, scheduleString, new SetDistributionRelationshipJob_PP());
  }

  public static void removeJobs() {
    List<CronTrigger> cronTriggers = [
      SELECT Id
      FROM CronTrigger
      WHERE
        CronJobDetail.JobType = '7'
        AND CronJobDetail.Name LIKE :SetDistributionRelationshipJob_PP.class.getName() + '%'
    ];

    for (CronTrigger cronTrigger : cronTriggers)
      System.abortJob(cronTrigger.Id);
  }

  public Database.QueryLocator start(Database.BatchableContext context) {
    AccountRelationshipsSelector_PP selector = (AccountRelationshipsSelector_PP) Application_PP.Selector.newInstance(
      AccountRelationship.SObjectType
    );

    return selector.queryLocatorByType('VAR/Reseller');
  }

  public void execute(Database.BatchableContext context, List<AccountRelationship> records) {
    AccountsService_PP service = (AccountsService_PP) Application_PP.Service.newInstance(AccountsService_PP.class);

    service.setRelationshipOnAccount(records);
  }

  public void finish(Database.BatchableContext context) {
  }
}