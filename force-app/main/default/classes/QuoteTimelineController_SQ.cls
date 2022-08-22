public with sharing class QuoteTimelineController_SQ {
  public static IBillingSegmentsSelector_SL billingSegmentSelector {
    get {
      return (IBillingSegmentsSelector_SL) Application_SL.Selector.newInstance(Billing_Segment__c.SObjectType);
    }
    set;
  }

  public class QuoteTimelineWrapper {
    @AuraEnabled
    public SBQQ__Quote__c quote { get; set; }
    @AuraEnabled
    public String quoteUrl { get; set; }
    @AuraEnabled
    public Boolean isReadOnly { get; set; }
    @AuraEnabled
    public List<SBQQ__QuoteLine__c> quoteLines { get; set; }
    @AuraEnabled
    public List<QuoteLineLink__c> quoteLineLinks { get; set; }
    @AuraEnabled
    public List<Billing_Segment__c> billingSegments { get; set; }
    @AuraEnabled
    public String editLineUrl { get; set; }
  }

  /**
   * @description This method returns necessary data for quote timeline gantt
   * This is being used in quoteTimeline lwc
   */
  @AuraEnabled
  public static QuoteTimelineWrapper getGanttData(String quoteId) {
    try {
      QuoteTimelineWrapper wrapper = new QuoteTimelineWrapper();

      wrapper.quote = [
        SELECT
          Id,
          Name,
          SBQQ__StartDate__c,
          SBQQ__EndDate__c,
          CurrencyIsoCode,
          SBQQ__Status__c,
          SBQQ__MasterContract__c,
          SBQQ__MasterContract__r.StartDate
        FROM SBQQ__Quote__c
        WHERE Id = :quoteId
      ];
      wrapper.quoteUrl = '/' + quoteId;
      wrapper.isReadOnly = wrapper.quote.SBQQ__Status__c != 'Draft';

      // Building url in apex due to CRIF check
      PageReference editLineRef = new PageReference('/apex/SBQQ__sb');
      editLineRef.getParameters().put('Id', quoteId);
      wrapper.editLineUrl = editLineRef.getUrl();

      Map<Id, SBQQ__QuoteLine__c> quoteLineMap = new Map<Id, SBQQ__QuoteLine__c>(
        [
          SELECT
            Id,
            Name,
            SBQQ__ProductName__c,
            SBQQ__EffectiveStartDate__c,
            SBQQ__EffectiveEndDate__c,
            SBQQ__RequiredBy__c,
            SBQQ__Quantity__c,
            SBQQ__ListTotal__c,
            SBQQ__NetTotal__c,
            SBQQ__TotalDiscountRate__c,
            SBQQ__Bundle__c,
            CPQ_QliARR__c,
            CurrencyIsoCode,
            QuoteTimelineOrder__c,
            SBQQ__UpgradedSubscription__c,
            SBQQ__UpgradedSubscription__r.SBQQ__StartDate__c
          FROM SBQQ__QuoteLine__c
          WHERE SBQQ__Quote__c = :quoteId
          ORDER BY SBQQ__Number__c ASC
        ]
      );
      wrapper.quoteLines = quoteLineMap.values();

      wrapper.quoteLineLinks = [
        SELECT Id, Type__c, Source__c, Target__c
        FROM QuoteLineLink__c
        WHERE Source__c IN :quoteLineMap.keyset() OR Target__c IN :quoteLineMap.keyset()
      ];

      wrapper.billingSegments = billingSegmentSelector.selectByQuoteId(new Set<Id>{ quoteId }, false);

      return wrapper;
    } catch (Exception e) {
      String errorMessage = e.getMessage() + e.getStackTraceString();
      AuraHandledException ae = new AuraHandledException(errorMessage);
      ae.setMessage(errorMessage);
      throw ae;
    }
  }

  /**
   * @description This method handles DML operations for quote timeline gantt
   * This is updaing QuoteLine and recreating QuoteLineLinks
   */
  @AuraEnabled
  public static void saveGanttData(
    String quoteId,
    List<SBQQ__QuoteLine__c> quoteLines,
    List<QuoteLineLink__c> quoteLineLinks
  ) {
    try {
      // Update quote
      update new SBQQ__Quote__c(Id = quoteId, SBQQ__ContractingMethod__c = 'Single Contract');
      // Update quote lines
      update quoteLines;
      // Delete existing links
      delete [
        SELECT Id
        FROM QuoteLineLink__c
        WHERE Source__r.SBQQ__Quote__c = :quoteId OR Target__r.SBQQ__Quote__c = :quoteId
      ];
      // Insert new links
      insert quoteLineLinks;
    } catch (Exception e) {
      String errorMessage = e.getMessage() + e.getStackTraceString();
      AuraHandledException ae = new AuraHandledException(errorMessage);
      ae.setMessage(errorMessage);
      throw ae;
    }
  }

  /**
   * @description Querying status of CPQ Quote calculator job
   */
  @AuraEnabled
  public static String pollQuoteCalculationStatus(String quoteId) {
    String recordString = quoteId + '%';
    List<SBQQ__RecordJob__c> cpqJobs = [
      SELECT Id, SBQQ__JobId__c
      FROM SBQQ__RecordJob__c
      WHERE SBQQ__RecordId__c LIKE :recordString
      ORDER BY CreatedDate DESC
      LIMIT 1
    ];
    if (!cpqJobs.isEmpty()) {
      String apexJobId = cpqJobs[0].SBQQ__JobId__c;
      List<AsyncApexJob> apexJobs = [SELECT Status FROM AsyncApexJob WHERE Id = :apexJobId];
      if (!apexJobs.isEmpty()) {
        // Holding Queued Preparing Processing Aborted Completed Failed
        return apexJobs[0].Status;
      }
    }
    return 'Unknown';
  }
}