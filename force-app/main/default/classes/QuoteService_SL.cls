global with sharing class QuoteService_SL implements IQuoteService_SL, SBQQ.CalculateCallback {
  private QuotesSelector_SL quotesSelectorSL {
    get {
      return (QuotesSelector_SL) Application_SL.Selector.newInstance(SBQQ__Quote__c.SObjectType);
    }
    set;
  }

  public SBQQ__Quote__c createQuoteForOpportunity(Date startDate, Date endDate, Id opportunityId) {
    return createQuoteForOpportunity(startDate, endDate, opportunityId, false);
  }

  public SBQQ__Quote__c createQuoteForOpportunity(
    Date startDate,
    Date endDate,
    Id opportunityId,
    Boolean replacementTransaction
  ) {
    SBQQ__Quote__c quote = new SBQQ__Quote__c();
    quote.SBQQ__Primary__c = true;
    quote.SBQQ__Opportunity2__c = opportunityId;
    quote.SBQQ__StartDate__c = startDate;
    quote.SBQQ__EndDate__c = endDate;
    quote.Replacement_Transaction__c = replacementTransaction;
    fflib_ISObjectUnitOfWork unitOfWork = Application_SL.UnitOfWork.newInstance();
    unitOfWork.registerNew(quote);
    unitOfWork.commitWork();

    return quote;
  }

  public Map<Id, SBQQ__Quote__c> syncFieldOnCancelledQuotes(Set<Id> replacementQuoteIds, SObjectField field) {
    Map<Id, SBQQ__Quote__c> childQuotesToUpdate = new Map<Id, SBQQ__Quote__c>();
    Map<Id, SBQQ__Quote__c> updatedChildQuotes = new Map<Id, SBQQ__Quote__c>();

    //get replacement quotes
    Map<Id, SBQQ__Quote__c> replacementQuotes = new Map<Id, SBQQ__Quote__c>(
      quotesSelectorSL.selectById(replacementQuoteIds, false)
    );
    //get all the child quotes for the supplied parent quote ids
    List<SBQQ__Quote__c> childQuotes = quotesSelectorSL.getCancelledQuotesByReplacedQuotes(replacementQuoteIds);

    //determine if parent quote field and child quote field !=
    for (SBQQ__Quote__c quote : childQuotes) {
      SBQQ__Quote__c parentQuote = replacementQuotes.get(quote.Replacement_Quote__c);
      if (quote.get(field) != parentQuote.get(field)) {
        quote.put(field, parentQuote.get(field));
        childQuotesToUpdate.put(quote.Id, quote);
      }
    }

    //perform update to child quote
    for (SBQQ__Quote__c quote : childQuotesToUpdate.values()) {
      DescribeFieldResult descrResult = field.getDescribe();
      SBQQ__Quote__c updatedQuote = updateQuote(
        quote.Id,
        descrResult.name,
        String.valueOf(quote.get(field)),
        descrResult.getSoapType().name()
      );
      updatedChildQuotes.put(updatedQuote.Id, updatedQuote);
    }

    return updatedChildQuotes;
  }

  public static SBQQ__Quote__c updateQuote(String quoteId, String fieldName, String fieldValue, String fieldType) {
    SBQQ__Quote__c quote = new SBQQ__Quote__c(Id = quoteId);
    List<SBQQ__Quote__c> queueableQuoteUpdate = new List<SBQQ__Quote__c>();

    switch on fieldType {
      when 'DATE' {
        quote.put(fieldName, Date.valueOf(fieldValue));
      }
      when 'BOOLEAN' {
        quote.put(fieldName, Boolean.valueOf(fieldValue));
        queueableQuoteUpdate.add(quote);
      }
      when else {
        System.debug(
          LoggingLevel.INFO,
          'fieldName:fieldType:fieldValue ' +
          fieldName +
          ':' +
          fieldType +
          ':' +
          fieldValue
        );
        quote.put(fieldName, fieldValue);
      }
    }
    return quote;
  }

  public static void quoteUpdater(Id quoteId) {
    try {
      CPQQuoteCalculator_SL calculator = new CPQQuoteCalculator_SL();
      CPQModel_Quote_SL model = calculator.read(quoteId);
      model = calculator.read(quoteId);
      calculator.calculate(model, 'QuoteService_SL');
    } catch (Exception e) {
      Logger.error('Failed synchronising replacement and cancellation quote fields', quoteId, e);
      System.debug(LoggingLevel.ERROR, e.getMessage());
      throw e;
    }
  }

  global void callback(String quote) {
    // save the quote
    String quoteJSON = SBQQ.ServiceRouter.save('SBQQ.QuoteAPI.QuoteSaver', quote);
    CPQModel_Quote_SL model = (CPQModel_Quote_SL) JSON.deserialize(quoteJSON, CPQModel_Quote_SL.class);
    System.debug(LoggingLevel.INFO, 'QuoteService_SL:callback executed');
    if (!System.isFuture()) {
      forceQuoteReCalcAsync(model.record.Id);
    } else {
      forceQuoteReSync(model.record.Id);
    }
  }

  @future(callout=true)
  private static void forceQuoteReCalcAsync(Id quoteId) {
    forceQuoteReSync(quoteId);
  }

  private static void forceQuoteReSync(Id quoteId) {
    QuotesSelector_SL quoteSelector = (QuotesSelector_SL) Application_SL.Selector.newInstance(
      SBQQ__Quote__c.SObjectType
    );
    List<SBQQ__Quote__c> quotes = quoteSelector.selectById(new Set<Id>{ quoteId }, false);
    Collection.of(quotes).mapAll(new NegateBooleanFunction_SL('Force_Calculation__c'));
    final fflib_ISObjectUnitOfWork unitOfWork = Application_SL.UnitOfWork.newInstance();
    unitOfWork.registerDirty(quotes);
    unitOfWork.commitWork();
  }

  public void addProductsToQuote(Id quoteId, List<Id> productIds, Double targetCustomerAmount) {
    CPQServiceRouter_SL serviceRouter = new CPQServiceRouter_SL();
    CPQModel_Quote_SL quoteModel = serviceRouter.readQuote(quoteId);
    CPQModel_Product_SL[] productModels = new List<CPQModel_Product_SL>(productIds.size());

    List<SBQQ__Quote__c> quotes = quotesSelectorSL.selectById(new Set<Id>{ quoteId }, false);

    for (Integer i = 0; i < productIds.size(); i++) {
      productModels[i] = serviceRouter.loadProductModel(
        productIds[i],
        OpportunityMetadata_SL.DefaultPriceBookMap.get(Constants_SL.DEFAULT_PRICE_BOOK),
        quotes.get(0).CurrencyIsoCode
      );
      productModels[i] = CPQServiceRouter_SL.setOptionsConfigured(productModels[i]);
    }

    CPQModel_Quote_SL quoteWithProducts = serviceRouter.addProductsToQuote(quoteModel, productModels, 0);
    if (targetCustomerAmount != null) {
      quoteWithProducts.record.SBQQ__TargetCustomerAmount__c = targetCustomerAmount;
    }
    serviceRouter.saveQuote(quoteWithProducts);
    forceQuoteReCalcAsync(quoteId);
  }

  /**
   * @param quoteId
   * @param packageProductId
   * @param optionProductIds
   * @param targetCustomerAmount
   * @description Adds a package product and some of its options to the given Quote. Assumes the added SKUs sit directly under the package. This method
   * currently does not support nested products
   */
  public void addPackageWithOptions(
    Id quoteId,
    Id packageProductId,
    List<Id> optionProductIds,
    Double targetCustomerAmount
  ) {
    CPQServiceRouter_SL serviceRouter = new CPQServiceRouter_SL();
    CPQModel_Quote_SL quoteModel = serviceRouter.readQuote(quoteId);
    List<SBQQ__Quote__c> quotes = quotesSelectorSL.selectById(new Set<Id>{ quoteId }, false);

    CPQModel_Product_SL productModel = serviceRouter.loadProductModel(
      packageProductId,
      OpportunityMetadata_SL.DefaultPriceBookMap.get(Constants_SL.DEFAULT_PRICE_BOOK),
      quotes.get(0).CurrencyIsoCode
    );

    if (productModel.configuration != null) {
      productModel.configuration.optionConfigurations.clear();
    }

    productModel = addOptionsToModel(productModel, optionProductIds);
    Decimal totalUnitPrice = getTotalUnitPrice(productModel);
    deriveDefaultQuantities(
      productModel.configuration.optionConfigurations,
      quotes.get(0).Quote_Duration__c,
      totalUnitPrice,
      targetCustomerAmount
    );
    productModel = CPQServiceRouter_SL.setOptionsConfigured(productModel);

    CPQModel_Quote_SL quoteWithProducts = serviceRouter.addProductsToQuote(
      quoteModel,
      new List<CPQModel_Product_SL>{ productModel },
      0
    );
    if (targetCustomerAmount != null) {
      quoteWithProducts.record.SBQQ__TargetCustomerAmount__c = targetCustomerAmount;
    }
    serviceRouter.saveQuote(quoteWithProducts);
    forceQuoteReCalcAsync(quoteId);
  }

  /**
   * @param optionConfigs Options for which quantities need defaulting
   * @param duration quote duration
   * @param totalUnitPrice total list price across all options
   * @param targetCustomerAmount total desired quote value
   */
  private void deriveDefaultQuantities(
    CPQModel_Configuration_SL[] optionConfigs,
    Decimal duration,
    Decimal totalUnitPrice,
    Double targetCustomerAmount
  ) {
    for (CPQModel_Configuration_SL optionConfig : optionConfigs) {
      Decimal approxProratedPrice = (optionConfig.optionData.SBQQ__UnitPrice__c / 365) * duration;
      Decimal optionTargetAmount = (optionConfig.optionData.SBQQ__UnitPrice__c / totalUnitPrice) * targetCustomerAmount;

      if (approxProratedPrice < optionTargetAmount) {
        Integer qty = (Integer) (optionTargetAmount / approxProratedPrice);
        optionConfig.optionData.SBQQ__Quantity__c = qty + 1;
      } else {
        optionConfig.optionData.SBQQ__Quantity__c = 1;
      }
    }
  }

  private Decimal getTotalUnitPrice(CPQModel_Product_SL productModel) {
    Decimal total = 0;
    for (CPQModel_Configuration_SL config : productModel.configuration.optionConfigurations) {
      total += config.optionData.SBQQ__UnitPrice__c;
    }
    return total;
  }

  private CPQModel_Product_SL addOptionsToModel(CPQModel_Product_SL productModel, List<Id> optionProductIds) {
    for (CPQModel_Option_SL optionModel : productModel.options) {
      if (optionProductIds.contains(optionModel.record.SBQQ__OptionalSKU__c)) {
        CPQModel_Configuration_SL configModel = new CPQModel_Configuration_SL();
        //        optionModel.record.SBQQ__Quantity__c=10;
        configModel.optionData = optionModel.record;
        configModel.configuredProductId = optionModel.record.SBQQ__ConfiguredSKU__c;
        configModel.optionId = optionModel.record.Id;
        configModel.optionConfigurations = new List<CPQModel_Configuration_SL>();
        configModel.isUpgrade = false;
        configModel.isDynamicOption = false;
        configModel.priceEditable = false;
        configModel.changedByProductActions = false;
        configModel.validationMessages = new List<String>();
        configModel.configured = true;
        configModel.configurationEntered = true;
        configModel.configurationData = new SBQQ__ProductOption__c();
        configModel.inheritedConfigurationData = new SBQQ__ProductOption__c();
        configModel.hiddenOptionIds = new Set<Id>();
        configModel.disabledOptionIds = new Set<Id>();
        configModel.listPrice = optionModel.record.SBQQ__UnitPrice__c;
        productModel.configuration.optionConfigurations.add(configModel);
      }
    }
    return productModel;
  }
}