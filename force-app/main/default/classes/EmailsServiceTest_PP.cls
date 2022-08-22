@isTest(IsParallel=false)
public class EmailsServiceTest_PP {
  @isTest
  public static void itShouldSendEmailMessage() {
    //given email details and partner application forms
    User manager = new User(
      Alias = 'mng',
      Email = 'TestAdmin+5456@UiPath.com',
      EmailEncodingKey = 'UTF-8',
      LanguageLocaleKey = 'en_US',
      LastName = 'Test Apex',
      LocaleSidKey = 'en_US',
      TimeZoneSidKey = 'America/Los_Angeles',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator']
      .Id,
      Username = 'TestAdminMng_b@UiPath.com'
    );
    insert manager;

    User userWithManager = new User(
      Alias = 'usr1',
      ManagerId = manager.Id,
      Email = 'TestAdmin@UiPath.com',
      EmailEncodingKey = 'UTF-8',
      LanguageLocaleKey = 'en_US',
      LastName = 'Test Apex',
      LocaleSidKey = 'en_US',
      TimeZoneSidKey = 'America/Los_Angeles',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator']
      .Id,
      Username = 'TestAdminUsr1@UiPath.com'
    );
    insert userWithManager;

    Lead lead1 = new Lead(
      FirstName = 'test1',
      LastName = 'Lead',
      Company = 'test1 lead',
      Country = 'United States',
      Email = 'test1@uipath.com',
      OwnerId = userWithManager.Id
    );
    insert lead1;
    Lead lead2 = new Lead(
      FirstName = 'test2',
      LastName = 'Lead',
      Company = 'test2 lead',
      Country = 'Belgium',
      Email = 'test2@uipath.com',
      OwnerId = userWithManager.Id
    );
    insert lead2;

    Partner_Application_Form__c paf1 = new Partner_Application_Form__c(
      OwnerId = userWithManager.Id,
      Lead__c = lead1.Id,
      Application_Status_Date__c = System.today().addDays(-15)
    );
    insert paf1;
    Partner_Application_Form__c paf2 = new Partner_Application_Form__c(
      OwnerId = userWithManager.Id,
      Lead__c = lead2.Id,
      Application_Status_Date__c = System.today().addDays(-5)
    );
    insert paf2;
    List<Partner_Application_Form__c> pafs = new List<Partner_Application_Form__c>();
    pafs.add(paf1);
    pafs.add(paf2);

    Test.startTest();
    Integer invocationsBefore = Limits.getEmailInvocations();

    //when we run sendOpenFormReminder
    EmailsService_PP.sendOpenFormReminder(pafs);

    //then it should send emails accordingly
    System.assertEquals(invocationsBefore + 1, Limits.getEmailInvocations());
    Test.stopTest();
  }

  @isTest
  public static void itShouldSendEmailMessageToQueueMemb() {
    //given there is a group with 2 members, one other group and one user
    User user1 = new User(
      Alias = 'mng',
      Email = 'TestAdmin5645@UiPath.com',
      EmailEncodingKey = 'UTF-8',
      LanguageLocaleKey = 'en_US',
      LastName = 'Test Apex',
      LocaleSidKey = 'en_US',
      TimeZoneSidKey = 'America/Los_Angeles',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator']
      .Id,
      Username = 'TestAdminMng3258@UiPath.com'
    );
    User user2 = new User(
      Alias = 'mng',
      Email = 'TestAdmin57645@UiPath.com',
      EmailEncodingKey = 'UTF-8',
      LanguageLocaleKey = 'en_US',
      LastName = 'Test Apex',
      LocaleSidKey = 'en_US',
      TimeZoneSidKey = 'America/Los_Angeles',
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator']
      .Id,
      Username = 'TestAdminMng37258@UiPath.com'
    );
    insert user1;
    insert user2;
    Group group1 = new Group(Name = 'QUEUE NAME TEST', Type = 'Queue');
    insert group1;
    Group group2 = new Group(Name = 'OTHER QUEUE NAME TEST', DeveloperName = 'OTHERQUEUENAMETEST');
    insert group2;
    QueuesObject testQueue = new QueueSObject(QueueID = group1.id, SObjectType = 'Lead');
    GroupMember gmem1 = new GroupMember(UserOrGroupId = user1.id, GroupId = group1.id);
    GroupMember gmem2 = new GroupMember(UserOrGroupId = group2.id, GroupId = group1.id);
    System.runAs(new User(Id = UserInfo.getUserId())) {
      insert testQueue;
      insert gmem1;
      insert gmem2;
    }

    Lead lead1 = new Lead(
      FirstName = 'test1',
      LastName = 'Lead',
      Company = 'test1 lead',
      Country = 'United States',
      Email = 'test1testQueue@uipath.com',
      OwnerId = group1.Id
    );
    insert lead1;
    Partner_Application_Form__c paf1 = new Partner_Application_Form__c(
      OwnerId = user2.Id,
      Lead__c = lead1.Id,
      Application_Status_Date__c = System.today().addDays(-8)
    );
    insert paf1;

    Test.startTest();
    Integer invocationsBefore = Limits.getEmailInvocations();

    //when we run sendOpenFormReminder
    EmailsService_PP.sendOpenFormReminder(new List<Partner_Application_Form__c>{ paf1 });

    //then it should send emails accordingly
    System.assertEquals(invocationsBefore + 1, Limits.getEmailInvocations());
    Test.stopTest();
  }
}