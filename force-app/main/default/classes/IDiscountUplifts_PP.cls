/**
 * File Name: IDiscountUplifts_PP
 *
 * @author: architect ir. Wilhelmus G.J. Velzeboer
 */
public interface IDiscountUplifts_PP extends IDiscountTableParent {
  IDiscountUpliftConditions_PP getConditions();
  List<DiscountUplift__c> getDiscountUplifts();
  Set<Id> getRecordIds();

  Boolean isNotEmpty();

  IDiscountUplifts_PP selectByAccountId(Set<Id> ids);
  IDiscountUplifts_PP selectByAccountId(Id id);
}