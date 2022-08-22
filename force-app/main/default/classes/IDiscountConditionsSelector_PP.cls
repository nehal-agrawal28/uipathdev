/**
 * File Name: IDiscountConditionsSelector_PP
 *
 * @author: architect ir. Wilhelmus G.J. Velzeboer
 */
public interface IDiscountConditionsSelector_PP extends fflib_ISObjectSelector {
  List<DiscountCondition__c> selectByScheduleId(Set<Id> discountSchedulesIds);
}