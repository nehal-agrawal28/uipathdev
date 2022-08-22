/**
 * File Name: PartnerDiscountsServiceImpl_PP
 * @description Calculates the discount percentage for Partner Quotes
 *
 * @author : architect ir. Wilhelmus G.J. Velzeboer
 */
public without sharing class PartnerDiscountsServiceImpl_PP implements IPartnerDiscountsService_PP {
  // Method for demo purposes to use anonymous apex to trigger the logic
  public ProductDiscountInfos_PP calculateProductDiscount(Id quoteId) {
    IQuotes_PP quotes = Quotes_PP.newInstance(new Set<Id>{ quoteId });
    QuoteLineItems_PP lineItems = QuoteLineItems_PP.newInstance(
      [
        SELECT Id, SBQQ__Quote__c, SBQQ__Discount__c, SBQQ__Product__c
        FROM SBQQ__QuoteLine__c
        WHERE SBQQ__Quote__c = :quoteId
      ]
    );
    ProductDiscountInfos_PP result = calculateProductDiscount(quotes, lineItems);
    update lineItems.getRecords();

    return result;
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
  public ProductDiscountInfos_PP calculateProductDiscount(IQuotes_PP quotes, IQuoteLineItems_PP lineItems) {
    setDiscountToZero(lineItems);

    IDiscountSchedules_PP schedules = PartnerDiscountSchedulesService_PP.getDiscountSchedulesForQuotes(quotes);

    IDiscountUplifts_PP uplifts = getDiscountUpliftsForQuotes(quotes);

    IProducts_PP products = getProductsOfLineItems(lineItems);

    // Apply schedules on quotes
    ProductDiscountInfos_PP scheduleDiscountInfo = applyDiscountSchedules(quotes, lineItems, products, schedules);

    List<ProductDiscountInfos_PP.DiscountInfo> result = new List<ProductDiscountInfos_PP.DiscountInfo>(
      scheduleDiscountInfo.getDiscountInfos()
    );

    // Apply Uplift
    if (uplifts.isNotEmpty()) {
      ProductDiscountInfos_PP upliftDiscountInfo = applyDiscountUplifts(quotes, lineItems, products, uplifts);
      result.addAll(upliftDiscountInfo.getDiscountInfos());
    }

    return new ProductDiscountInfos_PP(result);
  }

  /**
   * It gets the discount tables linked to the schedules
   * and gets the discount category for each product used in the quotes
   * then applies the tables to the quote line items of each quote
   *
   * @param quotes The quotes to process
   * @param lineItems All the LineItems of all the quotes
   * @param products The products used in all LineItems
   * @param discountSchedules All the discount schedules linked (via Account) for the quotes
   *
   * @return Instance of DiscountInfos
   */
  private ProductDiscountInfos_PP applyDiscountSchedules(
    IQuotes_PP quotes,
    IQuoteLineItems_PP lineItems,
    IProducts_PP products,
    IDiscountSchedules_PP discountSchedules
  ) {
    // get the discount tables for the schedules
    IDiscountTables_PP discountTables = getDiscountTablesWithItems(discountSchedules.getDiscountTableIds());

    ProductDiscountInfos_PP result = new ProductDiscountInfos_PP();

    // Apply the discount table on each quote
    for (SBQQ__Quote__c quote : quotes.getQuotes()) {
      IDiscountSchedules_PP schedules = discountSchedules.selectByAccountId(quote.SBQQ__Partner__c).sort();
      IDiscountTables_PP tables = discountTables.selectById(schedules.getDiscountTableIds());

      IDiscountTables_PP orderedTables = getOrderedDiscountTables(schedules, tables);

      IQuoteLineItems_PP quoteLineItems = lineItems.selectByQuoteId(quote.Id);
      IProducts_PP lineItemProducts = products.selectById(quoteLineItems.getProductIds());

      ProductDiscountInfos_PP discountInformation = getDiscountInformation(
        quote,
        orderedTables,
        lineItemProducts,
        schedules,
        false
      );

      quoteLineItems.setDiscountByProductId(discountInformation.getDiscountByProductId());

      result.add(discountInformation);
    }
    return result;
  }

  /**
   * Goes through each quote line item and applies the discount table
   * @param quotes The quotes to process
   * @param lineItems The lineItems of all the quotes
   * @param products The products of the quote line items
   * @param discountUplifts The discount uplift definitions
   *
   * @return Instance of ProductDiscountInfos_PP containing detailed information about the applied discounts
   */
  private ProductDiscountInfos_PP applyDiscountUplifts(
    IQuotes_PP quotes,
    IQuoteLineItems_PP lineItems,
    IProducts_PP products,
    IDiscountUplifts_PP discountUplifts
  ) {
    // get discount tables for uplifts
    IDiscountTables_PP discountTables = getDiscountTablesWithItems(discountUplifts.getDiscountTableIds());

    List<ProductDiscountInfos_PP.DiscountInfo> result = new List<ProductDiscountInfos_PP.DiscountInfo>();

    // Apply the uplift for each quote
    for (SBQQ__Quote__c quote : quotes.getQuotes()) {
      IDiscountUplifts_PP uplifts = discountUplifts.selectByAccountId(quote.SBQQ__Distributor__c);
      IDiscountTables_PP tables = discountTables.selectById(uplifts.getDiscountTableIds());

      IQuoteLineItems_PP quoteLineItems = lineItems.selectByQuoteId(quote.Id);

      IProducts_PP lineItemProducts = products.selectById(quoteLineItems.getProductIds());

      ProductDiscountInfos_PP discountInformation = getDiscountInformation(
        quote,
        tables,
        lineItemProducts,
        uplifts,
        true
      );

      quoteLineItems.setUpliftByProductId(discountInformation.getDiscountByProductId());

      result.addAll(discountInformation.getDiscountInfos());
    }
    return new ProductDiscountInfos_PP(result);
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
      DiscountSchedulesSelector_PP.newElevatedInstance().selectActiveByAccountId(quotes.getPartnerIds())
    );
  }

  /**
   * Retrieves the active uplifts for the given quotes
   * @param quotes The quotes
   *
   * @return Domain containing the active uplifts
   */
  private IDiscountUplifts_PP getActiveUplifts(IQuotes_PP quotes) {
    return DiscountUplifts_PP.newInstance(
      DiscountUpliftsSelector_PP.newElevatedInstance()
        .selectByAccountIdWithConditionsAndItems(quotes.getDistributorIds())
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
  private IDiscountSchedules_PP getApplicableSchedules(Set<Id> quoteIds, IDiscountSchedules_PP discountSchedules) {
    // get the Schedule conditions in sequential order
    IDiscountConditions_PP conditions = DiscountConditions_PP.newInstance(
      DiscountConditionsSelector_PP.newElevatedInstance().selectByScheduleId(discountSchedules.getRecordIds())
    );

    // get the referenced fields by the conditions
    Set<String> referencedFields = conditions.getFields();

    // retrieve the referenced data by the conditions
    IQuotes_PP quotesWithRelatedData = Quotes_PP.newInstance(
      QuotesSelector_PP.newWithoutSharingInstance().selectByIdWithReferences(quoteIds, referencedFields)
    );

    // for each quote and schedule; check if it is applicable
    List<DiscountSchedule__c> result = new List<DiscountSchedule__c>();
    for (SBQQ__Quote__c quote : quotesWithRelatedData.getQuotes()) {
      for (
        DiscountSchedule__c schedule : discountSchedules.selectByAccountId(quote.SBQQ__Partner__c)
          .getDiscountSchedules()
      ) {
        IDiscountConditions_PP scheduleConditions = conditions.selectByScheduleId(schedule.Id);
        if (scheduleConditions.getRecords().isEmpty() || isApplicableSchedule(quote, schedule, scheduleConditions)) {
          result.add(schedule);
        }
      }
    }
    return DiscountSchedules_PP.newInstance(result);
  }

  /**
   * Determines based on the uplift conditions if the given uplifts are applicable for the given quotes
   * @param quoteIds The quote Ids to check
   * @param uplifts The uplifts to validate for the given quotes
   *
   * @return Domain with the applicable uplifts
   */
  private IDiscountUplifts_PP getApplicableUplifts(Set<Id> quoteIds, IDiscountUplifts_PP uplifts) {
    // get the Uplift conditions
    IDiscountUpliftConditions_PP conditions = DiscountUpliftConditions_PP.newInstance(
      DiscountUpliftConditionsSelector_PP.newElevatedInstance().selectByUpliftId(uplifts.getRecordIds())
    );

    // get the referenced fields by the conditions
    Set<String> referencedFields = conditions.getFields();

    // retrieve the referenced data by the conditions
    IQuotes_PP quotesWithRelatedData = Quotes_PP.newInstance(
      QuotesSelector_PP.newWithoutSharingInstance().selectByIdWithReferences(quoteIds, referencedFields)
    );

    // for each quote and uplift; check if it is applicable
    List<DiscountUplift__c> result = new List<DiscountUplift__c>();
    for (SBQQ__Quote__c quote : quotesWithRelatedData.getQuotes()) {
      List<DiscountUplift__c> discountUplifts = uplifts.selectByAccountId(quote.SBQQ__Distributor__c)
        .getDiscountUplifts();
      for (DiscountUplift__c uplift : discountUplifts) {
        IDiscountUpliftConditions_PP upliftConditions = conditions.selectByUpliftId(uplift.Id);
        if (upliftConditions.getRecords().isEmpty() || isApplicableUplift(quote, uplift, upliftConditions)) {
          result.add(uplift);
        }
      }
    }
    return DiscountUplifts_PP.newInstance(result);
  }

  /**
   * Gets the discount defined in the discount tables for each product category
   *
   * @param quote
   * @param discountTables The discount tables holding the discount percentage for each category
   * @param products The products used in the Line Items
   * @param reasons
   * @param cumulative Add tables cumulatively if TRUE otherwise find and apply first occurrence of discount category
   *
   * @return Returns the discount percentage for each discount category.
   */
  private ProductDiscountInfos_PP getDiscountInformation(
    SBQQ__Quote__c quote,
    IDiscountTables_PP discountTables,
    IProducts_PP products,
    IDiscountTableParent reasons,
    Boolean cumulative
  ) {
    Map<Id, Product2> productById = products.getRecordById();
    ProductDiscountInfos_PP result = new ProductDiscountInfos_PP();
    Map<Id, DiscountTable__c> discountTableByIds = discountTables.getRecordsById();

    for (Id productId : productById.keySet()) {
      Boolean hasDiscount = false;

      for (SObject reason : reasons.getRecords()) {
        Id discountTableId = (Id) reason.get('DiscountTable__c');
        DiscountTable__c table = discountTableByIds.get(discountTableId);

        for (DiscountTableItem__c item : table.DiscountTableItems__r) {
          if (
            // Table item is linked to a category
            (String.isNotBlank(item.Category__c) &&
            productById.get(productId).PartnerDiscountCategory__c == item.Category__c) ||
            // table item is linked to a product
            (item.Product__c != null &&
            item.Product__c == productId)
          ) {
            hasDiscount = true;
            result.addDiscount(quote.Id, productId, item.DiscountPercentage__c, reason);
            break;
          }
        }
        if (hasDiscount && !cumulative)
          break;
      }
    }
    return result;
  }

  /**
   * Gets the discount tables with the related discount table items
   *
   * @param discountTableIds The schedule Ids for which to retrieve the discount tables
   *
   * @return Returns the DiscountTables with related discount table items
   */
  private IDiscountTables_PP getDiscountTablesWithItems(Set<Id> discountTableIds) {
    return DiscountTables_PP.newInstance(
      DiscountTablesSelector_PP.newElevatedInstance().selectByIdWithItems(discountTableIds)
    );
  }

  /**
   * Gets the active and applicable uplifts for the given quotes
   * @param quotes The quotes to retrieve the uplifts
   *
   * @return Returns the applicable uplifts
   */
  private IDiscountUplifts_PP getDiscountUpliftsForQuotes(IQuotes_PP quotes) {
    IDiscountUplifts_PP activeUplifts = getActiveUplifts(quotes);

    // Find which uplifts are applicable for the quotes
    IDiscountUplifts_PP uplifts = getApplicableUplifts(quotes.getRecordIds(), activeUplifts);
    return uplifts;
  }

  /**
   * Sorts the Discount schedules based on their sequence and returns the tables in that order.
   *
   * @param discountSchedules The DiscountSchedules holding the sequence number
   * @param discountTables The tables to order
   *
   * @return Returns Discount Tables in sequential order of the Discount Schedules.
   */
  private IDiscountTables_PP getOrderedDiscountTables(
    IDiscountSchedules_PP discountSchedules,
    IDiscountTables_PP discountTables
  ) {
    IDiscountSchedules_PP sortedSchedules = discountSchedules.sort();
    List<Id> sortedDiscountTableIds = sortedSchedules.getDiscountTableIdList();
    return discountTables.orderById(sortedDiscountTableIds);
  }

  /**
   * Get all the Product2 records for the given lineItems
   * @param lineItems The lineItems to retrieve their products
   *
   * @return Domain containing the products of the lineItems
   */
  private static IProducts_PP getProductsOfLineItems(IQuoteLineItems_PP lineItems) {
    IProducts_PP products = Products_PP.newInstance(lineItems.getProductIds());
    return products;
  }

  /**
   * Determine if a Schedule is applicable based on the conditions of the schedule
   * Note: If an error occurs when evaluating the conditions, the method return FALSE
   *
   * @param quote The Quote containing data used by the conditions
   * @param discountSchedule The Schedule linked to the given Quote
   * @param conditions The Conditions linked to the given discountSchedule
   *
   * @return Returns true is the conditions match with the given Quote and its related data
   */
  // DEPRECATED
  private Boolean isApplicableSchedule(
    SBQQ__Quote__c quote,
    DiscountSchedule__c discountSchedule,
    IDiscountConditions_PP conditions
  ) {
    if (String.isBlank(discountSchedule.ConditionFormula__c))
      return true;
    Boolean result = conditions.getCriteriaEvaluator()
      .formulaCriteria(discountSchedule.ConditionFormula__c)
      .evaluate(quote);

    // On the event of an error during the evaluation of the formula, ignore the entire schedule
    if (result == null)
      return false;

    return result;
  }

  /**
   * De
   * termine if a Schedule is applicable based on the conditions of the schedule
   * Note: If an error occurs when evaluating the conditions, the method return FALSE
   *
   * @param quote The Quote containing data used by the conditions
   * @param uplift The Uplift linked to the given Quote
   * @param conditions The Conditions linked to the given discountSchedule
   *
   * @return Returns true is the conditions match with the given Quote and its related data
   */
  private Boolean isApplicableUplift(
    SBQQ__Quote__c quote,
    DiscountUplift__c uplift,
    IDiscountUpliftConditions_PP conditions
  ) {
    if (String.isBlank(uplift.ConditionFormula__c))
      return true;
    Boolean result = conditions.getCriteriaEvaluator().formulaCriteria(uplift.ConditionFormula__c).evaluate(quote);

    // On the event of an error during the evaluation of the formula, ignore the entire schedule
    if (result == null)
      return false;

    return result;
  }

  /**
   * Reset all the LineItems Discount values to zero
   * @param lineItems The lineItems to reset their discount
   */
  private static void setDiscountToZero(IQuoteLineItems_PP lineItems) {
    lineItems.setPartnerTierLevelDiscount(0).setBusinessPartnerTypeDiscount(0);
  }
}