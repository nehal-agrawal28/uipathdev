/**
 * File Name: IDiscountTablesSelector_PP
 *
 * @author: architect ir. Wilhelmus G.J. Velzeboer
 */
public interface IDiscountTablesSelector_PP extends fflib_ISObjectSelector {
  List<DiscountTable__c> selectByIdWithItems(Set<Id> scheduleIds);
}