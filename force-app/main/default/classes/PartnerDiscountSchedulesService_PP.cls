public without sharing class PartnerDiscountSchedulesService_PP {
  public static IDiscountSchedules_PP getDiscountSchedulesForQuotes(IQuotes_PP quotes) {
    return service().getDiscountSchedulesForQuotes(quotes);
  }

  public static QuoteScheduleConditions_PP resolveQuoteScheduleConditions(IQuotes_PP quotes) {
    return service().resolveQuoteScheduleConditions(quotes);
  }

  private static IPartnerDiscountSchedulesService_PP service() {
    return (IPartnerDiscountSchedulesService_PP) Application_PP.Service.newInstance(
      IPartnerDiscountSchedulesService_PP.class
    );
  }
}