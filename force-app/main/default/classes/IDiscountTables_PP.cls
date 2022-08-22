/**
 * File Name: IDiscountTables_PP
 *
 * @author: architect ir. Wilhelmus G.J. Velzeboer
 */
public interface IDiscountTables_PP extends fflib_ISObjectDomain {
  List<DiscountTable__c> getDiscountTables();
  Map<Id, DiscountTable__c> getRecordsById();

  IDiscountTables_PP selectById(Set<Id> ids);

  IDiscountTables_PP orderById(List<Id> ids);
}