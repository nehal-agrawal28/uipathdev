public interface IPartnerDiscountSchedulesService_PP {
  /**
   * Gets the active and applicable schedules for the given quotes
   * @param quotes The quotes to retrieve the schedules
   *
   * @return Returns the applicable uplifts
   */
  IDiscountSchedules_PP getDiscountSchedulesForQuotes(IQuotes_PP quotes);

  /**
   * Resolves all the conditions of the schedules for the quotes
   * @param quotes quotes The quotes to resolve the schedules
   *
   * @return The resolved conditions of the schedules
   */
  QuoteScheduleConditions_PP resolveQuoteScheduleConditions(IQuotes_PP quotes);
}