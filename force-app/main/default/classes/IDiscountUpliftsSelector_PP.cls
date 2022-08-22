/**
 * File Name: IDiscountUpliftsSelector_PP
 *
 * @author: architect ir. Wilhelmus G.J. Velzeboer
 */
public interface IDiscountUpliftsSelector_PP extends fflib_ISObjectSelector {
  List<DiscountUplift__c> selectByAccountIdWithConditionsAndItems(Set<Id> accountIds);
}