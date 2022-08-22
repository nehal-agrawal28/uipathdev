/**
 * File Name: IPartnerDiscountsService_PP
 * Description:
 *
 * @author: architect ir. Wilhelmus G.J. Velzeboer
 */
public interface IPartnerDiscountsService_PP {
  ProductDiscountInfos_PP calculateProductDiscount(Id quoteId);
  /**
   * Calculates the discount for each line item in the quote by retrieving the active and valid discount schedules
   * and taking the discount percentages from the discount tables
   *
   * @param quotes The quotes to recalculate
   * @param lineItems The line items of the quotes to recalculate
   *
   * @return Returns the recalculated QuoteLineItems
   */
  ProductDiscountInfos_PP calculateProductDiscount(IQuotes_PP quotes, IQuoteLineItems_PP lineItems);
}