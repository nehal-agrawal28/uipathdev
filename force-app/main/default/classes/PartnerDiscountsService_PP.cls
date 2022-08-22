/**
 * File Name: PartnerDiscountsService_PP
 *
 * @author: architect ir. Wilhelmus G.J. Velzeboer
 */
public without sharing class PartnerDiscountsService_PP {
  public static ProductDiscountInfos_PP calculateProductDiscount(Id quoteId) {
    return service().calculateProductDiscount(quoteId);
  }

  /**
   * Calculates the discount for each line item in the quote by retrieving the active and valid discount schedules
   * and taking the discount percentages from the discount tables
   *
   * @param quotes The quotes to recalculate
   * @param lineItems The line items of the quotes to recalculate
   *
   * @return Returns the recalculated QuoteLineItems (not updated in the database)
   */
  public static ProductDiscountInfos_PP calculateProductDiscount(IQuotes_PP quotes, IQuoteLineItems_PP lineItems) {
    return service().calculateProductDiscount(quotes, lineItems);
  }

  private static IPartnerDiscountsService_PP service() {
    return (IPartnerDiscountsService_PP) Application_PP.Service.newInstance(IPartnerDiscountsService_PP.class);
  }
}