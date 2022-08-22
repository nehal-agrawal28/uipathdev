@IsTest
public class CaseFileDeleteSchedulerTest_SV {
  @testsetup
  public static void createTestRecord() {
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

    Case record = DataFactory_SV.createIncidentCase(false);
    record.AccountId = newAccount.Id;
    record.ContactId = newContact.Id;
    record.closedDate = system.today().adddays(-300);
    record.Related_To__c = 'Task Mining';
    record.Sub_Component__c = 'Visualizer';
    record.Closure_Classification__c = 'Bug';
    record.Solution__c = 'test';
    insert record;
    Test.setCreatedDate(record.Id, system.today().adddays(-300));
    record.Status = 'Closed';
    update record;
    system.debug([SELECT Id, ClosedDate, isClosed FROM Case]);
    Attachment att = DataFactory_SV.createAttachment(record.Id);
    Test.setCreatedDate(att.Id, system.today().adddays(-300));
  }

  @IsTest
  private static void CaseFileDeleteScheduler_SV_TestRun() {
    Test.startTest();
    CaseFileDeleteScheduler_SV bat = new CaseFileDeleteScheduler_SV();
    bat.isFullRun = true;
    System.schedule('CaseFileDeleteScheduler_SVTest1', '0 30 06 * * ?', bat);
    Test.stopTest();
  }

  @IsTest
  private static void CaseFileDeleteScheduler_SV_FullRun() {
    Test.startTest();
    CaseFileDeleteScheduler_SV bat = new CaseFileDeleteScheduler_SV();
    System.schedule('CaseFileDeleteScheduler_SVTest2', '0 30 06 * * ?', bat);
    Test.stopTest();
  }
}