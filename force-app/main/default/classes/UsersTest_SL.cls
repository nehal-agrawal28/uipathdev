@IsTest(IsParallel=false)
private class UsersTest_SL {
  @TestSetup
  static void setup() {
    Profile adminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
    List<User> users = new List<User>();
    List<sbaa__Approver__c> approvers = new List<sbaa__Approver__c>();

    User adminUser1 = new User(
      Alias = 'alias',
      Email = 'testAdmin1@UiPath.com',
      EmailEncodingKey = 'UTF-8',
      LanguageLocaleKey = 'en_US',
      LastName = 'Test Apex',
      LocaleSidKey = 'en_US',
      TimeZoneSidKey = 'America/Los_Angeles',
      ProfileId = adminProfile.Id,
      Username = 'testAdmin1@UiPath.com'
    );
    users.add(adminUser1);

    User adminUser2 = new User(
      Alias = 'alias',
      Email = 'testAdmin2@UiPath.com',
      EmailEncodingKey = 'UTF-8',
      LanguageLocaleKey = 'en_US',
      LastName = 'Test Apex',
      LocaleSidKey = 'en_US',
      TimeZoneSidKey = 'America/Los_Angeles',
      ProfileId = adminProfile.Id,
      Username = 'testAdmin2@UiPath.com'
    );
    users.add(adminUser2);
    insert users;

    sbaa__Approver__c approver1 = new sbaa__Approver__c(Name = 'Admin User One', sbaa__User__c = adminUser1.Id);
    approvers.add(approver1);

    sbaa__Approver__c approver2 = new sbaa__Approver__c(Name = 'Admin User Two', sbaa__User__c = adminUser2.Id);
    approvers.add(approver2);

    insert approvers;
  }

  @IsTest
  static void populateDelegatedUser() {
    User currentUser = getUserRecord('testAdmin1@UiPath.com');
    User delegatedUser = getUserRecord('testAdmin2@UiPath.com');
    sbaa__Approver__c delegatedApprover = getApproverRecord(delegatedUser.Id);
    currentUser.DelegatedApproverId = delegatedUser.Id;
    update currentUser;
    try {
      Test.startTest();
      System.runAs(delegatedUser) {
        new UserAdvancedApprovalQueueable_SL(new List<User>{ currentUser }).work();
      }
      Test.stopTest();
      sbaa__Approver__c currentdApprover = getApproverRecord(currentUser.Id);
      System.assertEquals(
        delegatedApprover.Id,
        currentdApprover.sbaa__DelegatedApprover__c,
        'Approver Id should match'
      );
    } catch (Exception e) {
      System.debug(e.getMessage() + e.getStackTraceString());
    }
  }

  private static User getUserRecord(String userName) {
    return [SELECT Id, DelegatedApproverId FROM User WHERE UserName = :userName LIMIT 1];
  }

  private static sbaa__Approver__c getApproverRecord(Id userId) {
    return [SELECT Id, sbaa__DelegatedApprover__c FROM sbaa__Approver__c WHERE sbaa__User__c = :userId LIMIT 1];
  }
}