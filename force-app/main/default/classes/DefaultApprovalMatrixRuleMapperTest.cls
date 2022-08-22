/**
 * Tests for DefaultApprovalMatrixRuleMapper
 * @author Girish Lakshmanan
 * @date 23/08/2019
 *
 */

@IsTest
public with sharing class DefaultApprovalMatrixRuleMapperTest {
  @IsTest
  public static void canGenerateApprovalRuleRecordAndConditions() {
    sbaa__ApprovalChain__c chain = new sbaa__ApprovalChain__c();
    chain.Name = 'Commercial';
    chain.sbaa__TargetObject__c = 'SBQQ__Quote__c';
    chain.Migration_ID__c = 'TEST12321334';
    insert chain;

    //insert
    ApprovalRuleMatrix__c matrixRecord = new ApprovalRuleMatrix__c(
      Name = 'CBO - Core Products > 70% Discount (Incl. Contracted Discount)',
      Active__c = true,
      ApprovalChain__c = chain.Id,
      ApprovalStep__c = 5,
      DynamicApproverField__c = 'Sales_Rep_s_Manager__c',
      Core_Products_List_Disc_Threshold__c = 70,
      List_Amount_in_USD_Threshold__c = 100000,
      System_Discount_Threshold__c = 0,
      PreApproved_Discount_Eligible__c = 'false',
      Migration_ID__c = 'RULE04646212',
      MD5Hash__c = 'dsadasdsa2313eadsdasd1231',
      Deployed_To_Production__c = true
    );
    insert matrixRecord;

    DefaultApprovalMatrixRuleMapper service = new DefaultApprovalMatrixRuleMapper();
    sbaa__ApprovalRule__c approvalRule = service.buildRule(matrixRecord);

    Database.upsert(approvalRule, sbaa__ApprovalRule__c.Fields.Migration_ID__c);

    List<sbaa__ApprovalCondition__c> conditions = service.buildConditions(matrixRecord);

    for (sbaa__ApprovalCondition__c condition : conditions) {
      condition.sbaa__ApprovalRule__c = approvalRule.Id;
      condition.sbaa__ApprovalRule__r = approvalRule;
    }

    //Delete all existing Conditions
    Database.delete([SELECT id FROM sbaa__ApprovalCondition__c WHERE sbaa__ApprovalRule__c = :approvalRule.Id]);

    //Insert new Conditions
    List<Database.SaveResult> results = Database.insert(conditions);
  }
}