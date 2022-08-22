/**
 * Generates Approval Rules and conditions from a list of Matrix Records
 * @author Girish Lakshmanan
 * @date 23/08/2019
 *
 */

public interface IApprovalRuleGenerationService {
  /**
   *
   *
   * @param sourceRecordIds are typically matrix record Ids
   *
   * @return
   */
  List<Id> generate(List<Id> sourceRecordIds);
}