/**
 * File Name: IDiscountUpliftConditions_PP
 *
 * @author: architect ir. Wilhelmus G.J. Velzeboer
 */
public interface IDiscountUpliftConditions_PP extends fflib_ISObjectDomain {
  fflib_Criteria getCriteriaEvaluator();
  Set<String> getFields();

  IDiscountUpliftConditions_PP selectByUpliftId(Id id);
}