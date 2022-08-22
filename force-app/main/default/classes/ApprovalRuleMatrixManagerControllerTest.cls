@isTest
private class ApprovalRuleMatrixManagerControllerTest {
  @TestSetup
  private static void makeData() {
    sbaa__ApprovalChain__c chain = new sbaa__ApprovalChain__c();
    chain.Name = 'Commercial';
    chain.sbaa__TargetObject__c = 'SBQQ__Quote__c';
    chain.Migration_ID__c = 'TEST4324234';
    insert chain;

    //insert
    ApprovalRuleMatrix__c sobj = new ApprovalRuleMatrix__c(
      Name = 'CBO - Core Products > 70% Discount (Incl. Contracted Discount)',
      Active__c = true,
      ApprovalChain__c = chain.Id,
      ApprovalStep__c = 5,
      DynamicApproverField__c = 'Sales_Rep_s_Manager__c',
      Core_Products_List_Disc_Threshold__c = 70,
      List_Amount_in_USD_Threshold__c = 100000,
      System_Discount_Threshold__c = 0,
      PreApproved_Discount_Eligible__c = 'false',
      Migration_ID__c = 'RULE0243434',
      Deployed_To_Production__c = true
    );
    insert sobj;
  }

  @isTest
  private static void matrixControllerMethodsTest() {
    Test.startTest();

    ApprovalRuleMatrixManagerController.ApprovalRuleMatrixManagerWrapper wrapper = ApprovalRuleMatrixManagerController.getInitialData();
    System.assertEquals(wrapper.matrixList.isEmpty(), false, 'Matrix rules not fetched');

    ApprovalRuleMatrix__c matrix = wrapper.matrixList[0];
    ApprovalRuleMatrix__c updatedMatrix = ApprovalRuleMatrixManagerController.saveMatrixRule(JSON.serialize(matrix));
    System.assertEquals(updatedMatrix != null, true, 'Matrix saving failed');

    ApprovalRuleMatrixManagerController.deleteMatrixRecords(new List<String>{ matrix.Id });
    List<ApprovalRuleMatrix__c> afterDeleteList = [SELECT Id FROM ApprovalRuleMatrix__c WHERE Id = :matrix.Id];
    System.assertEquals(afterDeleteList.isEmpty(), true, 'Matrix deletion failed');

    Test.stopTest();
  }

  @isTest
  private static void generateRuleTest() {
    Test.startTest();

    List<ApprovalRuleMatrix__c> matrixList = [SELECT Id FROM ApprovalRuleMatrix__c];
    ApprovalRuleMatrix__c matrix = ApprovalRuleMatrixManagerController.generateRule(matrixList[0].Id);
    System.assertEquals(matrix.ApprovalRule__c != null, true, 'Approval Rule generation failed' + matrix);

    Test.stopTest();
  }

  @isTest
  private static void approvalRulesRunEvenWithoutTemplates() {
    Test.startTest();

    //delete all sbaa__EmailTemplate__c
    delete [SELECT Id FROM sbaa__EmailTemplate__c];
    List<ApprovalRuleMatrix__c> matrixList = [SELECT Id FROM ApprovalRuleMatrix__c];
    ApprovalRuleMatrix__c matrix = ApprovalRuleMatrixManagerController.generateRule(matrixList[0].Id);
    System.assertEquals(
      matrix.SyncStatus__c != 'Error',
      true,
      'Approval Rule generation works if templates arent there yet'
    );

    try {
      ApprovalRuleMatrixManagerController.deleteMatrixRecords(null);
    } catch (Exception e) {
    }

    try {
      ApprovalRuleMatrixManagerController.saveMatrixRule(null);
    } catch (Exception e) {
    }

    Test.stopTest();
  }
}