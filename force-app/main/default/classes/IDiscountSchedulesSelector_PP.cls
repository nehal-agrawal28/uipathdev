/**
 * File Name: IDiscountSchedulesSelector_PP
 *
 * @author: architect ir. Wilhelmus G.J. Velzeboer
 */
public interface IDiscountSchedulesSelector_PP extends fflib_ISObjectSelector {
  List<DiscountSchedule__c> selectActiveByAccountId(Set<Id> accountIds);
}