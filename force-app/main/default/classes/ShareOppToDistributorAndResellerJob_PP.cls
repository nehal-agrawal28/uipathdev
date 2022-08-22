public without sharing class ShareOppToDistributorAndResellerJob_PP implements System.Schedulable, Database.Batchable<SObject> {
  // default is to run every day at midnight; note that timezone is dependent on running user's settings
  // second minute hour day_of_month month day_of_week optional_year
  public static final String DEFAULT_SCHEDULE = '0 0 0 * * ?';

  private Date createdDate;

  public ShareOppToDistributorAndResellerJob_PP() {
    createdDate = Date.today().addDays(-1);
  }

  public ShareOppToDistributorAndResellerJob_PP(Date createdDate) {
    this.createdDate = createdDate;
  }

  public void execute(SchedulableContext context) {
    Database.executeBatch(new ShareOppToDistributorAndResellerJob_PP());
  }

  public static String scheduleJob() {
    return scheduleJob(DEFAULT_SCHEDULE);
  }

  public static String scheduleJob(String scheduleString) {
    String name =
      ShareOppToDistributorAndResellerJob_PP.class.getName() + System.now().format(' yyyy-MM-dd HH:mm:ss z');

    return scheduleJob(name, scheduleString);
  }

  public static String scheduleJob(String name, String scheduleString) {
    return System.schedule(name, scheduleString, new ShareOppToDistributorAndResellerJob_PP());
  }

  public static void removeJobs() {
    List<CronTrigger> cronTriggers = [
      SELECT Id
      FROM CronTrigger
      WHERE
        CronJobDetail.JobType = '7'
        AND CronJobDetail.Name LIKE :ShareOppToDistributorAndResellerJob_PP.class.getName() + '%'
    ];

    for (CronTrigger cronTrigger : cronTriggers)
      System.abortJob(cronTrigger.Id);
  }

  public Database.QueryLocator start(Database.BatchableContext context) {
    OpportunitiesSelector_PP selector = (OpportunitiesSelector_PP) Application_PP.Selector.newInstance(
      Opportunity.SObjectType
    );

    return selector.queryLocatorWithSoldToAndTier2ByCreatedDate(createdDate);
  }

  public void execute(Database.BatchableContext context, List<Opportunity> records) {
    OpportunitiesService_PP service = (OpportunitiesService_PP) Application_PP.Service.newInstance(
      OpportunitiesService_PP.class
    );

    service.shareOppToDistributorAndReseller(records);
  }

  public void finish(Database.BatchableContext context) {
  }
}