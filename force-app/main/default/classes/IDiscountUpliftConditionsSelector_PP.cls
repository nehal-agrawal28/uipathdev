/**
 * File Name: DiscountUpliftConditionsSelector_PP
 *
 * @author: architect ir. Wilhelmus G.J. Velzeboer
 */
public interface IDiscountUpliftConditionsSelector_PP extends fflib_ISObjectSelector {
  List<DiscountUpliftCondition__c> selectByUpliftId(Set<Id> upliftId);
}