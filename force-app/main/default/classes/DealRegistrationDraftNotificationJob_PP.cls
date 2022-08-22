public without sharing class DealRegistrationDraftNotificationJob_PP implements System.Schedulable, Database.Batchable<sObject> {
  public void execute(SchedulableContext context) {
    Database.executeBatch(new DealRegistrationDraftNotificationJob_PP());
  }

  public static String scheduleJob(String scheduleString) {
    String name =
      DealRegistrationDraftNotificationJob_PP.class.getName() + System.now().format(' yyyy-MM-dd HH:mm:ss z');

    return scheduleJob(name, scheduleString);
  }

  public static String scheduleJob(String name, String scheduleString) {
    return System.schedule(name, scheduleString, new DealRegistrationDraftNotificationJob_PP());
  }

  public static void removeJobs() {
    List<CronTrigger> cronTriggers = [
      SELECT Id
      FROM CronTrigger
      WHERE
        CronJobDetail.JobType = '7'
        AND CronJobDetail.Name LIKE :DealRegistrationDraftNotificationJob_PP.class.getName() + '%'
    ];

    for (CronTrigger cronTrigger : cronTriggers)
      System.abortJob(cronTrigger.Id);
  }

  public Database.QueryLocator start(Database.BatchableContext context) {
    DealRegistrationsSelector_PP selector = (DealRegistrationsSelector_PP) Application_PP.Selector.newInstance(
      DealRegistration__c.SObjectType
    );

    return selector.queryLocatorDraftsOlderThan7Days();
  }

  public void execute(Database.BatchableContext BC, List<DealRegistration__c> records) {
    try {
      EmailsService_PP emailsService = ((EmailsService_PP) Application_PP.Service.newInstance(EmailsService_PP.class));
      emailsService.sendNotificationsForDraftDealRegistrations(records);
    } catch (Exception e) {
      PartnerPortalException.LogException(
        e,
        'Sending Draft Notifications',
        ('Error while sending draft notification emails to the following Deal Regs' + records)
      );
    }
  }

  public void finish(Database.BatchableContext context) {
  }
}