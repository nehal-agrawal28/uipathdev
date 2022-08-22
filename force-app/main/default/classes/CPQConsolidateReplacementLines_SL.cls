public with sharing class CPQConsolidateReplacementLines_SL extends AbstractQueueable implements Database.AllowsCallouts {
  Set<String> jobIds { get; set; }
  String quoteId { get; set; }
  String originalTransactionId { get; set; }

  // this class doesn't care how the jobs finished, as long as they are considered done it will process the quote lines
  // if an amend quote job failed, it will still consider it done for the purpose of making quote lines
  private static final Set<String> FINISHED_STATUSES = new Set<String>{ 'aborted', 'completed', 'failed' };

  private QuotesSelector_SL quoteSelector {
    get {
      return (QuotesSelector_SL) Application_SL.Selector.newInstance(SBQQ__Quote__c.SObjectType);
    }
    set;
  }

  private QuoteLinesSelector_SL quoteLinesSelectorSL {
    get {
      return (QuoteLinesSelector_SL) Application_SL.Selector.newInstance(SBQQ__QuoteLine__c.SObjectType);
    }
    set;
  }

  private PricebookEntrySelector_SL pricebookEntrySelectorSL {
    get {
      return (PricebookEntrySelector_SL) Application_SL.Selector.newInstance(PricebookEntry.SObjectType);
    }
    set;
  }

  public CPQConsolidateReplacementLines_SL(Set<String> jobIds, String quoteId, String originalTransactionId) {
    super('CPQCreateCancellationQuote_SL');

    this.jobIds = jobIds;
    this.quoteId = quoteId;
    this.originalTransactionId = originalTransactionId;
    //to allow for logging against record. only used in non-bulk contexts
    if (quoteId != null) {
      this.setPrimaryRecordId(quoteId);
    }
  }

  public override void work() {
    executeWork();
  }

  public void executeWork() {
    try {
      Boolean haveJobsFinished = haveJobsFinished();

      if (jobIds == null || haveJobsFinished) {
        cloneQuoteLines();
      } else {
        CPQConsolidateReplacementLines_SL quoteLineQueueable = new CPQConsolidateReplacementLines_SL(
          jobIds,
          quoteId,
          this.originalTransactionId
        );

        AbstractQueueable.enqueue(quoteLineQueueable);
      }
    } catch (Exception e) {
      Logger.error('Failed consolidating lines into replacement quote', quoteId, e);
      Logger.saveLog();
      throw e;
    }
  }

  private Boolean haveJobsFinished() {
    List<ApexJobStatusMsg_CM> jobs = ApexJobSelector_CM.getJobStatusById(jobIds);
    Boolean jobsFinished = true;
    for (ApexJobStatusMsg_CM job : jobs) {
      if (!FINISHED_STATUSES.contains(job.jobStatus.toLowerCase())) {
        jobsFinished = false;
      }
    }
    // Test classes cannot chain jobs, defaulting it to true for this case
    return Test.isRunningTest() ? true : jobsFinished;
  }

  public void cloneQuoteLines() {
    SBQQ__Quote__c quote = quoteSelector.selectById(new Set<Id>{ quoteId }, false)[0];
    List<SBQQ__QuoteLine__c> quoteLines = quoteLinesSelectorSL.queryQuoteLinesByReplacementQuote(quoteId);
    List<SBQQ__QuoteLine__c> clonedQuoteLines = cloneQuoteLinesIntoReplacementQuote(quoteLines, quote);
    SBQQ.TriggerControl.disable();
    final fflib_ISObjectUnitOfWork unitOfWork = Application_SL.UnitOfWork.newInstance();
    unitOfWork.registerNew(clonedQuoteLines);
    unitOfWork.commitWork();
    this.populateRequiredBys(clonedQuoteLines, quoteLines);
    SBQQ.TriggerControl.enable();
    updateQuotes(JSON.serialize(clonedQuoteLines));
  }

  //Populate SBQQ__RequiredBy__c on QLs using map data
  public List<SBQQ__QuoteLine__c> populateRequiredBys(
    List<SBQQ__QuoteLine__c> newQlList,
    List<SBQQ__QuoteLine__c> oldQlList
  ) {
    Map<Integer, Integer> reqByMap = createRequiredByMap(oldQlList);
    for (integer i : reqByMap.keySet()) {
      newQlList[i].SBQQ__RequiredBy__c = newQlList[reqByMap.get(i)].id;
    }
    return newQlList;
  }

  private Map<Integer, Integer> createRequiredByMap(List<SBQQ__QuoteLine__c> oldQlList) {
    Map<Id, Integer> idIndexMap = new Map<Id, Integer>();
    Map<Integer, Integer> reqByMap = new Map<Integer, Integer>();

    for (Integer i = 0; i < oldQlList.size(); i++) {
      idIndexMap.put(oldQlList[i].Id, i);
    }

    for (Integer i = 0; i < oldQlList.size(); i++) {
      if (oldQlList[i].SBQQ__RequiredBy__c != null) {
        reqByMap.put(i, idIndexMap.get(oldQlList[i].SBQQ__RequiredBy__c));
      }
    }
    return reqByMap;
  }

  /**
   * Updating the quote line items
   * This is done in a async method due to callout issues with updating quote line items
   * @param  jsonRecords  quote string that can be converted to a list of quotes to be updated
   */
  @testVisible
  private static void updateQuotes(String jsonRecords) {
    QuoteRipReplaceUpdQLIsQueueable_SL.updateQuoteLines(jsonRecords);
  }

  public List<SBQQ__QuoteLine__c> cloneQuoteLinesIntoReplacementQuote(
    List<SBQQ__QuoteLine__c> oldQuoteLines,
    SBQQ__Quote__c replacementQuote
  ) {
    return getClonedLines(oldQuoteLines.deepClone(false, false, false), replacementQuote);
  }

  // Remove fields that indicate quote is amendment or relate to data specific to old quote (have to remove Quote and Quote Line Ids later from string)
  private List<SBQQ__QuoteLine__c> getClonedLines(List<SBQQ__QuoteLine__c> newQlList, SBQQ__Quote__c replacementQuote) {
    //get all PBEs for the QLIs
    Set<Id> currentQliPbeIds = new Set<Id>(
      Collection.of(newQlList).pluckIds(SBQQ__QuoteLine__c.SBQQ__PricebookEntryId__c)
    );
    Map<Id, PricebookEntry> currentQliPbes = new Map<Id, PricebookEntry>(
      pricebookEntrySelectorSL.selectById(currentQliPbeIds, false)
    );

    Set<String> existingQliProductCodes = new Set<String>(
      Collection.of(currentQliPbes.values()).pluckStrings(PricebookEntry.ProductCode)
    );
    //
    Id targetPricebookId = replacementQuote.SBQQ__PricebookId__c;
    String targetCurrencyCode = replacementQuote.CurrencyIsoCode;

    Map<Id, PricebookEntry> targetQliPbes = new Map<Id, PricebookEntry>(
      (List<PricebookEntry>) Database.query(
        pricebookEntrySelectorSL.newQueryFactory(true)
          .setCondition(
            'Pricebook2Id = :targetPricebookId AND ProductCode IN :existingQliProductCodes AND CurrencyIsoCode = :targetCurrencyCode AND ProductCode != null'
          )
          .toSOQL()
      )
    );

    Map<String, Map<String, Id>> priceBookEntryIdByProductCodeByCurrency = getPriceBookEntryIdByProductCodeByCurrency(
      targetQliPbes
    );

    Integer i = 1;
    for (SBQQ__QuoteLine__c ql : newQlList) {
      Boolean isPBEinTargetPricebookPBEs = targetQliPbes.containsKey(ql.SBQQ__PricebookEntryId__c);
      if (!isPBEinTargetPricebookPBEs && ql.SBQQ__ProductCode__c != null && !String.isBlank(ql.SBQQ__ProductCode__c)) {
        setQLIpricebookentry(ql, currentQliPbes, priceBookEntryIdByProductCodeByCurrency);
      }
      ql.SBQQ__Quantity__c = ql.SBQQ__PriorQuantity__c;
      ql.SBQQ__PriorQuantity__c = null;
      ql.SBQQ__UpgradedSubscription__c = null;
      ql.SBQQ__UpgradedSubscription__r = null;
      ql.SBQQ__Existing__c = false;
      ql.SBQQ__RequiredBy__c = null;
      ql.SBQQ__Group__c = null;
      ql.SBQQ__StartDate__c = null;
      ql.SBQQ__EndDate__c = null;
      ql.SBQQ__SubscriptionTerm__c = null;
      ql.SBQQ__UpgradedAsset__c = null;
      ql.SBQQ__Quote__c = replacementQuote.Id;
      ql.SBQQ__Number__c = i; // Use loop iterator to ensure the bundles appear in order needed
      i++;
    }
    return newQlList;
  }

  /*
   * For a given qli, checks if it's referenced PBE was retrieved
   * then check for a given target Pricebook2 whether that qli's ProductCode has currency entries
   * then checks the given qli's currency has a corresponding PBE for that ProductCode
   * if ALL true, set the qli's pricebookentry to the resolved PBE.Id
   * else, do nothing
   */
  @TestVisible
  private void setQLIpricebookentry(
    SBQQ__QuoteLine__c ql,
    Map<Id, PricebookEntry> currentQliPbes,
    Map<String, Map<String, Id>> priceBookEntryByProductCodeByCurrency
  ) {
    //check current PBE was queried
    if (currentQliPbes.containsKey(ql.SBQQ__PricebookEntryId__c)) {
      PricebookEntry currentPbe = currentQliPbes.get(ql.SBQQ__PricebookEntryId__c);

      //check target Pricebook2 has this ProductCode
      if (priceBookEntryByProductCodeByCurrency.containsKey(currentPbe.ProductCode)) {
        //get PBE currencies for this ProductCode
        Map<String, Id> productCodePbeIdByCurrencyIso = priceBookEntryByProductCodeByCurrency.get(
          currentPbe.ProductCode
        );

        //check target Pricebook2 has this currency for this ProductCode
        if (productCodePbeIdByCurrencyIso.containsKey(ql.CurrencyIsoCode)) {
          ql.SBQQ__PricebookEntryId__c = productCodePbeIdByCurrencyIso.get(ql.CurrencyIsoCode);
        }
      }
    }
  }

  /*
   * Organises a given id=>pbe map into a map that for a given ProductCode, returns
   * a map of CurrencyIsoCode to PBE.Id
   * Example: get('UiPath01').put('USD','Id1234')
   */
  @TestVisible
  private static Map<String, Map<String, Id>> getPriceBookEntryIdByProductCodeByCurrency(
    Map<Id, PricebookEntry> pbeById
  ) {
    Map<String, Map<String, Id>> priceBookEntryIdByProductCodeByCurrency = new Map<String, Map<String, Id>>();

    for (PricebookEntry pbe : pbeById.values()) {
      Map<String, Id> priceBookEntryIdByCurrency;
      if (priceBookEntryIdByProductCodeByCurrency.containsKey(pbe.ProductCode)) {
        priceBookEntryIdByCurrency = priceBookEntryIdByProductCodeByCurrency.get(pbe.ProductCode);
      } else {
        priceBookEntryIdByCurrency = new Map<String, Id>();
      }
      priceBookEntryIdByCurrency.put(pbe.CurrencyIsoCode, pbe.Id);
      priceBookEntryIdByProductCodeByCurrency.put(pbe.ProductCode, priceBookEntryIdByCurrency);
    }
    return priceBookEntryIdByProductCodeByCurrency;
  }
}