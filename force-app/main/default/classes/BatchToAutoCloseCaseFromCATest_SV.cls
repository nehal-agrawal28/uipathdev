@IsTest
public class BatchToAutoCloseCaseFromCATest_SV {
  @testSetup
  static void createTestData() {
    User newUser = DataFactory_SV.createUser('test1', 'test2', 'System Administrator', true);

    Account newAccount = DataFactory_SV.createAccount(
      'Unassigned Account',
      'Test  Street',
      'Test City',
      '123abc',
      'United Kingdom',
      '12345678',
      'Others',
      true
    );

    Contact newContact = DataFactory_SV.createContact(
      newAccount.Id,
      'Test',
      String.valueOf(System.now()),
      'test123123asd@asdawe.com',
      'Title',
      true
    );

    Case newCase = DataFactory_SV.createIncidentCase(false);
    newCase.AccountId = newAccount.Id;
    newCase.ContactId = newContact.Id;
    newCase.OwnerId = newUser.Id;
    insert newCase;
  }

  @isTest
  static void testBatchToAutoCloseCaseFromCA() {
    String CRON_EXP = '0 0 3 * * ?';
    Test.startTest();
    String jobId = System.schedule(
      'BatchToAutoCloseCaseFromCA_SV',
      CRON_EXP,
      new ScheduleBatchToAutoCloseCaseFromCA_SV()
    );
    CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
    System.assertEquals(0, ct.TimesTriggered);
    Test.stopTest();
  }
}