@IsTest
private class SharePafToDistributorsJobTest_PP {
  @IsTest
  private static void itShouldScheduleJob() {
    System.Test.startTest();

    // given
    List<CronTrigger> ctsBefore = [
      SELECT Id
      FROM CronTrigger
      WHERE CronJobDetail.JobType = '7' AND CronJobDetail.Name LIKE :SharePafToDistributorsJob_PP.class.getName() + '%'
    ];

    // when
    String jobId = SharePafToDistributorsJob_PP.scheduleJob();

    // then
    List<CronTrigger> ctsAfter = [
      SELECT Id
      FROM CronTrigger
      WHERE CronJobDetail.JobType = '7' AND CronJobDetail.Name LIKE :SharePafToDistributorsJob_PP.class.getName() + '%'
    ];

    System.assertEquals(false, ctsAfter.isEmpty());
    System.Test.stopTest();
  }

  @IsTest
  private static void itShouldRemoveJobs() {
    // given
    SharePafToDistributorsJob_PP.scheduleJob();

    List<CronTrigger> ctsBefore = [
      SELECT Id
      FROM CronTrigger
      WHERE CronJobDetail.JobType = '7' AND CronJobDetail.Name LIKE :SharePafToDistributorsJob_PP.class.getName() + '%'
    ];

    System.assertEquals(false, ctsBefore.isEmpty());

    // when
    SharePafToDistributorsJob_PP.removeJobs();

    // then
    List<CronTrigger> ctsAfter = [
      SELECT Id
      FROM CronTrigger
      WHERE CronJobDetail.JobType = '7' AND CronJobDetail.Name LIKE :SharePafToDistributorsJob_PP.class.getName() + '%'
    ];

    System.assertEquals(true, ctsAfter.isEmpty());
  }

  @IsTest
  private static void itShouldRunBatch() {
    // given

    // when
    Test.startTest();
    Database.executeBatch(new SharePafToDistributorsJob_PP());
    Test.stopTest();

    // then
  }
}