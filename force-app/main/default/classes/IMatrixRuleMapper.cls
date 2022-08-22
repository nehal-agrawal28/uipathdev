/**
 * @author Girish Lakshmanan
 * @date 27/06/2019
 * @description Strategy Interface that allows multiple ways to map a matrix record to an Approval Rule.
 * A default implementation DefaultApprovalMatrixRuleMapper is implemented but can be swapped for any implementation
 *
 */
public interface IMatrixRuleMapper {
  /**
   * takes an approval matrix record and returns an approval rule.
   * The generated rule is only in memory and is not inserted yet.
   * Will need DML by the caller if persistence is required.
   *
   * @param matrixRecord
   *
   * @return
   */
  sbaa__ApprovalRule__c buildRule(ApprovalRuleMatrix__c matrixRecord);

  /**
   * takes an approval matrix record and returns a list of conditions.
   * The generated rule is only in memory and is not inserted yet.
   * Will need DML by the caller if persistence is required.
   *
   * @param matrixRecord
   *
   * @return
   */
  List<sbaa__ApprovalCondition__c> buildConditions(ApprovalRuleMatrix__c matrixRecord);
}