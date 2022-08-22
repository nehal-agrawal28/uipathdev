@IsTest
public with sharing class ApprovalAssignToMeControllerTest {
  @TestSetup
  public static void makeData() {
    Account testAccount = DataFactory_CM.createAccount('Customer', true);

    Opportunity opp = DataFactory_SL.createOpportunity(testAccount.Id, true);

    sbaa__Approver__c apr = new sbaa__Approver__c(Name = 'ThisIsAGroup', sbaa__GroupId__c = '00G76000000IIMg');
    insert apr;

    sbaa__Approval__c ap = new sbaa__Approval__c(
      sbaa__Opportunity__c = opp.Id,
      sbaa__Status__c = 'Requested',
      sbaa__ApprovalStep__c = 4,
      sbaa__Approver__c = apr.Id,
      sbaa__RecordField__c = 'Quote__c'
    );
    insert ap;
  }

  @IsTest
  public static void assignApprovalTest() {
    sbaa__Approval__c ap = [SELECT Id FROM sbaa__Approval__c LIMIT 1];
    Test.startTest();
    ApprovalAssignToMeController.ApprovalAssignToMeWrapper result = ApprovalAssignToMeController.assignApprovalToMe(ap.Id);
    System.assertEquals(true, result != null);
    Test.stopTest();
  }

  @IsTest
  public static void assignApprovalNegativeTest() {
    Test.startTest();
    Boolean isExcp = false;
    try {
      ApprovalAssignToMeController.ApprovalAssignToMeWrapper result = ApprovalAssignToMeController.assignApprovalToMe(null);
    } catch (Exception ex) {
      isExcp = true;
    }
    System.assertEquals(true, isExcp);
    Test.stopTest();
  }
}