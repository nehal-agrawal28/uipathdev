@isTest
private class ApprovalRuleMatricesTest {
  @isTest
  private static void approvalRuleMatrixTriggerTest() {
    Test.startTest();

    sbaa__ApprovalChain__c chain = new sbaa__ApprovalChain__c();
    chain.Name = 'Commercial';
    chain.sbaa__TargetObject__c = 'SBQQ__Quote__c';
    chain.Migration_ID__c = 'TEST12121212';
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
      Migration_ID__c = 'RULE056324',
      Deployed_To_Production__c = true
    );
    insert sobj;

    //update
    sobj.Active__c = false;
    update sobj;

    Test.stopTest();
  }
}