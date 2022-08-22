/**
 * File Name: IDiscountConditions_PP
 *
 * @author: architect ir. Wilhelmus G.J. Velzeboer
 */
public interface IDiscountConditions_PP extends fflib_ISObjectDomain {
  /**
   * Translates the Discounts Conditions into dynamic fflib_Criteria conditions
   *
   * @return Instance of fflib_Criteria containing the defined discount conditions
   */
  fflib_Criteria getCriteriaEvaluator();

  List<DiscountCondition__c> getDiscountConditions();

  Set<String> getFields();

  IDiscountConditions_PP selectByScheduleId(Id scheduleId);
}