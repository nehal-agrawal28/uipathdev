/**
 * File Name: IQuoteLineItems_PP
 * Description:
 *
 * @author: architect ir. Wilhelmus G.J. Velzeboer
 */
public interface IQuoteLineItems_PP extends fflib_ISObjectDomain {
  Set<Id> getProductIds();
  List<SBQQ__QuoteLine__c> getQuoteLineItems();

  IQuoteLineItems_PP selectByQuoteId(Id id);
  IQuoteLineItems_PP selectByQuoteId(Set<Id> Ids);

  void setDiscountByProductId(Map<Id, Decimal> discountByProductId);

  IQuoteLineItems_PP increaseDiscountByProductId(Map<Id, Decimal> discountByProductId);

  IQuoteLineItems_PP increaseUpliftByProductId(Map<Id, Decimal> discountByProductId);

  IQuoteLineItems_PP setUpliftByProductId(Map<Id, Decimal> discountByProductId);

  IQuoteLineItems_PP setPartnerTierLevelDiscount(Integer discount);

  IQuoteLineItems_PP setBusinessPartnerTypeDiscount(Integer discount);
}