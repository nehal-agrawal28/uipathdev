public without sharing class ShareDealRegistrationToPartnersJob_PP implements System.Schedulable, Database.Batchable<SObject> {
  // default is to run every day at midnight; note that timezone is dependent on running user's settings
  // second minute hour day_of_month month day_of_week optional_year
  public static final String DEFAULT_SCHEDULE = '0 0 0 * * ?';

  private Date createdDate;

  public ShareDealRegistrationToPartnersJob_PP() {
    createdDate = Date.today();
  }

  public ShareDealRegistrationToPartnersJob_PP(Date createdDate) {
    this.createdDate = createdDate;
  }

  public void execute(SchedulableContext context) {
    Database.executeBatch(new ShareDealRegistrationToPartnersJob_PP());
  }

  public static String scheduleJob() {
    return scheduleJob(DEFAULT_SCHEDULE);
  }

  public static String scheduleJob(String scheduleString) {
    String name = ShareDealRegistrationToPartnersJob_PP.class.getName() + System.now().format(' yyyy-MM-dd HH:mm:ss z');

    return scheduleJob(name, scheduleString);
  }

  public static String scheduleJob(String name, String scheduleString) {
    return System.schedule(name, scheduleString, new ShareDealRegistrationToPartnersJob_PP());
  }

  public static void removeJobs() {
    List<CronTrigger> cronTriggers = [
      SELECT Id
      FROM CronTrigger
      WHERE
        CronJobDetail.JobType = '7'
        AND CronJobDetail.Name LIKE :ShareDealRegistrationToPartnersJob_PP.class.getName() + '%'
    ];

    for (CronTrigger cronTrigger : cronTriggers)
      System.abortJob(cronTrigger.Id);
  }

  public Database.QueryLocator start(Database.BatchableContext context) {
    DealRegistrationsSelector_PP selector = (DealRegistrationsSelector_PP) Application_PP.Selector.newInstance(
      DealRegistration__c.SObjectType
    );

    return selector.queryLocatorWithPartnersByCreatedDate(createdDate);
  }

  public void execute(Database.BatchableContext context, List<DealRegistration__c> records) {
    DealRegistrationsService_PP service = (DealRegistrationsService_PP) Application_PP.Service.newInstance(
      DealRegistrationsService_PP.class
    );

    service.shareDealRegistrationToPartners(records);
  }

  public void finish(Database.BatchableContext context) {
  }
}