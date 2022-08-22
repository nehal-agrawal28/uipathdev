public inherited sharing class PartnerDiscountSchedulesServiceImpl_PP implements IPartnerDiscountSchedulesService_PP {
  /**
   * Gets the active and applicable schedules for the given quotes
   * @param quotes The quotes to retrieve the schedules
   *
   * @return Returns the applicable uplifts
   */
  public IDiscountSchedules_PP getDiscountSchedulesForQuotes(IQuotes_PP quotes) {
    QuoteScheduleConditions_PP quoteScheduleConditions = resolveQuoteScheduleConditions(quotes);
    return quoteScheduleConditions.selectApplicableSchedules();
  }

  /**
   * Resolves all the conditions of the schedules for the quotes
   * @param quotes quotes The quotes to resolve the schedules
   *
   * @return The resolved conditions of the schedules
   */
  public QuoteScheduleConditions_PP resolveQuoteScheduleConditions(IQuotes_PP quotes) {
    IDiscountSchedules_PP activeSchedules = getActiveSchedules(quotes);
    System.debug('activeSchedules:' + activeSchedules.getRecords().size());
    return resolveQuoteScheduleConditions(quotes.getRecordIds(), activeSchedules);
  }

  /**
   * Retrieves the schedules from the database with a status "Active" and fall in the right date range.
   *
   * @param quotes The quotes for which to retrieve their schedules
   *
   * @return The active schedules for the given quotes
   */
  private IDiscountSchedules_PP getActiveSchedules(IQuotes_PP quotes) {
    return DiscountSchedules_PP.newInstance(
      DiscountSchedulesSelector_PP.newInstance().selectActiveByAccountId(quotes.getPartnerIds())
    );
  }

  /**
   * Evaluates the conditions linked to each schedule and only returns the schedules where the conditions are met.
   *
   * @param quoteIds The quotes Id to query for evaluating the conditions
   * @param discountSchedules The Schedules to evaluate
   *
   * @return Returns Schedules where the conditions are met
   */
  private QuoteScheduleConditions_PP resolveQuoteScheduleConditions(
    Set<Id> quoteIds,
    IDiscountSchedules_PP discountSchedules
  ) {
    // get the Schedule conditions in sequential order
    IDiscountConditions_PP conditions = getConditions(discountSchedules);

    // get the referenced fields by the conditions
    Set<String> referencedFields = conditions.getFields();

    // retrieve the referenced data by the conditions
    IQuotes_PP quotesWithRelatedData = getQuotesWithReferencedData(quoteIds, referencedFields);

    // for each quote and schedule; check if it is applicable
    return resolveScheduleConditions(quotesWithRelatedData, discountSchedules, conditions);
  }

  /**
   * Evaluates the schedule conditions for each quote and report its result
   * @param quotes The quotes for which
   * @param schedules The schedules linked to the given quotes
   * @param conditions The conditions linked to the given schedules
   *
   * @return Returns QuoteScheduleConditions_PP with the evaluated result
   */
  private QuoteScheduleConditions_PP resolveScheduleConditions(
    IQuotes_PP quotes,
    IDiscountSchedules_PP schedules,
    IDiscountConditions_PP conditions
  ) {
    List<QuoteScheduleConditions_PP.Record> result = new List<QuoteScheduleConditions_PP.Record>();
    for (SBQQ__Quote__c quote : quotes.getQuotes()) {
      for (DiscountSchedule__c schedule : schedules.selectByAccountId(quote.SBQQ__Partner__c).getDiscountSchedules()) {
        IDiscountConditions_PP scheduleConditions = conditions.selectByScheduleId(schedule.Id);

        if (String.isBlank(schedule.ConditionFormula__c) || scheduleConditions.getRecords().isEmpty()) {
          result.add(new QuoteScheduleConditions_PP.Record(quote, schedule, '', true));
          continue;
        }

        fflib_Criteria criteria = scheduleConditions.getCriteriaEvaluator()
          .formulaCriteria(schedule.ConditionFormula__c);
        Boolean evaluatedCriteria = criteria.evaluate(quote);
        String evaluatedFormula = criteria.getEvaluatedFormula();
        result.add(new QuoteScheduleConditions_PP.Record(quote, schedule, evaluatedFormula, evaluatedCriteria));
      }
    }
    return QuoteScheduleConditions_PP.newInstance(result);
  }

  /**
   * Retrieves the quote records from the database which include the referenced fields
   *
   * @param quoteIds The quote Ids to query
   * @param referencedFields The fields to include in the query
   *
   * @return Returns instance of the Quotes_PP domain with the queried records containing the given referenced fields
   */
  private IQuotes_PP getQuotesWithReferencedData(Set<Id> quoteIds, Set<String> referencedFields) {
    return Quotes_PP.newInstance(
      QuotesSelector_PP.newWithoutSharingInstance().selectByIdWithReferences(quoteIds, referencedFields)
    );
  }

  /**
   * Retrieve the conditions for the schedules
   *
   * @param schedules The schedules for which the conditions needs to be retrieved
   *
   * @return Returns a domain with the conditions
   */
  private IDiscountConditions_PP getConditions(IDiscountSchedules_PP schedules) {
    return DiscountConditions_PP.newInstance(
      DiscountConditionsSelector_PP.newInstance().selectByScheduleId(schedules.getRecordIds())
    );
  }
}