/**
 * File Name: IProducts_PP
 *
 * @author: architect ir. Wilhelmus G.J. Velzeboer
 */
public interface IProducts_PP extends fflib_ISObjectDomain {
  Map<Id, String> getDiscountCategoryById();
  List<Product2> getProducts();
  Map<Id, Product2> getRecordById();

  IProducts_PP selectById(Set<Id> productIds);
}