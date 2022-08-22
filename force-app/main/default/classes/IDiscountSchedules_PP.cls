/**
 * File Name: IDiscountSchedules_PP
 */
public interface IDiscountSchedules_PP extends IDiscountTableParent {
  Set<Id> getRecordIds();

  IDiscountSchedules_PP selectByAccountId(Set<Id> ids);
  IDiscountSchedules_PP selectByAccountId(Id id);

  /**
   * Sorts the records contained in the domain in sequential order
   *
   * @return Sorted DiscountSchedule records in a domain
   */
  IDiscountSchedules_PP sort();

  List<DiscountSchedule__c> getDiscountSchedules();
}